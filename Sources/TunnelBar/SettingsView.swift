import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("General") {
                Toggle("Show TunnelBar in the Dock", isOn: $settings.showDockIcon)
                Toggle("Copy public URL automatically", isOn: $settings.copyPublicURLAutomatically)
                Toggle("Open Diagnostics by default", isOn: $settings.openDiagnosticsByDefault)
            }

            Section("Privacy") {
                Text("TunnelBar stores recent tunnel history locally on this Mac and does not collect analytics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 430)
    }
}
