import Foundation
import XCTest

final class WidgetContractTests: XCTestCase {
    func testEverySupportedFamilyMapsToOneSharedInformationDensity() {
        XCTAssertEqual(WidgetInformationDensity(family: .systemSmall), .compact)
        XCTAssertEqual(WidgetInformationDensity(family: .systemMedium), .standard)
        XCTAssertEqual(WidgetInformationDensity(family: .systemLarge), .expanded)
    }

    func testSharedChromeMetricsGrowWithAvailableWidgetSpace() {
        let compact = WidgetChromeMetrics(family: .systemSmall)
        let standard = WidgetChromeMetrics(family: .systemMedium)
        let expanded = WidgetChromeMetrics(family: .systemLarge)

        XCTAssertLessThan(compact.statusFontSize, standard.statusFontSize)
        XCTAssertLessThan(standard.statusFontSize, expanded.statusFontSize)
        XCTAssertLessThan(compact.statusIconSize, expanded.statusIconSize)
        XCTAssertLessThan(compact.sectionSpacing, expanded.sectionSpacing)
    }

    func testSharedSurfaceUsesWallpaperContrastOnlyInFullColor() {
        XCTAssertEqual(WidgetSurfaceTreatment(renderingMode: .fullColor), .wallpaperContrast)
        XCTAssertTrue(WidgetSurfaceTreatment(renderingMode: .fullColor).usesContrastShadow)
        XCTAssertEqual(WidgetSurfaceTreatment(renderingMode: .vibrant), .systemTint)
        XCTAssertEqual(WidgetSurfaceTreatment(renderingMode: .accented), .systemTint)
        XCTAssertFalse(WidgetSurfaceTreatment(renderingMode: .accented).usesContrastShadow)
    }

    func testReadyWidgetIdentifiersRemainDistinctAndStable() {
        XCTAssertEqual(
            WidgetIdentifier.timeAndDate.rawValue,
            "com.joshuawyadao.desktop-widgets.time-and-date.configurable-v2-string"
        )
        XCTAssertEqual(
            WidgetIdentifier.weather.rawValue,
            "com.joshuawyadao.desktop-widgets.weather.entity-search-v8"
        )
        XCTAssertEqual(
            WidgetIdentifier.battery.rawValue,
            "com.joshuawyadao.desktop-widgets.battery.configurable-v2"
        )
        XCTAssertEqual(
            WidgetIdentifier.calendar.rawValue,
            "com.joshuawyadao.desktop-widgets.calendar.configurable-v2"
        )
        XCTAssertEqual(
            Set([
                WidgetIdentifier.timeAndDate.rawValue,
                WidgetIdentifier.weather.rawValue,
                WidgetIdentifier.battery.rawValue,
                WidgetIdentifier.calendar.rawValue,
            ]).count,
            4
        )
    }

    func testMinuteTimelineStartsOnTheCurrentMinuteAndAdvancesExactlyOncePerMinute() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 9,
            minute: 9,
            second: 42
        ))!

        let dates = calendar.minuteTimeline(startingAt: start, count: 60)

        XCTAssertEqual(dates.count, 60)
        XCTAssertEqual(dates.first, calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 9,
            minute: 9
        )))
        XCTAssertEqual(dates.last, calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 10,
            minute: 8
        )))
        XCTAssertTrue(zip(dates, dates.dropFirst()).allSatisfy {
            $1.timeIntervalSince($0) == 60
        })
    }

    func testTimelineHelpersRejectEmptyRequests() {
        XCTAssertEqual(Calendar.current.minuteTimeline(startingAt: .now, count: 0), [])
        XCTAssertEqual(Calendar.current.minuteTimeline(startingAt: .now, count: -1), [])
        XCTAssertEqual(
            WeatherTimelinePolicy.dates(
                startingAt: .now,
                count: 0,
                timeZone: TimeZone(secondsFromGMT: 0)!
            ),
            []
        )
    }
}
