import AppIntents
import Foundation
import WidgetKit
import XCTest

final class WeatherConfigurationTests: XCTestCase {
    func testV8CityEntityRoundTripsTheSelectedCityWithReadablePresentation() throws {
        let tokyo = WeatherLocation(
            name: "Tokyo",
            latitude: 35.6762,
            longitude: 139.6503,
            timeZoneIdentifier: "Asia/Tokyo",
            adminArea: "Tokyo",
            country: "Japan"
        )
        let entity = WeatherV8CityEntity(location: tokyo)
        let configuration = WeatherV8ConfigurationIntent()
        configuration.city = entity

        XCTAssertEqual(configuration.resolvedLocation, tokyo)
        XCTAssertEqual(WeatherV8CityEntity(id: entity.id)?.location, tokyo)
        XCTAssertEqual(String(localized: entity.displayRepresentation.title), "Tokyo")
        XCTAssertEqual(
            entity.displayRepresentation.subtitle.map { String(localized: $0) },
            "Japan"
        )
    }

    func testLargeForecastUsesExpandedDashboardLayout() {
        let snapshot = WeatherSnapshot.sample()

        let medium = WeatherWidgetPresentation(
            date: snapshot.fetchedAt,
            configuration: .referencePreview(),
            snapshot: snapshot,
            state: .loaded,
            family: .systemMedium,
            locale: Locale(identifier: "en_US")
        )
        let large = WeatherWidgetPresentation(
            date: snapshot.fetchedAt,
            configuration: .referencePreview(),
            snapshot: snapshot,
            state: .loaded,
            family: .systemLarge,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertFalse(medium.usesExpandedForecastLayout)
        XCTAssertTrue(large.usesExpandedForecastLayout)
    }

    func testNewConfigurationStartsWithPortlandAndMinimalPreset() {
        let configuration = WeatherV8ConfigurationIntent()

        XCTAssertEqual(configuration.resolvedLocation, .portland)
        XCTAssertEqual(configuration.resolvedDetails, [.temperature])
    }

    func testConfigurationUsesDocumentedDefaultsAndDefensiveFallbacks() {
        for value in [nil, "unknown-choice"] {
            let configuration = WeatherV8ConfigurationIntent.referencePreview()
            configuration.city = nil
            configuration.viewMode = value
            configuration.temperatureUnit = value
            configuration.detailPreset = value

            XCTAssertEqual(configuration.resolvedCity, "Portland, Oregon, United States")
            XCTAssertEqual(configuration.resolvedViewMode, .week)
            XCTAssertEqual(configuration.resolvedTemperatureUnit, .automatic)
            XCTAssertEqual(configuration.resolvedDetailPreset, .minimal)
            XCTAssertEqual(configuration.resolvedDetails, [.temperature])
        }
    }

    func testEveryDetailPresetResolvesToItsDocumentedGroup() {
        let expected: [WeatherDetailPreset: [WeatherDetail]] = [
            .minimal: [.temperature],
            .simple: [.temperature, .condition],
            .rain: [.temperature, .precipitation],
            .comfort: [.temperature, .apparentTemperature, .humidity],
            .sun: [.temperature, .sunrise, .sunset, .uvIndex],
            .outdoor: [.temperature, .precipitation, .wind, .uvIndex],
            .detailed: [.temperature, .condition, .apparentTemperature, .humidity],
            .full: WeatherDetail.allCases,
        ]

        for preset in WeatherDetailPreset.allCases {
            let configuration = WeatherV8ConfigurationIntent.referencePreview()
            configuration.detailPreset = preset.rawValue

            XCTAssertEqual(configuration.resolvedDetailPreset, preset)
            XCTAssertEqual(configuration.resolvedDetails, expected[preset])
        }
    }

    func testDetailLimitsDeduplicateAndCapSelectionsForEveryWidgetSize() {
        let duplicated: [WeatherDetail] = [.temperature, .humidity, .temperature, .wind, .condition]

        XCTAssertEqual(
            WeatherDetailLimits.limited(duplicated, maximum: WeatherDetailLimits.small),
            [.temperature, .humidity]
        )
        XCTAssertEqual(
            WeatherDetailLimits.limited(duplicated, maximum: WeatherDetailLimits.medium),
            [.temperature, .humidity, .wind]
        )
        XCTAssertEqual(
            WeatherDetailLimits.limited(duplicated, maximum: WeatherDetailLimits.large),
            [.temperature, .humidity, .wind, .condition]
        )
    }

    func testFullPresetAdaptsVisibleDetailsAndWarningToEveryWidgetFamily() {
        let small = WeatherDetailPresentation(preset: .full, family: .systemSmall)
        XCTAssertEqual(small.visibleDetails, [.temperature, .condition])
        XCTAssertEqual(small.hiddenCount, 7)
        XCTAssertEqual(small.limit, 2)

        let medium = WeatherDetailPresentation(preset: .full, family: .systemMedium)
        XCTAssertEqual(medium.visibleDetails, [.temperature, .condition, .apparentTemperature])
        XCTAssertEqual(medium.hiddenCount, 6)
        XCTAssertEqual(medium.limit, 3)

        let large = WeatherDetailPresentation(preset: .full, family: .systemLarge)
        XCTAssertEqual(
            large.visibleDetails,
            [.temperature, .condition, .apparentTemperature, .humidity, .precipitation, .wind]
        )
        XCTAssertEqual(large.hiddenCount, 3)
        XCTAssertEqual(large.limit, 6)
    }

    func testWeatherPresentationAdaptsWeekAndHourViewsToEveryWidgetFamily() {
        let snapshot = WeatherSnapshot.sample()
        let date = snapshot.fetchedAt

        let expectations: [(WidgetFamily, WeatherViewMode, WeatherViewMode, Int)] = [
            (.systemSmall, .week, .day, 0),
            (.systemMedium, .week, .week, 7),
            (.systemLarge, .week, .week, 7),
            (.systemSmall, .hour, .hour, 3),
            (.systemMedium, .hour, .hour, 6),
            (.systemLarge, .hour, .hour, 6),
        ]

        for (family, requestedMode, expectedMode, expectedColumns) in expectations {
            let context = "family=\(family), mode=\(requestedMode.rawValue)"
            let configuration = WeatherV8ConfigurationIntent.referencePreview()
            configuration.viewMode = requestedMode.rawValue
            let presentation = WeatherWidgetPresentation(
                date: date,
                configuration: configuration,
                snapshot: snapshot,
                state: .loaded,
                family: family,
                locale: Locale(identifier: "en_US")
            )

            XCTAssertEqual(presentation.renderedMode, expectedMode, context)
            XCTAssertEqual(presentation.forecastColumnCount, expectedColumns, context)
        }
    }

    func testColumnForecastsUseCompactTemperaturesAndViewSpecificDetailBudgets() {
        let snapshot = WeatherSnapshot.sample()
        let expectedWeekLimits: [WidgetFamily: Int] = [
            .systemSmall: 1,
            .systemMedium: 1,
            .systemLarge: 2,
        ]
        let expectedDayLimits: [WidgetFamily: Int] = [
            .systemSmall: 2,
            .systemMedium: 3,
            .systemLarge: 6,
        ]

        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
            let week = WeatherDetailPresentation(preset: .full, family: family, mode: .week)
            let day = WeatherDetailPresentation(preset: .full, family: family, mode: .day)
            XCTAssertEqual(week.limit, expectedWeekLimits[family], "week family=\(family)")
            XCTAssertEqual(day.limit, expectedDayLimits[family], "day family=\(family)")
        }

        let configuration = WeatherV8ConfigurationIntent.referencePreview()
        let presentation = WeatherWidgetPresentation(
            date: snapshot.fetchedAt,
            configuration: configuration,
            snapshot: snapshot,
            state: .loaded,
            family: .systemMedium,
            locale: Locale(identifier: "en_US")
        )
        let temperature = presentation.metricValues(for: snapshot.daily[0]).first {
            $0.detail == .temperature
        }
        XCTAssertEqual(temperature?.text, "63°")
        XCTAssertEqual(temperature?.unitSuffix, "F")
        XCTAssertEqual(temperature?.displayText, "63°F")
        XCTAssertEqual(temperature?.spokenText, "Temperature 63°F")
    }

    func testEveryWidgetFamilyUsesDistinctReadableLayoutMetrics() {
        let small = WeatherWidgetLayoutMetrics(family: .systemSmall)
        let medium = WeatherWidgetLayoutMetrics(family: .systemMedium)
        let large = WeatherWidgetLayoutMetrics(family: .systemLarge)

        XCTAssertLessThan(small.headerFontSize, medium.headerFontSize)
        XCTAssertEqual(medium.headerFontSize, large.headerFontSize)
        XCTAssertLessThan(small.dayTemperatureSize, medium.dayTemperatureSize)
        XCTAssertLessThan(medium.dayTemperatureSize, large.dayTemperatureSize)
        XCTAssertGreaterThanOrEqual(small.forecastColumnSpacing, 6)
        XCTAssertGreaterThanOrEqual(medium.forecastColumnSpacing, 9)
        XCTAssertGreaterThanOrEqual(large.forecastColumnSpacing, 6)
        XCTAssertGreaterThanOrEqual(small.forecastVerticalSpacing, 4)
        XCTAssertGreaterThan(medium.forecastVerticalSpacing, small.forecastVerticalSpacing)
        XCTAssertGreaterThan(large.forecastVerticalSpacing, medium.forecastVerticalSpacing)
        XCTAssertLessThanOrEqual(small.dayTemperatureSize, 28)
        XCTAssertGreaterThanOrEqual(small.dayTemperatureMinimumWidth, 72)
        XCTAssertLessThanOrEqual(small.dayTemperatureMaximumWidth ?? .infinity, 78)
        XCTAssertLessThanOrEqual(small.minimumTemperaturePointSize, 14)
        XCTAssertLessThanOrEqual(medium.forecastTitleSize, 13)
        XCTAssertLessThanOrEqual(medium.forecastIconSize, 22)
        XCTAssertLessThanOrEqual(medium.forecastTemperatureSize, 15)
        XCTAssertGreaterThan(large.forecastTitleSize, medium.forecastTitleSize)
        XCTAssertGreaterThan(large.forecastTemperatureSize, medium.forecastTemperatureSize)
        XCTAssertFalse(small.usesStackedHeader)
        XCTAssertFalse(medium.usesStackedHeader)
        XCTAssertTrue(large.usesStackedHeader)
        XCTAssertFalse(small.fillsForecastSection)
        XCTAssertFalse(medium.fillsForecastSection)
        XCTAssertTrue(large.fillsForecastSection)
        XCTAssertFalse(small.usesFlexibleForecastItemSpacing)
        XCTAssertFalse(medium.usesFlexibleForecastItemSpacing)
        XCTAssertFalse(large.usesFlexibleForecastItemSpacing)
        XCTAssertGreaterThan(large.expandedIconSize, medium.expandedIconSize)
        XCTAssertGreaterThan(large.expandedTemperatureSize, medium.expandedTemperatureSize)
    }

    func testAttributionLinkIsForwardedToTheDefaultBrowser() {
        XCTAssertEqual(
            DesktopWidgetsURLRouter.externalURL(for: WeatherWidgetPresentation.attributionURL),
            WeatherWidgetPresentation.attributionURL
        )
        XCTAssertNil(DesktopWidgetsURLRouter.externalURL(for: URL(string: "desktop-widgets://weather")!))
        XCTAssertEqual(WeatherWidgetPresentation.attributionURL.host(), "open-meteo.com")
    }

    func testProviderLoadsTheSelectedCityInsteadOfTheDefault() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let service = RecordingWeatherService()
        let provider = WeatherProvider(
            service: service,
            cache: WeatherSnapshotCache(directoryURL: root)
        )
        let configuration = WeatherV8ConfigurationIntent.referencePreview()
        let tokyo = WeatherLocation(
            name: "Tokyo",
            latitude: 35.6762,
            longitude: 139.6503,
            timeZoneIdentifier: "Asia/Tokyo",
            adminArea: "Tokyo",
            country: "Japan"
        )
        configuration.city = WeatherV8CityEntity(location: tokyo)
        let expectedLocation = tokyo

        let entry = await provider.entry(for: configuration, date: Date.now)
        let requestedLocation = await service.requestedLocation

        XCTAssertEqual(requestedLocation, expectedLocation)
        XCTAssertEqual(entry.configuration.resolvedLocation, expectedLocation)
        XCTAssertEqual(entry.snapshot?.locationName, expectedLocation.displayName)
    }

    func testProviderBuildsSevenHourlyEntriesAndRefreshesLoadedAndStaleForecasts() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let now = Date.now
        let snapshot = WeatherSnapshot.sample(
            now: now.addingTimeInterval(-WeatherSnapshotCache.maximumFreshAge - 1)
        )
        let configuration = WeatherV8ConfigurationIntent.referencePreview()

        let loadedTimeline = await WeatherProvider(
            service: StubWeatherService(result: .success(snapshot)),
            cache: WeatherSnapshotCache(directoryURL: root)
        ).timeline(for: configuration, now: now)

        XCTAssertEqual(loadedTimeline.entries.count, 7)
        XCTAssertEqual(loadedTimeline.entries.first?.date, now)
        XCTAssertTrue(loadedTimeline.entries.allSatisfy { $0.state == .loaded })
        assertReloadDate(loadedTimeline.policy, equals: now.addingTimeInterval(60 * 60))

        let staleTimeline = await WeatherProvider(
            service: StubWeatherService(result: .failure(.requestFailed("Offline"))),
            cache: WeatherSnapshotCache(directoryURL: root)
        ).timeline(for: configuration, now: now)

        XCTAssertEqual(staleTimeline.entries.count, 7)
        XCTAssertTrue(staleTimeline.entries.allSatisfy {
            $0.state == .stale("Weather is temporarily unavailable. Offline")
        })
        XCTAssertTrue(staleTimeline.entries.allSatisfy { $0.snapshot == snapshot })
        assertReloadDate(staleTimeline.policy, equals: now.addingTimeInterval(60 * 60))
    }

    func testProviderRetriesTemporaryFailuresAfterThirtyMinutes() async {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let now = Date(timeIntervalSince1970: 1_786_288_940)
        let timeline = await WeatherProvider(
            service: StubWeatherService(result: .failure(.requestFailed("Offline"))),
            cache: WeatherSnapshotCache(directoryURL: root)
        ).timeline(for: .referencePreview(), now: now)

        XCTAssertEqual(timeline.entries.count, 1)
        XCTAssertEqual(
            timeline.entries.first?.state,
            .failed("Weather is temporarily unavailable. Offline", retryable: true)
        )
        assertReloadDate(timeline.policy, equals: now.addingTimeInterval(30 * 60))
    }

    func testProviderDoesNotRetryPermanentCityFailures() async {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let timeline = await WeatherProvider(
            service: StubWeatherService(result: .failure(.cityNotFound("Unknownville"))),
            cache: WeatherSnapshotCache(directoryURL: root)
        ).timeline(
            for: .referencePreview(),
            now: Date(timeIntervalSince1970: 1_786_288_940)
        )

        XCTAssertEqual(timeline.entries.count, 1)
        XCTAssertEqual(
            timeline.entries.first?.state,
            .failed(
                "No weather location matched “Unknownville”. Try adding a state or country.",
                retryable: false
            )
        )
        XCTAssertEqual(timeline.policy, .never)
    }

    func testWeatherPresentationCoversEveryFamilyModeAndDetailPreset() throws {
        let snapshot = WeatherSnapshot.sample()
        let locale = Locale(identifier: "en_US")

        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
            for mode in WeatherViewMode.allCases {
                for preset in WeatherDetailPreset.allCases {
                    let context = "family=\(family), mode=\(mode.rawValue), preset=\(preset.rawValue)"
                    let configuration = WeatherV8ConfigurationIntent.referencePreview()
                    configuration.viewMode = mode.rawValue
                    configuration.detailPreset = preset.rawValue
                    let presentation = WeatherWidgetPresentation(
                        date: snapshot.fetchedAt,
                        configuration: configuration,
                        snapshot: snapshot,
                        state: .loaded,
                        family: family,
                        locale: locale
                    )
                    let renderedMode = try XCTUnwrap(presentation.renderedMode, context)
                    let detailLimit = WeatherDetailLimits.maximum(for: family, mode: renderedMode)
                    let forecastTitles = presentation.forecastTitles
                    let forecastAccessibilityLabels = presentation.forecastAccessibilityLabels

                    XCTAssertLessThanOrEqual(
                        presentation.detailPresentation.visibleDetails.count,
                        detailLimit,
                        context
                    )
                    XCTAssertEqual(
                        presentation.detailPresentation.hiddenCount,
                        max(0, preset.details.count - detailLimit),
                        context
                    )
                    XCTAssertEqual(
                        presentation.detailLimitNotice == nil,
                        presentation.detailPresentation.hiddenCount == 0,
                        context
                    )
                    XCTAssertEqual(forecastTitles.count, presentation.forecastColumnCount, context)
                    XCTAssertEqual(
                        forecastAccessibilityLabels.count,
                        presentation.forecastColumnCount,
                        context
                    )
                    XCTAssertEqual(
                        presentation.forecastAccessibilityLabels(titles: forecastTitles),
                        forecastAccessibilityLabels,
                        context
                    )
                    XCTAssertTrue(forecastTitles.allSatisfy { !$0.isEmpty }, context)
                    XCTAssertTrue(forecastAccessibilityLabels.allSatisfy { !$0.isEmpty }, context)
                    if presentation.renderedMode == .day {
                        XCTAssertFalse(presentation.dayAccessibilityLabel?.isEmpty ?? true, context)
                    } else {
                        XCTAssertNil(presentation.dayAccessibilityLabel, context)
                    }
                    XCTAssertEqual(presentation.locationName, snapshot.locationName, context)
                    XCTAssertFalse(presentation.showsStaleStatus, context)
                    XCTAssertNil(presentation.failureMessage, context)
                }
            }
        }
    }

    func testWeatherPresentationRepresentsStaleFailureAndEmptyHourFallbackStates() {
        let snapshot = WeatherSnapshot.sample()
        let configuration = WeatherV8ConfigurationIntent.referencePreview()
        configuration.viewMode = WeatherViewMode.hour.rawValue

        let stale = WeatherWidgetPresentation(
            date: snapshot.fetchedAt,
            configuration: configuration,
            snapshot: snapshot,
            state: .stale("Offline"),
            family: .systemMedium,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertTrue(stale.showsStaleStatus)
        XCTAssertEqual(stale.renderedMode, .hour)

        let failure = WeatherWidgetPresentation(
            date: snapshot.fetchedAt,
            configuration: configuration,
            snapshot: nil,
            state: .failed("City not found", retryable: false),
            family: .systemSmall,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertNil(failure.renderedMode)
        XCTAssertEqual(failure.failureMessage, "City not found")
        XCTAssertEqual(failure.locationName, configuration.resolvedCity)

        let afterForecast = WeatherWidgetPresentation(
            date: snapshot.hourly.last!.date.addingTimeInterval(60 * 60),
            configuration: configuration,
            snapshot: snapshot,
            state: .loaded,
            family: .systemMedium,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(afterForecast.renderedMode, .day)
        XCTAssertEqual(afterForecast.forecastColumnCount, 0)
    }

    func testWeatherPresentationAdvancesTheWeekAcrossCityMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let beforeMidnight = calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 23,
            minute: 45
        ))!
        let snapshot = WeatherSnapshot.sample(now: beforeMidnight)
        let afterMidnight = calendar.date(byAdding: .minute, value: 30, to: beforeMidnight)!
        let presentation = WeatherWidgetPresentation(
            date: afterMidnight,
            configuration: .referencePreview(),
            snapshot: snapshot,
            state: .loaded,
            family: .systemMedium,
            locale: Locale(identifier: "en_US")
        )

        guard case let .week(days) = presentation.content else {
            return XCTFail("Expected a week presentation")
        }
        XCTAssertEqual(days.first, snapshot.daily[1])
        XCTAssertFalse(days.contains(snapshot.daily[0]))
    }

    func testCityQueryReturnsMultipleReadableMatchesAndRestoresIdentifiers() async throws {
        let matches = try OpenMeteoLocationSearchService.decodeLocations(
            data: Data(Self.geocodingFixture.utf8)
        )
        let query = WeatherV8CityQuery(searchService: StubWeatherLocationSearchService(locations: matches))
        let results = try await query.entities(matching: "Portland")

        XCTAssertEqual(results.map(\.location), matches)
        XCTAssertEqual(results.map { String(localized: $0.displayRepresentation.title) }, ["Portland", "Portland"])
        XCTAssertEqual(
            results.compactMap { $0.displayRepresentation.subtitle.map { String(localized: $0) } },
            ["Oregon, United States", "Maine, United States"]
        )

        let restored = try await query.entities(for: results.map(\.id))
        let defaultCity = await query.defaultResult()
        XCTAssertEqual(restored.map(\.location), matches)
        XCTAssertEqual(defaultCity?.location, .portland)
    }

    func testOptionsProvidersReturnStableDefaults() async throws {

        let modes = try await WeatherViewModeOptionsProvider().results()
        let defaultMode = await WeatherViewModeOptionsProvider().defaultResult()
        XCTAssertEqual(Set(modes.items), Set(WeatherViewMode.allCases.map(\.rawValue)))
        XCTAssertEqual(defaultMode, WeatherViewMode.week.rawValue)

        let units = try await WeatherTemperatureUnitOptionsProvider().results()
        let defaultUnit = await WeatherTemperatureUnitOptionsProvider().defaultResult()
        XCTAssertEqual(Set(units.items), Set(WeatherTemperatureUnit.allCases.map(\.rawValue)))
        XCTAssertEqual(defaultUnit, WeatherTemperatureUnit.automatic.rawValue)

        let presets = try await WeatherDetailPresetOptionsProvider().results()
        let defaultPreset = await WeatherDetailPresetOptionsProvider().defaultResult()
        XCTAssertEqual(Set(presets.items), Set(WeatherDetailPreset.allCases.map(\.rawValue)))
        XCTAssertEqual(defaultPreset, WeatherDetailPreset.minimal.rawValue)
    }

    func testTemperatureUnitsResolveAndFormatPredictably() {
        XCTAssertEqual(WeatherTemperatureUnit.fahrenheit.resolved(for: Locale(identifier: "fr_FR")), .fahrenheit)
        XCTAssertEqual(WeatherTemperatureUnit.celsius.resolved(for: Locale(identifier: "en_US")), .celsius)
        XCTAssertEqual(WeatherTemperatureUnit.automatic.resolved(for: Locale(identifier: "en_US")), .fahrenheit)
        XCTAssertEqual(WeatherTemperatureUnit.automatic.resolved(for: Locale(identifier: "fr_FR")), .celsius)
        XCTAssertEqual(WeatherTemperatureUnit.automatic.resolved(for: Locale(identifier: "en_GB")), .celsiusWithMPH)
        XCTAssertEqual(WeatherValueFormatter.temperature(63.4, unit: .fahrenheit), "63°F")
        XCTAssertEqual(WeatherValueFormatter.wind(8.2, unit: .celsius), "8 km/h")
        XCTAssertEqual(WeatherValueFormatter.wind(8.2, unit: .celsiusWithMPH), "8 mph")
    }

    func testSunTimesRespectTheUsersTwelveOrTwentyFourHourLocale() throws {
        let date = Date(timeIntervalSince1970: 1_786_291_200)
        let timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        let us = try XCTUnwrap(WeatherValueFormatter.time(
            date,
            timeZone: timeZone,
            locale: Locale(identifier: "en_US")
        ))
        let british = try XCTUnwrap(WeatherValueFormatter.time(
            date,
            timeZone: timeZone,
            locale: Locale(identifier: "en_GB")
        ))

        XCTAssertTrue(us.contains("AM") || us.contains("PM"))
        XCTAssertFalse(british.contains("AM") || british.contains("PM"))
    }

    func testBatchedForecastLabelsMatchIndividualLocalizedFormatting() throws {
        let timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let locale = Locale(identifier: "en_US")
        let dates = WeatherSnapshot.sample().hourly.prefix(4).map(\.date)

        XCTAssertEqual(
            WeatherValueFormatter.weekdayLabels(for: dates, timeZone: timeZone, locale: locale),
            dates.map { WeatherValueFormatter.weekday($0, timeZone: timeZone, locale: locale) }
        )
        XCTAssertEqual(
            WeatherValueFormatter.hourLabels(for: dates, timeZone: timeZone, locale: locale),
            dates.map { WeatherValueFormatter.hour($0, timeZone: timeZone, locale: locale) }
        )
    }

    func testWeatherCodesMapToSemanticConditions() {
        let expected: [(Int, WeatherCondition)] = [
            (0, .clear),
            (2, .partlyCloudy),
            (3, .cloudy),
            (45, .fog),
            (53, .drizzle),
            (63, .rain),
            (73, .snow),
            (96, .storm),
            (1000, .unknown),
        ]

        for (code, condition) in expected {
            XCTAssertEqual(WeatherCondition(wmoCode: code), condition)
            XCTAssertFalse(condition.displayName.isEmpty)
            XCTAssertFalse(condition.symbolName.isEmpty)
        }
    }

    func testDailyForecastsAdvanceAcrossMidnightInTheForecastCity() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let beforeMidnight = calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 23,
            minute: 45
        ))!
        let afterMidnight = calendar.date(byAdding: .minute, value: 30, to: beforeMidnight)!
        let snapshot = WeatherSnapshot.sample(now: beforeMidnight)

        let visibleDays = snapshot.dailyForecasts(startingAt: afterMidnight)

        XCTAssertEqual(visibleDays.first, snapshot.daily[1])
        XCTAssertEqual(snapshot.dailyForecast(for: afterMidnight), snapshot.daily[1])
        XCTAssertFalse(visibleDays.contains(snapshot.daily[0]))
    }

    func testWeatherTimelineUsesTheForecastCityHourBoundaries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Kathmandu")!
        let start = calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 10,
            minute: 37
        ))!

        let dates = WeatherTimelinePolicy.dates(
            startingAt: start,
            count: 3,
            timeZone: calendar.timeZone
        )

        XCTAssertEqual(dates[0], start)
        XCTAssertEqual(dates[1], calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 11
        )))
        XCTAssertEqual(dates[2], calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 12
        )))
    }

    func testRequestURLsIncludeCityUnitsAndAllDetailVariables() throws {
        let location = WeatherLocation(
            name: "Portland",
            latitude: 45.52345,
            longitude: -122.67621,
            timeZoneIdentifier: "America/Los_Angeles",
            adminArea: "Oregon",
            country: "United States"
        )
        let forecastURL = try OpenMeteoWeatherService.forecastURL(location: location, unit: .fahrenheit)
        let items = URLComponents(url: forecastURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let current = items.first(where: { $0.name == "current" })?.value ?? ""
        let hourly = items.first(where: { $0.name == "hourly" })?.value ?? ""
        let daily = items.first(where: { $0.name == "daily" })?.value ?? ""

        for field in ["temperature_2m", "apparent_temperature", "relative_humidity_2m", "precipitation_probability", "weather_code", "wind_speed_10m"] {
            XCTAssertTrue(current.contains(field), "Missing current field \(field)")
            XCTAssertTrue(hourly.contains(field), "Missing hourly field \(field)")
        }
        XCTAssertTrue(hourly.contains("uv_index"))
        XCTAssertTrue(daily.contains("temperature_2m_max"))
        XCTAssertTrue(daily.contains("apparent_temperature_max"))
        XCTAssertTrue(daily.contains("uv_index_max"))
        XCTAssertTrue(daily.contains("sunrise"))
        XCTAssertTrue(daily.contains("sunset"))
        XCTAssertTrue(daily.contains("relative_humidity_2m_mean"))
        XCTAssertTrue(daily.contains("precipitation_probability_max"))
        XCTAssertEqual(items.first(where: { $0.name == "temperature_unit" })?.value, "fahrenheit")
        XCTAssertEqual(items.first(where: { $0.name == "wind_speed_unit" })?.value, "mph")
        XCTAssertEqual(items.first(where: { $0.name == "timezone" })?.value, "auto")
        XCTAssertEqual(items.first(where: { $0.name == "timeformat" })?.value, "unixtime")
        XCTAssertEqual(items.first(where: { $0.name == "forecast_days" })?.value, "7")
        XCTAssertEqual(
            items.first(where: { $0.name == "forecast_hours" })?.value,
            String(OpenMeteoWeatherService.forecastHourCount)
        )
    }

    func testGeocodingRequestAndResponseProvideSelectableCityCoordinates() throws {
        let url = try OpenMeteoLocationSearchService.geocodingURL(
            query: "Portland",
            locale: Locale(identifier: "en_US")
        )
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(url.host(), "geocoding-api.open-meteo.com")
        XCTAssertEqual(items.first(where: { $0.name == "name" })?.value, "Portland")
        XCTAssertEqual(
            items.first(where: { $0.name == "count" })?.value,
            String(WeatherCityCatalog.maximumSearchResults)
        )

        let locations = try OpenMeteoLocationSearchService.decodeLocations(
            data: Data(Self.geocodingFixture.utf8)
        )
        XCTAssertEqual(locations.count, 2)
        XCTAssertEqual(locations[0], .portland)
        XCTAssertEqual(locations[1].name, "Portland")
        XCTAssertEqual(locations[1].adminArea, "Maine")
        XCTAssertNotEqual(
            WeatherCityCatalog.identifier(for: locations[0]),
            WeatherCityCatalog.identifier(for: locations[1])
        )
        XCTAssertEqual(
            locations.map(WeatherCityCatalog.displayTitle(for:)),
            ["Portland, Oregon, United States", "Portland, Maine, United States"]
        )
    }

    func testForecastServiceUsesHTTPTransportForAValidResponse() async throws {
        let session = stubSession(statusCode: 200, data: Data(Self.fixture.utf8))
        let snapshot = try await OpenMeteoWeatherService(session: session).forecast(
            location: .portland,
            unit: .automatic,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(snapshot.locationName, WeatherLocation.portland.displayName)
        XCTAssertEqual(snapshot.unit, .fahrenheit)
        XCTAssertEqual(snapshot.current.temperature, 63)
        XCTAssertEqual(snapshot.current.apparentTemperature, 62)
        XCTAssertEqual(snapshot.current.uvIndex, 3.2)
        XCTAssertEqual(WeatherURLProtocolStub.requestCount, 1)
        XCTAssertEqual(WeatherURLProtocolStub.lastRequest?.value(forHTTPHeaderField: "User-Agent"), "MacOS-Widgets/0.1")
    }

    func testForecastServiceMapsHTTPDecodeEmptyAndTransportFailures() async {
        await assertForecastError(
            session: stubSession(statusCode: 503, data: Data()),
            expected: .invalidResponse
        )
        await assertForecastError(
            session: stubSession(statusCode: 200, data: Data("not-json".utf8)),
            expected: .invalidData
        )
        await assertForecastError(
            session: stubSession(statusCode: 200, data: Data(Self.emptyForecastFixture.utf8)),
            expected: .invalidData
        )

        let transportError = URLError(.notConnectedToInternet)
        await assertForecastError(
            session: stubSession(error: transportError),
            expected: .requestFailed(transportError.localizedDescription)
        )
    }

    func testLocationSearchUsesHTTPTransportAndSkipsShortQueries() async throws {
        let session = stubSession(statusCode: 200, data: Data(Self.geocodingFixture.utf8))
        let service = OpenMeteoLocationSearchService(session: session)

        let locations = try await service.locations(
            matching: "  Portland  ",
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(locations.count, 2)
        XCTAssertEqual(WeatherURLProtocolStub.requestCount, 1)
        XCTAssertEqual(WeatherURLProtocolStub.lastRequest?.url?.host(), "geocoding-api.open-meteo.com")

        WeatherURLProtocolStub.reset()
        let shortQueryResults = try await service.locations(
            matching: " p ",
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(shortQueryResults, [])
        XCTAssertEqual(WeatherURLProtocolStub.requestCount, 0)
    }

    func testLocationSearchMapsHTTPDecodeAndTransportFailures() async {
        await assertLocationSearchError(
            session: stubSession(statusCode: 500, data: Data()),
            expected: .invalidResponse
        )
        await assertLocationSearchError(
            session: stubSession(statusCode: 200, data: Data("not-json".utf8)),
            expected: .invalidData
        )

        let transportError = URLError(.timedOut)
        await assertLocationSearchError(
            session: stubSession(error: transportError),
            expected: .requestFailed(transportError.localizedDescription)
        )
    }

    func testCityResultsKeepDistinctMatchesAndCapThePopupAtTwenty() {
        let locations = (0..<25).map { index in
            WeatherLocation(
                name: "Portland",
                latitude: 40 + Double(index) / 10,
                longitude: -120 - Double(index) / 10,
                timeZoneIdentifier: "America/Los_Angeles",
                adminArea: "Region \(index)",
                country: "United States"
            )
        }
        let duplicate = locations[3]

        let normalized = WeatherCityCatalog.normalized(locations + [duplicate])

        XCTAssertEqual(normalized.count, WeatherCityCatalog.maximumSearchResults)
        XCTAssertEqual(Set(normalized.map(WeatherCityCatalog.identifier(for:))).count, normalized.count)
        XCTAssertEqual(Set(normalized.map(WeatherCityCatalog.displayTitle(for:))).count, normalized.count)
    }

    func testForecastDecodingNormalizesCurrentHourlyAndDailyData() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_786_288_940)
        let location = WeatherLocation(
            name: "Portland",
            latitude: 45.52345,
            longitude: -122.67621,
            timeZoneIdentifier: "America/Los_Angeles",
            adminArea: "Oregon",
            country: "United States"
        )

        let snapshot = try OpenMeteoWeatherService.decodeForecast(
            data: Data(Self.fixture.utf8),
            location: location,
            unit: .fahrenheit,
            fetchedAt: fetchedAt
        )

        XCTAssertEqual(snapshot.locationName, "Portland, Oregon, United States")
        XCTAssertEqual(snapshot.providerID, "open-meteo")
        XCTAssertEqual(snapshot.timeZoneIdentifier, "America/Los_Angeles")
        XCTAssertEqual(snapshot.fetchedAt, fetchedAt)
        XCTAssertEqual(snapshot.current.temperature, 63)
        XCTAssertEqual(snapshot.current.condition, .clear)
        XCTAssertEqual(snapshot.hourly.count, 3)
        XCTAssertEqual(snapshot.hourly[1].precipitationProbability, 20)
        XCTAssertEqual(snapshot.hourly[1].apparentTemperature, 64)
        XCTAssertEqual(snapshot.hourly[2].condition, .rain)
        XCTAssertEqual(snapshot.daily.count, 2)
        XCTAssertEqual(snapshot.daily[0].highTemperature, 70)
        XCTAssertEqual(snapshot.daily[0].apparentHighTemperature, 69)
        XCTAssertEqual(snapshot.daily[0].uvIndex, 5.4)
        XCTAssertNotNil(snapshot.daily[0].sunrise)
        XCTAssertNotNil(snapshot.daily[0].sunset)
        XCTAssertEqual(snapshot.daily[1].humidity, 66)
        XCTAssertEqual(snapshot.daily[1].condition, .partlyCloudy)
    }

    func testForecastDecodingUsesUVFromTheHourlyIntervalContainingCurrentTime() throws {
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(Self.fixture.utf8)) as? [String: Any]
        )
        var current = try XCTUnwrap(payload["current"] as? [String: Any])
        current["time"] = 1_786_291_200 + 15 * 60
        payload["current"] = current

        let snapshot = try OpenMeteoWeatherService.decodeForecast(
            data: JSONSerialization.data(withJSONObject: payload),
            location: .portland,
            unit: .fahrenheit
        )

        XCTAssertEqual(snapshot.current.uvIndex, 3.2)
    }

    func testSnapshotCacheRoundTripsByCity() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let cache = WeatherSnapshotCache(directoryURL: root)
        let snapshot = WeatherSnapshot.sample(now: .now)
        try cache.save(snapshot, city: "Portland, Oregon")

        XCTAssertEqual(cache.load(city: "Portland, Oregon", unit: .fahrenheit), snapshot)
        XCTAssertNil(cache.load(city: "Portland, Oregon", unit: .celsius))
        XCTAssertNil(cache.load(city: "Seattle, Washington", unit: .fahrenheit))

        let expired = WeatherSnapshot.sample(now: .now.addingTimeInterval(-25 * 60 * 60))
        try cache.save(expired, city: "Expired City")
        XCTAssertNil(cache.load(city: "Expired City", unit: .fahrenheit))
    }

    func testSnapshotCacheUsesAFifteenMinuteFreshnessWindowWithoutLosingStaleFallback() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let now = Date(timeIntervalSince1970: 1_788_200_000)
        let cache = WeatherSnapshotCache(directoryURL: root)
        let fresh = WeatherSnapshot.sample(now: now.addingTimeInterval(-15 * 60))
        let refreshable = WeatherSnapshot.sample(now: now.addingTimeInterval(-15 * 60 - 1))

        try cache.save(fresh, city: "Fresh City")
        try cache.save(refreshable, city: "Refreshable City")

        XCTAssertEqual(cache.loadFresh(city: "Fresh City", unit: .fahrenheit, now: now), fresh)
        XCTAssertNil(cache.loadFresh(city: "Refreshable City", unit: .fahrenheit, now: now))
        XCTAssertEqual(
            cache.load(city: "Refreshable City", unit: .fahrenheit, now: now),
            refreshable
        )
    }

    func testOlderCachedSnapshotsDecodeWithoutNewOptionalWeatherMetrics() throws {
        let original = WeatherSnapshot.sample()
        let encoded = try JSONEncoder().encode(original)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )

        var current = try XCTUnwrap(object["current"] as? [String: Any])
        current.removeValue(forKey: "apparentTemperature")
        current.removeValue(forKey: "uvIndex")
        object["current"] = current
        object["hourly"] = try XCTUnwrap(object["hourly"] as? [[String: Any]]).map { value in
            var oldValue = value
            oldValue.removeValue(forKey: "apparentTemperature")
            oldValue.removeValue(forKey: "uvIndex")
            return oldValue
        }
        object["daily"] = try XCTUnwrap(object["daily"] as? [[String: Any]]).map { value in
            var oldValue = value
            for key in ["apparentHighTemperature", "uvIndex", "sunrise", "sunset"] {
                oldValue.removeValue(forKey: key)
            }
            return oldValue
        }

        let oldData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(WeatherSnapshot.self, from: oldData)

        XCTAssertNil(decoded.current.apparentTemperature)
        XCTAssertNil(decoded.current.uvIndex)
        XCTAssertNil(decoded.daily.first?.sunrise)
        XCTAssertEqual(decoded.locationName, original.locationName)
    }

    func testLoaderCachesAFreshForecastForTheResolvedCityAndUnit() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = WeatherSnapshot.sample(now: .now)
        let cache = WeatherSnapshotCache(directoryURL: root)
        let loader = WeatherLoader(
            service: StubWeatherService(result: .success(snapshot)),
            cache: cache
        )

        let outcome = await loader.load(
            location: .portland,
            unit: .fahrenheit,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(outcome, .fresh(snapshot))
        XCTAssertEqual(cache.load(city: WeatherLocation.portland.cacheIdentifier, unit: .fahrenheit), snapshot)
    }

    func testLoaderReusesAMatchingFreshSnapshotWithoutCallingTheService() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = WeatherSnapshot.sample(now: .now)
        let cache = WeatherSnapshotCache(directoryURL: root)
        try cache.save(snapshot, city: WeatherLocation.portland.cacheIdentifier)
        let service = CountingWeatherService(result: .failure(.requestFailed("Should not run")))
        let loader = WeatherLoader(service: service, cache: cache)

        let outcome = await loader.load(
            location: .portland,
            unit: .fahrenheit,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(outcome, .fresh(snapshot))
        let requestCount = await service.requestCount
        XCTAssertEqual(requestCount, 0)
    }

    func testRequestCoordinatorCoalescesOnlySimultaneousMatchingForecasts() async throws {
        let coordinator = WeatherForecastRequestCoordinator()
        let operation = DelayedWeatherOperation()

        async let first = coordinator.forecast(for: "portland-fahrenheit") {
            try await operation.forecast()
        }
        async let second = coordinator.forecast(for: "portland-fahrenheit") {
            try await operation.forecast()
        }
        _ = try await (first, second)
        let matchingRequestCount = await operation.requestCount
        XCTAssertEqual(matchingRequestCount, 1)

        async let third = coordinator.forecast(for: "portland-celsius") {
            try await operation.forecast()
        }
        async let fourth = coordinator.forecast(for: "tokyo-celsius") {
            try await operation.forecast()
        }
        _ = try await (third, fourth)
        let distinctRequestCount = await operation.requestCount
        XCTAssertEqual(distinctRequestCount, 3)
    }

    func testLoaderReturnsSavedForecastAsStaleWhenRefreshFails() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = WeatherSnapshot.sample(
            now: .now.addingTimeInterval(-WeatherSnapshotCache.maximumFreshAge - 1)
        )
        let cache = WeatherSnapshotCache(directoryURL: root)
        try cache.save(snapshot, city: WeatherLocation.portland.cacheIdentifier)
        let loader = WeatherLoader(
            service: StubWeatherService(result: .failure(.requestFailed("Offline"))),
            cache: cache
        )

        let outcome = await loader.load(
            location: .portland,
            unit: .fahrenheit,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(
            outcome,
            .stale(snapshot, message: "Weather is temporarily unavailable. Offline")
        )
    }

    func testLoaderRetainsDecodedStaleFallbackAcrossAFailedRefresh() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = WeatherSnapshot.sample(
            now: .now.addingTimeInterval(-WeatherSnapshotCache.maximumFreshAge - 1)
        )
        let cache = WeatherSnapshotCache(directoryURL: root)
        try cache.save(snapshot, city: WeatherLocation.portland.cacheIdentifier)
        let loader = WeatherLoader(
            service: RemovingWeatherService(cacheDirectory: root),
            cache: cache
        )

        let outcome = await loader.load(
            location: .portland,
            unit: .fahrenheit,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
        XCTAssertEqual(
            outcome,
            .stale(snapshot, message: "Weather is temporarily unavailable. Offline")
        )
    }

    func testLoaderDoesNotReuseCacheAcrossSameNamedCoordinates() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let firstLocation = WeatherLocation(
            name: "Springfield",
            latitude: 39.7817,
            longitude: -89.6501,
            timeZoneIdentifier: "America/Chicago",
            adminArea: "Illinois",
            country: "United States"
        )
        let secondLocation = WeatherLocation(
            name: "Springfield",
            latitude: 39.7990,
            longitude: -89.6436,
            timeZoneIdentifier: "America/Chicago",
            adminArea: "Illinois",
            country: "United States"
        )
        let cache = WeatherSnapshotCache(directoryURL: root)
        let snapshot = WeatherSnapshot.sample(now: .now)

        _ = await WeatherLoader(
            service: StubWeatherService(result: .success(snapshot)),
            cache: cache
        ).load(
            location: firstLocation,
            unit: .fahrenheit,
            locale: Locale(identifier: "en_US")
        )

        let outcome = await WeatherLoader(
            service: StubWeatherService(result: .failure(.requestFailed("Offline"))),
            cache: cache
        ).load(
            location: secondLocation,
            unit: .fahrenheit,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(
            outcome,
            .failed(
                message: "Weather is temporarily unavailable. Offline",
                retryable: true
            )
        )
    }

    func testLoaderReturnsFailureWithoutSubstitutingAnotherCityWhenNoCacheExists() async {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let loader = WeatherLoader(
            service: StubWeatherService(result: .failure(.cityNotFound("Unknownville"))),
            cache: WeatherSnapshotCache(directoryURL: root)
        )

        let outcome = await loader.load(
            location: WeatherLocation(
                name: "Unknownville",
                latitude: 0,
                longitude: 0,
                timeZoneIdentifier: "UTC",
                adminArea: nil,
                country: nil
            ),
            unit: .automatic,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(
            outcome,
            .failed(
                message: "No weather location matched “Unknownville”. Try adding a state or country.",
                retryable: false
            )
        )
    }

    func testUnknownCityErrorDoesNotSuggestAReplacementCity() {
        XCTAssertEqual(
            WeatherServiceError.cityNotFound("Not A Real Place").errorDescription,
            "No weather location matched “Not A Real Place”. Try adding a state or country."
        )
    }

    private func stubSession(statusCode: Int, data: Data) -> URLSession {
        WeatherURLProtocolStub.install { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [WeatherURLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private func stubSession(error: any Error) -> URLSession {
        WeatherURLProtocolStub.install { _ in throw error }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [WeatherURLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private func assertForecastError(
        session: URLSession,
        expected: WeatherServiceError
    ) async {
        do {
            _ = try await OpenMeteoWeatherService(session: session).forecast(
                location: .portland,
                unit: .fahrenheit,
                locale: Locale(identifier: "en_US")
            )
            XCTFail("Expected forecast request to fail with \(expected)")
        } catch let error as WeatherServiceError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Expected WeatherServiceError, received \(error)")
        }
    }

    private func assertLocationSearchError(
        session: URLSession,
        expected: WeatherServiceError
    ) async {
        do {
            _ = try await OpenMeteoLocationSearchService(session: session).locations(
                matching: "Portland",
                locale: Locale(identifier: "en_US")
            )
            XCTFail("Expected location search to fail with \(expected)")
        } catch let error as WeatherServiceError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Expected WeatherServiceError, received \(error)")
        }
    }

    private func assertReloadDate(
        _ policy: TimelineReloadPolicy,
        equals expectedDate: Date,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(policy, .after(expectedDate), file: file, line: line)
    }

    private static let fixture = """
    {
      "timezone": "America/Los_Angeles",
      "current": {
        "time": 1786291200,
        "temperature_2m": 63.0,
        "apparent_temperature": 62.0,
        "relative_humidity_2m": 61.0,
        "precipitation_probability": 5.0,
        "weather_code": 0,
        "wind_speed_10m": 7.0
      },
      "hourly": {
        "time": [1786291200, 1786294800, 1786298400],
        "temperature_2m": [63.0, 65.0, 66.0],
        "apparent_temperature": [62.0, 64.0, 65.0],
        "uv_index": [3.2, 3.8, 4.1],
        "relative_humidity_2m": [61.0, 60.0, 59.0],
        "precipitation_probability": [5.0, 20.0, 45.0],
        "weather_code": [0, 2, 61],
        "wind_speed_10m": [7.0, 8.0, 9.0]
      },
      "daily": {
        "time": [1786258800, 1786345200],
        "temperature_2m_max": [70.0, 72.0],
        "temperature_2m_min": [55.0, 57.0],
        "apparent_temperature_max": [69.0, 71.0],
        "uv_index_max": [5.4, 5.9],
        "sunrise": [1786276800, 1786363200],
        "sunset": [1786327200, 1786413600],
        "relative_humidity_2m_mean": [64.0, 66.0],
        "precipitation_probability_max": [20.0, 35.0],
        "weather_code": [0, 2],
        "wind_speed_10m_max": [10.0, 12.0]
      }
    }
    """

    private static let emptyForecastFixture = """
    {
      "timezone": "UTC",
      "current": {
        "time": 1786291200,
        "temperature_2m": 63.0,
        "relative_humidity_2m": 61.0,
        "precipitation_probability": 5.0,
        "weather_code": 0,
        "wind_speed_10m": 7.0
      },
      "hourly": {
        "time": [],
        "temperature_2m": [],
        "relative_humidity_2m": [],
        "precipitation_probability": [],
        "weather_code": [],
        "wind_speed_10m": []
      },
      "daily": {
        "time": [],
        "temperature_2m_max": [],
        "temperature_2m_min": [],
        "relative_humidity_2m_mean": [],
        "precipitation_probability_max": [],
        "weather_code": [],
        "wind_speed_10m_max": []
      }
    }
    """

    private static let geocodingFixture = """
    {
      "results": [
        {
          "name": "Portland",
          "latitude": 45.52345,
          "longitude": -122.67621,
          "timezone": "America/Los_Angeles",
          "admin1": "Oregon",
          "country": "United States"
        },
        {
          "name": "Portland",
          "latitude": 43.65737,
          "longitude": -70.2589,
          "timezone": "America/New_York",
          "admin1": "Maine",
          "country": "United States"
        }
      ]
    }
    """

}

private struct StubWeatherService: WeatherServing {
    let result: Result<WeatherSnapshot, WeatherServiceError>

    func forecast(location: WeatherLocation, unit: WeatherTemperatureUnit, locale: Locale) async throws -> WeatherSnapshot {
        try result.get()
    }
}

private actor CountingWeatherService: WeatherServing {
    let result: Result<WeatherSnapshot, WeatherServiceError>
    private(set) var requestCount = 0

    init(result: Result<WeatherSnapshot, WeatherServiceError>) {
        self.result = result
    }

    func forecast(
        location: WeatherLocation,
        unit: WeatherTemperatureUnit,
        locale: Locale
    ) async throws -> WeatherSnapshot {
        requestCount += 1
        return try result.get()
    }
}

private actor DelayedWeatherOperation {
    private(set) var requestCount = 0

    func forecast() async throws -> WeatherSnapshot {
        requestCount += 1
        try await Task.sleep(nanoseconds: 50_000_000)
        return WeatherSnapshot.sample(now: .now)
    }
}

private struct RemovingWeatherService: WeatherServing {
    let cacheDirectory: URL

    func forecast(
        location: WeatherLocation,
        unit: WeatherTemperatureUnit,
        locale: Locale
    ) async throws -> WeatherSnapshot {
        try FileManager.default.removeItem(at: cacheDirectory)
        throw WeatherServiceError.requestFailed("Offline")
    }
}

private struct StubWeatherLocationSearchService: WeatherLocationSearching {
    let locations: [WeatherLocation]

    func locations(matching query: String, locale: Locale) async throws -> [WeatherLocation] {
        locations
    }
}

private actor RecordingWeatherService: WeatherServing {
    private(set) var requestedLocation: WeatherLocation?

    func forecast(
        location: WeatherLocation,
        unit: WeatherTemperatureUnit,
        locale: Locale
    ) async throws -> WeatherSnapshot {
        requestedLocation = location
        let sample = WeatherSnapshot.sample()
        return WeatherSnapshot(
            locationName: location.displayName,
            providerID: sample.providerID,
            timeZoneIdentifier: location.timeZoneIdentifier,
            fetchedAt: sample.fetchedAt,
            unit: unit.resolved(for: locale),
            current: sample.current,
            hourly: sample.hourly,
            daily: sample.daily
        )
    }
}

private final class WeatherURLProtocolStub: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let state = WeatherURLProtocolStubState()

    static var requestCount: Int { state.requestCount }
    static var lastRequest: URLRequest? { state.lastRequest }

    static func install(_ handler: @escaping Handler) {
        state.install(handler)
    }

    static func reset() {
        state.reset()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            let (response, data) = try Self.state.response(for: request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class WeatherURLProtocolStubState: @unchecked Sendable {
    private let lock = NSLock()
    private var handler: WeatherURLProtocolStub.Handler?
    private var requests: [URLRequest] = []

    var requestCount: Int {
        lock.withLock { requests.count }
    }

    var lastRequest: URLRequest? {
        lock.withLock { requests.last }
    }

    func install(_ handler: @escaping WeatherURLProtocolStub.Handler) {
        lock.withLock {
            self.handler = handler
            requests = []
        }
    }

    func reset() {
        lock.withLock {
            handler = nil
            requests = []
        }
    }

    func response(for request: URLRequest) throws -> (HTTPURLResponse, Data) {
        let handler = lock.withLock { () -> WeatherURLProtocolStub.Handler? in
            requests.append(request)
            return self.handler
        }
        guard let handler else {
            throw URLError(.resourceUnavailable)
        }
        return try handler(request)
    }
}
