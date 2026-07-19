import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController?
    private var desktopCalendar: DesktopCalendarController?
    private var preferences: PreferencesWindowController?
    private var observers: [NSObjectProtocol] = []
    private var clockTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.shared
        desktopCalendar = DesktopCalendarController(settings: settings)
        statusBar = StatusBarController(
            onPreferences: { [weak self] in self?.showPreferences() },
            onRefresh: { [weak self] in self?.desktopCalendar?.refresh() }
        )

        let refresh: (Notification) -> Void = { [weak self] _ in
            self?.desktopCalendar?.refresh()
        }
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main, using: refresh))
        observers.append(center.addObserver(
            forName: Settings.changed, object: nil, queue: .main, using: refresh))
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main, using: refresh))
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: refresh))

        desktopCalendar?.refresh()

        // Keeps the world-clock times in sync with the system clock without
        // waiting for another trigger. Skipped entirely when there's no
        // world clock to keep current.
        let timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self, !settings.timeZones.isEmpty else { return }
            self.desktopCalendar?.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        clockTimer = timer
    }

    private func showPreferences() {
        if preferences == nil {
            preferences = PreferencesWindowController(settings: .shared)
        }
        preferences?.show()
    }
}
