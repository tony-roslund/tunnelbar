import AppKit
import SwiftUI

@main
struct TunnelBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let tunnelManager = TunnelManager()
    private let historyStore = HistoryStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let contentView = TunnelBarView(
            tunnelManager: tunnelManager,
            historyStore: historyStore
        )

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 620)
        popover.contentViewController = NSHostingController(rootView: contentView)

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
        tunnelManager.stopAll()
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
