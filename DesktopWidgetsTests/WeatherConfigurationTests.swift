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
            .comfort: [.temperature, .humidity],
            .detailed: [.temperature, .condition, .humidity],
            .full: [.temperature, .condition, .humidity, .precipitation, .wind],
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
        XCTAssertEqual(small.hiddenCount, 3)
        XCTAssertEqual(small.limit, 2)

        let medium = WeatherDetailPresentation(preset: .full, family: .systemMedium)
        XCTAssertEqual(medium.visibleDetails, [.temperature, .condition, .humidity])
        XCTAssertEqual(medium.hiddenCount, 2)
        XCTAssertEqual(medium.limit, 3)

        let large = WeatherDetailPresentation(preset: .full, family: .systemLarge)
        XCTAssertEqual(large.visibleDetails, WeatherDetail.allCases)
        XCTAssertEqual(large.hiddenCount, 0)
        XCTAssertEqual(large.limit, 5)
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
            .systemLarge: 5,
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
        XCTAssertGreaterThanOrEqual(medium.forecastColumnSpacing, 6)
        XCTAssertGreaterThanOrEqual(large.forecastColumnSpacing, 6)
        XCTAssertGreaterThanOrEqual(small.forecastVerticalSpacing, 4)
        XCTAssertGreaterThan(medium.forecastVerticalSpacing, small.forecastVerticalSpacing)
        XCTAssertGreaterThan(large.forecastVerticalSpacing, medium.forecastVerticalSpacing)
        XCTAssertLessThanOrEqual(small.dayTemperatureSize, 28)
        XCTAssertGreaterThanOrEqual(small.dayTemperatureMinimumWidth, 66)
        XCTAssertLessThanOrEqual(small.temperatureMinimumScaleFactor, 0.5)
        XCTAssertLessThanOrEqual(medium.forecastTitleSize, 14)
        XCTAssertLessThanOrEqual(medium.forecastTemperatureSize, 16)
        XCTAssertEqual(medium.forecastTitleSize, large.forecastTitleSize)
        XCTAssertEqual(medium.forecastTemperatureSize, large.forecastTemperatureSize)
        XCTAssertFalse(small.spreadsForecastVertically)
        XCTAssertFalse(medium.spreadsForecastVertically)
        XCTAssertTrue(large.spreadsForecastVertically)
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
                    XCTAssertEqual(presentation.forecastTitles.count, presentation.forecastColumnCount, context)
                    XCTAssertEqual(
                        presentation.forecastAccessibilityLabels.count,
                        presentation.forecastColumnCount,
                        context
                    )
                    XCTAssertTrue(presentation.forecastTitles.allSatisfy { !$0.isEmpty }, context)
                    XCTAssertTrue(presentation.forecastAccessibilityLabels.allSatisfy { !$0.isEmpty }, context)
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

        for field in ["temperature_2m", "relative_humidity_2m", "precipitation_probability", "weather_code", "wind_speed_10m"] {
            XCTAssertTrue(current.contains(field), "Missing current field \(field)")
            XCTAssertTrue(hourly.contains(field), "Missing hourly field \(field)")
        }
        XCTAssertTrue(daily.contains("temperature_2m_max"))
        XCTAssertTrue(daily.contains("relative_humidity_2m_mean"))
        XCTAssertTrue(daily.contains("precipitation_probability_max"))
        XCTAssertEqual(items.first(where: { $0.name == "temperature_unit" })?.value, "fahrenheit")
        XCTAssertEqual(items.first(where: { $0.name == "wind_speed_unit" })?.value, "mph")
        XCTAssertEqual(items.first(where: { $0.name == "timezone" })?.value, "auto")
        XCTAssertEqual(items.first(where: { $0.name == "timeformat" })?.value, "unixtime")
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
        XCTAssertEqual(snapshot.hourly[2].condition, .rain)
        XCTAssertEqual(snapshot.daily.count, 2)
        XCTAssertEqual(snapshot.daily[0].highTemperature, 70)
        XCTAssertEqual(snapshot.daily[1].humidity, 66)
        XCTAssertEqual(snapshot.daily[1].condition, .partlyCloudy)
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
        XCTAssertEqual(cache.load(city: WeatherLocation.portland.displayName, unit: .fahrenheit), snapshot)
    }

    func testLoaderReturnsSavedForecastAsStaleWhenRefreshFails() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = WeatherSnapshot.sample(now: .now)
        let cache = WeatherSnapshotCache(directoryURL: root)
        try cache.save(snapshot, city: WeatherLocation.portland.displayName)
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

    private static let fixture = """
    {
      "timezone": "America/Los_Angeles",
      "current": {
        "time": 1786291200,
        "temperature_2m": 63.0,
        "relative_humidity_2m": 61.0,
        "precipitation_probability": 5.0,
        "weather_code": 0,
        "wind_speed_10m": 7.0
      },
      "hourly": {
        "time": [1786291200, 1786294800, 1786298400],
        "temperature_2m": [63.0, 65.0, 66.0],
        "relative_humidity_2m": [61.0, 60.0, 59.0],
        "precipitation_probability": [5.0, 20.0, 45.0],
        "weather_code": [0, 2, 61],
        "wind_speed_10m": [7.0, 8.0, 9.0]
      },
      "daily": {
        "time": [1786258800, 1786345200],
        "temperature_2m_max": [70.0, 72.0],
        "temperature_2m_min": [55.0, 57.0],
        "relative_humidity_2m_mean": [64.0, 66.0],
        "precipitation_probability_max": [20.0, 35.0],
        "weather_code": [0, 2],
        "wind_speed_10m_max": [10.0, 12.0]
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
