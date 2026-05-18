import AppKit
import SwiftUI

enum TunnelBarViewMetrics {
    static let width: CGFloat = 520
    static let fixedHeight: CGFloat = 430
    static let minimumHeight: CGFloat = fixedHeight
    static let collapsedHeight: CGFloat = fixedHeight
    static let maximumHeight: CGFloat = fixedHeight
}

struct TunnelBarView: View {
    @ObservedObject var tunnelManager: TunnelManager
    @ObservedObject var settings: AppSettings
    var onHeightChange: ((CGFloat) -> Void)?

    @State private var localURL = "http://localhost:3000"
    @State private var showDiagnostics: Bool
    @State private var showAbout = false

    private let accent = TBTheme.accent

    init(
        tunnelManager: TunnelManager,
        settings: AppSettings,
        onHeightChange: ((CGFloat) -> Void)? = nil
    ) {
        self.tunnelManager = tunnelManager
        self.settings = settings
        self.onHeightChange = onHeightChange
        _showDiagnostics = State(initialValue: settings.openDiagnosticsByDefault)
    }

    var body: some View {
        ZStack {
            TBTheme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header
                inputSection
                activeSection
                diagnosticsSection
                footer
            }
            .padding(18)
        }
        .frame(width: TunnelBarViewMetrics.width)
        .foregroundStyle(TBTheme.primaryText)
        .preferredColorScheme(.dark)
        .readHeight { height in
            onHeightChange?(height)
        }
        .animation(.easeInOut(duration: 0.2), value: visibleTunnelCount)
        .animation(.easeInOut(duration: 0.2), value: showDiagnostics)
        .sheet(isPresented: $showAbout) {
            AboutTunnelBarView()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            TerminalBrandMark()

            Spacer()

            HStack(spacing: 7) {
                if shouldPulseHeaderStatus {
                    PulsingStatusDot(color: statusColor)
                } else {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 9, height: 9)
                }

                Text(tunnelManager.state.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TBTheme.primaryText)
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TypewriterText("Local URL:", color: TBTheme.accent, speedMilliseconds: 22)

                InlineURLTextField(text: $localURL, placeholder: "http://localhost:3000")
                    .frame(height: 23)

                inputActionButton
            }
            .font(.system(.body, design: .monospaced).weight(.semibold))
            .padding(.vertical, 6)

            if let message = tunnelManager.lastError {
                MessagePanel(title: "Could not create tunnel", message: message)
            }
        }
    }

    private var inputActionButton: some View {
        Button {
            if let matchingRunningTunnel {
                tunnelManager.stop(matchingRunningTunnel.id)
            } else {
                tunnelManager.start(rawLocalURL: localURL)
            }
        } label: {
            Image(systemName: matchingRunningTunnel == nil ? "play.fill" : "stop.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(matchingRunningTunnel == nil ? accent : TBTheme.danger)
        }
        .buttonStyle(.plain)
        .disabled(localURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && matchingRunningTunnel == nil)
        .help(matchingRunningTunnel == nil ? "Start tunnel" : "Stop tunnel")
    }

    @ViewBuilder
    private var activeSection: some View {
        let visibleTunnels = tunnelManager.tunnels.filter { tunnel in
            tunnel.state == .active || tunnel.state == .starting || tunnel.state == .stopping
        }

        if !visibleTunnels.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(visibleTunnels) { tunnel in
                    TerminalTunnelLine(
                        tunnel: tunnel,
                        statusColor: color(for: tunnel.state),
                        onStop: { tunnelManager.stop(tunnel.id) },
                        onCopy: { tunnelManager.copyPublicURL(for: tunnel.id) },
                        publicURL: tunnelManager.publicURL(for: tunnel.id)
                    )
                }
            }
        }
    }

    private var diagnosticsSection: some View {
        DisclosureGroup(isExpanded: $showDiagnostics) {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if tunnelManager.logs.isEmpty {
                        Text("No diagnostics yet.")
                            .foregroundStyle(TBTheme.secondaryText)
                    } else {
                        ForEach(Array(tunnelManager.logs.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
            }
            .frame(height: 120)
            .padding(10)
            .background(TBTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } label: {
            Text("Diagnostics")
                .font(.headline)
        }
    }

    private var footer: some View {
        HStack {
            Text("Temporary tunnel URLs are public while running.")
                .font(.caption2)
                .foregroundStyle(TBTheme.secondaryText)

            Spacer()

            SettingsLink {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("Settings")

            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("About")

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
    }

    private var visibleTunnelCount: Int {
        tunnelManager.tunnels.filter { tunnel in
            tunnel.state == .active || tunnel.state == .starting || tunnel.state == .stopping
        }.count
    }

    private var matchingRunningTunnel: ActiveTunnel? {
        guard
            let mapping = try? LocalURLParser.parse(localURL)
        else {
            return nil
        }

        return tunnelManager.tunnels.first { tunnel in
            tunnel.tunnelOrigin == mapping.tunnelOrigin.absoluteString
                && (tunnel.state == .active || tunnel.state == .starting || tunnel.state == .stopping)
        }
    }

    private var statusColor: Color {
        switch tunnelManager.state {
        case .active:
            TBTheme.success
        case .starting, .stopping:
            TBTheme.warning
        case .idle, .stopped:
            TBTheme.secondaryText
        case .failed:
            TBTheme.danger
        }
    }

    private var shouldPulseHeaderStatus: Bool {
        switch tunnelManager.state {
        case .active, .starting, .stopping, .failed:
            true
        case .idle, .stopped:
            false
        }
    }

    private func color(for state: TunnelState) -> Color {
        switch state {
        case .active:
            TBTheme.success
        case .starting, .stopping:
            TBTheme.warning
        case .failed:
            TBTheme.danger
        case .idle, .stopped:
            .secondary
        }
    }
}

enum TBTheme {
    static let accent = Color(red: 0.85, green: 1.0, blue: 0.37)
    static let success = Color(red: 0.38, green: 0.95, blue: 0.46)
    static let warning = Color(red: 1.0, green: 0.56, blue: 0.18)
    static let danger = Color(red: 1.0, green: 0.28, blue: 0.24)
    static let background = Color(red: 0.035, green: 0.043, blue: 0.035)
    static let cardBackground = Color(red: 0.055, green: 0.063, blue: 0.052)
    static let fieldBackground = Color(red: 0.025, green: 0.029, blue: 0.025)
    static let primaryText = Color(red: 0.95, green: 0.94, blue: 0.90)
    static let secondaryText = Color(red: 0.62, green: 0.62, blue: 0.58)
    static let border = Color.white.opacity(0.13)
    static let controlBackground = Color.white.opacity(0.07)
    static let controlBackgroundHover = Color.white.opacity(0.11)
}

private struct PulsingStatusDot: View {
    let color: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.35) / 1.35
            let pulse = sin(phase * .pi * 2)

            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .scaleEffect(0.92 + pulse * 0.14)
                .opacity(0.76 + pulse * 0.2)
                .shadow(color: color.opacity(0.55), radius: 6)
        }
        .frame(width: 11, height: 11)
    }
}

struct TerminalBrandMark: View {
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            Text("% tunnelbar")

            TimelineView(.periodic(from: .now, by: 0.45)) { context in
                let isVisible = Int(context.date.timeIntervalSinceReferenceDate / 0.45).isMultiple(of: 2)

                Rectangle()
                    .fill(TBTheme.accent)
                    .frame(width: 8, height: 18)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: 1)
            }
            .frame(width: 8, height: 18)
        }
        .font(.system(.title3, design: .monospaced).weight(.semibold))
        .foregroundStyle(TBTheme.accent)
    }
}

private struct AboutTunnelBarView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TBTheme.background
                .ignoresSafeArea()

            VStack(spacing: 18) {
                TunnelBarLogoView(size: 92)

                VStack(spacing: 6) {
                    Text("TunnelBar")
                        .font(.system(.title2, design: .monospaced).weight(.semibold))
                        .foregroundStyle(TBTheme.primaryText)

                    Text(versionText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(TBTheme.secondaryText)
                }

                VStack(spacing: 5) {
                    Text("Created 2026")
                    Text("Copyright © 2026 74Lab")
                    HStack(spacing: 0) {
                        Text("Developed by ")
                        Link("@tonyroslund", destination: URL(string: "https://x.com/tonyroslund")!)
                            .foregroundStyle(TBTheme.accent)
                        Text(" at 74Lab")
                    }
                }
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(TBTheme.secondaryText)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .foregroundStyle(TBTheme.background)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(TBTheme.accent)
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
            .padding(26)
        }
        .frame(width: 340)
        .preferredColorScheme(.dark)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        return switch (version, build) {
        case (.some(let version), .some(let build)):
            "Version \(version) (\(build))"
        case (.some(let version), .none):
            "Version \(version)"
        default:
            "Version 0.1.3"
        }
    }
}

private struct TunnelBarLogoView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(Color(red: 0.85, green: 1.0, blue: 0.37))

            Text("%_")
                .font(.system(size: size * 0.34, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(red: 0.047, green: 0.051, blue: 0.043))
        }
        .frame(width: size, height: size)
    }
}

private struct TerminalTunnelLine: View {
    let tunnel: ActiveTunnel
    let statusColor: Color
    let onStop: () -> Void
    let onCopy: () -> Void
    let publicURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let publicString = tunnel.publicURL {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TypewriterText("Tunnel URL:", color: TBTheme.accent, speedMilliseconds: 18)

                    TypewriterText(publicString, color: TBTheme.primaryText, speedMilliseconds: 8)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 4)

                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TBTheme.accent)
                    }
                    .buttonStyle(.plain)
                    .help("Copy public URL")
                }
            } else if case .failed(let message) = tunnel.state {
                MessagePanel(title: "Tunnel failed", message: message)
            } else if shouldAnimateStatus {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TypewriterText(statusTitle, color: statusColor, speedMilliseconds: 20)
                    AnimatedEllipsis(color: statusColor)
                    Spacer()
                }
            } else {
                Text(statusTitle)
                    .foregroundStyle(statusColor)
            }
        }
        .font(.system(.caption, design: .monospaced).weight(.semibold))
        .padding(.vertical, 2)
    }

    private var statusTitle: String {
        switch tunnel.state {
        case .starting:
            tunnel.statusDetail ?? "Starting"
        case .stopping:
            "Stopping"
        default:
            tunnel.state.label
        }
    }

    private var shouldAnimateStatus: Bool {
        tunnel.state == .starting || tunnel.state == .stopping
    }
}

private struct TypewriterText: View {
    private let text: String
    private let color: Color
    private let speedMilliseconds: UInt64

    @State private var visibleCount = 0

    init(_ text: String, color: Color, speedMilliseconds: UInt64 = 20) {
        self.text = text
        self.color = color
        self.speedMilliseconds = speedMilliseconds
    }

    var body: some View {
        Text(String(text.prefix(visibleCount)))
            .foregroundStyle(color)
            .task(id: text) {
                visibleCount = 0

                guard !text.isEmpty else {
                    return
                }

                for count in 1...text.count {
                    try? await Task.sleep(for: .milliseconds(speedMilliseconds))
                    guard !Task.isCancelled else {
                        return
                    }
                    visibleCount = count
                }
            }
    }
}

private struct AnimatedEllipsis: View {
    let color: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.45)) { context in
            let dotCount = Int(context.date.timeIntervalSinceReferenceDate / 0.45) % 4
            ZStack(alignment: .leading) {
                Text(". . .")
                    .opacity(0)

                Text(String(repeating: " .", count: dotCount))
                    .foregroundStyle(color)
            }
            .monospacedDigit()
        }
    }
}

private struct InlineURLTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> CaretAtEndTextField {
        let textField = CaretAtEndTextField()
        textField.delegate = context.coordinator
        textField.stringValue = text
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.lineBreakMode = .byTruncatingTail
        textField.cell?.usesSingleLineMode = true
        textField.cell?.wraps = false
        textField.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
        textField.textColor = NSColor(
            calibratedRed: 0.95,
            green: 0.94,
            blue: 0.90,
            alpha: 1
        )
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor(
                    calibratedRed: 0.62,
                    green: 0.62,
                    blue: 0.58,
                    alpha: 1
                ),
                .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .semibold),
            ]
        )
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateNSView(_ textField: CaretAtEndTextField, context: Context) {
        if textField.stringValue != text {
            textField.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }

            text = textField.stringValue
        }
    }
}

private final class CaretAtEndTextField: NSTextField {
    private var didRequestInitialFocus = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard window != nil else {
            didRequestInitialFocus = false
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard
                let self,
                let window = self.window,
                !self.didRequestInitialFocus
            else {
                return
            }

            self.didRequestInitialFocus = true
            window.makeFirstResponder(self)
            self.moveCaretToEnd()
        }
    }

    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()

        if didBecomeFirstResponder {
            DispatchQueue.main.async { [weak self] in
                self?.clearFullSelection()
            }
        }

        return didBecomeFirstResponder
    }

    override func selectText(_ sender: Any?) {
        super.selectText(sender)

        DispatchQueue.main.async { [weak self] in
            self?.moveCaretToEnd()
        }
    }

    private func clearFullSelection() {
        guard
            let editor = currentEditor(),
            editor.selectedRange.length == stringValue.count
        else {
            return
        }

        moveCaretToEnd()
    }

    private func moveCaretToEnd() {
        currentEditor()?.selectedRange = NSRange(location: stringValue.count, length: 0)
    }
}

private struct URLLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(Color(red: 0.85, green: 1.0, blue: 0.37))
                .frame(width: 42, alignment: .leading)

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(TBTheme.primaryText)
                .textSelection(.enabled)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct MessagePanel: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)

            Text(message)
                .font(.caption)
                .foregroundStyle(TBTheme.secondaryText)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.08))
                .stroke(Color.red.opacity(0.22))
        )
    }
}

private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(TBTheme.primaryText)
            .frame(width: 26, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? TBTheme.controlBackgroundHover : TBTheme.controlBackground)
                    .stroke(TBTheme.border)
            )
    }
}

private struct IconLinkModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(TBTheme.primaryText)
            .frame(width: 26, height: 24)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(TBTheme.controlBackground)
                    .stroke(TBTheme.border)
            )
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = TunnelBarViewMetrics.collapsedHeight

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension View {
    func readHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
    }
}
