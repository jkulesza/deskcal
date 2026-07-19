import AppKit
import DeskCalCore
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: Settings

    private let fontNames: [String] = {
        var names = NSFontManager.shared.availableFontNames(with: .fixedPitchFontMask) ?? []
        if !names.contains("Menlo") {
            names.append("Menlo")
        }
        return names.sorted()
    }()

    var body: some View {
        Form {
            Group {
                fontSection
                Divider()
                colorSection
                Divider()
                rangeSection
                Divider()
                positionSection
                Divider()
            }
            timeZoneSection
            Divider()
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
        }
        .padding(20)
        .frame(width: 420)
    }

    @ViewBuilder private var fontSection: some View {
        Picker("Font:", selection: $settings.fontName) {
            ForEach(fontNames, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        Stepper(
            "Font size: \(Int(settings.fontSize)) pt",
            value: $settings.fontSize,
            in: 8...72,
            step: 1
        )
    }

    @ViewBuilder private var colorSection: some View {
        ColorPicker("Active month color:", selection: colorBinding($settings.activeColorHex))
        ColorPicker("Inactive month color:", selection: colorBinding($settings.inactiveColorHex))
        ColorPicker("Today color:", selection: colorBinding($settings.todayColorHex))
    }

    @ViewBuilder private var rangeSection: some View {
        Stepper(
            "Months prior: \(settings.monthsBefore)",
            value: $settings.monthsBefore,
            in: 0...12
        )
        Stepper(
            "Months following: \(settings.monthsAfter)",
            value: $settings.monthsAfter,
            in: 0...12
        )
    }

    @ViewBuilder private var positionSection: some View {
        Picker("Screen corner:", selection: $settings.corner) {
            ForEach(ScreenCorner.allCases) { corner in
                Text(corner.label).tag(corner)
            }
        }
        Stepper(
            "Horizontal offset: \(Int(settings.offsetX)) px",
            value: $settings.offsetX,
            in: 0...2000,
            step: 4
        )
        Stepper(
            "Vertical offset: \(Int(settings.offsetY)) px",
            value: $settings.offsetY,
            in: 0...2000,
            step: 4
        )
    }

    @ViewBuilder private var timeZoneSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Time zones").font(.headline)
            ForEach($settings.timeZones) { $entry in
                TimeZoneRow(entry: $entry) {
                    settings.timeZones.removeAll { $0.id == entry.id }
                }
            }
            Button("Add Time Zone") {
                settings.timeZones.append(TimeZoneEntry(identifier: TimeZone.current.identifier))
            }
        }
    }

    private func colorBinding(_ hex: Binding<String>) -> Binding<Color> {
        Binding(
            get: { Color(nsColor: NSColor(hexString: hex.wrappedValue) ?? .white) },
            set: { hex.wrappedValue = NSColor($0).hexString }
        )
    }
}
