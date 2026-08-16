import AppIntents
import SwiftUI
import WidgetKit

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
            let dates = WeatherTimelinePolicy.dates(
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

}

struct WeatherWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: WeatherEntry

    private var presentation: WeatherWidgetPresentation {
        WeatherWidgetPresentation(
            date: entry.date,
            configuration: entry.configuration,
            snapshot: entry.snapshot,
            state: entry.state,
            family: family,
            locale: .autoupdatingCurrent
        )
    }

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
            header

            switch presentation.content {
            case let .day(current, forecast):
                dayView(current: current, forecast: forecast, snapshot: snapshot)
            case let .week(days):
                weekView(days)
            case let .hour(hours):
                hourView(hours)
            case .failure:
                failureView
            }

            if presentation.showsStaleStatus {
                staleLabel(snapshot)
            }

            if hiddenDetailCount > 0 {
                detailLimitNotice
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(presentation.locationName)
                .font(.system(size: family == .systemSmall ? 14 : 17, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityLabel("Weather for \(presentation.locationName)")

            Spacer(minLength: 4)

            Link(destination: WeatherWidgetPresentation.attributionURL) {
                Text("Open-Meteo")
                    .font(.system(size: 8, weight: .medium))
                    .underline()
                    .opacity(0.82)
            }
            .accessibilityLabel("Weather data by Open-Meteo")
        }
    }

    private func weekView(_ days: [DailyWeather]) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                forecastColumn(
                    title: presentation.forecastTitles[index],
                    condition: day.condition,
                    values: presentation.metricValues(for: day),
                    isCurrent: index == 0,
                    accessibilityLabel: presentation.forecastAccessibilityLabels[index]
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func hourView(_ hours: [WeatherPoint]) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(hours.enumerated()), id: \.offset) { index, hour in
                forecastColumn(
                    title: presentation.forecastTitles[index],
                    condition: hour.condition,
                    values: presentation.metricValues(for: hour),
                    isCurrent: index == 0,
                    accessibilityLabel: presentation.forecastAccessibilityLabels[index]
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayView(
        current: WeatherPoint,
        forecast: DailyWeather?,
        snapshot: WeatherSnapshot
    ) -> some View {
        let details = presentation.metricValues(for: current)

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

                    if let forecast {
                        Text(
                            "H \(WeatherValueFormatter.temperature(forecast.highTemperature, unit: snapshot.unit, includeUnit: false))  L \(WeatherValueFormatter.temperature(forecast.lowTemperature, unit: snapshot.unit, includeUnit: false))"
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
        .accessibilityLabel(presentation.dayAccessibilityLabel ?? "Weather for today")
    }

    private func forecastColumn(
        title: String,
        condition: WeatherCondition,
        values: [WeatherMetricValue],
        isCurrent: Bool,
        accessibilityLabel: String
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
        .accessibilityLabel(accessibilityLabel)
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
        presentation.detailPresentation.visibleDetails
    }

    private var hiddenDetailCount: Int {
        presentation.detailPresentation.hiddenCount
    }

    private var detailLimit: Int {
        presentation.detailPresentation.limit
    }

    private var detailLimitNotice: some View {
        Label(
            presentation.detailLimitNotice ?? "Weather detail limit applied",
            systemImage: "info.circle.fill"
        )
        .font(.system(size: 9, weight: .semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .opacity(0.9)
        .accessibilityLabel(
            "\(hiddenDetailCount) weather details hidden because this widget size limit is \(detailLimit)"
        )
    }

    private var failureView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(presentation.locationName)
                .font(.system(.headline, design: .monospaced))
                .lineLimit(1)

            Spacer(minLength: 0)

            Image(systemName: "cloud.slash.fill")
                .font(.system(size: 34))
                .widgetAccentable()

            if let message = presentation.failureMessage {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Link("Weather data by Open-Meteo", destination: WeatherWidgetPresentation.attributionURL)
                .font(.system(size: 9))
                .underline()
        }
        .accessibilityElement(children: .combine)
    }

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
