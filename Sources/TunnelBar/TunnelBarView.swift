import SwiftUI

struct TunnelBarView: View {
    @ObservedObject var tunnelManager: TunnelManager
    @ObservedObject var historyStore: HistoryStore

    @State private var localURL = "http://localhost:3000"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            inputSection
            activeSection
            historySection
            diagnosticsSection
            footer
        }
        .padding(18)
        .frame(width: 360)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TunnelBar")
                    .font(.title2.weight(.semibold))
                Text(tunnelManager.state.label)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("http://localhost:3000/path", text: $localURL)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button {
                    tunnelManager.start(rawLocalURL: localURL) { localURL, publicURL in
                        historyStore.add(localURL: localURL, publicURL: publicURL)
                    }
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .disabled(tunnelManager.state == .starting)

                Button {
                    tunnelManager.stopAll()
                } label: {
                    Label("Stop All", systemImage: "stop.fill")
                }
                .disabled(!tunnelManager.tunnels.contains(where: { $0.canStop }))

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var activeSection: some View {
        if !tunnelManager.tunnels.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tunnels")
                    .font(.headline)

                ForEach(tunnelManager.tunnels) { tunnel in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(tunnel.state.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(color(for: tunnel.state))

                            Spacer()

                            if tunnel.canStop {
                                Button {
                                    tunnelManager.stop(tunnel.id)
                                } label: {
                                    Label("Stop", systemImage: "stop.fill")
                                }
                                .labelStyle(.iconOnly)
                                .help("Stop this tunnel")
                            }
                        }

                        Text(tunnel.localURL)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(2)

                        if let publicURL = tunnel.publicURL {
                            Text(publicURL)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(3)

                            HStack {
                                Button {
                                    tunnelManager.copyPublicURL(for: tunnel.id)
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }

                                if let url = tunnelManager.publicURL(for: tunnel.id) {
                                    Link(destination: url) {
                                        Label("Open", systemImage: "arrow.up.right")
                                    }
                                }
                            }
                        } else if case .failed(let message) = tunnel.state {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Exposing \(tunnel.origin)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        } else if let message = tunnelManager.lastError {
            VStack(alignment: .leading, spacing: 6) {
                Text("Could not create tunnel")
                    .font(.headline)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            } else {
                ForEach(historyStore.items.prefix(4)) { item in
                    Button {
                        localURL = item.localURL
                        Clipboard.copy(item.publicURL)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.localURL)
                                .lineLimit(1)
                            Text(item.publicURL)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diagnostics")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(tunnelManager.logs.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(height: 120)
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var footer: some View {
        HStack {
            Text("Quick tunnel URLs are public while running.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
    }

    private var statusColor: Color {
        switch tunnelManager.state {
        case .active:
            .green
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
            .green
        case .starting, .stopping:
            .orange
        case .failed:
            .red
        case .idle, .stopped:
            .secondary
        }
    }
}
