import AppIntents
import Foundation
import XCTest

final class WeatherConfigurationTests: XCTestCase {
    func testConfigurationUsesDocumentedDefaultsAndDefensiveFallbacks() {
        for value in [nil, "unknown-choice"] {
            let configuration = WeatherConfigurationIntent.referencePreview()
            configuration.city = "  "
            configuration.viewMode = value
            configuration.temperatureUnit = value

            XCTAssertEqual(configuration.resolvedCity, "Portland, Oregon")
            XCTAssertEqual(configuration.resolvedViewMode, .week)
            XCTAssertEqual(configuration.resolvedTemperatureUnit, .automatic)
            XCTAssertEqual(configuration.resolvedDetails, [.temperature])
        }
    }

    func testEveryDetailCanBeSelectedAndEmptySelectionKeepsConditionVisible() {
        let configuration = WeatherConfigurationIntent.referencePreview()
        configuration.showCondition = true
        configuration.showHumidity = true
        configuration.showPrecipitation = true
        configuration.showWind = true

        XCTAssertEqual(
            configuration.resolvedDetails,
            [.temperature, .condition, .humidity, .precipitation, .wind]
        )

        configuration.showTemperature = false
        configuration.showCondition = false
        configuration.showHumidity = false
        configuration.showPrecipitation = false
        configuration.showWind = false
        XCTAssertEqual(configuration.resolvedDetails, [.condition])
    }

    func testOptionsProvidersReturnStableIDsAndDefaults() async throws {
        let modes = try await WeatherViewModeOptionsProvider().results()
        let defaultMode = await WeatherViewModeOptionsProvider().defaultResult()
        XCTAssertEqual(Set(modes.items), Set(WeatherViewMode.allCases.map(\.rawValue)))
        XCTAssertEqual(defaultMode, WeatherViewMode.week.rawValue)

        let units = try await WeatherTemperatureUnitOptionsProvider().results()
        let defaultUnit = await WeatherTemperatureUnitOptionsProvider().defaultResult()
        XCTAssertEqual(Set(units.items), Set(WeatherTemperatureUnit.allCases.map(\.rawValue)))
        XCTAssertEqual(defaultUnit, WeatherTemperatureUnit.automatic.rawValue)
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

    func testRequestURLsIncludeCityUnitsAndAllDetailVariables() throws {
        let geocodingURL = try OpenMeteoWeatherService.geocodingURL(city: "Portland, Oregon")
        let geocodingItems = URLComponents(url: geocodingURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(geocodingItems.first(where: { $0.name == "name" })?.value, "Portland, Oregon")
        XCTAssertEqual(geocodingItems.first(where: { $0.name == "count" })?.value, "1")

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

    func testLocationCacheAvoidsRepeatedGeocodingAndExpiresOldCoordinates() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = WeatherLocationCache(directoryURL: root)
        let location = WeatherLocation(
            name: "Portland",
            latitude: 45.52345,
            longitude: -122.67621,
            timeZoneIdentifier: "America/Los_Angeles",
            adminArea: "Oregon",
            country: "United States"
        )

        try cache.save(location, city: "Portland, Oregon")
        XCTAssertEqual(cache.load(city: "Portland, Oregon"), location)

        try cache.save(
            location,
            city: "Expired City",
            savedAt: .now.addingTimeInterval(-31 * 24 * 60 * 60)
        )
        XCTAssertNil(cache.load(city: "Expired City"))
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
            city: "Portland, Oregon",
            unit: .fahrenheit,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(outcome, .fresh(snapshot))
        XCTAssertEqual(cache.load(city: "Portland, Oregon", unit: .fahrenheit), snapshot)
    }

    func testLoaderReturnsSavedForecastAsStaleWhenRefreshFails() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let snapshot = WeatherSnapshot.sample(now: .now)
        let cache = WeatherSnapshotCache(directoryURL: root)
        try cache.save(snapshot, city: "Portland, Oregon")
        let loader = WeatherLoader(
            service: StubWeatherService(result: .failure(.requestFailed("Offline"))),
            cache: cache
        )

        let outcome = await loader.load(
            city: "Portland, Oregon",
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
            city: "Unknownville",
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
}

private struct StubWeatherService: WeatherServing {
    let result: Result<WeatherSnapshot, WeatherServiceError>

    func forecast(city: String, unit: WeatherTemperatureUnit, locale: Locale) async throws -> WeatherSnapshot {
        try result.get()
    }
}
