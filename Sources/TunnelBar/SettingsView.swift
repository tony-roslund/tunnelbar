import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ZStack {
            TBTheme.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 26) {
                TerminalBrandMark()

                VStack(alignment: .leading, spacing: 14) {
                    Text("General")
                        .font(.system(.headline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(TBTheme.primaryText)

                    VStack(alignment: .leading, spacing: 14) {
                        SettingsToggleRow(
                            title: "Show TunnelBar in the Dock",
                            isOn: $settings.showDockIcon
                        )

                        SettingsToggleRow(
                            title: "Start TunnelBar at Login",
                            isOn: $settings.launchAtLogin
                        )

                        SettingsToggleRow(
                            title: "Copy public URL automatically",
                            isOn: $settings.copyPublicURLAutomatically
                        )

                        SettingsToggleRow(
                            title: "Open Diagnostics by default",
                            isOn: $settings.openDiagnosticsByDefault
                        )
                    }

                    if let statusMessage = settings.launchAtLoginStatusMessage {
                        Text(statusMessage)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(TBTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Updates")
                        .font(.system(.headline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(TBTheme.primaryText)

                    Button {
                        AppUpdater.shared.checkForUpdates()
                    } label: {
                        Text("Check for Updates")
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .foregroundStyle(TBTheme.background)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(TBTheme.accent)
                            )
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Privacy")
                        .font(.system(.headline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(TBTheme.primaryText)

                    Text("TunnelBar does not collect analytics or store secrets.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(TBTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(28)
        }
        .frame(width: 430)
        .foregroundStyle(TBTheme.primaryText)
        .preferredColorScheme(.dark)
        .onAppear {
            settings.refreshLaunchAtLoginStatus()
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Text(title)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(TBTheme.primaryText)
                .frame(width: 282, alignment: .leading)

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(TBTheme.accent)
                .labelsHidden()
        }
    }
}
