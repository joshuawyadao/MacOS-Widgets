import AppIntents
import SwiftUI
import WidgetKit

struct WeatherWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: WeatherEntry

    private var layout: WeatherWidgetLayoutMetrics {
        WeatherWidgetLayoutMetrics(family: family)
    }

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
        VStack(alignment: .leading, spacing: layout.contentSpacing) {
            header

            switch presentation.content {
            case let .day(current, forecast):
                dayView(current: current, forecast: forecast, snapshot: snapshot)
            case let .week(days):
                if presentation.usesExpandedForecastLayout {
                    expandedForecastDashboard(snapshot: snapshot) {
                        weekView(days)
                    }
                } else {
                    weekView(days)
                }
            case let .hour(hours):
                if presentation.usesExpandedForecastLayout {
                    expandedForecastDashboard(snapshot: snapshot) {
                        hourView(hours)
                    }
                } else {
                    hourView(hours)
                }
            case .failure:
                failureView
            }

            if presentation.showsStaleStatus {
                staleLabel(snapshot)
            }

            if hiddenDetailCount > 0 {
                detailLimitNotice
            }

            if family == .systemSmall {
                HStack {
                    Spacer(minLength: 0)
                    attributionControl(compact: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(headerLocationName)
                .font(.system(size: layout.headerFontSize, weight: .medium, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityLabel("Weather for \(presentation.locationName)")

            if family != .systemSmall {
                Spacer(minLength: 4)
                attributionControl(compact: true)
            }
        }
    }

    private func weekView(_ days: [DailyWeather]) -> some View {
        HStack(alignment: .top, spacing: layout.forecastColumnSpacing) {
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
        HStack(alignment: .top, spacing: layout.forecastColumnSpacing) {
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

    private func expandedForecastDashboard<ForecastContent: View>(
        snapshot: WeatherSnapshot,
        @ViewBuilder forecastContent: () -> ForecastContent
    ) -> some View {
        VStack(spacing: layout.expandedSectionSpacing) {
            expandedCurrentSummary(snapshot)

            Divider()
                .overlay(Color.white.opacity(0.3))

            forecastContent()
                .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func expandedCurrentSummary(_ snapshot: WeatherSnapshot) -> some View {
        let hourlyPoint = snapshot.hourly.last(where: { $0.date <= entry.date })
        let current = if let hourlyPoint, hourlyPoint.date > snapshot.current.date {
            hourlyPoint
        } else {
            snapshot.current
        }
        let details = presentation.metricValues(for: current)
        let forecast = snapshot.dailyForecast(for: entry.date)

        return HStack(alignment: .center, spacing: layout.dayHorizontalSpacing) {
            Image(systemName: current.condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: layout.expandedIconSize))
                .frame(
                    width: layout.expandedIconSize + 12,
                    height: layout.expandedIconSize + 12
                )
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 5) {
                if let temperature = details.first(where: { $0.detail == .temperature }) {
                    temperatureLabel(temperature, size: layout.expandedTemperatureSize)
                }

                Text(current.condition.displayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(1)

                if let forecast {
                    Text(
                        "High \(WeatherValueFormatter.temperature(forecast.highTemperature, unit: snapshot.unit, includeUnit: false))  ·  Low \(WeatherValueFormatter.temperature(forecast.lowTemperature, unit: snapshot.unit, includeUnit: false))"
                    )
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: layout.forecastVerticalSpacing) {
                ForEach(details.filter { $0.detail != .temperature && $0.detail != .condition }) { value in
                    Label(value.text, systemImage: value.symbolName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            (["Current weather", current.condition.displayName] + details
                .filter { $0.detail != .condition }
                .map(\.spokenText))
                .joined(separator: ", ")
        )
    }

    private func dayView(
        current: WeatherPoint,
        forecast: DailyWeather?,
        snapshot: WeatherSnapshot
    ) -> some View {
        let details = presentation.metricValues(for: current)

        return HStack(alignment: .center, spacing: layout.dayHorizontalSpacing) {
            VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 6) {
                Text("Today")
                    .font(.headline)

                Image(systemName: current.condition.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: layout.dayIconSize))
                    .widgetAccentable()

                if visibleDetails.contains(.condition) {
                    Text(current.condition.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: family == .systemSmall ? 4 : 7) {
                if let temperature = details.first(where: { $0.detail == .temperature }) {
                    temperatureLabel(temperature, size: layout.dayTemperatureSize)

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
        return VStack(spacing: layout.forecastVerticalSpacing) {
            Text(title)
                .font(
                    .system(
                        size: layout.forecastTitleSize,
                        weight: isCurrent ? .black : .bold,
                        design: .rounded
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Image(systemName: condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: layout.forecastIconSize))
                .frame(height: layout.forecastIconSize + 4)
                .widgetAccentable()

            ForEach(values) { value in
                if value.detail == .temperature {
                    temperatureLabel(value, size: layout.forecastTemperatureSize)
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
        .font(.system(size: layout.metricFontSize, weight: .semibold, design: .rounded))
        .lineLimit(value.detail == .condition ? 2 : 1)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(0.75)
    }

    private func temperatureLabel(
        _ value: WeatherMetricValue,
        size: CGFloat
    ) -> some View {
        Text(value.displayText)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var headerLocationName: String {
        guard family == .systemSmall else { return presentation.locationName }
        return presentation.locationName.split(separator: ",", maxSplits: 1).first.map(String.init)
            ?? presentation.locationName
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

            attributionControl(compact: false)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func attributionControl(compact: Bool) -> some View {
        Link(destination: WeatherWidgetPresentation.attributionURL) {
            attributionLabel(compact: compact)
        }
        .accessibilityLabel("Weather data by Open-Meteo")
    }

    private func attributionLabel(compact: Bool) -> some View {
        Text(compact ? "Open-Meteo" : "Weather data by Open-Meteo")
            .font(.system(size: compact ? 8 : 9, weight: .medium))
            .underline()
            .opacity(compact ? 0.82 : 1)
    }

}

struct WeatherWidget: Widget {
    static let kind = WidgetIdentifier.weather.rawValue

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: WeatherV7ConfigurationIntent.self,
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

#Preview("Hour", as: .systemLarge) {
    WeatherWidget()
} timeline: {
    WeatherEntry(
        date: WeatherSnapshot.sample().fetchedAt,
        configuration: weatherHourPreviewConfiguration,
        snapshot: .sample(),
        state: .loaded
    )
}

private var weatherDayPreviewConfiguration: WeatherV7ConfigurationIntent {
    let configuration = WeatherV7ConfigurationIntent.referencePreview()
    configuration.viewMode = WeatherViewMode.day.rawValue
    configuration.detailPreset = WeatherDetailPreset.comfort.rawValue
    return configuration
}

private var weatherHourPreviewConfiguration: WeatherV7ConfigurationIntent {
    let configuration = WeatherV7ConfigurationIntent.referencePreview()
    configuration.viewMode = WeatherViewMode.hour.rawValue
    configuration.detailPreset = WeatherDetailPreset.rain.rawValue
    return configuration
}
