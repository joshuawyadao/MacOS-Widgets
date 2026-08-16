import Foundation
import WidgetKit

enum WeatherEntryState: Equatable, Sendable {
    case loaded
    case stale(String)
    case failed(String, retryable: Bool)
}

enum WeatherWidgetContent: Equatable, Sendable {
    case failure(message: String)
    case day(current: WeatherPoint, forecast: DailyWeather?)
    case week([DailyWeather])
    case hour([WeatherPoint])
}

struct WeatherMetricValue: Equatable, Identifiable, Sendable {
    let detail: WeatherDetail
    let text: String
    let spokenText: String
    let symbolName: String

    var id: String { detail.rawValue }
}

struct WeatherWidgetPresentation: Equatable, Sendable {
    static let attributionURL = URL(string: "https://open-meteo.com/")!

    let content: WeatherWidgetContent
    let detailPresentation: WeatherDetailPresentation
    let showsStaleStatus: Bool
    let locationName: String
    private let locale: Locale
    private let timeZone: TimeZone
    private let unit: WeatherResolvedUnit

    var renderedMode: WeatherViewMode? {
        switch content {
        case .failure:
            nil
        case .day:
            .day
        case .week:
            .week
        case .hour:
            .hour
        }
    }

    var forecastColumnCount: Int {
        switch content {
        case let .week(days):
            days.count
        case let .hour(hours):
            hours.count
        case .failure, .day:
            0
        }
    }

    var forecastTitles: [String] {
        switch content {
        case let .week(days):
            days.map { WeatherValueFormatter.weekday($0.date, timeZone: timeZone, locale: locale) }
        case let .hour(hours):
            hours.enumerated().map { index, hour in
                index == 0 ? "Now" : WeatherValueFormatter.hour(hour.date, timeZone: timeZone, locale: locale)
            }
        case .failure, .day:
            []
        }
    }

    var forecastAccessibilityLabels: [String] {
        switch content {
        case let .week(days):
            return zip(forecastTitles, days).map { title, day in
                ([title, day.condition.displayName] + metricValues(for: day)
                    .filter { $0.detail != .condition }
                    .map(\.spokenText))
                    .joined(separator: ", ")
            }
        case let .hour(hours):
            return zip(forecastTitles, hours).map { title, hour in
                ([title, hour.condition.displayName] + metricValues(for: hour)
                    .filter { $0.detail != .condition }
                    .map(\.spokenText))
                    .joined(separator: ", ")
            }
        case .failure, .day:
            return []
        }
    }

    var dayAccessibilityLabel: String? {
        guard case let .day(current, _) = content else { return nil }
        return (["Today", current.condition.displayName] + metricValues(for: current)
            .filter { $0.detail != .condition }
            .map(\.spokenText))
            .joined(separator: ", ")
    }

    var detailLimitNotice: String? {
        guard detailPresentation.hiddenCount > 0 else { return nil }
        return "Showing \(detailPresentation.visibleDetails.count) of \(detailPresentation.totalCount) · \(familyName) limit \(detailPresentation.limit)"
    }

    var failureMessage: String? {
        guard case let .failure(message) = content else { return nil }
        return message
    }

    private let familyName: String

    init(
        date: Date,
        configuration: PresetWeatherConfigurationIntent,
        snapshot: WeatherSnapshot?,
        state: WeatherEntryState,
        family: WidgetFamily,
        locale: Locale
    ) {
        self.detailPresentation = WeatherDetailPresentation(
            preset: configuration.resolvedDetailPreset,
            family: family
        )
        self.showsStaleStatus = if case .stale = state { true } else { false }
        self.locationName = snapshot?.locationName ?? configuration.resolvedCity
        self.locale = locale
        self.timeZone = snapshot?.timeZone ?? .autoupdatingCurrent
        self.unit = snapshot?.unit ?? configuration.resolvedTemperatureUnit.resolved(for: locale)
        self.familyName = switch family {
        case .systemSmall: "Small"
        case .systemMedium: "Medium"
        case .systemLarge: "Large"
        default: "This size"
        }

        guard let snapshot else {
            if case let .failed(message, _) = state {
                self.content = .failure(message: message)
            } else {
                self.content = .failure(message: "Weather is unavailable.")
            }
            return
        }

        switch configuration.resolvedViewMode {
        case .week where family == .systemSmall:
            self.content = Self.dayContent(snapshot: snapshot, date: date)
        case .week:
            self.content = .week(Array(snapshot.dailyForecasts(startingAt: date).prefix(7)))
        case .day:
            self.content = Self.dayContent(snapshot: snapshot, date: date)
        case .hour:
            let hourStart = Self.forecastHourStart(for: date, timeZone: snapshot.timeZone)
            let limit = family == .systemSmall ? 3 : 6
            let hours = Array(snapshot.hourly.filter { $0.date >= hourStart }.prefix(limit))
            self.content = hours.isEmpty
                ? Self.dayContent(snapshot: snapshot, date: date)
                : .hour(hours)
        }
    }

    private static func dayContent(snapshot: WeatherSnapshot, date: Date) -> WeatherWidgetContent {
        .day(
            current: effectiveCurrent(in: snapshot, at: date),
            forecast: snapshot.dailyForecast(for: date)
        )
    }

    private static func effectiveCurrent(in snapshot: WeatherSnapshot, at date: Date) -> WeatherPoint {
        guard let hourlyPoint = snapshot.hourly.last(where: { $0.date <= date }),
              hourlyPoint.date > snapshot.current.date else {
            return snapshot.current
        }
        return hourlyPoint
    }

    private static func forecastHourStart(for date: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateInterval(of: .hour, for: date)?.start ?? date
    }

    func metricValues(for point: WeatherPoint) -> [WeatherMetricValue] {
        metricValues(
            temperature: point.temperature,
            humidity: point.humidity,
            precipitation: point.precipitationProbability,
            wind: point.windSpeed,
            condition: point.condition
        )
    }

    func metricValues(for day: DailyWeather) -> [WeatherMetricValue] {
        metricValues(
            temperature: day.highTemperature,
            humidity: day.humidity,
            precipitation: day.precipitationProbability,
            wind: day.windSpeed,
            condition: day.condition
        )
    }

    private func metricValues(
        temperature: Double,
        humidity: Double?,
        precipitation: Double?,
        wind: Double?,
        condition: WeatherCondition
    ) -> [WeatherMetricValue] {
        detailPresentation.visibleDetails.compactMap { detail in
            switch detail {
            case .temperature:
                WeatherMetricValue(
                    detail: detail,
                    text: WeatherValueFormatter.temperature(temperature, unit: unit),
                    spokenText: "Temperature \(WeatherValueFormatter.temperature(temperature, unit: unit))",
                    symbolName: "thermometer.medium"
                )
            case .condition:
                WeatherMetricValue(
                    detail: detail,
                    text: condition.displayName,
                    spokenText: condition.displayName,
                    symbolName: condition.symbolName
                )
            case .humidity:
                WeatherValueFormatter.percentage(humidity).map {
                    WeatherMetricValue(
                        detail: detail,
                        text: $0,
                        spokenText: "Humidity \($0)",
                        symbolName: "humidity.fill"
                    )
                }
            case .precipitation:
                WeatherValueFormatter.percentage(precipitation).map {
                    WeatherMetricValue(
                        detail: detail,
                        text: $0,
                        spokenText: "Chance of rain \($0)",
                        symbolName: "drop.fill"
                    )
                }
            case .wind:
                WeatherValueFormatter.wind(wind, unit: unit).map {
                    WeatherMetricValue(
                        detail: detail,
                        text: $0,
                        spokenText: "Wind \($0)",
                        symbolName: "wind"
                    )
                }
            }
        }
    }
}
