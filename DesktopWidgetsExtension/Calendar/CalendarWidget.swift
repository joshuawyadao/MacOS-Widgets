import AppIntents
import SwiftUI
import WidgetKit

struct CalendarEntry: TimelineEntry {
    let date: Date
    let configuration: CalendarConfigurationIntent
    let monthOffset: Int
    let events: CalendarEventSnapshot
}

struct CalendarProvider: AppIntentTimelineProvider {
    private let eventReader = SystemCalendarEventReader()

    func placeholder(in context: Context) -> CalendarEntry {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return CalendarEntry(
            date: Self.referenceDate,
            configuration: .referencePreview(),
            monthOffset: 0,
            events: .sample(referenceDate: Self.referenceDate, calendar: calendar)
        )
    }

    func snapshot(
        for configuration: CalendarConfigurationIntent,
        in context: Context
    ) async -> CalendarEntry {
        makeEntry(
            date: context.isPreview ? Self.referenceDate : .now,
            configuration: configuration,
            family: context.family,
            usesSampleEvents: context.isPreview
        )
    }

    func timeline(
        for configuration: CalendarConfigurationIntent,
        in context: Context
    ) async -> Timeline<CalendarEntry> {
        let now = Date.now
        let entry = makeEntry(
            date: now,
            configuration: configuration,
            family: context.family,
            usesSampleEvents: false
        )
        let refreshDate = CalendarTimelinePolicy.nextRefresh(
            after: now,
            calendar: .autoupdatingCurrent,
            eventsEnabled: configuration.showEvents
        )
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func makeEntry(
        date: Date,
        configuration: CalendarConfigurationIntent,
        family: WidgetFamily,
        usesSampleEvents: Bool
    ) -> CalendarEntry {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        let monthOffset = CalendarNavigationStore.monthOffset()
        let resolvedView = configuration.resolvedView(for: family)
        let interval = CalendarDisplayInterval.interval(
            for: resolvedView,
            date: date,
            monthOffset: monthOffset,
            calendar: calendar
        )
        let events = usesSampleEvents
            ? CalendarEventSnapshot.sample(referenceDate: date, calendar: calendar)
            : eventReader.snapshot(in: interval, calendar: calendar, enabled: configuration.showEvents)
        return CalendarEntry(
            date: date,
            configuration: configuration,
            monthOffset: monthOffset,
            events: events
        )
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

    private var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.locale = locale
        calendar.timeZone = timeZone
        return calendar
    }

    private var resolvedView: CalendarResolvedView {
        entry.configuration.resolvedView(for: family)
    }

    private var monthMetrics: CalendarWidgetLayoutMetrics {
        CalendarWidgetLayoutMetrics(family: family)
    }

    private var displayDate: Date {
        calendar.date(byAdding: .month, value: entry.monthOffset, to: entry.date) ?? entry.date
    }

    private var monthPresentation: CalendarMonthPresentation {
        CalendarMonthPresentation(
            displayDate: displayDate,
            today: entry.date,
            calendar: calendar,
            locale: locale
        )
    }

    private var weekPresentation: CalendarWeekPresentation {
        CalendarWeekPresentation(
            date: entry.date,
            today: entry.date,
            calendar: calendar,
            locale: locale
        )
    }

    private var dayPresentation: CalendarDayFocusPresentation {
        CalendarDayFocusPresentation(
            date: entry.date,
            calendar: calendar,
            locale: locale
        )
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: 7)
    }

    var body: some View {
        Group {
            switch resolvedView {
            case .day: dayView
            case .week: weekView
            case .month: monthView
            }
        }
        .foregroundStyle(.white)
        .fontDesign(.rounded)
        .shadow(color: .black.opacity(0.30), radius: 1, y: 1)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var dayView: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 10 : 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayPresentation.monthYearText)
                    .font(.system(size: family == .systemLarge ? 20 : 12, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                eventAccessBadge
            }

            Spacer(minLength: 0)

            Text(dayPresentation.weekdayText)
                .font(.system(size: family == .systemLarge ? 24 : 14, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(dayPresentation.dayText)
                .font(.system(size: family == .systemLarge ? 112 : (family == .systemMedium ? 72 : 62), weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            dayEventSummary
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dayAccessibilityLabel)
    }

    private var dayEventSummary: some View {
        let count = entry.events.count(on: entry.date, calendar: calendar)
        return HStack(spacing: 5) {
            switch entry.events.accessState {
            case .disabled:
                Text("TODAY")
            case .available:
                Image(systemName: count == 0 ? "calendar" : "calendar.badge.clock")
                Text(count == 1 ? "1 EVENT" : "\(count) EVENTS")
            case .requiresPermission:
                Image(systemName: "calendar.badge.exclamationmark")
                Text("ENABLE IN APP")
            case .denied:
                Image(systemName: "calendar.badge.exclamationmark")
                Text("ACCESS OFF")
            }
        }
        .font(.system(size: family == .systemLarge ? 15 : 10, weight: .bold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private var dayAccessibilityLabel: String {
        let count = entry.events.count(on: entry.date, calendar: calendar)
        guard entry.events.accessState == .available else { return dayPresentation.accessibilityLabel }
        return "\(dayPresentation.accessibilityLabel), \(count) \(count == 1 ? "event" : "events")"
    }

    private var weekView: some View {
        VStack(spacing: family == .systemLarge ? 14 : 8) {
            HStack {
                Text(weekPresentation.headerText)
                    .font(.system(size: family == .systemLarge ? 22 : 14, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                Spacer(minLength: 4)
                eventAccessBadge
            }

            HStack(alignment: .top, spacing: family == .systemLarge ? 8 : 3) {
                ForEach(weekPresentation.days) { day in
                    weekDay(day)
                }
            }
        }
    }

    private func weekDay(_ day: CalendarDayPresentation) -> some View {
        let eventCount = entry.events.count(on: day.date, calendar: calendar)
        return VStack(spacing: family == .systemLarge ? 8 : 4) {
            Text(day.weekdayText)
                .font(.system(size: family == .systemLarge ? 14 : 9, weight: .bold, design: .rounded))
                .lineLimit(1)

            Text(day.dayText)
                .font(.system(size: family == .systemLarge ? 30 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(day.isToday ? .black : .white)
                .frame(width: family == .systemLarge ? 43 : 27, height: family == .systemLarge ? 43 : 27)
                .background {
                    if day.isToday { Circle().fill(.white) }
                }

            if entry.events.accessState == .available {
                eventDots(count: eventCount, dark: false, size: family == .systemLarge ? 4 : 3)
            }

            if family == .systemLarge, entry.events.accessState == .available {
                Text(eventCount == 1 ? "1 event" : "\(eventCount) events")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayAccessibilityLabel(day, eventCount: eventCount))
        .accessibilityAddTraits(day.isToday ? .isSelected : [])
    }

    private var monthView: some View {
        VStack(spacing: monthMetrics.sectionSpacing) {
            monthHeader
            weekdayHeader
            monthGrid
        }
    }

    private var monthHeader: some View {
        HStack(spacing: 4) {
            Button(intent: PreviousCalendarMonthIntent()) {
                Image(systemName: "arrow.left")
                    .font(.system(size: monthMetrics.arrowSize, weight: .medium))
                    .frame(width: monthMetrics.dayCircleSize, height: monthMetrics.dayCircleSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Spacer(minLength: 2)

            Button(intent: CurrentCalendarMonthIntent()) {
                Text(monthTitle)
                    .font(.system(size: monthMetrics.headerFontSize, weight: .heavy, design: .rounded))
                    .tracking(monthMetrics.usesCompactMonth ? 0.2 : 0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(monthPresentation.accessibilityLabel), show current month")

            Spacer(minLength: 2)
            eventAccessBadge

            Button(intent: NextCalendarMonthIntent()) {
                Image(systemName: "arrow.right")
                    .font(.system(size: monthMetrics.arrowSize, weight: .medium))
                    .frame(width: monthMetrics.dayCircleSize, height: monthMetrics.dayCircleSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")
        }
    }

    private var monthTitle: String {
        let month = monthMetrics.usesCompactMonth
            ? monthPresentation.abbreviatedMonthText
            : monthPresentation.monthText
        return "\(month)   \(monthPresentation.yearText)"
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(monthWeekdayTexts.enumerated()), id: \.offset) { _, weekday in
                Text(weekday)
                    .font(.system(size: monthMetrics.weekdayFontSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
    }

    private var monthWeekdayTexts: [String] {
        monthMetrics.usesCompactWeekdays
            ? monthPresentation.compactWeekdayTexts
            : monthPresentation.weekdayTexts
    }

    private var monthGrid: some View {
        LazyVGrid(columns: columns, spacing: monthMetrics.rowSpacing) {
            ForEach(monthPresentation.days) { day in
                monthDay(day)
            }
        }
    }

    private func monthDay(_ day: CalendarDayPresentation) -> some View {
        let eventCount = entry.events.count(on: day.date, calendar: calendar)
        return VStack(spacing: 0) {
            Text(day.dayText)
                .font(.system(size: monthMetrics.dayFontSize, weight: .bold, design: .rounded))
            if entry.events.accessState == .available {
                eventDots(count: eventCount, dark: day.isToday, size: family == .systemLarge ? 3 : 2)
            }
        }
        .foregroundStyle(day.isToday ? .black : .white)
        .frame(maxWidth: .infinity)
        .frame(height: monthMetrics.dayCircleSize)
        .background {
            if day.isToday { Circle().fill(.white) }
        }
        .opacity(day.isInDisplayedMonth || day.isToday ? 1 : 0.38)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayAccessibilityLabel(day, eventCount: eventCount))
        .accessibilityAddTraits(day.isToday ? .isSelected : [])
    }

    @ViewBuilder
    private var eventAccessBadge: some View {
        if entry.configuration.showEvents {
            switch entry.events.accessState {
            case .requiresPermission, .denied:
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.caption.weight(.bold))
                    .accessibilityLabel(entry.events.accessState == .requiresPermission
                        ? "Enable Calendar access in the Desktop Widgets app"
                        : "Calendar access is turned off")
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func eventDots(count: Int, dark: Bool, size: CGFloat) -> some View {
        if count > 0 {
            HStack(spacing: 1) {
                ForEach(0..<min(count, 3), id: \.self) { _ in
                    Circle()
                        .fill(dark ? Color.black : Color.white)
                        .frame(width: size, height: size)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func dayAccessibilityLabel(
        _ day: CalendarDayPresentation,
        eventCount: Int
    ) -> String {
        guard entry.events.accessState == .available else { return day.accessibilityLabel }
        return "\(day.accessibilityLabel), \(eventCount) \(eventCount == 1 ? "event" : "events")"
    }
}

struct CalendarWidget: Widget {
    static let kind = WidgetIdentifier.calendar.rawValue

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: CalendarConfigurationIntent.self,
            provider: CalendarProvider()
        ) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("A configurable day, week, or month calendar with optional event indicators.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .containerBackgroundRemovable(true)
    }
}

#if DEBUG
struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(family: .systemSmall)
                .previewDisplayName("Small — Automatic Day")
            preview(family: .systemMedium)
                .previewDisplayName("Medium — Automatic Week")
            preview(family: .systemLarge)
                .previewDisplayName("Large — Automatic Month")
        }
    }

    private static func preview(family: WidgetFamily) -> some View {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return CalendarWidgetView(entry: CalendarEntry(
            date: CalendarProvider.referenceDate,
            configuration: .referencePreview(),
            monthOffset: 0,
            events: .sample(referenceDate: CalendarProvider.referenceDate, calendar: calendar)
        ))
        .previewContext(WidgetPreviewContext(family: family))
    }
}
#endif
