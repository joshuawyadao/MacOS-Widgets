import AppKit
import Foundation
import SwiftUI
import WidgetKit
import XCTest

@MainActor
final class WidgetRenderingSmokeTests: XCTestCase {
    func testTimeAndDateRendersRepresentativeTwelveAndTwentyFourHourLayouts() throws {
        let reference = TimeAndDateStringConfigurationIntent.referencePreview()
        try assertRenders(
            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: .now, configuration: reference),
                family: .systemSmall,
                typography: .widgetFonts
            ),
            family: .systemSmall,
            name: "Time & Date Small 12-hour"
        )

        let inline24Hour = TimeAndDateStringConfigurationIntent.referencePreview()
        inline24Hour.layout = TimeAndDateLayout.inline.rawValue
        inline24Hour.dateFormat = TimeAndDateDateFormat.iso.rawValue
        inline24Hour.timeFormat = TimeAndDateTimeFormat.twentyFourHour.rawValue
        inline24Hour.secondaryTimeZone = TimeAndDateSecondaryZone.tokyo.rawValue
        inline24Hour.secondaryLabel = "Family"
        try assertRenders(
            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: .now, configuration: inline24Hour),
                family: .systemMedium,
                typography: .widgetFonts
            ),
            family: .systemMedium,
            name: "Time & Date Medium ISO 24-hour"
        )

        let centered = TimeAndDateStringConfigurationIntent.referencePreview()
        centered.layout = TimeAndDateLayout.centered.rawValue
        try assertRenders(
            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: .now, configuration: centered),
                family: .systemLarge,
                typography: .widgetFonts
            ),
            family: .systemLarge,
            name: "Time & Date Large centered"
        )
    }

    func testWeatherRendersLoadedStaleAndFailureStatesAcrossFamilies() throws {
        let sample = WeatherSnapshot.sample(now: .now)
        let longLocationSnapshot = WeatherSnapshot(
            locationName: "San Fernando del Valle de Catamarca, Argentina",
            providerID: sample.providerID,
            timeZoneIdentifier: sample.timeZoneIdentifier,
            fetchedAt: sample.fetchedAt,
            unit: sample.unit,
            current: sample.current,
            hourly: sample.hourly,
            daily: sample.daily
        )
        let configuration = WeatherV8ConfigurationIntent.referencePreview()
        configuration.detailPreset = WeatherDetailPreset.sun.rawValue

        try assertRenders(
            WeatherWidgetView(
                entry: WeatherEntry(
                    date: sample.fetchedAt,
                    configuration: configuration,
                    snapshot: longLocationSnapshot,
                    state: .loaded
                ),
                family: .systemSmall,
                typography: .theme(.handmade),
                coverage: .allText
            ),
            family: .systemSmall,
            name: "Weather Small long location"
        )
        try assertRenders(
            WeatherWidgetView(
                entry: WeatherEntry(
                    date: sample.fetchedAt,
                    configuration: configuration,
                    snapshot: sample,
                    state: .stale("Offline")
                ),
                family: .systemMedium,
                typography: .theme(.technical),
                coverage: .allText
            ),
            family: .systemMedium,
            name: "Weather Medium stale"
        )
        try assertRenders(
            WeatherWidgetView(
                entry: WeatherEntry(
                    date: sample.fetchedAt,
                    configuration: configuration,
                    snapshot: nil,
                    state: .failed("No weather location matched the selected city.", retryable: false)
                ),
                family: .systemLarge,
                typography: .theme(.playful),
                coverage: .allText
            ),
            family: .systemLarge,
            name: "Weather Large failure"
        )
    }

    func testBatteryRendersAvailableAndUnavailableStatesAcrossFamilies() throws {
        let configuration = BatteryConfigurationIntent.referencePreview()
        configuration.showHealth = true
        configuration.showCycles = true
        let diagnosticSnapshot = BatterySnapshot(
            percentage: 85,
            state: .discharging,
            timeRemainingMinutes: 366,
            healthPercentage: 91,
            cycleCount: 247
        )
        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
            try assertRenders(
                BatteryWidgetView(
                    entry: BatteryEntry(
                        date: .now,
                        configuration: configuration,
                        snapshot: diagnosticSnapshot
                    ),
                    family: family
                ),
                family: family,
                name: "Battery \(family) available"
            )
        }

        try assertRenders(
            BatteryWidgetView(
                entry: BatteryEntry(
                    date: .now,
                    configuration: configuration,
                    snapshot: nil
                ),
                family: .systemSmall
            ),
            family: .systemSmall,
            name: "Battery Small unavailable"
        )
    }

    func testCalendarRendersAutomaticViewsAndPermissionStateAcrossFamilies() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let referenceDate = CalendarProvider.referenceDate
        let configuration = CalendarConfigurationIntent.referencePreview(
            showEvents: true,
            showNextEventTime: true
        )
        let availableEntry = CalendarEntry(
            date: referenceDate,
            configuration: configuration,
            monthOffset: 0,
            events: .sample(referenceDate: referenceDate, calendar: calendar)
        )

        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
            try assertRenders(
                CalendarWidgetView(entry: availableEntry, family: family),
                family: family,
                name: "Calendar \(family) automatic"
            )
        }

        let permissionEntry = CalendarEntry(
            date: referenceDate,
            configuration: configuration,
            monthOffset: 0,
            events: CalendarEventSnapshot(accessState: .requiresPermission, countsByDay: [:])
        )
        try assertRenders(
            CalendarWidgetView(entry: permissionEntry, family: .systemSmall),
            family: .systemSmall,
            name: "Calendar Small permission required"
        )
    }

    func testEveryTypographyThemeAndCoverageRendersAcrossAllFourWidgets() throws {
        let referenceDate = CalendarProvider.referenceDate
        let weather = WeatherSnapshot.sample(now: referenceDate)
        let calendarEntry = CalendarEntry(
            date: referenceDate,
            configuration: .referencePreview(showEvents: false),
            monthOffset: 0,
            events: .disabled
        )

        for theme in WidgetTypographyTheme.allCases {
            let typography = WidgetTypographyResolution.theme(theme)
            for coverage in WidgetTypographyCoverage.allCases {
                for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
                    try assertRenders(
                        TimeAndDateWidgetView(
                            entry: TimeAndDateEntry(
                                date: referenceDate,
                                configuration: .referencePreview()
                            ),
                            family: family,
                            typography: typography,
                            coverage: coverage
                        ),
                        family: family,
                        name: "Time & Date \(family) \(theme.rawValue) \(coverage.rawValue) typography"
                    )
                    try assertRenders(
                        WeatherWidgetView(
                            entry: WeatherEntry(
                                date: referenceDate,
                                configuration: .referencePreview(),
                                snapshot: weather,
                                state: .loaded
                            ),
                            family: family,
                            typography: typography,
                            coverage: coverage
                        ),
                        family: family,
                        name: "Weather \(family) \(theme.rawValue) \(coverage.rawValue) typography"
                    )
                    try assertRenders(
                        BatteryWidgetView(
                            entry: BatteryEntry(
                                date: referenceDate,
                                configuration: .referencePreview(),
                                snapshot: .sample
                            ),
                            family: family,
                            typography: typography,
                            coverage: coverage
                        ),
                        family: family,
                        name: "Battery \(family) \(theme.rawValue) \(coverage.rawValue) typography"
                    )
                    try assertRenders(
                        CalendarWidgetView(
                            entry: calendarEntry,
                            family: family,
                            typography: typography,
                            coverage: coverage
                        ),
                        family: family,
                        name: "Calendar \(family) \(theme.rawValue) \(coverage.rawValue) typography"
                    )
                }
            }
        }
    }

    private func assertRenders<Content: View>(
        _ content: Content,
        family: WidgetFamily,
        name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let size = renderSize(for: family)
        let renderer = ImageRenderer(
            content: content
                .frame(width: size.width, height: size.height)
        )
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.scale = 1

        let image: NSImage = try XCTUnwrap(renderer.nsImage, "Failed to render \(name)", file: file, line: line)
        let data: Data = try XCTUnwrap(image.tiffRepresentation, "Rendered \(name) had no pixels", file: file, line: line)
        let bitmap: NSBitmapImageRep = try XCTUnwrap(
            NSBitmapImageRep(data: data),
            "Rendered \(name) could not be decoded",
            file: file,
            line: line
        )
        XCTAssertTrue(
            containsVisibleContent(bitmap),
            "Rendered \(name) contained no visible, non-uniform content",
            file: file,
            line: line
        )
    }

    private func containsVisibleContent(_ bitmap: NSBitmapImageRep) -> Bool {
        var firstPixel: NSColor?
        var hasVisiblePixel = false
        var hasPixelVariation = false

        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let pixel = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    continue
                }

                hasVisiblePixel = hasVisiblePixel || pixel.alphaComponent > 0.01
                if let firstPixel {
                    hasPixelVariation = hasPixelVariation || colorsDiffer(firstPixel, pixel)
                } else {
                    firstPixel = pixel
                }

                if hasVisiblePixel && hasPixelVariation {
                    return true
                }
            }
        }

        return false
    }

    private func colorsDiffer(_ lhs: NSColor, _ rhs: NSColor) -> Bool {
        abs(lhs.redComponent - rhs.redComponent) > 0.01
            || abs(lhs.greenComponent - rhs.greenComponent) > 0.01
            || abs(lhs.blueComponent - rhs.blueComponent) > 0.01
            || abs(lhs.alphaComponent - rhs.alphaComponent) > 0.01
    }

    private func renderSize(for family: WidgetFamily) -> CGSize {
        switch family {
        case .systemSmall:
            CGSize(width: 158, height: 158)
        case .systemLarge:
            CGSize(width: 338, height: 354)
        default:
            CGSize(width: 338, height: 158)
        }
    }
}
