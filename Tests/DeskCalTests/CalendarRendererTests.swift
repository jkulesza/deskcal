import XCTest
@testable import DeskCalCore

final class CalendarRendererTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = 1
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)!
    }

    private var style: RenderStyle {
        RenderStyle(
            font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            activeColor: .white,
            inactiveColor: .gray,
            todayColor: .red,
            monthsBefore: 1,
            monthsAfter: 2
        )
    }

    func testJune2026MatchesScreenshot() {
        XCTAssertEqual(
            CalendarRenderer.monthLines(year: 2026, month: 6, calendar: calendar),
            [
                "     June 2026",
                "Su Mo Tu We Th Fr Sa",
                "    1  2  3  4  5  6",
                " 7  8  9 10 11 12 13",
                "14 15 16 17 18 19 20",
                "21 22 23 24 25 26 27",
                "28 29 30",
            ]
        )
    }

    func testJuly2026MatchesScreenshot() {
        XCTAssertEqual(
            CalendarRenderer.monthLines(year: 2026, month: 7, calendar: calendar),
            [
                "     July 2026",
                "Su Mo Tu We Th Fr Sa",
                "          1  2  3  4",
                " 5  6  7  8  9 10 11",
                "12 13 14 15 16 17 18",
                "19 20 21 22 23 24 25",
                "26 27 28 29 30 31",
            ]
        )
    }

    func testLeapYearFebruary() {
        XCTAssertEqual(
            CalendarRenderer.monthLines(year: 2024, month: 2, calendar: calendar),
            [
                "   February 2024",
                "Su Mo Tu We Th Fr Sa",
                "             1  2  3",
                " 4  5  6  7  8  9 10",
                "11 12 13 14 15 16 17",
                "18 19 20 21 22 23 24",
                "25 26 27 28 29",
            ]
        )
    }

    func testMonthStartingOnSundayHasNoLeadingBlanks() {
        let lines = CalendarRenderer.monthLines(year: 2026, month: 2, calendar: calendar)
        XCTAssertEqual(lines[2], " 1  2  3  4  5  6  7")
    }

    func testRenderIncludesAllRequestedMonths() {
        let text = CalendarRenderer.render(
            today: date(2026, 7, 17),
            style: style,
            calendar: calendar
        ).string
        XCTAssertTrue(text.contains("June 2026"))
        XCTAssertTrue(text.contains("July 2026"))
        XCTAssertTrue(text.contains("August 2026"))
        XCTAssertTrue(text.contains("September 2026"))
        XCTAssertFalse(text.contains("May 2026"))
        XCTAssertFalse(text.contains("October 2026"))
    }

    func testRenderColorsTodayAndMonths() {
        let rendered = CalendarRenderer.render(
            today: date(2026, 7, 17),
            style: style,
            calendar: calendar
        )
        let text = rendered.string as NSString

        func color(at location: Int) -> NSColor? {
            rendered.attribute(.foregroundColor, at: location, effectiveRange: nil) as? NSColor
        }

        // Today ("17" inside the July block) is red.
        let julyStart = text.range(of: "July 2026").location
        let todayRange = text.range(of: "17", options: [], range: NSRange(
            location: julyStart, length: text.length - julyStart))
        XCTAssertEqual(color(at: todayRange.location), .red)

        // The current month's title is white; a prior month's title is grey.
        XCTAssertEqual(color(at: julyStart), .white)
        XCTAssertEqual(color(at: text.range(of: "June 2026").location), .gray)

        // A non-today day in the current month is white.
        let day16Range = text.range(of: "16", options: [], range: NSRange(
            location: julyStart, length: text.length - julyStart))
        XCTAssertEqual(color(at: day16Range.location), .white)
    }

    func testZeroSurroundingMonths() {
        var soloStyle = style
        soloStyle.monthsBefore = 0
        soloStyle.monthsAfter = 0
        let text = CalendarRenderer.render(
            today: date(2026, 7, 17),
            style: soloStyle,
            calendar: calendar
        ).string
        XCTAssertTrue(text.contains("July 2026"))
        XCTAssertFalse(text.contains("June 2026"))
        XCTAssertFalse(text.contains("August 2026"))
    }
}
