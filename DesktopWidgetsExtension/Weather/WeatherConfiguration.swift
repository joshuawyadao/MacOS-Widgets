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

enum WeatherDetail: String, CaseIterable, Sendable {
    case temperature
    case condition
    case humidity
    case precipitation
    case wind
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

struct WeatherConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Customize Weather"
    static let description = IntentDescription("Choose a city, forecast view, units, and the details shown.")

    @Parameter(
        title: "City",
        description: "For the best match, include a state, province, or country."
    )
    var city: String?

    @Parameter(title: "Forecast View", optionsProvider: WeatherViewModeOptionsProvider())
    var viewMode: String?

    @Parameter(title: "Temperature Units", optionsProvider: WeatherTemperatureUnitOptionsProvider())
    var temperatureUnit: String?

    @Parameter(title: "Show Temperature", default: true)
    var showTemperature: Bool

    @Parameter(title: "Show Condition", default: false)
    var showCondition: Bool

    @Parameter(title: "Show Humidity", default: false)
    var showHumidity: Bool

    @Parameter(title: "Show Chance of Rain", default: false)
    var showPrecipitation: Bool

    @Parameter(title: "Show Wind", default: false)
    var showWind: Bool

    var resolvedCity: String {
        let trimmed = city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Portland, Oregon" : trimmed
    }

    var resolvedViewMode: WeatherViewMode {
        viewMode.flatMap(WeatherViewMode.init(rawValue:)) ?? .week
    }

    var resolvedTemperatureUnit: WeatherTemperatureUnit {
        temperatureUnit.flatMap(WeatherTemperatureUnit.init(rawValue:)) ?? .automatic
    }

    var resolvedDetails: [WeatherDetail] {
        var details: [WeatherDetail] = []
        if showTemperature { details.append(.temperature) }
        if showCondition { details.append(.condition) }
        if showHumidity { details.append(.humidity) }
        if showPrecipitation { details.append(.precipitation) }
        if showWind { details.append(.wind) }
        return details.isEmpty ? [.condition] : details
    }

    static func referencePreview() -> Self {
        let configuration = Self()
        configuration.city = "Portland, Oregon"
        configuration.viewMode = WeatherViewMode.week.rawValue
        configuration.temperatureUnit = WeatherTemperatureUnit.fahrenheit.rawValue
        configuration.showTemperature = true
        configuration.showCondition = false
        configuration.showHumidity = false
        configuration.showPrecipitation = false
        configuration.showWind = false
        return configuration
    }
}
