import SwiftUI
import WidgetKit

struct TimeAndDateEntry: TimelineEntry {
    let date: Date
    let configuration: TimeAndDateStringConfigurationIntent
}

struct TimeAndDateProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TimeAndDateEntry {
        TimeAndDateEntry(date: .now, configuration: .referencePreview())
    }

    func snapshot(
        for configuration: TimeAndDateStringConfigurationIntent,
        in context: Context
    ) async -> TimeAndDateEntry {
        TimeAndDateEntry(date: .now, configuration: configuration)
    }

    func timeline(
        for configuration: TimeAndDateStringConfigurationIntent,
        in context: Context
    ) async -> Timeline<TimeAndDateEntry> {
        let dates = Calendar.autoupdatingCurrent.minuteTimeline(startingAt: .now, count: 60)
        let entries = dates.map { date in
            TimeAndDateEntry(date: date, configuration: configuration)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct TimeAndDateWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    let entry: TimeAndDateEntry

    private var metrics: TimeAndDateMetrics {
        TimeAndDateMetrics(family: family)
    }

    private var presentation: TimeAndDatePresentation {
        TimeAndDatePresentation(
            date: entry.date,
            configuration: entry.configuration,
            family: family,
            locale: locale,
            timeZone: timeZone
        )
    }

    var body: some View {
        Group {
            switch presentation.arrangement {
            case .classicWide:
                referenceLayout
            case .verticalDateFirst:
                stackedLayout
            case .verticalTimeFirst:
                timeFirstLayout
            case .centeredDateFirst:
                centeredLayout
            case .horizontalDateFirst:
                inlineLayout
            }
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityLabel)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var referenceLayout: some View {
        VStack(alignment: .leading, spacing: metrics.spacing) {
            dateLabel
            Spacer(minLength: 0)

            HStack(alignment: .top, spacing: 12) {
                timeLabel

                Spacer(minLength: 8)

                if let periodText = presentation.periodText {
                    periodLabel(periodText)
                        .padding(.top, metrics.referencePeriodInset)
                }
            }
        }
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: metrics.spacing) {
            dateLabel
            Spacer(minLength: 0)
            compactTimeLabel
        }
    }

    private var timeFirstLayout: some View {
        VStack(alignment: .leading, spacing: metrics.spacing) {
            compactTimeLabel
            Spacer(minLength: 0)
            dateLabel
        }
    }

    private var centeredLayout: some View {
        VStack(alignment: .center, spacing: metrics.spacing) {
            dateLabel
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            compactTimeLabel
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var inlineLayout: some View {
        HStack(alignment: .center, spacing: metrics.inlineSpacing) {
            dateLabel
                .frame(maxWidth: .infinity, alignment: .leading)

            compactTimeLabel
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var dateLabel: some View {
        Text(presentation.dateText)
            .font(entry.configuration.resolvedDateFont.font(size: metrics.dateSize, role: .date))
            .fontWeight(entry.configuration.resolvedDateFont == .systemBold ? .black : nil)
            .tracking(metrics.dateTracking)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
    }

    private var timeLabel: some View {
        Text(presentation.timeText)
            .font(entry.configuration.resolvedTimeFont.font(size: metrics.timeSize, role: .time))
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .layoutPriority(1)
    }

    private var compactTimeLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: metrics.periodSpacing) {
            timeLabel

            if let periodText = presentation.periodText {
                periodLabel(periodText)
            }
        }
        .frame(maxWidth: entry.configuration.resolvedLayout == .centered ? .infinity : nil)
    }

    private func periodLabel(_ text: String) -> some View {
        Text(text)
            .font(entry.configuration.resolvedTimeFont.font(size: metrics.periodSize, role: .time))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

private struct TimeAndDateMetrics {
    let dateSize: CGFloat
    let timeSize: CGFloat
    let periodSize: CGFloat
    let dateTracking: CGFloat
    let spacing: CGFloat
    let periodSpacing: CGFloat
    let inlineSpacing: CGFloat
    let referencePeriodInset: CGFloat

    init(family: WidgetFamily) {
        switch family {
        case .systemSmall:
            dateSize = 18
            timeSize = 50
            periodSize = 18
            dateTracking = 0.4
            spacing = 6
            periodSpacing = 6
            inlineSpacing = 8
            referencePeriodInset = 8
        case .systemLarge:
            dateSize = 32
            timeSize = 100
            periodSize = 42
            dateTracking = 1.2
            spacing = 14
            periodSpacing = 12
            inlineSpacing = 28
            referencePeriodInset = 18
        default:
            dateSize = 26
            timeSize = 76
            periodSize = 34
            dateTracking = 0.9
            spacing = 10
            periodSpacing = 10
            inlineSpacing = 20
            referencePeriodInset = 14
        }
    }
}

struct TimeAndDateWidget: Widget {
    static let kind = WidgetIdentifier.timeAndDate.rawValue

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: TimeAndDateStringConfigurationIntent.self,
            provider: TimeAndDateProvider()
        ) { entry in
            TimeAndDateWidgetView(entry: entry)
        }
        .configurationDisplayName("Time & Date")
        .description("A customizable date and clock with your choice of layout, formats, and fonts.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .containerBackgroundRemovable(true)
    }
}

#if DEBUG
struct TimeAndDateWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: timeAndDatePreviewDate, configuration: .referencePreview())
            )
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: timeAndDatePreviewDate, configuration: .referencePreview())
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(
                    date: timeAndDatePreviewDate,
                    configuration: timeAndDateAlternatePreviewConfiguration
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Alternate Configuration")

            TimeAndDateWidgetView(
                entry: TimeAndDateEntry(date: timeAndDatePreviewDate, configuration: .referencePreview())
            )
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")
        }
    }
}
#endif

private var timeAndDateAlternatePreviewConfiguration: TimeAndDateStringConfigurationIntent {
    let configuration = TimeAndDateStringConfigurationIntent()
    configuration.layout = TimeAndDateLayout.inline.rawValue
    configuration.dateFormat = TimeAndDateDateFormat.iso.rawValue
    configuration.timeFormat = TimeAndDateTimeFormat.twentyFourHour.rawValue
    configuration.dateFont = TimeAndDateFont.snellRoundhand.rawValue
    configuration.timeFont = TimeAndDateFont.systemMonospaced.rawValue
    return configuration
}

private var timeAndDatePreviewDate: Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .autoupdatingCurrent
    return calendar.date(
        from: DateComponents(year: 2026, month: 8, day: 9, hour: 9, minute: 9)
    ) ?? .now
}
