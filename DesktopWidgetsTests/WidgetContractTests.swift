import Foundation
import XCTest

final class WidgetContractTests: XCTestCase {
    func testTypographyCatalogKeepsStableCuratedThemesAndOverrides() {
        XCTAssertEqual(
            WidgetTypographyTheme.allCases.map(\.rawValue),
            ["system", "modern", "editorial", "technical", "playful", "handmade"]
        )
        XCTAssertEqual(WidgetTypographyOverride.options(for: .weather).first, .followGlobal)
        XCTAssertFalse(WidgetTypographyOverride.options(for: .weather).contains(.widgetFonts))
        XCTAssertTrue(WidgetTypographyOverride.options(for: .timeAndDate).contains(.widgetFonts))
        XCTAssertEqual(
            WidgetTypographyCoverage.allCases.map(\.rawValue),
            ["displayText", "allText"]
        )
    }

    func testTypographyStorePersistsGlobalThemeAndResolvesSafeOverrides() throws {
        let suiteName = "com.joshuawyadao.DesktopWidgetsTests.typography.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.removePersistentDomain(forName: suiteName)
        let store = WidgetTypographyStore(defaults: defaults)

        XCTAssertEqual(store.globalTheme, .system)
        XCTAssertEqual(store.coverage, .displayText)
        XCTAssertEqual(store.resolution(for: .weather), .theme(.system))
        XCTAssertEqual(
            store.style(for: .weather),
            WidgetTypographyStyle(resolution: .theme(.system), coverage: .displayText)
        )

        store.globalTheme = .editorial
        XCTAssertEqual(store.globalTheme, .editorial)
        XCTAssertEqual(store.resolution(for: .battery), .theme(.editorial))

        store.setOverride(.technical, for: .weather)
        store.coverage = .allText
        XCTAssertEqual(store.override(for: .weather), .technical)
        XCTAssertEqual(store.resolution(for: .weather), .theme(.technical))
        XCTAssertEqual(
            store.style(for: .weather),
            WidgetTypographyStyle(resolution: .theme(.technical), coverage: .allText)
        )

        store.setOverride(.widgetFonts, for: .battery)
        XCTAssertEqual(store.override(for: .battery), .followGlobal)
        XCTAssertEqual(store.resolution(for: .battery), .theme(.editorial))

        store.setOverride(.widgetFonts, for: .timeAndDate)
        XCTAssertEqual(store.resolution(for: .timeAndDate), .widgetFonts)

        defaults.set("unknown", forKey: WidgetTypographyStore.overrideKeyPrefix + WidgetTypographyTarget.calendar.rawValue)
        defaults.set("unknown", forKey: WidgetTypographyStore.coverageKey)
        XCTAssertEqual(store.override(for: .calendar), .followGlobal)
        XCTAssertEqual(store.resolution(for: .calendar), .theme(.editorial))
        XCTAssertEqual(store.coverage, .displayText)

        store.reset()
        XCTAssertEqual(store.globalTheme, .system)
        XCTAssertEqual(store.coverage, .displayText)
        XCTAssertTrue(WidgetTypographyTarget.allCases.allSatisfy {
            store.override(for: $0) == .followGlobal
        })
    }

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
