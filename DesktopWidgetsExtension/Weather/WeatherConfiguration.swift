import AppIntents
import Foundation
import WidgetKit

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
    var temperatureSuffix: String { self == .fahrenheit ? "F" : "C" }
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
        case .detailed: "Detailed — 3 details · Large or Medium Day"
        case .full: "Full — All 5 details · Large Day"
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

    static func maximum(for family: WidgetFamily, mode: WeatherViewMode = .day) -> Int {
        if mode != .day {
            switch family {
            case .systemSmall, .systemMedium:
                return 1
            case .systemLarge:
                return 2
            default:
                return 1
            }
        }

        return switch family {
        case .systemSmall:
            small
        case .systemMedium:
            medium
        case .systemLarge:
            large
        default:
            small
        }
    }
}

struct WeatherDetailPresentation: Equatable, Sendable {
    let visibleDetails: [WeatherDetail]
    let totalCount: Int
    let limit: Int

    var hiddenCount: Int {
        max(0, totalCount - visibleDetails.count)
    }

    init(
        preset: WeatherDetailPreset,
        family: WidgetFamily,
        mode: WeatherViewMode = .day
    ) {
        let details = preset.details
        let limit = WeatherDetailLimits.maximum(for: family, mode: mode)
        self.visibleDetails = WeatherDetailLimits.limited(details, maximum: limit)
        self.totalCount = details.count
        self.limit = limit
    }
}

enum WeatherCityCatalog {
    static let maximumSearchResults = 20

    static let suggestions: [WeatherLocation] = [
        .portland,
        WeatherLocation(
            name: "Seattle",
            latitude: 47.6062,
            longitude: -122.3321,
            timeZoneIdentifier: "America/Los_Angeles",
            adminArea: "Washington",
            country: "United States"
        ),
        WeatherLocation(
            name: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZoneIdentifier: "America/New_York",
            adminArea: "New York",
            country: "United States"
        ),
        WeatherLocation(
            name: "London",
            latitude: 51.5074,
            longitude: -0.1278,
            timeZoneIdentifier: "Europe/London",
            adminArea: "England",
            country: "United Kingdom"
        ),
        WeatherLocation(
            name: "Tokyo",
            latitude: 35.6762,
            longitude: 139.6503,
            timeZoneIdentifier: "Asia/Tokyo",
            adminArea: "Tokyo",
            country: "Japan"
        ),
    ]

    static func identifier(for location: WeatherLocation) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(location).base64EncodedString()) ?? ""
    }

    static func location(for identifier: String?) -> WeatherLocation? {
        guard let identifier,
              let data = Data(base64Encoded: identifier),
              let location = try? JSONDecoder().decode(WeatherLocation.self, from: data) else {
            return nil
        }
        return location
    }

    static func displayTitle(for location: WeatherLocation) -> String {
        location.displayName
    }

    static func normalized(_ locations: [WeatherLocation]) -> [WeatherLocation] {
        var seen = Set<String>()
        return locations.filter { location in
            seen.insert(identifier(for: location)).inserted
        }
        .prefix(maximumSearchResults)
        .map { $0 }
    }

}

struct WeatherV8CityEntity: AppEntity, Hashable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "City"
    static let defaultQuery = WeatherV8CityQuery()

    let location: WeatherLocation

    var id: String {
        WeatherCityCatalog.identifier(for: location)
    }

    var displayRepresentation: DisplayRepresentation {
        let title: LocalizedStringResource = "\(location.name)"
        let subtitle: LocalizedStringResource = "\(location.qualifier)"
        return DisplayRepresentation(title: title, subtitle: subtitle)
    }

    init(location: WeatherLocation) {
        self.location = location
    }

    init?(id: String) {
        guard let location = WeatherCityCatalog.location(for: id) else { return nil }
        self.location = location
    }

    static let portland = Self(location: .portland)
}

struct WeatherV8CityQuery: EntityStringQuery {
    private let searchService: any WeatherLocationSearching

    init() {
        self.searchService = OpenMeteoLocationSearchService()
    }

    init(searchService: any WeatherLocationSearching) {
        self.searchService = searchService
    }

    func entities(for identifiers: [WeatherV8CityEntity.ID]) async throws -> [WeatherV8CityEntity] {
        identifiers.compactMap(WeatherV8CityEntity.init(id:))
    }

    func suggestedEntities() async throws -> [WeatherV8CityEntity] {
        WeatherCityCatalog.suggestions.map(WeatherV8CityEntity.init(location:))
    }

    func defaultResult() async -> WeatherV8CityEntity? {
        .portland
    }

    func entities(matching string: String) async throws -> [WeatherV8CityEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            return try await suggestedEntities()
        }

        do {
            let matches = try await searchService.locations(
                matching: query,
                locale: .autoupdatingCurrent
            )
            return WeatherCityCatalog.normalized(matches).map(WeatherV8CityEntity.init(location:))
        } catch {
            return WeatherCityCatalog.suggestions
                .filter { $0.displayName.localizedCaseInsensitiveContains(query) }
                .map(WeatherV8CityEntity.init(location:))
        }
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

struct WeatherV8ConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Customize Weather"
    static let description = IntentDescription("Search for a city, select a forecast view, and apply a group of weather details in one click.")

    @Parameter(
        title: "City",
        description: "Type at least two letters and choose a matching city from the results."
    )
    var city: WeatherV8CityEntity?

    @Parameter(title: "Forecast View", optionsProvider: WeatherViewModeOptionsProvider())
    var viewMode: String?

    @Parameter(title: "Temperature Units", optionsProvider: WeatherTemperatureUnitOptionsProvider())
    var temperatureUnit: String?

    @Parameter(
        title: "Details Preset",
        description: "One click applies the whole group. Day supports 2, 3, or 5 details by size; Week and Hour use tighter limits.",
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
