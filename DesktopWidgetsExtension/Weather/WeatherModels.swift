import Foundation

enum WeatherTimelinePolicy {
    static func dates(startingAt date: Date, count: Int, timeZone: TimeZone) -> [Date] {
        guard count > 0 else { return [] }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hourStart = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        return (0..<count).compactMap { offset in
            offset == 0 ? date : calendar.date(byAdding: .hour, value: offset, to: hourStart)
        }
    }
}

enum WeatherCondition: String, Codable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case fog
    case drizzle
    case rain
    case snow
    case storm
    case unknown

    init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1, 2: self = .partlyCloudy
        case 3: self = .cloudy
        case 45, 48: self = .fog
        case 51...57: self = .drizzle
        case 61...67, 80...82: self = .rain
        case 71...77, 85, 86: self = .snow
        case 95...99: self = .storm
        default: self = .unknown
        }
    }

    var displayName: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly cloudy"
        case .cloudy: "Cloudy"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .snow: "Snow"
        case .storm: "Thunderstorm"
        case .unknown: "Conditions unavailable"
        }
    }

    var symbolName: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "cloud.snow.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }
}

struct WeatherPoint: Codable, Equatable, Sendable {
    let date: Date
    let temperature: Double
    let apparentTemperature: Double?
    let humidity: Double?
    let precipitationProbability: Double?
    let windSpeed: Double?
    let uvIndex: Double?
    let condition: WeatherCondition

    init(
        date: Date,
        temperature: Double,
        apparentTemperature: Double? = nil,
        humidity: Double?,
        precipitationProbability: Double?,
        windSpeed: Double?,
        uvIndex: Double? = nil,
        condition: WeatherCondition
    ) {
        self.date = date
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.humidity = humidity
        self.precipitationProbability = precipitationProbability
        self.windSpeed = windSpeed
        self.uvIndex = uvIndex
        self.condition = condition
    }
}

struct DailyWeather: Codable, Equatable, Sendable {
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let apparentHighTemperature: Double?
    let humidity: Double?
    let precipitationProbability: Double?
    let windSpeed: Double?
    let uvIndex: Double?
    let sunrise: Date?
    let sunset: Date?
    let condition: WeatherCondition

    init(
        date: Date,
        highTemperature: Double,
        lowTemperature: Double,
        apparentHighTemperature: Double? = nil,
        humidity: Double?,
        precipitationProbability: Double?,
        windSpeed: Double?,
        uvIndex: Double? = nil,
        sunrise: Date? = nil,
        sunset: Date? = nil,
        condition: WeatherCondition
    ) {
        self.date = date
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.apparentHighTemperature = apparentHighTemperature
        self.humidity = humidity
        self.precipitationProbability = precipitationProbability
        self.windSpeed = windSpeed
        self.uvIndex = uvIndex
        self.sunrise = sunrise
        self.sunset = sunset
        self.condition = condition
    }
}

struct WeatherSnapshot: Codable, Equatable, Sendable {
    let locationName: String
    let providerID: String
    let timeZoneIdentifier: String
    let fetchedAt: Date
    let unit: WeatherResolvedUnit
    let current: WeatherPoint
    let hourly: [WeatherPoint]
    let daily: [DailyWeather]

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .autoupdatingCurrent
    }

    func dailyForecasts(startingAt date: Date) -> [DailyWeather] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let requestedDay = calendar.startOfDay(for: date)
        return daily.filter { calendar.startOfDay(for: $0.date) >= requestedDay }
    }

    func dailyForecast(for date: Date) -> DailyWeather? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return daily.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    static func sample(now: Date = Date(timeIntervalSince1970: 1_786_288_940)) -> Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        let hourly = (0..<12).map { offset in
            WeatherPoint(
                date: calendar.date(byAdding: .hour, value: offset, to: now) ?? now,
                temperature: 63 + Double(offset),
                apparentTemperature: 62 + Double(offset),
                humidity: 58 + Double(offset % 4),
                precipitationProbability: offset > 7 ? 20 : 5,
                windSpeed: 6 + Double(offset % 3),
                uvIndex: Double(max(0, 6 - abs(offset - 5))),
                condition: offset > 7 ? .partlyCloudy : .clear
            )
        }

        let temperatures = [63.0, 69, 70, 70, 72, 75, 74]
        let daily = temperatures.enumerated().map { offset, temperature in
            DailyWeather(
                date: calendar.date(byAdding: .day, value: offset, to: now) ?? now,
                highTemperature: temperature,
                lowTemperature: temperature - 12,
                apparentHighTemperature: temperature - 1,
                humidity: 60 + Double(offset),
                precipitationProbability: offset == 5 ? 35 : 10,
                windSpeed: 8 + Double(offset % 3),
                uvIndex: 4 + Double(offset % 3),
                sunrise: calendar.date(bySettingHour: 6, minute: 15, second: 0, of: calendar.date(byAdding: .day, value: offset, to: now) ?? now),
                sunset: calendar.date(bySettingHour: 20, minute: 10, second: 0, of: calendar.date(byAdding: .day, value: offset, to: now) ?? now),
                condition: offset == 5 ? .rain : .clear
            )
        }

        return WeatherSnapshot(
            locationName: "Portland, Oregon",
            providerID: "open-meteo",
            timeZoneIdentifier: "America/Los_Angeles",
            fetchedAt: now,
            unit: .fahrenheit,
            current: hourly[0],
            hourly: hourly,
            daily: daily
        )
    }
}

enum WeatherValueFormatter {
    static func temperature(_ value: Double, unit: WeatherResolvedUnit, includeUnit: Bool = true) -> String {
        let rounded = Int(value.rounded())
        return includeUnit ? "\(rounded)\(unit.temperatureSymbol)" : "\(rounded)°"
    }

    static func percentage(_ value: Double?) -> String? {
        value.map { "\(Int($0.rounded()))%" }
    }

    static func wind(_ value: Double?, unit: WeatherResolvedUnit) -> String? {
        value.map { "\(Int($0.rounded())) \(unit.windSymbol)" }
    }

    static func uvIndex(_ value: Double?) -> String? {
        value.map { "UV \(Int($0.rounded()))" }
    }

    static func time(_ date: Date?, timeZone: TimeZone, locale: Locale) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        return formatter.string(from: date)
    }

    static func weekday(_ date: Date, timeZone: TimeZone, locale: Locale = .autoupdatingCurrent) -> String {
        formattedDate(date, pattern: "EEE", timeZone: timeZone, locale: locale)
    }

    static func hour(_ date: Date, timeZone: TimeZone, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("j")
        return formatter.string(from: date)
    }

    private static func formattedDate(
        _ date: Date,
        pattern: String,
        timeZone: TimeZone,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}
