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

    func testPortfolioPreviewRendersWithSyntheticData() throws {
        let size = CGSize(width: 740, height: 448)
        let utc = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let renderer = ImageRenderer(
            content: PortfolioPreview()
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .environment(\.timeZone, utc)
                .environment(\.colorScheme, .light)
        )
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.scale = 2

        let image: NSImage = try XCTUnwrap(renderer.nsImage, "Failed to render the portfolio preview")
        let tiffData: Data = try XCTUnwrap(image.tiffRepresentation, "Portfolio preview had no pixels")
        let bitmap: NSBitmapImageRep = try XCTUnwrap(
            NSBitmapImageRep(data: tiffData),
            "Portfolio preview could not be decoded"
        )
        XCTAssertTrue(containsVisibleContent(bitmap), "Portfolio preview contained no visible content")

        let requestURL = URL(fileURLWithPath: "/private/tmp/DesktopWidgetsPortfolioPreview.request")
        guard FileManager.default.fileExists(atPath: requestURL.path) else {
            return
        }

        let outputURL = URL(fileURLWithPath: "/private/tmp/DesktopWidgetsPortfolioPreview.png")
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let pngData: Data = try XCTUnwrap(
            bitmap.representation(using: .png, properties: [:]),
            "Portfolio preview could not be encoded as PNG"
        )
        try pngData.write(to: outputURL, options: .atomic)
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

@MainActor
private struct PortfolioPreview: View {
    private let referenceDate = CalendarProvider.referenceDate
    private let widgetSize = CGSize(width: 338, height: 158)

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text("macOS Widgets")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Native WidgetKit views rendered with synthetic data")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    widgetCard {
                        TimeAndDateWidgetView(
                            entry: TimeAndDateEntry(
                                date: referenceDate,
                                configuration: timeConfiguration
                            ),
                            family: .systemMedium,
                            typography: .theme(.editorial),
                            coverage: .allText
                        )
                    }
                    widgetCard {
                        WeatherWidgetView(
                            entry: WeatherEntry(
                                date: referenceDate,
                                configuration: .referencePreview(),
                                snapshot: .sample(now: referenceDate),
                                state: .loaded
                            ),
                            family: .systemMedium,
                            typography: .theme(.technical),
                            coverage: .allText
                        )
                        .environment(\.openURL, OpenURLAction { _ in .handled })
                        .overlay(alignment: .topTrailing) {
                            // ImageRenderer cannot host an interactive Link, so replace its
                            // disabled-control artifact with the same visible attribution.
                            Text("Open-Meteo")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .underline()
                                .foregroundStyle(.primary.opacity(0.82))
                                .frame(width: 58, height: 16)
                                .background(Color(red: 0.91, green: 0.93, blue: 0.97))
                        }
                    }
                }

                HStack(spacing: 16) {
                    widgetCard {
                        BatteryWidgetView(
                            entry: BatteryEntry(
                                date: referenceDate,
                                configuration: .referencePreview(),
                                snapshot: .sample
                            ),
                            family: .systemMedium,
                            typography: .theme(.playful),
                            coverage: .allText
                        )
                    }
                    widgetCard {
                        CalendarWidgetView(
                            entry: calendarEntry,
                            family: .systemMedium,
                            typography: .theme(.handmade),
                            coverage: .allText
                        )
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 740, height: 448, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.88, green: 0.91, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var calendarEntry: CalendarEntry {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return CalendarEntry(
            date: referenceDate,
            configuration: .referencePreview(showEvents: true, showNextEventTime: true),
            monthOffset: 0,
            events: .sample(referenceDate: referenceDate, calendar: calendar)
        )
    }

    private var timeConfiguration: TimeAndDateStringConfigurationIntent {
        let configuration = TimeAndDateStringConfigurationIntent.referencePreview()
        configuration.timeFormat = TimeAndDateTimeFormat.twentyFourHour.rawValue
        return configuration
    }

    private func widgetCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: widgetSize.width, height: widgetSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.13), radius: 12, y: 5)
    }
}
