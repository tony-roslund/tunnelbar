import Foundation

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

    private let defaults: UserDefaults

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
    }
}
