import Foundation
import WidgetKit

struct WeatherWidgetLayoutMetrics: Equatable, Sendable {
    let contentSpacing: CGFloat
    let forecastColumnSpacing: CGFloat
    let forecastVerticalSpacing: CGFloat
    let headerFontSize: CGFloat
    let dayHorizontalSpacing: CGFloat
    let dayIconSize: CGFloat
    let dayTemperatureSize: CGFloat
    let forecastTitleSize: CGFloat
    let forecastIconSize: CGFloat
    let forecastTemperatureSize: CGFloat
    let metricFontSize: CGFloat
    let expandedSectionSpacing: CGFloat
    let expandedIconSize: CGFloat
    let expandedTemperatureSize: CGFloat
    let dayTemperatureMinimumWidth: CGFloat
    let dayTemperatureMaximumWidth: CGFloat?
    let minimumTemperaturePointSize: CGFloat
    let usesStackedHeader: Bool
    let fillsForecastSection: Bool
    let usesFlexibleForecastItemSpacing: Bool

    init(family: WidgetFamily) {
        let chrome = WidgetChromeMetrics(family: family)
        switch WidgetInformationDensity(family: family) {
        case .compact:
            self.init(
                contentSpacing: chrome.sectionSpacing,
                forecastColumnSpacing: 6,
                forecastVerticalSpacing: 4,
                headerFontSize: 13,
                dayHorizontalSpacing: 5,
                dayIconSize: 34,
                dayTemperatureSize: 28,
                forecastTitleSize: 13,
                forecastIconSize: 22,
                forecastTemperatureSize: 15,
                metricFontSize: 9,
                expandedSectionSpacing: 8,
                expandedIconSize: 44,
                expandedTemperatureSize: 38,
                dayTemperatureMinimumWidth: 72,
                dayTemperatureMaximumWidth: 78,
                minimumTemperaturePointSize: 14,
                usesStackedHeader: false,
                fillsForecastSection: false,
                usesFlexibleForecastItemSpacing: false
            )
        case .expanded:
            self.init(
                contentSpacing: chrome.sectionSpacing,
                forecastColumnSpacing: 8,
                forecastVerticalSpacing: 8,
                headerFontSize: 15,
                dayHorizontalSpacing: 28,
                dayIconSize: 70,
                dayTemperatureSize: 56,
                forecastTitleSize: 14,
                forecastIconSize: 30,
                forecastTemperatureSize: 16,
                metricFontSize: 11,
                expandedSectionSpacing: 10,
                expandedIconSize: 68,
                expandedTemperatureSize: 54,
                dayTemperatureMinimumWidth: 132,
                dayTemperatureMaximumWidth: nil,
                minimumTemperaturePointSize: 13,
                usesStackedHeader: true,
                fillsForecastSection: true,
                usesFlexibleForecastItemSpacing: false
            )
        case .standard:
            self.init(
                contentSpacing: chrome.sectionSpacing,
                forecastColumnSpacing: 9,
                forecastVerticalSpacing: 7,
                headerFontSize: 15,
                dayHorizontalSpacing: 20,
                dayIconSize: 48,
                dayTemperatureSize: 38,
                forecastTitleSize: 13,
                forecastIconSize: 22,
                forecastTemperatureSize: 15,
                metricFontSize: 9,
                expandedSectionSpacing: 10,
                expandedIconSize: 52,
                expandedTemperatureSize: 44,
                dayTemperatureMinimumWidth: 96,
                dayTemperatureMaximumWidth: nil,
                minimumTemperaturePointSize: 12,
                usesStackedHeader: false,
                fillsForecastSection: false,
                usesFlexibleForecastItemSpacing: false
            )
        }
    }

    private init(
        contentSpacing: CGFloat,
        forecastColumnSpacing: CGFloat,
        forecastVerticalSpacing: CGFloat,
        headerFontSize: CGFloat,
        dayHorizontalSpacing: CGFloat,
        dayIconSize: CGFloat,
        dayTemperatureSize: CGFloat,
        forecastTitleSize: CGFloat,
        forecastIconSize: CGFloat,
        forecastTemperatureSize: CGFloat,
        metricFontSize: CGFloat,
        expandedSectionSpacing: CGFloat,
        expandedIconSize: CGFloat,
        expandedTemperatureSize: CGFloat,
        dayTemperatureMinimumWidth: CGFloat,
        dayTemperatureMaximumWidth: CGFloat?,
        minimumTemperaturePointSize: CGFloat,
        usesStackedHeader: Bool,
        fillsForecastSection: Bool,
        usesFlexibleForecastItemSpacing: Bool
    ) {
        self.contentSpacing = contentSpacing
        self.forecastColumnSpacing = forecastColumnSpacing
        self.forecastVerticalSpacing = forecastVerticalSpacing
        self.headerFontSize = headerFontSize
        self.dayHorizontalSpacing = dayHorizontalSpacing
        self.dayIconSize = dayIconSize
        self.dayTemperatureSize = dayTemperatureSize
        self.forecastTitleSize = forecastTitleSize
        self.forecastIconSize = forecastIconSize
        self.forecastTemperatureSize = forecastTemperatureSize
        self.metricFontSize = metricFontSize
        self.expandedSectionSpacing = expandedSectionSpacing
        self.expandedIconSize = expandedIconSize
        self.expandedTemperatureSize = expandedTemperatureSize
        self.dayTemperatureMinimumWidth = dayTemperatureMinimumWidth
        self.dayTemperatureMaximumWidth = dayTemperatureMaximumWidth
        self.minimumTemperaturePointSize = minimumTemperaturePointSize
        self.usesStackedHeader = usesStackedHeader
        self.fillsForecastSection = fillsForecastSection
        self.usesFlexibleForecastItemSpacing = usesFlexibleForecastItemSpacing
    }
}

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
    let unitSuffix: String?
    let spokenText: String
    let symbolName: String

    var displayText: String {
        text + (unitSuffix ?? "")
    }

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
    let usesExpandedForecastLayout: Bool

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
        configuration: WeatherV8ConfigurationIntent,
        snapshot: WeatherSnapshot?,
        state: WeatherEntryState,
        family: WidgetFamily,
        locale: Locale
    ) {
        self.showsStaleStatus = if case .stale = state { true } else { false }
        self.locationName = snapshot?.locationName ?? configuration.resolvedCity
        self.locale = locale
        self.timeZone = snapshot?.timeZone ?? .autoupdatingCurrent
        self.unit = snapshot?.unit ?? configuration.resolvedTemperatureUnit.resolved(for: locale)
        self.usesExpandedForecastLayout = family == .systemLarge
        self.familyName = switch family {
        case .systemSmall: "Small"
        case .systemMedium: "Medium"
        case .systemLarge: "Large"
        default: "This size"
        }

        let resolvedContent: WeatherWidgetContent
        guard let snapshot else {
            if case let .failed(message, _) = state {
                resolvedContent = .failure(message: message)
            } else {
                resolvedContent = .failure(message: "Weather is unavailable.")
            }
            self.content = resolvedContent
            self.detailPresentation = WeatherDetailPresentation(
                preset: configuration.resolvedDetailPreset,
                family: family,
                mode: configuration.resolvedViewMode
            )
            return
        }

        switch configuration.resolvedViewMode {
        case .week where family == .systemSmall:
            resolvedContent = Self.dayContent(snapshot: snapshot, date: date)
        case .week:
            resolvedContent = .week(Array(snapshot.dailyForecasts(startingAt: date).prefix(7)))
        case .day:
            resolvedContent = Self.dayContent(snapshot: snapshot, date: date)
        case .hour:
            let hourStart = Self.forecastHourStart(for: date, timeZone: snapshot.timeZone)
            let limit = family == .systemSmall ? 3 : 6
            let hours = Array(snapshot.hourly.filter { $0.date >= hourStart }.prefix(limit))
            resolvedContent = hours.isEmpty
                ? Self.dayContent(snapshot: snapshot, date: date)
                : .hour(hours)
        }
        self.content = resolvedContent
        let resolvedMode: WeatherViewMode = switch resolvedContent {
        case .failure: configuration.resolvedViewMode
        case .day: .day
        case .week: .week
        case .hour: .hour
        }
        self.detailPresentation = WeatherDetailPresentation(
            preset: configuration.resolvedDetailPreset,
            family: family,
            mode: resolvedMode
        )
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
                    text: WeatherValueFormatter.temperature(temperature, unit: unit, includeUnit: false),
                    unitSuffix: unit.temperatureSuffix,
                    spokenText: "Temperature \(WeatherValueFormatter.temperature(temperature, unit: unit))",
                    symbolName: "thermometer.medium"
                )
            case .condition:
                WeatherMetricValue(
                    detail: detail,
                    text: condition.displayName,
                    unitSuffix: nil,
                    spokenText: condition.displayName,
                    symbolName: condition.symbolName
                )
            case .humidity:
                WeatherValueFormatter.percentage(humidity).map {
                    WeatherMetricValue(
                        detail: detail,
                        text: $0,
                        unitSuffix: nil,
                        spokenText: "Humidity \($0)",
                        symbolName: "humidity.fill"
                    )
                }
            case .precipitation:
                WeatherValueFormatter.percentage(precipitation).map {
                    WeatherMetricValue(
                        detail: detail,
                        text: $0,
                        unitSuffix: nil,
                        spokenText: "Chance of rain \($0)",
                        symbolName: "drop.fill"
                    )
                }
            case .wind:
                WeatherValueFormatter.wind(wind, unit: unit).map {
                    WeatherMetricValue(
                        detail: detail,
                        text: $0,
                        unitSuffix: nil,
                        spokenText: "Wind \($0)",
                        symbolName: "wind"
                    )
                }
            }
        }
    }
}
