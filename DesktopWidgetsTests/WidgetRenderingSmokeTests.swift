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
                family: .systemSmall
            ),
            family: .systemSmall,
            name: "Time & Date Small 12-hour"
        )

        let inline24Hour = TimeAndDateStringConfigurationIntent.referencePreview()
        inline24Hour.layout = TimeAndDateLayout.inline.rawValue
        inline24Hour.dateFormat = TimeAndDateDateFormat.iso.rawValue
        inline24Hour.timeFormat = TimeAndDateTimeFormat.twentyFourHour.rawValue
        try assertRenders(
            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: .now, configuration: inline24Hour),
                family: .systemMedium
            ),
            family: .systemMedium,
            name: "Time & Date Medium ISO 24-hour"
        )

        let centered = TimeAndDateStringConfigurationIntent.referencePreview()
        centered.layout = TimeAndDateLayout.centered.rawValue
        try assertRenders(
            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: .now, configuration: centered),
                family: .systemLarge
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

        try assertRenders(
            WeatherWidgetView(
                entry: WeatherEntry(
                    date: sample.fetchedAt,
                    configuration: configuration,
                    snapshot: longLocationSnapshot,
                    state: .loaded
                ),
                family: .systemSmall
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
                family: .systemMedium
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
                family: .systemLarge
            ),
            family: .systemLarge,
            name: "Weather Large failure"
        )
    }

    func testBatteryRendersAvailableAndUnavailableStatesAcrossFamilies() throws {
        let configuration = BatteryConfigurationIntent.referencePreview()
        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
            try assertRenders(
                BatteryWidgetView(
                    entry: BatteryEntry(
                        date: .now,
                        configuration: configuration,
                        snapshot: .sample
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
        XCTAssertGreaterThan(data.count, 0, "Rendered \(name) was empty", file: file, line: line)
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
