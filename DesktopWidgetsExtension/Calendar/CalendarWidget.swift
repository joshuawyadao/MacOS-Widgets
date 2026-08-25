import AppIntents
import SwiftUI
import WidgetKit

struct CalendarEntry: TimelineEntry {
    let date: Date
    let monthOffset: Int
}

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Self.referenceDate, monthOffset: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(CalendarEntry(
            date: context.isPreview ? Self.referenceDate : .now,
            monthOffset: context.isPreview ? 0 : CalendarNavigationStore.monthOffset()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let now = Date.now
        let entry = CalendarEntry(date: now, monthOffset: CalendarNavigationStore.monthOffset())
        let refreshDate = CalendarTimelinePolicy.nextRefresh(
            after: now,
            calendar: .autoupdatingCurrent
        )
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    static var referenceDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12)) ?? .now
    }
}

struct CalendarWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    let entry: CalendarEntry

    private var metrics: CalendarWidgetLayoutMetrics {
        CalendarWidgetLayoutMetrics(family: family)
    }

    private var presentation: CalendarMonthPresentation {
        var calendar = Calendar.autoupdatingCurrent
        calendar.locale = locale
        calendar.timeZone = timeZone
        let displayDate = calendar.date(
            byAdding: .month,
            value: entry.monthOffset,
            to: entry.date
        ) ?? entry.date
        return CalendarMonthPresentation(
            displayDate: displayDate,
            today: entry.date,
            calendar: calendar,
            locale: locale
        )
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: 7)
    }

    var body: some View {
        VStack(spacing: metrics.sectionSpacing) {
            monthHeader
            weekdayHeader
            dayGrid
        }
        .foregroundStyle(.white)
        .fontDesign(.rounded)
        .shadow(color: .black.opacity(0.30), radius: 1, y: 1)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var monthHeader: some View {
        HStack(spacing: 4) {
            Button(intent: PreviousCalendarMonthIntent()) {
                Image(systemName: "arrow.left")
                    .font(.system(size: metrics.arrowSize, weight: .medium))
                    .frame(width: metrics.dayCircleSize, height: metrics.dayCircleSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Spacer(minLength: 2)

            Button(intent: CurrentCalendarMonthIntent()) {
                Text(monthTitle)
                    .font(.system(size: metrics.headerFontSize, weight: .heavy, design: .rounded))
                    .tracking(metrics.usesCompactMonth ? 0.2 : 0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(presentation.accessibilityLabel), show current month")

            Spacer(minLength: 2)

            Button(intent: NextCalendarMonthIntent()) {
                Image(systemName: "arrow.right")
                    .font(.system(size: metrics.arrowSize, weight: .medium))
                    .frame(width: metrics.dayCircleSize, height: metrics.dayCircleSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")
        }
    }

    private var monthTitle: String {
        let month = metrics.usesCompactMonth
            ? presentation.abbreviatedMonthText
            : presentation.monthText
        return "\(month)   \(presentation.yearText)"
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(weekdayTexts.enumerated()), id: \.offset) { _, weekday in
                Text(weekday)
                    .font(.system(size: metrics.weekdayFontSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
    }

    private var weekdayTexts: [String] {
        metrics.usesCompactWeekdays
            ? presentation.compactWeekdayTexts
            : presentation.weekdayTexts
    }

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: metrics.rowSpacing) {
            ForEach(presentation.days) { day in
                Text(day.dayText)
                    .font(.system(size: metrics.dayFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(day.isToday ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: metrics.dayCircleSize)
                    .background {
                        if day.isToday {
                            Circle().fill(.white)
                        }
                    }
                    .opacity(day.isInDisplayedMonth || day.isToday ? 1 : 0.38)
                    .accessibilityLabel(day.accessibilityLabel)
                    .accessibilityAddTraits(day.isToday ? .isSelected : [])
            }
        }
    }
}

struct CalendarWidget: Widget {
    static let kind = WidgetIdentifier.calendar.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("A browsable month calendar that highlights today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .containerBackgroundRemovable(true)
    }
}

#if DEBUG
struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CalendarWidgetView(entry: CalendarEntry(date: CalendarProvider.referenceDate, monthOffset: 0))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")

            CalendarWidgetView(entry: CalendarEntry(date: CalendarProvider.referenceDate, monthOffset: 0))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")

            CalendarWidgetView(entry: CalendarEntry(date: CalendarProvider.referenceDate, monthOffset: 0))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Reference — August 2026")
        }
    }
}
#endif
