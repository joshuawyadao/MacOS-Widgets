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
}

enum WeatherDetailPreset: String, CaseIterable, Hashable, Sendable, WeatherStringOption {
    case minimal
    case simple
    case rain
    case comfort
    case detailed
    case full

    var displayName: LocalizedStringResource {
        switch self {
        case .minimal: "Minimal — Temperature"
        case .simple: "Simple — Temperature + Condition"
        case .rain: "Rain — Temperature + Rain chance"
        case .comfort: "Comfort — Temperature + Humidity"
        case .detailed: "Detailed — 3 details · Medium or Large"
        case .full: "Full — All 5 details · Large"
        }
    }

    var details: [WeatherDetail] {
        switch self {
        case .minimal:
            [.temperature]
        case .simple:
            [.temperature, .condition]
        case .rain:
            [.temperature, .precipitation]
        case .comfort:
            [.temperature, .humidity]
        case .detailed:
            [.temperature, .condition, .humidity]
        case .full:
            WeatherDetail.allCases
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

struct WeatherDetailPresetOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        WeatherOptionItems.collection(for: WeatherDetailPreset.self, prompt: "Choose a weather detail preset")
    }

    func defaultResult() async -> String? {
        WeatherDetailPreset.minimal.rawValue
    }
}

struct PresetWeatherConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Customize Weather"
    static let description = IntentDescription("Search for a city, choose a forecast view, and apply a group of weather details in one click.")

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
        title: "Details Preset",
        description: "One click applies the whole group. Small shows 2 details, Medium 3, and Large 5.",
        optionsProvider: WeatherDetailPresetOptionsProvider()
    )
    var detailPreset: String?

    init() {
        city = .portland
        detailPreset = WeatherDetailPreset.minimal.rawValue
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

    var resolvedDetailPreset: WeatherDetailPreset {
        detailPreset.flatMap(WeatherDetailPreset.init(rawValue:)) ?? .minimal
    }

    var resolvedDetails: [WeatherDetail] {
        resolvedDetailPreset.details
    }

    static func referencePreview() -> Self {
        let configuration = Self()
        configuration.viewMode = WeatherViewMode.week.rawValue
        configuration.temperatureUnit = WeatherTemperatureUnit.fahrenheit.rawValue
        return configuration
    }
}
