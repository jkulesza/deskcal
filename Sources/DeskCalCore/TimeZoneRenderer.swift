import AppKit

/// A world clock entry identified by an IANA time zone identifier, e.g.
/// "America/Denver". Displayed using everything after the first "/".
public struct TimeZoneEntry: Codable, Identifiable, Equatable {
    public var id: UUID
    public var identifier: String

    public init(id: UUID = UUID(), identifier: String) {
        self.id = id
        self.identifier = identifier
    }

    /// The identifier with its leading region (e.g. "America/") stripped,
    /// underscores turned into spaces: "America/Denver" -> "Denver".
    public var displayLabel: String {
        guard let slashIndex = identifier.firstIndex(of: "/") else { return identifier }
        let rest = identifier[identifier.index(after: slashIndex)...]
        return rest.replacingOccurrences(of: "_", with: " ")
    }
}

/// Generates the world-clock lines shown beside the current month.
public enum TimeZoneRenderer {
    /// `entries` ordered earliest UTC offset to latest, as of `now`.
    public static func sortedByOffset(_ entries: [TimeZoneEntry], now: Date = Date()) -> [TimeZoneEntry] {
        entries.sorted { lhs, rhs in
            offsetSeconds(for: lhs.identifier, now: now) < offsetSeconds(for: rhs.identifier, now: now)
        }
    }

    private static func offsetSeconds(for identifier: String, now: Date) -> Int {
        (TimeZone(identifier: identifier) ?? .current).secondsFromGMT(for: now)
    }

    /// One line per entry, formatted "Label HH:mm EEEE, MMMM d" with labels
    /// right-aligned (leading-space padded) so every time lines up on the left.
    public static func lines(for entries: [TimeZoneEntry], now: Date = Date()) -> [String] {
        guard !entries.isEmpty else { return [] }
        let ordered = sortedByOffset(entries, now: now)
        let maxLabelWidth = ordered.map { $0.displayLabel.count }.max() ?? 0

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"

        return ordered.map { entry in
            let zone = TimeZone(identifier: entry.identifier) ?? .current
            timeFormatter.timeZone = zone
            dateFormatter.timeZone = zone
            let displayLabel = entry.displayLabel
            let label = String(repeating: " ", count: maxLabelWidth - displayLabel.count) + displayLabel
            return "\(label) \(timeFormatter.string(from: now)) \(dateFormatter.string(from: now))"
        }
    }

    /// The attributed world-clock block, drawn in the current month's active color.
    public static func render(entries: [TimeZoneEntry], style: RenderStyle, now: Date = Date()) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: style.activeColor,
        ]
        for (index, line) in lines(for: entries, now: now).enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n", attributes: attributes))
            }
            result.append(NSAttributedString(string: line, attributes: attributes))
        }
        return result
    }
}
