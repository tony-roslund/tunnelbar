import SwiftUI

struct TunnelBarView: View {
    @ObservedObject var tunnelManager: TunnelManager
    @ObservedObject var historyStore: HistoryStore

    @State private var localURL = "http://localhost:3000"
    @State private var showDiagnostics = false

    private let accent = Color(red: 0.85, green: 1.0, blue: 0.37)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            inputSection
            activeSection
            historySection
            diagnosticsSection
            footer
        }
        .padding(18)
        .frame(width: 420)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("% tunnelbar")
                    .font(.system(.title3, design: .monospaced).weight(.semibold))

                HStack(spacing: 7) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(tunnelManager.state.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
            }

            Spacer()

            if tunnelManager.tunnels.contains(where: { $0.canStop }) {
                Button {
                    tunnelManager.stopAll()
                } label: {
                    Label("Stop All", systemImage: "stop.fill")
                }
                .controlSize(.small)
            }
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Local URL")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                TextField("http://localhost:3000", text: $localURL)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                            .stroke(Color(nsColor: .separatorColor))
                    )

                Button {
                    tunnelManager.start(rawLocalURL: localURL) { localURL, publicURL in
                        historyStore.add(localURL: localURL, publicURL: publicURL)
                    }
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .disabled(localURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let message = tunnelManager.lastError, !hasVisibleFailedTunnel {
                MessagePanel(title: "Could not create tunnel", message: message)
            }
        }
    }

    @ViewBuilder
    private var activeSection: some View {
        if !tunnelManager.tunnels.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tunnels")
                    .font(.headline)

                ForEach(tunnelManager.tunnels) { tunnel in
                    TunnelRow(
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

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent")
                    .font(.headline)

                Spacer()

                Button {
                    historyStore.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(historyStore.items.isEmpty)
                .help("Clear recent tunnels")
            }

            if historyStore.items.isEmpty {
                Text("No tunnel history yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(sectionBackground)
            } else {
                VStack(spacing: 8) {
                    ForEach(historyStore.items.prefix(4)) { item in
                        Button {
                            localURL = item.localURL
                            Clipboard.copy(item.publicURL)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.localURL)
                                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(item.publicURL)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(sectionBackground)
                        }
                        .buttonStyle(.plain)
                    }
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
                            .foregroundStyle(.secondary)
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
            .background(Color(nsColor: .textBackgroundColor))
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
                .foregroundStyle(.secondary)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(nsColor: .controlBackgroundColor))
            .stroke(Color(nsColor: .separatorColor).opacity(0.7))
    }

    private var hasVisibleFailedTunnel: Bool {
        tunnelManager.tunnels.contains { tunnel in
            if case .failed = tunnel.state {
                return true
            }

            return false
        }
    }

    private var statusColor: Color {
        switch tunnelManager.state {
        case .active:
            accent
        case .starting, .stopping:
            .orange
        case .failed:
            .red
        case .idle, .stopped:
            .secondary
        }
    }

    private func color(for state: TunnelState) -> Color {
        switch state {
        case .active:
            accent
        case .starting, .stopping:
            .orange
        case .failed:
            .red
        case .idle, .stopped:
            .secondary
        }
    }
}

private struct TunnelRow: View {
    let tunnel: ActiveTunnel
    let statusColor: Color
    let onStop: () -> Void
    let onCopy: () -> Void
    let publicURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(tunnel.state.label, systemImage: statusIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)

                Spacer()

                if tunnel.canStop {
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Stop this tunnel")
                }
            }

            URLLine(label: "local", value: tunnel.localURL)

            if let publicString = tunnel.publicURL {
                URLLine(label: "public", value: publicString)

                HStack {
                    Button(action: onCopy) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    if let publicURL {
                        Link(destination: publicURL) {
                            Label("Open", systemImage: "arrow.up.right")
                        }
                    }
                }
                .controlSize(.small)
            } else if case .failed(let message) = tunnel.state {
                MessagePanel(title: "Tunnel failed", message: message)
            } else {
                Text("Exposing \(tunnel.origin)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color(nsColor: .controlBackgroundColor))
                .stroke(Color(nsColor: .separatorColor).opacity(0.75))
        )
    }

    private var statusIcon: String {
        switch tunnel.state {
        case .active:
            "link"
        case .starting:
            "arrow.triangle.2.circlepath"
        case .stopping, .stopped:
            "stop.circle"
        case .failed:
            "exclamationmark.triangle"
        case .idle:
            "circle"
        }
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
                .foregroundStyle(.primary)
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
                .foregroundStyle(.secondary)
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
