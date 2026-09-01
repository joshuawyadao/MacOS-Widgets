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
            eventsEnabled: configuration.showEvents || configuration.showNextEventTime,
            nextEvent: configuration.showNextEventTime ? entry.events.nextEvent : nil
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
        let monthOffset = CalendarNavigationStore.monthOffset(
            referenceDate: date,
            calendar: calendar
        )
        let resolvedView = configuration.resolvedView(for: family)
        let interval = CalendarDisplayInterval.interval(
            for: resolvedView,
            date: date,
            monthOffset: monthOffset,
            calendar: calendar
        )
        let upcomingInterval = DateInterval(
            start: date,
            end: calendar.date(byAdding: .day, value: 7, to: date)
                ?? date.addingTimeInterval(7 * 86_400)
        )
        let eventsEnabled = configuration.showEvents || configuration.showNextEventTime
        let events = usesSampleEvents
            ? CalendarEventSnapshot.sample(referenceDate: date, calendar: calendar)
            : eventReader.snapshot(
                in: interval,
                upcomingWithin: configuration.showNextEventTime ? upcomingInterval : nil,
                calendar: calendar,
                enabled: eventsEnabled,
                referenceDate: date
            )
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
    @Environment(\.widgetFamily) private var environmentFamily
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    let entry: CalendarEntry
    private let familyOverride: WidgetFamily?
    private let typographyOverride: WidgetTypographyResolution?
    private let coverageOverride: WidgetTypographyCoverage?

    init(
        entry: CalendarEntry,
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

    private var resolvedTypography: WidgetTypographyStyle {
        let stored = WidgetTypographyStore.live.style(for: .calendar)
        return WidgetTypographyStyle(
            resolution: typographyOverride ?? stored.resolution,
            coverage: coverageOverride ?? stored.coverage
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.locale = locale
        calendar.timeZone = timeZone
        return calendar
    }

    var body: some View {
        ResolvedCalendarWidgetView(
            entry: entry,
            family: family,
            renderingMode: renderingMode,
            locale: locale,
            timeZone: timeZone,
            calendar: calendar,
            typography: resolvedTypography
        )
    }
}

private enum CalendarWidgetPresentation {
    case day(CalendarDayFocusPresentation)
    case week(CalendarWeekPresentation)
    case month(CalendarMonthPresentation)
}

private struct ResolvedCalendarWidgetView: View {
    let entry: CalendarEntry
    let family: WidgetFamily
    let renderingMode: WidgetRenderingMode
    let calendar: Calendar
    let typography: WidgetTypographyStyle
    let resolvedView: CalendarResolvedView
    let monthMetrics: CalendarWidgetLayoutMetrics
    let columns: [GridItem]
    let presentation: CalendarWidgetPresentation
    let showsNextEventLine: Bool
    let nextEventText: CalendarNextEventTextPresentation?

    init(
        entry: CalendarEntry,
        family: WidgetFamily,
        renderingMode: WidgetRenderingMode,
        locale: Locale,
        timeZone: TimeZone,
        calendar: Calendar,
        typography: WidgetTypographyStyle
    ) {
        self.entry = entry
        self.family = family
        self.renderingMode = renderingMode
        self.calendar = calendar
        self.typography = typography
        let resolvedView = entry.configuration.resolvedView(for: family)
        self.resolvedView = resolvedView
        self.monthMetrics = CalendarWidgetLayoutMetrics(family: family)
        self.columns = Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: 7)
        let supportsNextEventLine = switch resolvedView {
        case .day: true
        case .week: family != .systemSmall
        case .month: family == .systemLarge
        }
        let shouldShowNextEventLine = entry.configuration.showNextEventTime && supportsNextEventLine
        self.showsNextEventLine = shouldShowNextEventLine
        self.nextEventText = shouldShowNextEventLine
            ? CalendarNextEventTextPresentation(
                snapshot: entry.events,
                calendar: calendar,
                locale: locale,
                timeZone: timeZone
            )
            : nil

        switch resolvedView {
        case .day:
            self.presentation = .day(CalendarDayFocusPresentation(
                date: entry.date,
                calendar: calendar,
                locale: locale
            ))
        case .week:
            self.presentation = .week(CalendarWeekPresentation(
                date: entry.date,
                today: entry.date,
                calendar: calendar,
                locale: locale
            ))
        case .month:
            let displayDate = calendar.date(
                byAdding: .month,
                value: entry.monthOffset,
                to: entry.date
            ) ?? entry.date
            self.presentation = .month(CalendarMonthPresentation(
                displayDate: displayDate,
                today: entry.date,
                calendar: calendar,
                locale: locale
            ))
        }
    }

    var body: some View {
        Group {
            switch presentation {
            case let .day(dayPresentation): dayView(dayPresentation)
            case let .week(weekPresentation): weekView(weekPresentation)
            case let .month(monthPresentation): monthView(monthPresentation)
            }
        }
        .widgetSurface(renderingMode: renderingMode)
    }

    private func dayView(_ dayPresentation: CalendarDayFocusPresentation) -> some View {
        VStack(
            alignment: .leading,
            spacing: typography.verticalSpacing(family == .systemLarge ? 10 : 4)
        ) {
            HStack(alignment: .firstTextBaseline) {
                Text(dayPresentation.monthYearText)
                    .font(
                        typography.displayFont(
                            size: family == .systemLarge ? 20 : 12,
                            weight: .heavy,
                            fallback: .system(size: family == .systemLarge ? 20 : 12, weight: .heavy, design: .rounded)
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(typography.displayMinimumScaleFactor(0.7))
                    .padding(.vertical, typography.displayTextVerticalPadding)
                Spacer(minLength: typography.horizontalSpacing(4))
                eventAccessBadge
            }

            Spacer(minLength: 0)

            Text(dayPresentation.weekdayText)
                .font(
                    typography.supportingFont(
                        size: family == .systemLarge ? 24 : 14,
                        weight: .bold,
                        fallback: .system(
                            size: family == .systemLarge ? 24 : 14,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
                .padding(.vertical, typography.supportingTextVerticalPadding)

            Text(dayPresentation.dayText)
                .font(
                    typography.displayFont(
                        size: family == .systemLarge ? 112 : (family == .systemMedium ? 72 : 62),
                        weight: .black,
                        fallback: .system(
                            size: family == .systemLarge ? 112 : (family == .systemMedium ? 72 : 62),
                            weight: .black,
                            design: .rounded
                        )
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(typography.displayMinimumScaleFactor(0.65))
                .padding(.vertical, typography.displayTextVerticalPadding)

            dayEventSummary

            if showsNextEventLine {
                nextEventLine
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dayAccessibilityLabel(dayPresentation))
    }

    private var dayEventSummary: some View {
        let count = entry.events.count(on: entry.date, calendar: calendar)
        return HStack(spacing: typography.horizontalSpacing(5)) {
            if !entry.configuration.showEvents {
                Text("TODAY")
            } else {
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
        }
        .font(
            typography.supportingFont(
                size: family == .systemLarge ? 15 : 10,
                weight: .bold,
                fallback: .system(
                    size: family == .systemLarge ? 15 : 10,
                    weight: .bold,
                    design: .rounded
                )
            )
        )
        .lineLimit(1)
        .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.7))
        .padding(.vertical, typography.supportingTextVerticalPadding)
    }

    private func dayAccessibilityLabel(_ dayPresentation: CalendarDayFocusPresentation) -> String {
        let count = entry.events.count(on: entry.date, calendar: calendar)
        let dayLabel = CalendarDayFocusAccessibility.label(
            dateLabel: dayPresentation.accessibilityLabel,
            accessState: entry.configuration.showEvents ? entry.events.accessState : .disabled,
            eventCount: count
        )
        guard let nextEventText else { return dayLabel }
        return "\(dayLabel), \(nextEventText.accessibilityText)"
    }

    private func weekView(_ weekPresentation: CalendarWeekPresentation) -> some View {
        VStack(spacing: typography.verticalSpacing(family == .systemLarge ? 14 : 8)) {
            HStack {
                Text(weekPresentation.headerText)
                    .font(
                        typography.displayFont(
                            size: family == .systemLarge ? 22 : 14,
                            weight: .heavy,
                            fallback: .system(size: family == .systemLarge ? 22 : 14, weight: .heavy, design: .rounded)
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(typography.displayMinimumScaleFactor(0.7))
                    .padding(.vertical, typography.displayTextVerticalPadding)
                Spacer(minLength: typography.horizontalSpacing(4))
                eventAccessBadge
            }

            HStack(
                alignment: .top,
                spacing: typography.horizontalSpacing(family == .systemLarge ? 8 : 3)
            ) {
                ForEach(weekPresentation.days) { day in
                    weekDay(day)
                }
            }

            if showsNextEventLine {
                nextEventLine
            }
        }
    }

    private func weekDay(_ day: CalendarDayPresentation) -> some View {
        let eventCount = entry.events.count(on: day.date, calendar: calendar)
        let marker = CalendarDayMarkerPresentation(
            day: day,
            eventCount: eventCount,
            showsEventIndicators: entry.configuration.showEvents
                && entry.events.accessState == .available
        )
        return VStack(spacing: typography.verticalSpacing(family == .systemLarge ? 8 : 4)) {
            Text(day.weekdayText)
                .font(
                    typography.supportingFont(
                        size: family == .systemLarge ? 14 : 9,
                        weight: .bold,
                        fallback: .system(
                            size: family == .systemLarge ? 14 : 9,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
                .padding(.vertical, typography.supportingTextVerticalPadding)

            calendarDayMarker(
                marker,
                diameter: family == .systemLarge ? 43 : 27,
                fontSize: family == .systemLarge ? 30 : 17,
                dotSize: family == .systemLarge ? 4 : 3
            )

            if family == .systemLarge,
               entry.configuration.showEvents,
               entry.events.accessState == .available {
                Text(eventCount == 1 ? "1 event" : "\(eventCount) events")
                    .font(
                        typography.supportingFont(
                            size: 11,
                            weight: .semibold,
                            fallback: .caption2.weight(.semibold)
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
                    .padding(.vertical, typography.supportingTextVerticalPadding)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayAccessibilityLabel(day, eventCount: eventCount))
        .accessibilityAddTraits(day.isToday ? .isSelected : [])
    }

    private func monthView(_ monthPresentation: CalendarMonthPresentation) -> some View {
        VStack(spacing: typography.verticalSpacing(monthMetrics.sectionSpacing)) {
            monthHeader(monthPresentation)
            weekdayHeader(monthPresentation)
            monthGrid(monthPresentation)
            if showsNextEventLine {
                nextEventLine
            }
        }
    }

    private func monthHeader(_ monthPresentation: CalendarMonthPresentation) -> some View {
        HStack(spacing: typography.horizontalSpacing(4)) {
            Button(intent: PreviousCalendarMonthIntent()) {
                Image(systemName: "arrow.left")
                    .font(.system(size: monthMetrics.arrowSize, weight: .medium))
                    .frame(width: monthMetrics.dayCircleSize, height: monthMetrics.dayCircleSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Spacer(minLength: typography.horizontalSpacing(2))

            Button(intent: CurrentCalendarMonthIntent()) {
                Text(monthTitle(monthPresentation))
                    .font(
                        typography.displayFont(
                            size: monthMetrics.headerFontSize,
                            weight: .heavy,
                            fallback: .system(size: monthMetrics.headerFontSize, weight: .heavy, design: .rounded)
                        )
                    )
                    .tracking(monthMetrics.usesCompactMonth ? 0.2 : 0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(typography.displayMinimumScaleFactor(0.72))
                    .padding(.vertical, typography.displayTextVerticalPadding)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(monthPresentation.accessibilityLabel), show current month")

            Spacer(minLength: typography.horizontalSpacing(2))
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

    private func monthTitle(_ monthPresentation: CalendarMonthPresentation) -> String {
        let month = monthMetrics.usesCompactMonth
            ? monthPresentation.abbreviatedMonthText
            : monthPresentation.monthText
        return "\(month)   \(monthPresentation.yearText)"
    }

    private func weekdayHeader(_ monthPresentation: CalendarMonthPresentation) -> some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(Array(monthWeekdayTexts(monthPresentation).enumerated()), id: \.offset) { _, weekday in
                Text(weekday)
                    .font(
                        typography.supportingFont(
                            size: monthMetrics.weekdayFontSize,
                            weight: .bold,
                            fallback: .system(
                                size: monthMetrics.weekdayFontSize,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
                    .padding(.vertical, typography.supportingTextVerticalPadding)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
    }

    private func monthWeekdayTexts(_ monthPresentation: CalendarMonthPresentation) -> [String] {
        monthMetrics.usesCompactWeekdays
            ? monthPresentation.compactWeekdayTexts
            : monthPresentation.weekdayTexts
    }

    private func monthGrid(_ monthPresentation: CalendarMonthPresentation) -> some View {
        LazyVGrid(columns: columns, spacing: typography.verticalSpacing(monthMetrics.rowSpacing)) {
            ForEach(monthPresentation.days) { day in
                monthDay(day)
            }
        }
    }

    private func monthDay(_ day: CalendarDayPresentation) -> some View {
        let eventCount = entry.events.count(on: day.date, calendar: calendar)
        let marker = CalendarDayMarkerPresentation(
            day: day,
            eventCount: eventCount,
            showsEventIndicators: entry.configuration.showEvents
                && entry.events.accessState == .available
        )
        return calendarDayMarker(
            marker,
            diameter: monthMetrics.dayCircleSize,
            fontSize: monthMetrics.dayFontSize,
            dotSize: family == .systemLarge ? 3 : 2
        )
        .frame(maxWidth: .infinity)
        .opacity(day.isInDisplayedMonth || day.isToday ? 1 : 0.38)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayAccessibilityLabel(day, eventCount: eventCount))
        .accessibilityAddTraits(day.isToday ? .isSelected : [])
    }

    private func calendarDayMarker(
        _ marker: CalendarDayMarkerPresentation,
        diameter: CGFloat,
        fontSize: CGFloat,
        dotSize: CGFloat
    ) -> some View {
        Group {
            if marker.isToday {
                todayMarker(
                    marker,
                    diameter: diameter,
                    fontSize: fontSize,
                    dotSize: dotSize
                )
            } else {
                regularDayMarker(
                    marker,
                    diameter: diameter,
                    fontSize: fontSize,
                    dotSize: dotSize
                )
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private func regularDayMarker(
        _ marker: CalendarDayMarkerPresentation,
        diameter: CGFloat,
        fontSize: CGFloat,
        dotSize: CGFloat
    ) -> some View {
        Text(marker.dayText)
            .font(
                typography.supportingFont(
                    size: fontSize,
                    weight: .bold,
                    fallback: .system(size: fontSize, weight: .bold, design: .rounded)
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
            .foregroundStyle(renderingMode == .fullColor ? Color.white : Color.primary)
            .offset(y: marker.eventDotCount > 0 ? -(dotSize * 0.55) : 0)
            .frame(width: diameter, height: diameter)
            .overlay(alignment: .bottom) {
                markerEventDots(
                    marker,
                    color: renderingMode == .fullColor ? .white : .primary,
                    size: dotSize
                )
            }
    }

    @ViewBuilder
    private func todayMarker(
        _ marker: CalendarDayMarkerPresentation,
        diameter: CGFloat,
        fontSize: CGFloat,
        dotSize: CGFloat
    ) -> some View {
        switch CalendarTodayMarkerStyle(renderingMode: renderingMode) {
        case .filled:
            Circle()
                .fill(.white)
                .overlay {
                    Text(marker.dayText)
                        .font(
                            typography.supportingFont(
                                size: fontSize,
                                weight: .bold,
                                fallback: .system(size: fontSize, weight: .bold, design: .rounded)
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
                        .foregroundStyle(.black)
                        .offset(y: marker.eventDotCount > 0 ? -(dotSize * 0.55) : 0)
                }
                .overlay(alignment: .bottom) {
                    markerEventDots(marker, color: .black, size: dotSize)
                }
                .frame(width: diameter, height: diameter)
        case .outlined:
            Circle()
                .stroke(Color.primary, lineWidth: max(1.5, diameter * 0.07))
                .overlay {
                    Text(marker.dayText)
                        .font(
                            typography.supportingFont(
                                size: fontSize,
                                weight: .bold,
                                fallback: .system(size: fontSize, weight: .bold, design: .rounded)
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(typography.supportingMinimumScaleFactor(0.65))
                        .foregroundStyle(Color.primary)
                        .offset(y: marker.eventDotCount > 0 ? -(dotSize * 0.55) : 0)
                }
                .overlay(alignment: .bottom) {
                    markerEventDots(marker, color: .primary, size: dotSize)
                }
                .frame(width: diameter, height: diameter)
        }
    }

    private func markerEventDots(
        _ marker: CalendarDayMarkerPresentation,
        color: Color,
        size: CGFloat
    ) -> some View {
        eventDots(count: marker.eventDotCount, color: color, size: size)
            .padding(.bottom, max(1, size * 0.35))
            .zIndex(2)
    }

    @ViewBuilder
    private func eventDots(count: Int, color: Color, size: CGFloat) -> some View {
        if count > 0 {
            HStack(spacing: 1) {
                ForEach(0..<min(count, 3), id: \.self) { _ in
                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                }
            }
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var eventAccessBadge: some View {
        if entry.configuration.showEvents || entry.configuration.showNextEventTime {
            switch entry.events.accessState {
            case .requiresPermission, .denied:
                WidgetStatusBadge(
                    systemImage: "calendar.badge.exclamationmark",
                    accessibilityText: entry.events.accessState == .requiresPermission
                        ? "Enable Calendar access in the Desktop Widgets app"
                        : "Calendar access is turned off"
                )
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var nextEventLine: some View {
        if let nextEventText {
            WidgetStatusLine(
                text: nextEventText.displayText,
                systemImage: "calendar.badge.clock",
                accessibilityText: nextEventText.accessibilityText,
                typography: typography
            )
        }
    }

    private func dayAccessibilityLabel(
        _ day: CalendarDayPresentation,
        eventCount: Int
    ) -> String {
        guard entry.configuration.showEvents,
              entry.events.accessState == .available else { return day.accessibilityLabel }
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
        .description("A configurable calendar with private event counts and next-event timing.")
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
