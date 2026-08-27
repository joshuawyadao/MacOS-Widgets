import AppIntents
import SwiftUI
import WidgetKit

struct WeatherWidgetView: View {
    @Environment(\.widgetFamily) private var environmentFamily
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: WeatherEntry
    private let familyOverride: WidgetFamily?
    private let typographyOverride: WidgetTypographyResolution?
    private let coverageOverride: WidgetTypographyCoverage?

    init(
        entry: WeatherEntry,
        family: WidgetFamily? = nil,
        typography: WidgetTypographyResolution? = nil,
        coverage: WidgetTypographyCoverage? = nil
    ) {
        self.entry = entry
        self.familyOverride = family
        self.typographyOverride = typography
        self.coverageOverride = coverage
    }

    private var family: WidgetFamily {
        familyOverride ?? environmentFamily
    }

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

    private var typography: WidgetTypographyStyle {
        let stored = WidgetTypographyStore.live.style(for: .weather)
        return WidgetTypographyStyle(
            resolution: typographyOverride ?? stored.resolution,
            coverage: coverageOverride ?? stored.coverage
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
        .widgetSurface(renderingMode: renderingMode)
    }

    private func loadedView(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: typography.verticalSpacing(layout.contentSpacing)) {
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

    @ViewBuilder
    private var header: some View {
        if layout.usesStackedHeader {
            VStack(alignment: .leading, spacing: typography.verticalSpacing(3)) {
                locationLabel

                HStack {
                    Spacer(minLength: 0)
                    attributionControl(compact: true)
                }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: typography.horizontalSpacing(8)) {
                locationLabel

                if family != .systemSmall {
                    Spacer(minLength: typography.horizontalSpacing(4))
                    attributionControl(compact: true)
                }
            }
        }
    }

    private var locationLabel: some View {
        Text(headerLocationName)
            .font(
                typography.displayFont(
                    size: layout.headerFontSize,
                    weight: .semibold,
                    fallback: .system(size: layout.headerFontSize, weight: .medium, design: .monospaced)
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(
                typography.displayMinimumScaleFactor(layout.usesStackedHeader ? 0.65 : 0.75)
            )
            .padding(.vertical, typography.displayTextVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel("Weather for \(presentation.locationName)")
    }

    private func weekView(_ days: [DailyWeather]) -> some View {
        HStack(
            alignment: .top,
            spacing: typography.horizontalSpacing(layout.forecastColumnSpacing)
        ) {
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
        .frame(
            maxWidth: .infinity,
            maxHeight: layout.fillsForecastSection ? .infinity : nil,
            alignment: .top
        )
    }

    private func hourView(_ hours: [WeatherPoint]) -> some View {
        HStack(
            alignment: .top,
            spacing: typography.horizontalSpacing(layout.forecastColumnSpacing)
        ) {
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
        .frame(
            maxWidth: .infinity,
            maxHeight: layout.fillsForecastSection ? .infinity : nil,
            alignment: .top
        )
    }

    private func expandedForecastDashboard<ForecastContent: View>(
        snapshot: WeatherSnapshot,
        @ViewBuilder forecastContent: () -> ForecastContent
    ) -> some View {
        VStack(spacing: typography.verticalSpacing(layout.expandedSectionSpacing)) {
            expandedCurrentSummary(snapshot)
                .frame(maxHeight: .infinity, alignment: .center)

            Divider()
                .overlay(Color.primary.opacity(0.3))

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

        return HStack(
            alignment: .center,
            spacing: typography.horizontalSpacing(layout.dayHorizontalSpacing)
        ) {
            Image(systemName: current.condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: layout.expandedIconSize))
                .frame(
                    width: layout.expandedIconSize + 12,
                    height: layout.expandedIconSize + 12
                )
                .widgetAccentable()

            VStack(alignment: .leading, spacing: typography.verticalSpacing(5)) {
                if let temperature = details.first(where: { $0.detail == .temperature }) {
                    temperatureLabel(
                        temperature,
                        size: layout.expandedTemperatureSize,
                        usesDisplayTypography: true
                    )
                }

                Text(current.condition.displayName)
                    .font(
                        typography.supportingFont(
                            size: 15,
                            weight: .bold,
                            fallback: .system(size: 15, weight: .bold, design: .rounded)
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
                    .padding(.vertical, typography.supportingTextVerticalPadding)

                if let forecast {
                    Text(
                        "High \(WeatherValueFormatter.temperature(forecast.highTemperature, unit: snapshot.unit, includeUnit: false))  ·  Low \(WeatherValueFormatter.temperature(forecast.lowTemperature, unit: snapshot.unit, includeUnit: false))"
                    )
                    .font(
                        typography.supportingFont(
                            size: 12,
                            weight: .semibold,
                            fallback: .system(size: 12, weight: .semibold, design: .rounded)
                        )
                    )
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
                    .padding(.vertical, typography.supportingTextVerticalPadding)
                }
            }

            Spacer(minLength: typography.horizontalSpacing(8))

            VStack(
                alignment: .trailing,
                spacing: typography.verticalSpacing(layout.forecastVerticalSpacing)
            ) {
                ForEach(details.filter { $0.detail != .temperature && $0.detail != .condition }) { value in
                    Label(value.text, systemImage: value.symbolName)
                        .font(
                            typography.supportingFont(
                                size: 13,
                                weight: .semibold,
                                fallback: .system(size: 13, weight: .semibold, design: .rounded)
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.68))
                        .padding(.vertical, typography.supportingTextVerticalPadding)
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

        return HStack(
            alignment: .center,
            spacing: typography.horizontalSpacing(layout.dayHorizontalSpacing)
        ) {
            VStack(
                alignment: .leading,
                spacing: typography.verticalSpacing(family == .systemSmall ? 4 : 6)
            ) {
                Text("Today")
                    .font(
                        typography.supportingFont(
                            size: 17,
                            weight: .semibold,
                            fallback: .headline
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
                    .padding(.vertical, typography.supportingTextVerticalPadding)

                Image(systemName: current.condition.symbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: layout.dayIconSize))
                    .widgetAccentable()

                if visibleDetails.contains(.condition) {
                    Text(current.condition.displayName)
                        .font(
                            typography.supportingFont(
                                size: 12,
                                weight: .semibold,
                                fallback: .caption.weight(.semibold)
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
                        .padding(.vertical, typography.supportingTextVerticalPadding)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(
                alignment: .trailing,
                spacing: typography.verticalSpacing(family == .systemSmall ? 4 : 7)
            ) {
                if let temperature = details.first(where: { $0.detail == .temperature }) {
                    temperatureLabel(
                        temperature,
                        size: layout.dayTemperatureSize,
                        usesDisplayTypography: true
                    )

                    if let forecast {
                        highLowLabel(forecast, snapshot: snapshot)
                    }
                }

                ForEach(details.filter { $0.detail != .temperature && $0.detail != .condition }) { value in
                    metricLabel(value)
                }
            }
            .frame(
                minWidth: layout.dayTemperatureMinimumWidth,
                maxWidth: layout.dayTemperatureMaximumWidth,
                alignment: .trailing
            )
            .layoutPriority(1)
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
        return VStack(spacing: typography.verticalSpacing(layout.forecastVerticalSpacing)) {
            Text(title)
                .font(
                    typography.supportingFont(
                        size: layout.forecastTitleSize,
                        weight: isCurrent ? .black : .bold,
                        fallback: .system(
                            size: layout.forecastTitleSize,
                            weight: isCurrent ? .black : .bold,
                            design: .rounded
                        )
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
                .padding(.vertical, typography.supportingTextVerticalPadding)

            if layout.usesFlexibleForecastItemSpacing {
                Spacer(minLength: typography.verticalSpacing(layout.forecastVerticalSpacing))
            }

            Image(systemName: condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: layout.forecastIconSize))
                .frame(height: layout.forecastIconSize + 4)
                .widgetAccentable()

            if layout.usesFlexibleForecastItemSpacing {
                Spacer(minLength: typography.verticalSpacing(layout.forecastVerticalSpacing))
            }

            ForEach(values) { value in
                if value.detail == .temperature {
                    temperatureLabel(value, size: layout.forecastTemperatureSize)
                } else {
                    metricLabel(value)
                }
            }
        }
        .frame(maxHeight: layout.fillsForecastSection ? .infinity : nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func highLowLabel(_ forecast: DailyWeather, snapshot: WeatherSnapshot) -> some View {
        let high = WeatherValueFormatter.temperature(
            forecast.highTemperature,
            unit: snapshot.unit,
            includeUnit: false
        )
        let low = WeatherValueFormatter.temperature(
            forecast.lowTemperature,
            unit: snapshot.unit,
            includeUnit: false
        )

        if family == .systemSmall {
            VStack(alignment: .trailing, spacing: typography.verticalSpacing(0)) {
                Text("H \(high)")
                Text("L \(low)")
            }
            .font(
                typography.supportingFont(
                    size: 12,
                    weight: .semibold,
                    fallback: .caption.weight(.semibold)
                )
            )
            .monospacedDigit()
            .lineLimit(2)
            .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
            .padding(.vertical, typography.supportingTextVerticalPadding)
        } else {
            Text("H \(high)  L \(low)")
                .font(
                    typography.supportingFont(
                        size: 12,
                        weight: .semibold,
                        fallback: .caption.weight(.semibold)
                    )
                )
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
                .padding(.vertical, typography.supportingTextVerticalPadding)
        }
    }

    private func metricLabel(_ value: WeatherMetricValue) -> some View {
        Group {
            if value.detail == .condition {
                Text(value.text)
            } else {
                Label(value.text, systemImage: value.symbolName)
            }
        }
        .font(
            typography.supportingFont(
                size: layout.metricFontSize,
                weight: .semibold,
                fallback: .system(size: layout.metricFontSize, weight: .semibold, design: .rounded)
            )
        )
        .lineLimit(value.detail == .condition ? 2 : 1)
        .multilineTextAlignment(.center)
        .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.75))
        .padding(.vertical, typography.supportingTextVerticalPadding)
    }

    private func temperatureLabel(
        _ value: WeatherMetricValue,
        size: CGFloat,
        usesDisplayTypography: Bool = false
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            temperatureText(value.displayText, size: size, usesDisplayTypography: usesDisplayTypography)
            temperatureText(
                value.displayText,
                size: max(layout.minimumTemperaturePointSize, size * 0.84),
                usesDisplayTypography: usesDisplayTypography
            )
            temperatureText(
                value.displayText,
                size: max(layout.minimumTemperaturePointSize, size * 0.68),
                usesDisplayTypography: usesDisplayTypography
            )
            temperatureText(
                value.displayText,
                size: layout.minimumTemperaturePointSize,
                usesDisplayTypography: usesDisplayTypography
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.spokenText)
    }

    private func temperatureText(
        _ text: String,
        size: CGFloat,
        usesDisplayTypography: Bool
    ) -> some View {
        Text(text)
            .font(
                usesDisplayTypography
                    ? typography.displayFont(
                        size: size,
                        weight: .bold,
                        fallback: .system(size: size, weight: .bold, design: .rounded)
                    )
                    : typography.supportingFont(
                        size: size,
                        weight: .bold,
                        fallback: .system(size: size, weight: .bold, design: .rounded)
                    )
            )
            .monospacedDigit()
            .padding(
                .vertical,
                usesDisplayTypography
                    ? typography.displayTextVerticalPadding
                    : typography.supportingTextVerticalPadding
            )
            .fixedSize(horizontal: true, vertical: true)
    }

    private var headerLocationName: String {
        guard family == .systemSmall else { return presentation.locationName }
        return presentation.locationName.split(separator: ",", maxSplits: 1).first.map(String.init)
            ?? presentation.locationName
    }

    private func staleLabel(_ snapshot: WeatherSnapshot) -> some View {
        WidgetStatusLine(
            text: "Last updated \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))",
            systemImage: "arrow.clockwise",
            accessibilityText: "Showing saved weather from \(snapshot.fetchedAt.formatted())",
            typography: typography
        )
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
        WidgetStatusLine(
            text: presentation.detailLimitNotice ?? "Weather detail limit applied",
            systemImage: "info.circle.fill",
            accessibilityText: "\(hiddenDetailCount) weather details hidden because this widget size limit is \(detailLimit)",
            typography: typography
        )
    }

    private var failureView: some View {
        VStack(alignment: .leading, spacing: typography.verticalSpacing(10)) {
            Text(presentation.locationName)
                .font(
                    typography.displayFont(
                        size: 15,
                        weight: .bold,
                        fallback: .system(.headline, design: .monospaced)
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(typography.displayMinimumScaleFactor(0.7))
                .padding(.vertical, typography.displayTextVerticalPadding)

            Spacer(minLength: 0)

            Image(systemName: "cloud.slash.fill")
                .font(.system(size: 34))
                .widgetAccentable()

            if let message = presentation.failureMessage {
                Text(message)
                    .font(
                        typography.supportingFont(
                            size: 12,
                            weight: .semibold,
                            fallback: .caption.weight(.semibold)
                        )
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, typography.supportingTextVerticalPadding)
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
            .font(
                typography.supportingFont(
                    size: compact ? 8 : 9,
                    weight: .medium,
                    fallback: .system(size: compact ? 8 : 9, weight: .medium)
                )
            )
            .underline()
            .lineLimit(1)
            .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
            .padding(.vertical, typography.supportingTextVerticalPadding)
            .opacity(compact ? 0.82 : 1)
    }

}

struct WeatherWidget: Widget {
    static let kind = WidgetIdentifier.weather.rawValue

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: WeatherV8ConfigurationIntent.self,
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

#if DEBUG
struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeatherWidgetView(
                entry: WeatherEntry(
                    date: WeatherSnapshot.sample().fetchedAt,
                    configuration: .referencePreview(),
                    snapshot: .sample(),
                    state: .loaded
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Week")

            WeatherWidgetView(
                entry: WeatherEntry(
                    date: WeatherSnapshot.sample().fetchedAt,
                    configuration: weatherDayPreviewConfiguration,
                    snapshot: .sample(),
                    state: .loaded
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Day")

            WeatherWidgetView(
                entry: WeatherEntry(
                    date: WeatherSnapshot.sample().fetchedAt,
                    configuration: weatherHourPreviewConfiguration,
                    snapshot: .sample(),
                    state: .loaded
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Hour")
        }
    }
}
#endif

private var weatherDayPreviewConfiguration: WeatherV8ConfigurationIntent {
    let configuration = WeatherV8ConfigurationIntent.referencePreview()
    configuration.viewMode = WeatherViewMode.day.rawValue
    configuration.detailPreset = WeatherDetailPreset.comfort.rawValue
    return configuration
}

private var weatherHourPreviewConfiguration: WeatherV8ConfigurationIntent {
    let configuration = WeatherV8ConfigurationIntent.referencePreview()
    configuration.viewMode = WeatherViewMode.hour.rawValue
    configuration.detailPreset = WeatherDetailPreset.rain.rawValue
    return configuration
}
