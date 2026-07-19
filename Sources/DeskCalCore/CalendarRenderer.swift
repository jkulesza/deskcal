import AppKit

/// Style options for rendering the calendar stack.
public struct RenderStyle {
    public var font: NSFont
    public var activeColor: NSColor
    public var inactiveColor: NSColor
    public var todayColor: NSColor
    public var monthsBefore: Int
    public var monthsAfter: Int

    public init(
        font: NSFont,
        activeColor: NSColor,
        inactiveColor: NSColor,
        todayColor: NSColor,
        monthsBefore: Int,
        monthsAfter: Int
    ) {
        self.font = font
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.todayColor = todayColor
        self.monthsBefore = max(0, monthsBefore)
        self.monthsAfter = max(0, monthsAfter)
    }
}

/// Generates the ASCII month grids and the attributed string drawn on the desktop.
public enum CalendarRenderer {
    /// Width in characters of one month block: 7 two-char day cells + 6 separators.
    public static let lineWidth = 20

    public static func defaultCalendar() -> Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1
        return calendar
    }

    /// Rows of 7 day-number cells for a month; nil marks a blank cell.
    static func weekRows(year: Int, month: Int, calendar: Calendar) -> [[Int?]] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let firstOfMonth = calendar.date(from: components),
              let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth)
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7

        var cells: [Int?] = Array(repeating: nil, count: leadingBlanks)
        cells.append(contentsOf: dayRange.map { Optional($0) })
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<($0 + 7)]) }
    }

    static func title(year: Int, month: Int, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? Locale.current
        let name = formatter.monthSymbols[month - 1]
        let text = "\(name) \(year)"
        let padding = max(0, (lineWidth - text.count) / 2)
        return String(repeating: " ", count: padding) + text
    }

    static func weekdayHeader(calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? Locale.current
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let ordered = (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
        return ordered.map { String($0.prefix(2)) }.joined(separator: " ")
    }

    private static func cellText(_ day: Int?) -> String {
        guard let day = day else { return "  " }
        return day < 10 ? " \(day)" : "\(day)"
    }

    /// Plain-text lines for one month: centered title, weekday header, then week rows.
    /// Trailing whitespace is trimmed from each line.
    public static func monthLines(year: Int, month: Int, calendar: Calendar) -> [String] {
        var lines = [title(year: year, month: month, calendar: calendar),
                     weekdayHeader(calendar: calendar)]
        for row in weekRows(year: year, month: month, calendar: calendar) {
            let line = row.map(cellText).joined(separator: " ")
            lines.append(trimTrailing(line))
        }
        return lines
    }

    private static func trimTrailing(_ line: String) -> String {
        var text = line
        while text.hasSuffix(" ") {
            text.removeLast()
        }
        return text
    }

    /// The full attributed calendar stack: monthsBefore grey months, the current
    /// month in the active color with today highlighted, then monthsAfter grey months.
    public static func render(
        today: Date,
        style: RenderStyle,
        calendar: Calendar = defaultCalendar()
    ) -> NSAttributedString {
        renderMonths(
            offsets: Array(-style.monthsBefore...style.monthsAfter),
            today: today,
            style: style,
            calendar: calendar
        )
    }

    /// Just the grey months before the current month, if any.
    public static func renderBeforeMonths(
        today: Date,
        style: RenderStyle,
        calendar: Calendar = defaultCalendar()
    ) -> NSAttributedString {
        guard style.monthsBefore > 0 else { return NSAttributedString() }
        return renderMonths(offsets: Array(-style.monthsBefore..<0), today: today, style: style, calendar: calendar)
    }

    /// Just the current month, in the active color with today highlighted.
    public static func renderCurrentMonth(
        today: Date,
        style: RenderStyle,
        calendar: Calendar = defaultCalendar()
    ) -> NSAttributedString {
        renderMonths(offsets: [0], today: today, style: style, calendar: calendar)
    }

    /// Just the grey months after the current month, if any.
    public static func renderAfterMonths(
        today: Date,
        style: RenderStyle,
        calendar: Calendar = defaultCalendar()
    ) -> NSAttributedString {
        guard style.monthsAfter > 0 else { return NSAttributedString() }
        return renderMonths(offsets: Array(1...style.monthsAfter), today: today, style: style, calendar: calendar)
    }

    private static func renderMonths(
        offsets: [Int],
        today: Date,
        style: RenderStyle,
        calendar: Calendar
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)

        func append(_ text: String, _ color: NSColor) {
            result.append(NSAttributedString(string: text, attributes: [
                .font: style.font,
                .foregroundColor: color,
            ]))
        }

        for (index, offset) in offsets.enumerated() {
            guard let monthDate = calendar.date(byAdding: .month, value: offset, to: today) else { continue }
            let year = calendar.component(.year, from: monthDate)
            let month = calendar.component(.month, from: monthDate)
            let isCurrent = offset == 0
            let baseColor = isCurrent ? style.activeColor : style.inactiveColor

            if index > 0 {
                append("\n\n\n", baseColor)
            }
            append(title(year: year, month: month, calendar: calendar) + "\n", baseColor)
            append(weekdayHeader(calendar: calendar) + "\n", baseColor)

            let rows = weekRows(year: year, month: month, calendar: calendar)
            for (rowIndex, row) in rows.enumerated() {
                for (cellIndex, day) in row.enumerated() {
                    if cellIndex > 0 {
                        append(" ", baseColor)
                    }
                    let isToday = isCurrent && day != nil && day == todayComponents.day
                    append(cellText(day), isToday ? style.todayColor : baseColor)
                }
                if rowIndex < rows.count - 1 {
                    append("\n", baseColor)
                }
            }
        }
        return result
    }
}
