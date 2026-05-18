import AppKit
import Combine
import SwiftUI

@main
struct TunnelBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let settings = AppSettings.shared

    var body: some Scene {
        Settings {
            SettingsView(settings: settings)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 430, height: 300)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let settings = AppSettings.shared
    private lazy var tunnelManager = TunnelManager(settings: settings)
    private var settingsCancellable: AnyCancellable?
    private var popoverSizeCancellable: AnyCancellable?
    private var windowWillCloseObserver: NSObjectProtocol?
    private var didRunInteractiveProcessCleanup = false
    private let appUpdater = AppUpdater.shared

    override init() {
        StartupCleanupState.terminatedCloudflaredProcessIDs = CloudflaredProcessCleaner
            .terminateOrphanedBundledProcesses()
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        tunnelManager.recordOrphanedCloudflaredProcessesCleanedUpOnStartup(
            StartupCleanupState.terminatedCloudflaredProcessIDs
        )
        applyActivationPolicy(showDockIcon: settings.showDockIcon)
        settingsCancellable = settings.$showDockIcon
            .removeDuplicates()
            .sink { [weak self] showDockIcon in
                self?.applyActivationPolicy(showDockIcon: showDockIcon)
            }
        windowWillCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(50))
                guard let self else {
                    return
                }

                self.applyActivationPolicy(showDockIcon: self.settings.showDockIcon)
            }
        }

        let contentView = TunnelBarView(
            tunnelManager: tunnelManager,
            settings: settings,
            onHeightChange: { [weak self] height in
                self?.setPopoverHeight(height)
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.sizingOptions = [.preferredContentSize]

        popover.contentSize = NSSize(
            width: TunnelBarViewMetrics.width,
            height: TunnelBarViewMetrics.collapsedHeight
        )
        popoverSizeCancellable = hostingController.publisher(for: \.preferredContentSize)
            .receive(on: RunLoop.main)
            .sink { [weak self] size in
                self?.setPopoverHeight(size.height)
            }

        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = hostingController

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = nil
        item.button?.attributedTitle = NSAttributedString(
            string: "%_",
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
            ]
        )
        item.button?.toolTip = "TunnelBar"
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        statusItem = item
    }

    func applicationWillTerminate(_ notification: Notification) {
        tunnelManager.terminateAllForAppShutdown()
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            cleanupOrphanedCloudflaredProcessesIfNeeded()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func cleanupOrphanedCloudflaredProcessesIfNeeded() {
        guard !didRunInteractiveProcessCleanup else {
            return
        }

        didRunInteractiveProcessCleanup = true
        tunnelManager.cleanupOrphanedCloudflaredProcessesNow()
    }

    private func applyActivationPolicy(showDockIcon: Bool) {
        if showDockIcon {
            NSApp.setActivationPolicy(.regular)
            return
        }

        guard !hasVisibleStandardWindow else {
            return
        }

        NSApp.setActivationPolicy(.accessory)
    }

    private var hasVisibleStandardWindow: Bool {
        NSApp.windows.contains { window in
            window.isVisible
                && window.canBecomeKey
                && window.level == .normal
        }
    }

    private func setPopoverHeight(_ rawHeight: CGFloat) {
        let height = min(
            max(ceil(rawHeight), TunnelBarViewMetrics.minimumHeight),
            TunnelBarViewMetrics.maximumHeight
        )
        let nextSize = NSSize(width: TunnelBarViewMetrics.width, height: height)

        guard abs(popover.contentSize.height - height) > 1 else {
            return
        }

        guard !popover.isShown else {
            return
        }

        popover.contentSize = nextSize
    }
}

@MainActor
private enum StartupCleanupState {
    static var terminatedCloudflaredProcessIDs: [Int32] = []
}
