import Foundation
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var showDockIcon: Bool {
        didSet { defaults.set(showDockIcon, forKey: Keys.showDockIcon) }
    }

    @Published var copyPublicURLAutomatically: Bool {
        didSet { defaults.set(copyPublicURLAutomatically, forKey: Keys.copyPublicURLAutomatically) }
    }

    @Published var openDiagnosticsByDefault: Bool {
        didSet { defaults.set(openDiagnosticsByDefault, forKey: Keys.openDiagnosticsByDefault) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard !isSynchronizingLaunchAtLogin else {
                return
            }

            updateLaunchAtLogin(to: launchAtLogin, revertingTo: oldValue)
        }
    }

    @Published private(set) var launchAtLoginStatusMessage: String?

    private let defaults: UserDefaults
    private var isSynchronizingLaunchAtLogin = false

    private enum Keys {
        static let showDockIcon = "TunnelBar.settings.showDockIcon"
        static let copyPublicURLAutomatically = "TunnelBar.settings.copyPublicURLAutomatically"
        static let openDiagnosticsByDefault = "TunnelBar.settings.openDiagnosticsByDefault"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showDockIcon = defaults.bool(forKey: Keys.showDockIcon)
        copyPublicURLAutomatically = defaults.object(forKey: Keys.copyPublicURLAutomatically) as? Bool ?? true
        openDiagnosticsByDefault = defaults.bool(forKey: Keys.openDiagnosticsByDefault)
        launchAtLogin = Self.isLaunchAtLoginEnabled
        launchAtLoginStatusMessage = Self.launchAtLoginStatusMessage
    }

    func refreshLaunchAtLoginStatus() {
        isSynchronizingLaunchAtLogin = true
        launchAtLogin = Self.isLaunchAtLoginEnabled
        launchAtLoginStatusMessage = Self.launchAtLoginStatusMessage
        isSynchronizingLaunchAtLogin = false
    }

    private func updateLaunchAtLogin(to enabled: Bool, revertingTo previousValue: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            refreshLaunchAtLoginStatus()
        } catch {
            isSynchronizingLaunchAtLogin = true
            launchAtLogin = previousValue
            launchAtLoginStatusMessage = "Could not update Start at Login: \(error.localizedDescription)"
            isSynchronizingLaunchAtLogin = false
        }
    }

    private static var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    private static var launchAtLoginStatusMessage: String? {
        switch SMAppService.mainApp.status {
        case .enabled, .notRegistered:
            nil
        case .requiresApproval:
            "macOS needs approval in System Settings before TunnelBar can start at login."
        case .notFound:
            "Start at Login is available after TunnelBar is installed in Applications."
        @unknown default:
            "Start at Login status is unavailable."
        }
    }
}
