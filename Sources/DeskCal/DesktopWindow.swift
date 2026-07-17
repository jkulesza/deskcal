import AppKit
import DeskCalCore

/// Owns the borderless, click-through window that draws the calendar on the desktop.
final class DesktopCalendarController {
    private let settings: Settings
    private let window: NSWindow
    private let label: NSTextField
    private let padding: CGFloat = 4

    init(settings: Settings) {
        self.settings = settings

        label = NSTextField(labelWithAttributedString: NSAttributedString())
        label.isSelectable = false
        label.isEditable = false
        label.drawsBackground = false
        label.lineBreakMode = .byClipping

        window = NSWindow(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        // Just above the wallpaper, below every normal window and the desktop icons.
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.contentView?.addSubview(label)
    }

    func refresh() {
        let text = CalendarRenderer.render(today: Date(), style: settings.renderStyle)
        label.attributedStringValue = text
        label.sizeToFit()

        let size = NSSize(
            width: label.frame.width + padding * 2,
            height: label.frame.height + padding * 2
        )
        window.setContentSize(size)
        label.setFrameOrigin(NSPoint(x: padding, y: padding))
        reposition()
        window.orderFrontRegardless()
    }

    private func reposition() {
        guard let screen = NSScreen.screens.first else { return }
        let area = screen.visibleFrame
        let size = window.frame.size
        let dx = CGFloat(settings.offsetX)
        let dy = CGFloat(settings.offsetY)

        let origin: NSPoint
        switch settings.corner {
        case .topLeft:
            origin = NSPoint(x: area.minX + dx, y: area.maxY - dy - size.height)
        case .topRight:
            origin = NSPoint(x: area.maxX - dx - size.width, y: area.maxY - dy - size.height)
        case .bottomLeft:
            origin = NSPoint(x: area.minX + dx, y: area.minY + dy)
        case .bottomRight:
            origin = NSPoint(x: area.maxX - dx - size.width, y: area.minY + dy)
        }
        window.setFrameOrigin(origin)
    }
}
