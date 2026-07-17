import AppKit
import Combine
import DeskCalCore

enum ScreenCorner: String, CaseIterable, Identifiable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
}

/// UserDefaults-backed settings. Every mutation persists immediately and posts
/// `Settings.changed` so the desktop calendar re-renders live.
final class Settings: ObservableObject {
    static let shared = Settings()
    static let changed = Notification.Name("DeskCalSettingsChanged")

    private enum Key {
        static let fontName = "fontName"
        static let fontSize = "fontSize"
        static let inactiveColor = "inactiveColor"
        static let activeColor = "activeColor"
        static let todayColor = "todayColor"
        static let monthsBefore = "monthsBefore"
        static let monthsAfter = "monthsAfter"
        static let corner = "corner"
        static let offsetX = "offsetX"
        static let offsetY = "offsetY"
        static let launchAtLogin = "launchAtLogin"
    }

    @Published var fontName: String { didSet { persist() } }
    @Published var fontSize: Double { didSet { persist() } }
    @Published var inactiveColorHex: String { didSet { persist() } }
    @Published var activeColorHex: String { didSet { persist() } }
    @Published var todayColorHex: String { didSet { persist() } }
    @Published var monthsBefore: Int { didSet { persist() } }
    @Published var monthsAfter: Int { didSet { persist() } }
    @Published var corner: ScreenCorner { didSet { persist() } }
    @Published var offsetX: Double { didSet { persist() } }
    @Published var offsetY: Double { didSet { persist() } }
    @Published var launchAtLogin: Bool {
        didSet {
            persist()
            if launchAtLogin != oldValue {
                LaunchAtLogin.set(enabled: launchAtLogin)
            }
        }
    }

    private let defaults: UserDefaults
    private var loaded = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.fontName: "Menlo",
            Key.fontSize: 12.0,
            Key.inactiveColor: "#7F7F7F",
            Key.activeColor: "#FFFFFF",
            Key.todayColor: "#FF3B30",
            Key.monthsBefore: 1,
            Key.monthsAfter: 2,
            Key.corner: ScreenCorner.topLeft.rawValue,
            Key.offsetX: 8.0,
            Key.offsetY: 8.0,
            Key.launchAtLogin: false,
        ])

        fontName = defaults.string(forKey: Key.fontName) ?? "Menlo"
        fontSize = defaults.double(forKey: Key.fontSize)
        inactiveColorHex = defaults.string(forKey: Key.inactiveColor) ?? "#7F7F7F"
        activeColorHex = defaults.string(forKey: Key.activeColor) ?? "#FFFFFF"
        todayColorHex = defaults.string(forKey: Key.todayColor) ?? "#FF3B30"
        monthsBefore = defaults.integer(forKey: Key.monthsBefore)
        monthsAfter = defaults.integer(forKey: Key.monthsAfter)
        corner = ScreenCorner(rawValue: defaults.string(forKey: Key.corner) ?? "") ?? .topLeft
        offsetX = defaults.double(forKey: Key.offsetX)
        offsetY = defaults.double(forKey: Key.offsetY)
        launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        loaded = true
    }

    private func persist() {
        guard loaded else { return }
        defaults.set(fontName, forKey: Key.fontName)
        defaults.set(fontSize, forKey: Key.fontSize)
        defaults.set(inactiveColorHex, forKey: Key.inactiveColor)
        defaults.set(activeColorHex, forKey: Key.activeColor)
        defaults.set(todayColorHex, forKey: Key.todayColor)
        defaults.set(monthsBefore, forKey: Key.monthsBefore)
        defaults.set(monthsAfter, forKey: Key.monthsAfter)
        defaults.set(corner.rawValue, forKey: Key.corner)
        defaults.set(offsetX, forKey: Key.offsetX)
        defaults.set(offsetY, forKey: Key.offsetY)
        defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
        NotificationCenter.default.post(name: Settings.changed, object: self)
    }

    var font: NSFont {
        NSFont(name: fontName, size: CGFloat(fontSize))
            ?? NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
    }

    var renderStyle: RenderStyle {
        RenderStyle(
            font: font,
            activeColor: NSColor(hexString: activeColorHex) ?? .white,
            inactiveColor: NSColor(hexString: inactiveColorHex) ?? .gray,
            todayColor: NSColor(hexString: todayColorHex) ?? .systemRed,
            monthsBefore: monthsBefore,
            monthsAfter: monthsAfter
        )
    }
}
