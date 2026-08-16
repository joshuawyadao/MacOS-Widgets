import AppIntents
import SwiftUI
import WidgetKit

enum WeatherEntryState: Equatable, Sendable {
    case loaded
    case stale(String)
    case failed(String, retryable: Bool)
}

struct WeatherEntry: TimelineEntry {
    let date: Date
    let configuration: PresetWeatherConfigurationIntent
    let snapshot: WeatherSnapshot?
    let state: WeatherEntryState
}

struct WeatherProvider: AppIntentTimelineProvider {
    private let service: any WeatherServing
    private let cache: WeatherSnapshotCache

    init(
        service: any WeatherServing = OpenMeteoWeatherService(),
        cache: WeatherSnapshotCache = WeatherSnapshotCache()
    ) {
        self.service = service
        self.cache = cache
    }

    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(
            date: .now,
            configuration: .referencePreview(),
            snapshot: .sample(),
            state: .loaded
        )
    }

    func snapshot(
        for configuration: PresetWeatherConfigurationIntent,
        in context: Context
    ) async -> WeatherEntry {
        if context.isPreview {
            return WeatherEntry(
                date: .now,
                configuration: configuration,
                snapshot: .sample(),
                state: .loaded
            )
        }
        return await loadEntry(configuration: configuration, date: .now)
    }

    func timeline(
        for configuration: PresetWeatherConfigurationIntent,
        in context: Context
    ) async -> Timeline<WeatherEntry> {
        let now = Date.now
        let loaded = await loadEntry(configuration: configuration, date: now)

        switch loaded.state {
        case let .failed(_, retryable):
            return Timeline(
                entries: [loaded],
                policy: retryable ? .after(now.addingTimeInterval(30 * 60)) : .never
            )
        case .loaded, .stale:
            let dates = timelineDates(
                startingAt: now,
                count: 7,
                timeZone: loaded.snapshot?.timeZone ?? .autoupdatingCurrent
            )
            let entries = dates.map { date in
                WeatherEntry(
                    date: date,
                    configuration: configuration,
                    snapshot: loaded.snapshot,
                    state: loaded.state
                )
            }
            return Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60)))
        }
    }

    private func loadEntry(configuration: PresetWeatherConfigurationIntent, date: Date) async -> WeatherEntry {
        let outcome = await WeatherLoader(service: service, cache: cache).load(
            location: configuration.resolvedLocation,
            unit: configuration.resolvedTemperatureUnit,
            locale: .autoupdatingCurrent
        )

        switch outcome {
        case let .fresh(snapshot):
            return WeatherEntry(date: date, configuration: configuration, snapshot: snapshot, state: .loaded)
        case let .stale(snapshot, message):
            return WeatherEntry(date: date, configuration: configuration, snapshot: snapshot, state: .stale(message))
        case let .failed(message, retryable):
            return WeatherEntry(
                date: date,
                configuration: configuration,
                snapshot: nil,
                state: .failed(message, retryable: retryable)
            )
        }
    }

    private func timelineDates(startingAt date: Date, count: Int, timeZone: TimeZone) -> [Date] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hourStart = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        return (0..<count).compactMap { offset in
            offset == 0 ? date : calendar.date(byAdding: .hour, value: offset, to: hourStart)
        }
    }
}

struct WeatherWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: WeatherEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                loadedView(snapshot)
            } else {
                failureView
            }
        }
        .foregroundStyle(renderingMode == .fullColor ? Color.white : Color.primary)
        .shadow(
            color: renderingMode == .fullColor ? .black.opacity(0.55) : .clear,
            radius: 1.5,
            x: 0,
            y: 1
        )
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private func loadedView(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 10) {
            header(snapshot)

            switch entry.configuration.resolvedViewMode {
            case .week:
                if family == .systemSmall {
                    dayView(snapshot)
                } else {
                    weekView(snapshot)
                }
            case .day:
                dayView(snapshot)
            case .hour:
                hourView(snapshot)
            }

            if case .stale = entry.state {
                staleLabel(snapshot)
            }

            if hiddenDetailCount > 0 {
                detailLimitNotice
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func header(_ snapshot: WeatherSnapshot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(snapshot.locationName)
                .font(.system(size: family == .systemSmall ? 14 : 17, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityLabel("Weather for \(snapshot.locationName)")

            Spacer(minLength: 4)

            Link(destination: URL(string: "https://open-meteo.com/")!) {
                Text("Open-Meteo")
                    .font(.system(size: 8, weight: .medium))
                    .underline()
                    .opacity(0.82)
            }
            .accessibilityLabel("Weather data by Open-Meteo")
        }
    }

    private func weekView(_ snapshot: WeatherSnapshot) -> some View {
        let days = Array(snapshot.dailyForecasts(startingAt: entry.date).prefix(7))
        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                forecastColumn(
                    title: WeatherValueFormatter.weekday(day.date, timeZone: snapshot.timeZone),
                    condition: day.condition,
                    values: metricValues(day, snapshot: snapshot),
                    isCurrent: index == 0
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func hourView(_ snapshot: WeatherSnapshot) -> some View {
        let hourStart = forecastHourStart(for: entry.date, timeZone: snapshot.timeZone)
        let hours = Array(snapshot.hourly.filter { $0.date >= hourStart }.prefix(family == .systemSmall ? 3 : 6))

        if hours.isEmpty {
            dayView(snapshot)
        } else {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(hours.enumerated()), id: \.offset) { index, hour in
                    forecastColumn(
                        title: index == 0
                            ? "Now"
                            : WeatherValueFormatter.hour(hour.date, timeZone: snapshot.timeZone),
                        condition: hour.condition,
                        values: metricValues(hour, snapshot: snapshot),
                        isCurrent: index == 0
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func dayView(_ snapshot: WeatherSnapshot) -> some View {
        let current = effectiveCurrent(in: snapshot)
        let today = snapshot.dailyForecast(for: entry.date)
        let details = metricValues(current, snapshot: snapshot)

        return HStack(alignment: .center, spacing: family == .systemSmall ? 10 : 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.headline)

                Image(systemName: current.condition.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: family == .systemLarge ? 66 : 44))
                    .widgetAccentable()

                if visibleDetails.contains(.condition) {
                    Text(current.condition.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 5) {
                if visibleDetails.contains(.temperature) {
                    Text(WeatherValueFormatter.temperature(current.temperature, unit: snapshot.unit))
                        .font(.system(size: family == .systemLarge ? 58 : 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)

                    if let today {
                        Text(
                            "H \(WeatherValueFormatter.temperature(today.highTemperature, unit: snapshot.unit, includeUnit: false))  L \(WeatherValueFormatter.temperature(today.lowTemperature, unit: snapshot.unit, includeUnit: false))"
                        )
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                    }
                }

                ForEach(details.filter { $0.detail != .temperature && $0.detail != .condition }) { value in
                    metricLabel(value)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayAccessibility(snapshot))
    }

    private func forecastColumn(
        title: String,
        condition: WeatherCondition,
        values: [WeatherMetricValue],
        isCurrent: Bool
    ) -> some View {
        let spacious = values.count == 1 && values.first?.detail == .temperature

        return VStack(spacing: family == .systemLarge ? 7 : 5) {
            Text(title)
                .font(
                    .system(
                        size: family == .systemLarge ? 17 : (spacious ? 17 : 14),
                        weight: isCurrent ? .black : .bold,
                        design: .rounded
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Image(systemName: condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: family == .systemLarge ? 30 : (spacious ? 30 : 23)))
                .frame(height: family == .systemLarge ? 34 : (spacious ? 34 : 26))
                .widgetAccentable()

            ForEach(values) { value in
                if value.detail == .temperature {
                    Text(value.text)
                        .font(
                            .system(
                                size: family == .systemLarge ? 18 : (spacious ? 21 : 15),
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .monospacedDigit()
                } else {
                    metricLabel(value)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ([title, condition.displayName] + values.filter { $0.detail != .condition }.map(\.spokenText))
                .joined(separator: ", ")
        )
    }

    private func metricLabel(_ value: WeatherMetricValue) -> some View {
        Group {
            if value.detail == .condition {
                Text(value.text)
            } else {
                Label(value.text, systemImage: value.symbolName)
            }
        }
        .font(.system(size: family == .systemLarge ? 11 : 9, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private func metricValues(_ point: WeatherPoint, snapshot: WeatherSnapshot) -> [WeatherMetricValue] {
        metricValues(
            temperature: point.temperature,
            humidity: point.humidity,
            precipitation: point.precipitationProbability,
            wind: point.windSpeed,
            condition: point.condition,
            snapshot: snapshot
        )
    }

    private func metricValues(_ day: DailyWeather, snapshot: WeatherSnapshot) -> [WeatherMetricValue] {
        metricValues(
            temperature: day.highTemperature,
            humidity: day.humidity,
            precipitation: day.precipitationProbability,
            wind: day.windSpeed,
            condition: day.condition,
            snapshot: snapshot
        )
    }

    private func metricValues(
        temperature: Double,
        humidity: Double?,
        precipitation: Double?,
        wind: Double?,
        condition: WeatherCondition,
        snapshot: WeatherSnapshot
    ) -> [WeatherMetricValue] {
        visibleDetails.compactMap { detail in
            switch detail {
            case .temperature:
                WeatherMetricValue(
                    detail: detail,
                    text: WeatherValueFormatter.temperature(temperature, unit: snapshot.unit),
                    spokenText: "Temperature \(WeatherValueFormatter.temperature(temperature, unit: snapshot.unit))",
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
                    WeatherMetricValue(detail: detail, text: $0, spokenText: "Humidity \($0)", symbolName: "humidity.fill")
                }
            case .precipitation:
                WeatherValueFormatter.percentage(precipitation).map {
                    WeatherMetricValue(detail: detail, text: $0, spokenText: "Chance of rain \($0)", symbolName: "drop.fill")
                }
            case .wind:
                WeatherValueFormatter.wind(wind, unit: snapshot.unit).map {
                    WeatherMetricValue(detail: detail, text: $0, spokenText: "Wind \($0)", symbolName: "wind")
                }
            }
        }
    }

    private func staleLabel(_ snapshot: WeatherSnapshot) -> some View {
        Label(
            "Last updated \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))",
            systemImage: "arrow.clockwise"
        )
        .font(.system(size: 9, weight: .medium))
        .opacity(0.8)
        .accessibilityLabel("Showing saved weather from \(snapshot.fetchedAt.formatted())")
    }

    private var visibleDetails: [WeatherDetail] {
        WeatherDetailLimits.limited(entry.configuration.resolvedDetails, maximum: detailLimit)
    }

    private var hiddenDetailCount: Int {
        max(0, entry.configuration.resolvedDetails.count - visibleDetails.count)
    }

    private var detailLimit: Int {
        switch family {
        case .systemSmall:
            WeatherDetailLimits.small
        case .systemMedium:
            WeatherDetailLimits.medium
        case .systemLarge:
            WeatherDetailLimits.large
        default:
            WeatherDetailLimits.small
        }
    }

    private var familyName: String {
        switch family {
        case .systemSmall: "Small"
        case .systemMedium: "Medium"
        case .systemLarge: "Large"
        default: "this size"
        }
    }

    private var detailLimitNotice: some View {
        Label(
            "Showing \(visibleDetails.count) of \(entry.configuration.resolvedDetails.count) · \(familyName) limit \(detailLimit)",
            systemImage: "info.circle.fill"
        )
        .font(.system(size: 9, weight: .semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .opacity(0.9)
        .accessibilityLabel(
            "\(hiddenDetailCount) weather details hidden because the \(familyName) widget limit is \(detailLimit)"
        )
    }

    private var failureView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.configuration.resolvedCity)
                .font(.system(.headline, design: .monospaced))
                .lineLimit(1)

            Spacer(minLength: 0)

            Image(systemName: "cloud.slash.fill")
                .font(.system(size: 34))
                .widgetAccentable()

            if case let .failed(message, _) = entry.state {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Link("Weather data by Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
                .font(.system(size: 9))
                .underline()
        }
        .accessibilityElement(children: .combine)
    }

    private func dayAccessibility(_ snapshot: WeatherSnapshot) -> String {
        let current = effectiveCurrent(in: snapshot)
        let values = metricValues(current, snapshot: snapshot)
            .filter { $0.detail != .condition }
            .map(\.spokenText)
        return (["Today", current.condition.displayName] + values).joined(separator: ", ")
    }

    private func effectiveCurrent(in snapshot: WeatherSnapshot) -> WeatherPoint {
        guard let hourlyPoint = snapshot.hourly.last(where: { $0.date <= entry.date }),
              hourlyPoint.date > snapshot.current.date else {
            return snapshot.current
        }
        return hourlyPoint
    }

    private func forecastHourStart(for date: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateInterval(of: .hour, for: date)?.start ?? date
    }
}

private struct WeatherMetricValue: Identifiable {
    let detail: WeatherDetail
    let text: String
    let spokenText: String
    let symbolName: String

    var id: String { detail.rawValue }
}

struct WeatherWidget: Widget {
    static let kind = WidgetIdentifier.weather.rawValue

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: PresetWeatherConfigurationIntent.self,
            provider: WeatherProvider()
        ) { entry in
            WeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("A clear city forecast with week, day, and hour views.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .containerBackgroundRemovable(true)
    }
}

#Preview("Week", as: .systemMedium) {
    WeatherWidget()
} timeline: {
    WeatherEntry(
        date: WeatherSnapshot.sample().fetchedAt,
        configuration: .referencePreview(),
        snapshot: .sample(),
        state: .loaded
    )
}

#Preview("Day", as: .systemSmall) {
    WeatherWidget()
} timeline: {
    WeatherEntry(
        date: WeatherSnapshot.sample().fetchedAt,
        configuration: weatherDayPreviewConfiguration,
        snapshot: .sample(),
        state: .loaded
    )
}

private var weatherDayPreviewConfiguration: PresetWeatherConfigurationIntent {
    let configuration = PresetWeatherConfigurationIntent.referencePreview()
    configuration.viewMode = WeatherViewMode.day.rawValue
    configuration.detailPreset = WeatherDetailPreset.comfort.rawValue
    return configuration
}
