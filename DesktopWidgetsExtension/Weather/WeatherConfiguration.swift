import AppIntents
import Foundation

protocol WeatherStringOption: CaseIterable, RawRepresentable where RawValue == String {
    var displayName: LocalizedStringResource { get }
}

enum WeatherViewMode: String, CaseIterable, Sendable, WeatherStringOption {
    case week
    case day
    case hour

    var displayName: LocalizedStringResource {
        switch self {
        case .week: "Week — 7-day forecast"
        case .day: "Day — Today's details"
        case .hour: "Hour — Next 6 hours"
        }
    }
}

enum WeatherTemperatureUnit: String, CaseIterable, Sendable, WeatherStringOption {
    case automatic
    case fahrenheit
    case celsius

    var displayName: LocalizedStringResource {
        switch self {
        case .automatic: "Automatic — Match this Mac"
        case .fahrenheit: "Fahrenheit — °F"
        case .celsius: "Celsius — °C"
        }
    }

    func resolved(for locale: Locale) -> WeatherResolvedUnit {
        switch self {
        case .automatic:
            switch locale.measurementSystem {
            case .us:
                .fahrenheit
            case .uk:
                .celsiusWithMPH
            case .metric:
                .celsius
            default:
                .celsius
            }
        case .fahrenheit:
            .fahrenheit
        case .celsius:
            .celsius
        }
    }
}

enum WeatherResolvedUnit: String, Codable, Sendable {
    case fahrenheit
    case celsius
    case celsiusWithMPH

    var temperatureAPIValue: String { self == .fahrenheit ? "fahrenheit" : "celsius" }
    var temperatureSymbol: String { self == .fahrenheit ? "°F" : "°C" }
    var windAPIValue: String { self == .celsius ? "kmh" : "mph" }
    var windSymbol: String { self == .celsius ? "km/h" : "mph" }
    var precipitationAPIValue: String { self == .fahrenheit ? "inch" : "mm" }
}

enum WeatherDetail: String, CaseIterable, Hashable, Sendable {
    case temperature
    case condition
    case humidity
    case precipitation
    case wind

    var displayName: String {
        switch self {
        case .temperature: "Temperature"
        case .condition: "Condition"
        case .humidity: "Humidity"
        case .precipitation: "Chance of rain"
        case .wind: "Wind"
        }
    }

    var editorDescription: String {
        switch self {
        case .temperature: "Current or forecast temperature"
        case .condition: "Written weather description"
        case .humidity: "Relative humidity percentage"
        case .precipitation: "Precipitation probability"
        case .wind: "Wind speed"
        }
    }

    var symbolName: String {
        switch self {
        case .temperature: "thermometer.medium"
        case .condition: "cloud.sun.fill"
        case .humidity: "humidity.fill"
        case .precipitation: "drop.fill"
        case .wind: "wind"
        }
    }
}

enum WeatherDetailLimits {
    static let small = 2
    static let medium = 3
    static let large = 5

    static func limited(_ details: [WeatherDetail], maximum: Int) -> [WeatherDetail] {
        var seen = Set<WeatherDetail.RawValue>()
        return details.filter { seen.insert($0.rawValue).inserted }.prefix(maximum).map { $0 }
    }
}

struct WeatherLocationEntity: AppEntity, Hashable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "City"
    static let defaultQuery = WeatherLocationQuery()

    let location: WeatherLocation

    var id: String {
        guard let data = try? JSONEncoder().encode(location) else { return location.displayName }
        return data.base64EncodedString()
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(location.name)",
            subtitle: "\(location.qualifier)"
        )
    }

    init(location: WeatherLocation) {
        self.location = location
    }

    init?(id: String) {
        guard let data = Data(base64Encoded: id),
              let location = try? JSONDecoder().decode(WeatherLocation.self, from: data) else {
            return nil
        }
        self.location = location
    }

    static let portland = Self(location: .portland)

    static let suggestions: [Self] = [
        .portland,
        Self(location: WeatherLocation(
            name: "Seattle",
            latitude: 47.6062,
            longitude: -122.3321,
            timeZoneIdentifier: "America/Los_Angeles",
            adminArea: "Washington",
            country: "United States"
        )),
        Self(location: WeatherLocation(
            name: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZoneIdentifier: "America/New_York",
            adminArea: "New York",
            country: "United States"
        )),
        Self(location: WeatherLocation(
            name: "London",
            latitude: 51.5074,
            longitude: -0.1278,
            timeZoneIdentifier: "Europe/London",
            adminArea: "England",
            country: "United Kingdom"
        )),
        Self(location: WeatherLocation(
            name: "Tokyo",
            latitude: 35.6762,
            longitude: 139.6503,
            timeZoneIdentifier: "Asia/Tokyo",
            adminArea: "Tokyo",
            country: "Japan"
        )),
    ]
}

struct WeatherLocationQuery: EntityStringQuery {
    init() {}

    func entities(for identifiers: [WeatherLocationEntity.ID]) async throws -> [WeatherLocationEntity] {
        identifiers.compactMap(WeatherLocationEntity.init(id:))
    }

    func suggestedEntities() async throws -> [WeatherLocationEntity] {
        WeatherLocationEntity.suggestions
    }

    func entities(matching string: String) async throws -> [WeatherLocationEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            return WeatherLocationEntity.suggestions.filter {
                $0.location.displayName.localizedCaseInsensitiveContains(query)
            }
        }

        let matches = try await OpenMeteoLocationSearchService().locations(
            matching: query,
            locale: .autoupdatingCurrent
        )
        return matches.map(WeatherLocationEntity.init(location:))
    }
}

struct WeatherDetailEntity: AppEntity, Hashable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Weather detail"
    static let defaultQuery = WeatherDetailQuery()

    let detail: WeatherDetail

    var id: String { detail.rawValue }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(detail.displayName)",
            subtitle: "\(detail.editorDescription)",
            image: .init(systemName: detail.symbolName)
        )
    }

    static let temperature = Self(detail: .temperature)
}

struct WeatherDetailQuery: EntityQuery {
    init() {}

    func entities(for identifiers: [WeatherDetailEntity.ID]) async throws -> [WeatherDetailEntity] {
        identifiers.compactMap(WeatherDetail.init(rawValue:)).map(WeatherDetailEntity.init(detail:))
    }

    func suggestedEntities() async throws -> [WeatherDetailEntity] {
        WeatherDetail.allCases.map(WeatherDetailEntity.init(detail:))
    }
}

private enum WeatherOptionItems {
    static func collection<Option: WeatherStringOption>(
        for optionType: Option.Type,
        prompt: LocalizedStringResource
    ) -> IntentItemCollection<String> {
        IntentItemCollection(
            promptLabel: prompt,
            sections: [
                IntentItemSection(
                    items: Option.allCases.map { option in
                        IntentItem(option.rawValue, title: option.displayName)
                    }
                )
            ]
        )
    }
}

struct WeatherViewModeOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        WeatherOptionItems.collection(for: WeatherViewMode.self, prompt: "Choose a forecast view")
    }

    func defaultResult() async -> String? {
        WeatherViewMode.week.rawValue
    }
}

struct WeatherTemperatureUnitOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        WeatherOptionItems.collection(for: WeatherTemperatureUnit.self, prompt: "Choose temperature units")
    }

    func defaultResult() async -> String? {
        WeatherTemperatureUnit.automatic.rawValue
    }
}

struct SearchableWeatherConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Customize Weather"
    static let description = IntentDescription("Search for a city, choose a forecast view, and select the details shown.")

    @Parameter(
        title: "City",
        description: "Start typing, then choose the matching city from the list. Portland is used until you choose one."
    )
    var city: WeatherLocationEntity?

    @Parameter(title: "Forecast View", optionsProvider: WeatherViewModeOptionsProvider())
    var viewMode: String?

    @Parameter(title: "Temperature Units", optionsProvider: WeatherTemperatureUnitOptionsProvider())
    var temperatureUnit: String?

    @Parameter(
        title: "Details",
        description: "Choose up to 2 on Small, 3 on Medium, or 5 on Large.",
        size: [
            .systemSmall: .init(min: 1, max: 2),
            .systemMedium: .init(min: 1, max: 3),
            .systemLarge: .init(min: 1, max: 5),
        ],
        query: WeatherDetailQuery()
    )
    var details: [WeatherDetailEntity]?

    init() {
        city = .portland
        details = [.temperature]
    }

    var resolvedLocation: WeatherLocation {
        city?.location ?? .portland
    }

    var resolvedCity: String {
        resolvedLocation.displayName
    }

    var resolvedViewMode: WeatherViewMode {
        viewMode.flatMap(WeatherViewMode.init(rawValue:)) ?? .week
    }

    var resolvedTemperatureUnit: WeatherTemperatureUnit {
        temperatureUnit.flatMap(WeatherTemperatureUnit.init(rawValue:)) ?? .automatic
    }

    var resolvedDetails: [WeatherDetail] {
        let selection = WeatherDetailLimits.limited((details ?? []).map(\.detail), maximum: WeatherDetailLimits.large)
        return selection.isEmpty ? [.temperature] : selection
    }

    static func referencePreview() -> Self {
        let configuration = Self()
        configuration.viewMode = WeatherViewMode.week.rawValue
        configuration.temperatureUnit = WeatherTemperatureUnit.fahrenheit.rawValue
        return configuration
    }
}
