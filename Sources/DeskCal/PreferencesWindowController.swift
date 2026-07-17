import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    convenience init(settings: Settings) {
        let hosting = NSHostingController(rootView: PreferencesView(settings: settings))
        let window = NSWindow(contentViewController: hosting)
        window.title = "DeskCal Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
