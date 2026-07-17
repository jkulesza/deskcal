import AppKit

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onPreferences: () -> Void
    private let onRefresh: () -> Void

    init(onPreferences: @escaping () -> Void, onRefresh: @escaping () -> Void) {
        self.onPreferences = onPreferences
        self.onRefresh = onRefresh
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "calendar",
                accessibilityDescription: "DeskCal"
            )
        }

        let menu = NSMenu()

        let preferencesItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        let refreshItem = NSMenuItem(
            title: "Refresh",
            action: #selector(refresh),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(.separator())

        let aboutItem = NSMenuItem(
            title: "About DeskCal",
            action: #selector(about),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit DeskCal",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openPreferences() {
        onPreferences()
    }

    @objc private func refresh() {
        onRefresh()
    }

    @objc private func about() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
