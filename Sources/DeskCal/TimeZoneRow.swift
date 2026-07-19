import DeskCalCore
import SwiftUI

/// One row in the preferences time-zone list: just an IANA time zone picker
/// (the desktop display label is derived from its identifier). Order is
/// automatic (by UTC offset), so there is nothing to drag or type here.
struct TimeZoneRow: View {
    @Binding var entry: TimeZoneEntry
    var onDelete: () -> Void

    private static let identifiers = TimeZone.knownTimeZoneIdentifiers.sorted()

    var body: some View {
        HStack {
            Picker("", selection: $entry.identifier) {
                ForEach(Self.identifiers, id: \.self) { identifier in
                    Text(identifier).tag(identifier)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            Button(action: onDelete) {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)
        }
    }
}
