import AppKit
import DeskCalCore

/// Owns the borderless, click-through window that draws the calendar on the desktop.
final class DesktopCalendarController {
    private let settings: Settings
    private let window: NSWindow
    private let beforeLabel: NSTextField
    private let currentLabel: NSTextField
    private let timeZoneLabel: NSTextField
    private let afterLabel: NSTextField
    private let padding: CGFloat = 4
    /// Vertical gap between stacked month blocks, in line heights (matches the
    /// blank-line spacing the single-block renderer used to produce).
    private let blockGapLines: CGFloat = 3
    private let columnGap: CGFloat = 24

    init(settings: Settings) {
        self.settings = settings

        func makeLabel() -> NSTextField {
            let label = NSTextField(labelWithAttributedString: NSAttributedString())
            label.isSelectable = false
            label.isEditable = false
            label.drawsBackground = false
            label.lineBreakMode = .byClipping
            return label
        }

        beforeLabel = makeLabel()
        currentLabel = makeLabel()
        timeZoneLabel = makeLabel()
        afterLabel = makeLabel()

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
        for label in [beforeLabel, currentLabel, timeZoneLabel, afterLabel] {
            window.contentView?.addSubview(label)
        }
    }

    func refresh() {
        let today = Date()
        let style = settings.renderStyle

        beforeLabel.attributedStringValue = CalendarRenderer.renderBeforeMonths(today: today, style: style)
        currentLabel.attributedStringValue = CalendarRenderer.renderCurrentMonth(today: today, style: style)
        afterLabel.attributedStringValue = CalendarRenderer.renderAfterMonths(today: today, style: style)
        timeZoneLabel.attributedStringValue = TimeZoneRenderer.render(entries: settings.timeZones, style: style)

        for label in [beforeLabel, currentLabel, timeZoneLabel, afterLabel] {
            label.sizeToFit()
        }

        let hasBefore = !beforeLabel.attributedStringValue.string.isEmpty
        let hasAfter = !afterLabel.attributedStringValue.string.isEmpty
        let hasTimeZones = !timeZoneLabel.attributedStringValue.string.isEmpty

        let gap = blockGapLines * lineHeight(for: style.font)
        let rowWidth = currentLabel.frame.width + (hasTimeZones ? columnGap + timeZoneLabel.frame.width : 0)
        let rowHeight = max(currentLabel.frame.height, hasTimeZones ? timeZoneLabel.frame.height : 0)

        var totalWidth = rowWidth
        var totalHeight = rowHeight
        if hasBefore {
            totalWidth = max(totalWidth, beforeLabel.frame.width)
            totalHeight += gap + beforeLabel.frame.height
        }
        if hasAfter {
            totalWidth = max(totalWidth, afterLabel.frame.width)
            totalHeight += gap + afterLabel.frame.height
        }

        let size = NSSize(width: totalWidth + padding * 2, height: totalHeight + padding * 2)
        window.setContentSize(size)

        var cursorTop = size.height - padding
        if hasBefore {
            beforeLabel.setFrameOrigin(NSPoint(x: padding, y: cursorTop - beforeLabel.frame.height))
            cursorTop -= beforeLabel.frame.height + gap
        }

        let rowY = cursorTop - rowHeight
        currentLabel.setFrameOrigin(NSPoint(x: padding, y: rowY + rowHeight - currentLabel.frame.height))
        if hasTimeZones {
            timeZoneLabel.setFrameOrigin(NSPoint(
                x: padding + currentLabel.frame.width + columnGap,
                y: rowY + rowHeight - timeZoneLabel.frame.height
            ))
        }
        cursorTop = rowY - gap

        if hasAfter {
            afterLabel.setFrameOrigin(NSPoint(x: padding, y: cursorTop - afterLabel.frame.height))
        }

        reposition()
        window.orderFrontRegardless()
    }

    private func lineHeight(for font: NSFont) -> CGFloat {
        ceil(font.ascender - font.descender + font.leading)
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
