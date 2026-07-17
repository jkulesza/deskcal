import AppKit
import ServiceManagement

/// Registers/unregisters the app as a login item. Uses SMAppService on macOS 13+
/// (when built with a Swift 5.7+/macOS 13 SDK toolchain, e.g. in CI) and falls
/// back to a per-user LaunchAgent plist on macOS 12.
enum LaunchAtLogin {
    private static let agentLabel = "com.jkulesza.deskcal"

    static func set(enabled: Bool) {
#if swift(>=5.7)
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("DeskCal: failed to update login item: %@", error.localizedDescription)
            }
            return
        }
#endif
        setViaLaunchAgent(enabled: enabled)
    }

    private static func setViaLaunchAgent(enabled: Bool) {
        let fileManager = FileManager.default
        let agentsDir = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        let plistURL = agentsDir.appendingPathComponent("\(agentLabel).plist")

        if enabled {
            guard let executable = Bundle.main.executablePath else {
                NSLog("DeskCal: cannot enable launch at login without a bundle executable path")
                return
            }
            let plist: [String: Any] = [
                "Label": agentLabel,
                "ProgramArguments": [executable],
                "RunAtLoad": true,
            ]
            do {
                try fileManager.createDirectory(at: agentsDir, withIntermediateDirectories: true)
                try (plist as NSDictionary).write(to: plistURL)
            } catch {
                NSLog("DeskCal: failed to write LaunchAgent: %@", error.localizedDescription)
            }
        } else {
            try? fileManager.removeItem(at: plistURL)
        }
    }
}
