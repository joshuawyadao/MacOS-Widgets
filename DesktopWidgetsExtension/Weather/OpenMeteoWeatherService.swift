import CryptoKit
import Foundation

enum WeatherServiceError: LocalizedError, Equatable, Sendable {
    case invalidCity
    case cityNotFound(String)
    case invalidResponse
    case invalidData
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCity:
            "Enter a city, state, or country in Edit Weather."
        case let .cityNotFound(city):
            "No weather location matched “\(city)”. Try adding a state or country."
        case .invalidResponse:
            "The weather service returned an unexpected response."
        case .invalidData:
            "The forecast could not be read."
        case let .requestFailed(message):
            "Weather is temporarily unavailable. \(message)"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .invalidCity, .cityNotFound:
            false
        case .invalidResponse, .invalidData, .requestFailed:
            true
        }
    }
}

protocol WeatherServing: Sendable {
    func forecast(location: WeatherLocation, unit: WeatherTemperatureUnit, locale: Locale) async throws -> WeatherSnapshot
}

protocol WeatherLocationSearching: Sendable {
    func locations(matching query: String, locale: Locale) async throws -> [WeatherLocation]
}

enum WeatherLoadOutcome: Equatable, Sendable {
    case fresh(WeatherSnapshot)
    case stale(WeatherSnapshot, message: String)
    case failed(message: String, retryable: Bool)
}

struct WeatherLoader: Sendable {
    private let service: any WeatherServing
    private let cache: WeatherSnapshotCache

    init(service: any WeatherServing, cache: WeatherSnapshotCache) {
        self.service = service
        self.cache = cache
    }

    func load(location: WeatherLocation, unit: WeatherTemperatureUnit, locale: Locale) async -> WeatherLoadOutcome {
        let resolvedUnit = unit.resolved(for: locale)
        let cacheKey = location.displayName
        do {
            let snapshot = try await service.forecast(location: location, unit: unit, locale: locale)
            try? cache.save(snapshot, city: cacheKey)
            return .fresh(snapshot)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if let cached = cache.load(city: cacheKey, unit: resolvedUnit) {
                return .stale(cached, message: message)
            }
            return .failed(
                message: message,
                retryable: (error as? WeatherServiceError)?.isRetryable ?? true
            )
        }
    }
}

struct WeatherLocation: Codable, Equatable, Hashable, Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
    let adminArea: String?
    let country: String?

    var displayName: String {
        var parts = [name]
        if let adminArea, !adminArea.isEmpty, adminArea.caseInsensitiveCompare(name) != .orderedSame {
            parts.append(adminArea)
        }
        if let country, !country.isEmpty, !parts.contains(where: { $0.caseInsensitiveCompare(country) == .orderedSame }) {
            parts.append(country)
        }
        return parts.joined(separator: ", ")
    }

    var qualifier: String {
        [adminArea, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty && $0.caseInsensitiveCompare(name) != .orderedSame }
            .joined(separator: ", ")
    }

    static let portland = Self(
        name: "Portland",
        latitude: 45.52345,
        longitude: -122.67621,
        timeZoneIdentifier: "America/Los_Angeles",
        adminArea: "Oregon",
        country: "United States"
    )
}

struct OpenMeteoWeatherService: WeatherServing {
    static let providerID = "open-meteo"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func forecast(location: WeatherLocation, unit: WeatherTemperatureUnit, locale: Locale) async throws -> WeatherSnapshot {
        do {
            let resolvedUnit = unit.resolved(for: locale)
            let url = try Self.forecastURL(location: location, unit: resolvedUnit)
            let data = try await data(from: url)
            return try Self.decodeForecast(data: data, location: location, unit: resolvedUnit)
        } catch let error as WeatherServiceError {
            throw error
        } catch {
            throw WeatherServiceError.requestFailed(error.localizedDescription)
        }
    }

    private func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("MacOS-Widgets/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw WeatherServiceError.invalidResponse
        }
        return data
    }

    static func forecastURL(location: WeatherLocation, unit: WeatherResolvedUnit) throws -> URL {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,relative_humidity_2m_mean,precipitation_probability_max,weather_code,wind_speed_10m_max"),
            URLQueryItem(name: "temperature_unit", value: unit.temperatureAPIValue),
            URLQueryItem(name: "wind_speed_unit", value: unit.windAPIValue),
            URLQueryItem(name: "precipitation_unit", value: unit.precipitationAPIValue),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidResponse }
        return url
    }

    static func decodeForecast(
        data: Data,
        location: WeatherLocation,
        unit: WeatherResolvedUnit,
        fetchedAt: Date = .now
    ) throws -> WeatherSnapshot {
        let response: ForecastResponse
        do {
            response = try JSONDecoder().decode(ForecastResponse.self, from: data)
        } catch {
            throw WeatherServiceError.invalidData
        }

        let timeZone = TimeZone(identifier: response.timezone)
            ?? TimeZone(identifier: location.timeZoneIdentifier)
            ?? .autoupdatingCurrent
        let hourlyDates = response.hourly.time.map(Date.init(timeIntervalSince1970:))
        let dailyDates = response.daily.time.map(Date.init(timeIntervalSince1970:))
        let currentDate = Date(timeIntervalSince1970: response.current.time)

        let hourlyCount = [
            hourlyDates.count,
            response.hourly.temperature.count,
            response.hourly.weatherCode.count,
        ].min() ?? 0
        let dailyCount = [
            dailyDates.count,
            response.daily.highTemperature.count,
            response.daily.lowTemperature.count,
            response.daily.weatherCode.count,
        ].min() ?? 0
        guard hourlyCount > 0, dailyCount > 0 else { throw WeatherServiceError.invalidData }

        let hourly = (0..<hourlyCount).map { index in
            WeatherPoint(
                date: hourlyDates[index],
                temperature: response.hourly.temperature[index],
                humidity: response.hourly.humidity.value(at: index) ?? nil,
                precipitationProbability: response.hourly.precipitationProbability.value(at: index) ?? nil,
                windSpeed: response.hourly.windSpeed.value(at: index) ?? nil,
                condition: WeatherCondition(wmoCode: response.hourly.weatherCode[index])
            )
        }

        let daily = (0..<dailyCount).map { index in
            DailyWeather(
                date: dailyDates[index],
                highTemperature: response.daily.highTemperature[index],
                lowTemperature: response.daily.lowTemperature[index],
                humidity: response.daily.humidity.value(at: index) ?? nil,
                precipitationProbability: response.daily.precipitationProbability.value(at: index) ?? nil,
                windSpeed: response.daily.windSpeed.value(at: index) ?? nil,
                condition: WeatherCondition(wmoCode: response.daily.weatherCode[index])
            )
        }

        return WeatherSnapshot(
            locationName: location.displayName,
            providerID: providerID,
            timeZoneIdentifier: timeZone.identifier,
            fetchedAt: fetchedAt,
            unit: unit,
            current: WeatherPoint(
                date: currentDate,
                temperature: response.current.temperature,
                humidity: response.current.humidity,
                precipitationProbability: response.current.precipitationProbability,
                windSpeed: response.current.windSpeed,
                condition: WeatherCondition(wmoCode: response.current.weatherCode)
            ),
            hourly: hourly,
            daily: daily
        )
    }

}

struct OpenMeteoLocationSearchService: WeatherLocationSearching {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func locations(matching query: String, locale: Locale) async throws -> [WeatherLocation] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else { return [] }

        do {
            let url = try Self.geocodingURL(query: trimmedQuery, locale: locale)
            var request = URLRequest(url: url)
            request.timeoutInterval = 6
            request.setValue("MacOS-Widgets/0.1", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw WeatherServiceError.invalidResponse
            }
            return try Self.decodeLocations(data: data)
        } catch let error as WeatherServiceError {
            throw error
        } catch {
            throw WeatherServiceError.requestFailed(error.localizedDescription)
        }
    }

    static func geocodingURL(query: String, locale: Locale) throws -> URL {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: String(WeatherCityChoice.maximumSearchResults)),
            URLQueryItem(name: "language", value: locale.language.languageCode?.identifier ?? "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw WeatherServiceError.invalidResponse }
        return url
    }

    static func decodeLocations(data: Data) throws -> [WeatherLocation] {
        let response: GeocodingResponse
        do {
            response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        } catch {
            throw WeatherServiceError.invalidData
        }

        return (response.results ?? []).map { result in
            WeatherLocation(
                name: result.name,
                latitude: result.latitude,
                longitude: result.longitude,
                timeZoneIdentifier: result.timezone ?? TimeZone.autoupdatingCurrent.identifier,
                adminArea: result.adminArea,
                country: result.country
            )
        }
    }
}

struct WeatherSnapshotCache: Sendable {
    private static let maximumStaleAge: TimeInterval = 24 * 60 * 60
    private static let maximumStoredEntries = 12
    private let directoryURL: URL

    init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("WeatherSnapshots", isDirectory: true)
    }

    func load(city: String, unit: WeatherResolvedUnit) -> WeatherSnapshot? {
        let url = fileURL(city: city, unit: unit)
        guard let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WeatherSnapshot.self, from: data) else {
            return nil
        }
        guard Date.now.timeIntervalSince(snapshot.fetchedAt) <= Self.maximumStaleAge else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        return snapshot
    }

    func save(_ snapshot: WeatherSnapshot, city: String) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: fileURL(city: city, unit: snapshot.unit), options: .atomic)
        pruneIfNeeded()
    }

    private func fileURL(city: String, unit: WeatherResolvedUnit) -> URL {
        let digest = SHA256.hash(data: Data("\(city.lowercased())|\(unit.rawValue)".utf8))
        let key = digest.map { String(format: "%02x", $0) }.joined()
        return directoryURL.appendingPathComponent("\(key).json")
    }

    private func pruneIfNeeded() {
        let resourceKeys: Set<URLResourceKey> = [.contentModificationDateKey, .isRegularFileKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else { return }

        let files = urls.compactMap { url -> (URL, Date)? in
            guard let values = try? url.resourceValues(forKeys: resourceKeys),
                  values.isRegularFile == true else { return nil }
            return (url, values.contentModificationDate ?? .distantPast)
        }
        .sorted { $0.1 > $1.1 }

        for (url, _) in files.dropFirst(Self.maximumStoredEntries) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

private extension Array {
    func value(at index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct ForecastResponse: Decodable {
    let timezone: String
    let current: CurrentForecast
    let hourly: HourlyForecast
    let daily: DailyForecast
}

private struct CurrentForecast: Decodable {
    let time: TimeInterval
    let temperature: Double
    let humidity: Double?
    let precipitationProbability: Double?
    let weatherCode: Int
    let windSpeed: Double?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case humidity = "relative_humidity_2m"
        case precipitationProbability = "precipitation_probability"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
    }
}

private struct HourlyForecast: Decodable {
    let time: [TimeInterval]
    let temperature: [Double]
    let humidity: [Double?]
    let precipitationProbability: [Double?]
    let weatherCode: [Int]
    let windSpeed: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case humidity = "relative_humidity_2m"
        case precipitationProbability = "precipitation_probability"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
    }
}

private struct DailyForecast: Decodable {
    let time: [TimeInterval]
    let highTemperature: [Double]
    let lowTemperature: [Double]
    let humidity: [Double?]
    let precipitationProbability: [Double?]
    let weatherCode: [Int]
    let windSpeed: [Double?]

    enum CodingKeys: String, CodingKey {
        case time
        case highTemperature = "temperature_2m_max"
        case lowTemperature = "temperature_2m_min"
        case humidity = "relative_humidity_2m_mean"
        case precipitationProbability = "precipitation_probability_max"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m_max"
    }
}

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]?
}

private struct GeocodingResult: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let timezone: String?
    let adminArea: String?
    let country: String?

    enum CodingKeys: String, CodingKey {
        case name
        case latitude
        case longitude
        case timezone
        case adminArea = "admin1"
        case country
    }
}
