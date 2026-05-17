import Foundation

public enum TunnelState: Equatable, Sendable {
    case idle
    case starting
    case active
    case failed(String)
    case stopping
    case stopped

    var label: String {
        switch self {
        case .idle:
            "Idle"
        case .starting:
            "Starting"
        case .active:
            "Active"
        case .failed:
            "Failed"
        case .stopping:
            "Stopping"
        case .stopped:
            "Stopped"
        }
    }
}

public struct ActiveTunnel: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var localURL: String
    public let origin: String
    public let tunnelOrigin: String
    public var quickTunnelURL: String?
    public var publicURL: String?
    public var state: TunnelState

    var canStop: Bool {
        state == .starting || state == .active
    }
}

@MainActor
final class TunnelManager: ObservableObject {
    @Published private(set) var state: TunnelState = .idle
    @Published private(set) var tunnels: [ActiveTunnel] = []
    @Published private(set) var lastError: String?
    @Published private(set) var logs: [String] = []

    private var contexts: [UUID: TunnelProcessContext] = [:]
    private let startupTimeoutSeconds: UInt64 = 25

    func start(rawLocalURL: String, onStarted: @escaping @MainActor @Sendable (String, String) -> Void) {
        let mapping: LocalURLMapping
        do {
            mapping = try LocalURLParser.parse(rawLocalURL)
        } catch {
            lastError = error.localizedDescription
            updateAggregateState()
            appendLog(error.localizedDescription)
            return
        }

        if reuseActiveTunnelIfPossible(mapping: mapping, onStarted: onStarted) {
            return
        }

        let tunnelID = UUID()
        let tunnel = ActiveTunnel(
            id: tunnelID,
            localURL: mapping.input.absoluteString,
            origin: mapping.origin.absoluteString,
            tunnelOrigin: mapping.tunnelOrigin.absoluteString,
            quickTunnelURL: nil,
            publicURL: nil,
            state: .starting
        )

        tunnels.insert(tunnel, at: 0)
        lastError = nil
        updateAggregateState()

        do {
            let executableURL = try CloudflaredLocator.executableURL()
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = executableURL
            process.arguments = ["tunnel", "--url", mapping.tunnelOrigin.absoluteString]
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
                    return
                }

                Task { @MainActor in
                    self?.handleCloudflaredOutput(
                        text,
                        tunnelID: tunnelID,
                        mapping: mapping,
                        onStarted: onStarted
                    )
                }
            }

            errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
                    return
                }

                Task { @MainActor in
                    self?.handleCloudflaredOutput(
                        text,
                        tunnelID: tunnelID,
                        mapping: mapping,
                        onStarted: onStarted
                    )
                }
            }

            process.terminationHandler = { [weak self] process in
                Task { @MainActor in
                    self?.handleTermination(tunnelID: tunnelID, status: process.terminationStatus)
                }
            }

            contexts[tunnelID] = TunnelProcessContext(
                id: tunnelID,
                mapping: mapping,
                process: process,
                outputPipe: outputPipe,
                errorPipe: errorPipe
            )
            appendLog("Starting cloudflared tunnel for \(mapping.origin.absoluteString)")
            if mapping.tunnelOrigin != mapping.origin {
                appendLog("Using \(mapping.tunnelOrigin.absoluteString) for tunnel connection")
            }

            try process.run()
            startTimeout(for: tunnelID)
        } catch {
            let message = "Could not start cloudflared: \(error.localizedDescription)"
            markTunnel(tunnelID, failed: message)
            appendLog(message)
            cleanupContext(tunnelID)
        }
    }

    func stop(_ tunnelID: UUID) {
        guard let context = contexts[tunnelID] else {
            updateTunnel(tunnelID) { tunnel in
                tunnel.state = .stopped
            }
            updateAggregateState()
            return
        }

        updateTunnel(tunnelID) { tunnel in
            tunnel.state = .stopping
        }
        updateAggregateState()
        appendLog("Stopping tunnel for \(context.mapping.origin.absoluteString)")
        context.process.terminate()
    }

    func stopAll() {
        let ids = contexts.keys
        if ids.isEmpty {
            tunnels = tunnels.map { tunnel in
                var updated = tunnel
                if updated.state == .starting || updated.state == .active || updated.state == .stopping {
                    updated.state = .stopped
                }
                return updated
            }
            updateAggregateState()
            return
        }

        for id in ids {
            stop(id)
        }
    }

    func copyPublicURL(for tunnelID: UUID) {
        guard
            let publicURL = tunnels.first(where: { $0.id == tunnelID })?.publicURL
        else {
            return
        }

        Clipboard.copy(publicURL)
    }

    func publicURL(for tunnelID: UUID) -> URL? {
        guard
            let publicURL = tunnels.first(where: { $0.id == tunnelID })?.publicURL
        else {
            return nil
        }

        return URL(string: publicURL)
    }

    private func handleCloudflaredOutput(
        _ text: String,
        tunnelID: UUID,
        mapping: LocalURLMapping,
        onStarted: @escaping @MainActor @Sendable (String, String) -> Void
    ) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        appendLog(cleanText)
        contexts[tunnelID]?.recordOutput(cleanText)

        guard
            contexts[tunnelID] != nil,
            tunnels.first(where: { $0.id == tunnelID })?.state == .starting,
            let quickTunnelURL = CloudflaredLogParser.firstQuickTunnelURL(in: text),
            let publicURL = try? mapping.publicURL(from: quickTunnelURL)
        else {
            return
        }

        updateTunnel(tunnelID) { tunnel in
            tunnel.quickTunnelURL = quickTunnelURL.absoluteString
            tunnel.publicURL = publicURL.absoluteString
            tunnel.state = .active
        }
        updateAggregateState()
        contexts[tunnelID]?.startupTask?.cancel()
        Clipboard.copy(publicURL.absoluteString)
        appendLog("Copied public URL: \(publicURL.absoluteString)")
        onStarted(mapping.input.absoluteString, publicURL.absoluteString)
    }

    private func handleTermination(tunnelID: UUID, status: Int32) {
        guard let tunnel = tunnels.first(where: { $0.id == tunnelID }) else {
            cleanupContext(tunnelID)
            updateAggregateState()
            return
        }

        let wasStopping = tunnel.state == .stopping
        let wasStarting = tunnel.state == .starting
        let wasActive = tunnel.state == .active
        let alreadyFailed = failedMessage(for: tunnel) != nil
        let context = contexts[tunnelID]

        cleanupContext(tunnelID)

        if alreadyFailed {
            appendLog("cloudflared exited with status \(status)")
        } else if wasStopping || status == 0 || wasActive {
            updateTunnel(tunnelID) { tunnel in
                tunnel.state = .stopped
            }
            appendLog("Tunnel stopped for \(tunnel.origin)")
        } else if wasStarting {
            let message = CloudflaredFailureClassifier.message(
                outputLines: context?.outputLines ?? [],
                mapping: tunnelMapping(from: tunnel),
                fallback: "cloudflared exited before creating a public URL."
            )
            markTunnel(tunnelID, failed: message)
            appendLog("cloudflared exited with status \(status) before creating a public URL")
        } else {
            markTunnel(tunnelID, failed: "cloudflared exited with status \(status).")
            appendLog("cloudflared exited with status \(status)")
        }

        updateAggregateState()
    }

    private func startTimeout(for tunnelID: UUID) {
        let timeout = startupTimeoutSeconds
        contexts[tunnelID]?.startupTask?.cancel()
        contexts[tunnelID]?.startupTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeout))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard
                    let self,
                    self.tunnels.first(where: { $0.id == tunnelID })?.state == .starting
                else {
                    return
                }

                let tunnel = self.tunnels.first(where: { $0.id == tunnelID })
                let message = CloudflaredFailureClassifier.message(
                    outputLines: self.contexts[tunnelID]?.outputLines ?? [],
                    mapping: tunnel.flatMap(self.tunnelMapping(from:)),
                    fallback: "Timed out waiting for a tunnel URL. Check that the local server is still running, then try again."
                )
                self.markTunnel(tunnelID, failed: message)
                self.appendLog("Timed out waiting for cloudflared to report a quick tunnel URL")
                self.contexts[tunnelID]?.process.terminate()
                self.updateAggregateState()
            }
        }
    }

    private func reuseActiveTunnelIfPossible(
        mapping: LocalURLMapping,
        onStarted: @escaping @MainActor @Sendable (String, String) -> Void
    ) -> Bool {
        guard let existing = tunnels.first(where: {
            $0.tunnelOrigin == mapping.tunnelOrigin.absoluteString && $0.state == .active
        }) else {
            return false
        }

        guard
            let quickTunnelURLString = existing.quickTunnelURL,
            let quickTunnelURL = URL(string: quickTunnelURLString),
            let publicURL = try? mapping.publicURL(from: quickTunnelURL)
        else {
            return true
        }

        updateTunnel(existing.id) { tunnel in
            tunnel.localURL = mapping.input.absoluteString
            tunnel.publicURL = publicURL.absoluteString
        }
        Clipboard.copy(publicURL.absoluteString)
        appendLog("Reused active tunnel for \(mapping.origin.absoluteString)")
        appendLog("Copied public URL: \(publicURL.absoluteString)")
        onStarted(mapping.input.absoluteString, publicURL.absoluteString)
        return true
    }

    private func markTunnel(_ tunnelID: UUID, failed message: String) {
        updateTunnel(tunnelID) { tunnel in
            tunnel.state = .failed(message)
        }
        lastError = message
        updateAggregateState()
    }

    private func updateTunnel(_ tunnelID: UUID, mutate: (inout ActiveTunnel) -> Void) {
        guard let index = tunnels.firstIndex(where: { $0.id == tunnelID }) else {
            return
        }

        var tunnel = tunnels[index]
        mutate(&tunnel)
        tunnels[index] = tunnel
    }

    private func updateAggregateState() {
        if tunnels.contains(where: { $0.state == .starting }) {
            state = .starting
        } else if tunnels.contains(where: { $0.state == .stopping }) {
            state = .stopping
        } else if tunnels.contains(where: { $0.state == .active }) {
            state = .active
        } else if let failed = tunnels.compactMap({ failedMessage(for: $0) }).first ?? lastError {
            state = .failed(failed)
        } else {
            state = .idle
        }
    }

    private func failedMessage(for tunnel: ActiveTunnel) -> String? {
        if case .failed(let message) = tunnel.state {
            return message
        }

        return nil
    }

    private func cleanupContext(_ tunnelID: UUID) {
        guard let context = contexts.removeValue(forKey: tunnelID) else {
            return
        }

        context.outputPipe.fileHandleForReading.readabilityHandler = nil
        context.errorPipe.fileHandleForReading.readabilityHandler = nil
        context.startupTask?.cancel()
    }

    private func appendLog(_ line: String) {
        guard !line.isEmpty else {
            return
        }

        logs.append(line)
        if logs.count > 200 {
            logs.removeFirst(logs.count - 200)
        }
    }

    private func tunnelMapping(from tunnel: ActiveTunnel) -> LocalURLMapping? {
        try? LocalURLParser.parse(tunnel.localURL)
    }
}

private final class TunnelProcessContext {
    let id: UUID
    let mapping: LocalURLMapping
    let process: Process
    let outputPipe: Pipe
    let errorPipe: Pipe
    var startupTask: Task<Void, Never>?
    var outputLines: [String] = []

    init(
        id: UUID,
        mapping: LocalURLMapping,
        process: Process,
        outputPipe: Pipe,
        errorPipe: Pipe
    ) {
        self.id = id
        self.mapping = mapping
        self.process = process
        self.outputPipe = outputPipe
        self.errorPipe = errorPipe
    }

    func recordOutput(_ text: String) {
        guard !text.isEmpty else {
            return
        }

        outputLines.append(text)
        if outputLines.count > 40 {
            outputLines.removeFirst(outputLines.count - 40)
        }
    }
}

enum CloudflaredFailureClassifier {
    static func message(
        outputLines: [String],
        mapping: LocalURLMapping?,
        fallback: String
    ) -> String {
        let output = outputLines.joined(separator: "\n").lowercased()
        let origin = mapping?.origin.absoluteString ?? "the local URL"

        if output.contains("connection refused")
            || output.contains("connect: connection refused")
            || output.contains("failed to connect to origin")
            || output.contains("unable to connect to the origin")
            || output.contains("connection reset by peer") {
            return "Nothing is responding at \(origin). Start your local dev server, then try again."
        }

        if output.contains("no route to host") || output.contains("network is unreachable") {
            return "TunnelBar could not reach \(origin). Check the local server address and try again."
        }

        if output.contains("permission denied") {
            return "cloudflared could not start because macOS denied permission. Check Diagnostics, then try again."
        }

        if output.contains("failed to request quick tunnel")
            || output.contains("error creating quick tunnel")
            || output.contains("could not create quick tunnel") {
            return "cloudflared could not create a tunnel. Check Diagnostics, then try again."
        }

        return fallback
    }
}

enum CloudflaredLocator {
    enum LocatorError: LocalizedError {
        case missingCloudflared

        var errorDescription: String? {
            "cloudflared was not found. Bundle cloudflared in the app resources, or install it locally while developing."
        }
    }

    static func executableURL() throws -> URL {
        if let bundledURL = Bundle.main.url(forResource: bundledResourceName, withExtension: nil) {
            try makeExecutableIfNeeded(bundledURL)
            return bundledURL
        }

        if let pathURL = findOnPath("cloudflared") {
            return pathURL
        }

        throw LocatorError.missingCloudflared
    }

    private static var bundledResourceName: String {
        #if arch(arm64)
        "cloudflared-arm64"
        #else
        "cloudflared-amd64"
        #endif
    }

    private static func findOnPath(_ name: String) -> URL? {
        let paths = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)

        for path in paths {
            let candidate = URL(fileURLWithPath: path).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }

    private static func makeExecutableIfNeeded(_ url: URL) throws {
        guard !FileManager.default.isExecutableFile(atPath: url.path) else {
            return
        }

        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: url.path
        )
    }
}
