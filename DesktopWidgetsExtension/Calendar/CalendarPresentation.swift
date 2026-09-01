import Foundation
import WidgetKit

struct CalendarDayPresentation: Equatable, Identifiable, Sendable {
    let id: Int
    let date: Date
    let weekdayText: String
    let dayText: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let accessibilityLabel: String
}

struct CalendarDayMarkerPresentation: Equatable, Sendable {
    let dayText: String
    let isToday: Bool
    let eventDotCount: Int

    init(
        day: CalendarDayPresentation,
        eventCount: Int,
        showsEventIndicators: Bool
    ) {
        dayText = day.dayText
        isToday = day.isToday
        eventDotCount = showsEventIndicators ? min(max(eventCount, 0), 3) : 0
    }
}

enum CalendarDayFocusAccessibility {
    static func label(
        dateLabel: String,
        accessState: CalendarEventAccessState,
        eventCount: Int
    ) -> String {
        switch accessState {
        case .disabled:
            return dateLabel
        case .available:
            return "\(dateLabel), \(eventCount) \(eventCount == 1 ? "event" : "events")"
        case .requiresPermission:
            return "\(dateLabel), Enable Calendar access in the Desktop Widgets app"
        case .denied:
            return "\(dateLabel), Calendar access is turned off"
        }
    }
}

enum CalendarTodayMarkerStyle: Equatable, Sendable {
    case filled
    case outlined

    init(renderingMode: WidgetRenderingMode) {
        self = renderingMode == .fullColor ? .filled : .outlined
    }
}

struct CalendarDayFocusPresentation: Equatable, Sendable {
    let weekdayText: String
    let dayText: String
    let monthYearText: String
    let accessibilityLabel: String

    init(date: Date, calendar: Calendar, locale: Locale) {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone

        formatter.dateFormat = "EEEE"
        weekdayText = formatter.string(from: date).uppercased(with: locale)
        formatter.dateFormat = "d"
        dayText = formatter.string(from: date)
        formatter.dateFormat = "MMMM yyyy"
        monthYearText = formatter.string(from: date).uppercased(with: locale)
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        accessibilityLabel = formatter.string(from: date)
    }
}

struct CalendarWeekPresentation: Equatable, Sendable {
    let headerText: String
    let days: [CalendarDayPresentation]
    let accessibilityLabel: String

    init(date: Date, today: Date, calendar: Calendar, locale: Locale) {
        let interval = CalendarDisplayInterval.week(containing: date, calendar: calendar)
        let endDate = calendar.date(byAdding: .day, value: 6, to: interval.start) ?? interval.start
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        if calendar.isDate(interval.start, equalTo: endDate, toGranularity: .month) {
            formatter.dateFormat = "MMMM yyyy"
            headerText = formatter.string(from: interval.start).uppercased(with: locale)
        } else {
            formatter.dateFormat = "MMM d"
            let startText = formatter.string(from: interval.start)
            formatter.dateFormat = "MMM d, yyyy"
            let endText = formatter.string(from: endDate)
            headerText = "\(startText) – \(endText)".uppercased(with: locale)
        }

        days = (0..<7).map { position in
            let day = calendar.date(byAdding: .day, value: position, to: interval.start) ?? interval.start
            let isToday = calendar.isDate(day, inSameDayAs: today)
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            var label = formatter.string(from: day)
            if isToday { label += ", Today" }
            formatter.dateFormat = "EEE"
            let weekday = formatter.string(from: day)
            formatter.dateFormat = "d"
            let dayText = formatter.string(from: day)

            return CalendarDayPresentation(
                id: position,
                date: day,
                weekdayText: weekday.uppercased(with: locale),
                dayText: dayText,
                isInDisplayedMonth: true,
                isToday: isToday,
                accessibilityLabel: "\(weekday), \(label)"
            )
        }
        accessibilityLabel = "Week of \(days.first?.accessibilityLabel ?? headerText)"
    }
}

struct CalendarMonthPresentation: Equatable, Sendable {
    let monthText: String
    let abbreviatedMonthText: String
    let yearText: String
    let weekdayTexts: [String]
    let compactWeekdayTexts: [String]
    let days: [CalendarDayPresentation]
    let accessibilityLabel: String

    init(
        displayDate: Date,
        today: Date,
        calendar sourceCalendar: Calendar,
        locale: Locale
    ) {
        var calendar = sourceCalendar
        calendar.locale = locale

        let displayComponents = calendar.dateComponents([.era, .year, .month, .isLeapMonth], from: displayDate)
        let monthStart = calendar.date(from: displayComponents) ?? displayDate

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone

        formatter.dateFormat = "LLLL"
        monthText = formatter.string(from: monthStart).uppercased(with: locale)
        formatter.dateFormat = "LLL"
        abbreviatedMonthText = formatter.string(from: monthStart).uppercased(with: locale)
        formatter.dateFormat = "yyyy"
        yearText = formatter.string(from: monthStart)
        formatter.dateFormat = "LLLL yyyy"
        accessibilityLabel = formatter.string(from: monthStart)

        weekdayTexts = Self.rotatedWeekdaySymbols(
            formatter.shortStandaloneWeekdaySymbols,
            firstWeekday: calendar.firstWeekday
        )
        compactWeekdayTexts = Self.rotatedWeekdaySymbols(
            formatter.veryShortStandaloneWeekdaySymbols,
            firstWeekday: calendar.firstWeekday
        )

        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingDayCount = (weekday - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -leadingDayCount, to: monthStart) ?? monthStart

        days = (0..<42).map { position in
            let date = calendar.date(byAdding: .day, value: position, to: gridStart) ?? gridStart
            let components = calendar.dateComponents([.era, .year, .month, .day, .isLeapMonth], from: date)
            let isInDisplayedMonth = components.era == displayComponents.era
                && components.year == displayComponents.year
                && components.month == displayComponents.month
                && components.isLeapMonth == displayComponents.isLeapMonth
            let isToday = calendar.isDate(date, inSameDayAs: today)
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            var label = formatter.string(from: date)
            if isToday {
                label += ", Today"
            }
            formatter.dateFormat = "EEE"
            let weekdayText = formatter.string(from: date).uppercased(with: locale)
            formatter.dateFormat = "d"
            let dayText = formatter.string(from: date)

            return CalendarDayPresentation(
                id: position,
                date: date,
                weekdayText: weekdayText,
                dayText: dayText,
                isInDisplayedMonth: isInDisplayedMonth,
                isToday: isToday,
                accessibilityLabel: label
            )
        }
    }

    private static func rotatedWeekdaySymbols(
        _ symbols: [String],
        firstWeekday: Int
    ) -> [String] {
        guard symbols.count == 7 else { return symbols }
        let startIndex = max(0, min(6, firstWeekday - 1))
        return (0..<7).map { symbols[(startIndex + $0) % 7] }
    }
}

struct CalendarWidgetLayoutMetrics: Equatable, Sendable {
    let headerFontSize: CGFloat
    let weekdayFontSize: CGFloat
    let dayFontSize: CGFloat
    let arrowSize: CGFloat
    let dayCircleSize: CGFloat
    let sectionSpacing: CGFloat
    let rowSpacing: CGFloat
    let usesCompactMonth: Bool
    let usesCompactWeekdays: Bool

    init(family: WidgetFamily) {
        switch WidgetInformationDensity(family: family) {
        case .compact:
            headerFontSize = 11
            weekdayFontSize = 7.5
            dayFontSize = 9
            arrowSize = 11
            dayCircleSize = 14
            sectionSpacing = 2
            rowSpacing = 1
            usesCompactMonth = true
            usesCompactWeekdays = true
        case .expanded:
            headerFontSize = 20
            weekdayFontSize = 12
            dayFontSize = 16
            arrowSize = 20
            dayCircleSize = 29
            sectionSpacing = 9
            rowSpacing = 7
            usesCompactMonth = false
            usesCompactWeekdays = false
        case .standard:
            headerFontSize = 14
            weekdayFontSize = 9
            dayFontSize = 11
            arrowSize = 14
            dayCircleSize = 15
            sectionSpacing = 2
            rowSpacing = 1
            usesCompactMonth = false
            usesCompactWeekdays = false
        }
    }
}

enum CalendarTimelinePolicy {
    static func nextRefresh(
        after date: Date,
        calendar: Calendar,
        eventsEnabled: Bool = false,
        nextEvent: CalendarNextEventTiming? = nil
    ) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let midnight = calendar.date(byAdding: .day, value: 1, to: startOfDay)
            ?? date.addingTimeInterval(86_400)
        guard eventsEnabled else { return midnight }

        let periodicRefresh = min(midnight, date.addingTimeInterval(30 * 60))
        guard let nextEvent else { return periodicRefresh }
        let eventBoundary = nextEvent.isOngoing ? nextEvent.end : nextEvent.start
        guard eventBoundary > date else { return periodicRefresh }
        return min(periodicRefresh, eventBoundary)
    }
}

enum CalendarDisplayInterval {
    static func interval(
        for view: CalendarResolvedView,
        date: Date,
        monthOffset: Int,
        calendar: Calendar
    ) -> DateInterval {
        switch view {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
            return DateInterval(start: start, end: end)
        case .week:
            return week(containing: date, calendar: calendar)
        case .month:
            let shiftedDate = calendar.date(byAdding: .month, value: monthOffset, to: date) ?? date
            let components = calendar.dateComponents([.era, .year, .month], from: shiftedDate)
            let monthStart = calendar.date(from: components) ?? shiftedDate
            let weekday = calendar.component(.weekday, from: monthStart)
            let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
            let start = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) ?? monthStart
            let end = calendar.date(byAdding: .day, value: 42, to: start) ?? start.addingTimeInterval(42 * 86_400)
            return DateInterval(start: start, end: end)
        }
    }

    static func week(containing date: Date, calendar: Calendar) -> DateInterval {
        let dayStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dayStart)
        let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
        let start = calendar.date(byAdding: .day, value: -leadingDays, to: dayStart) ?? dayStart
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start.addingTimeInterval(7 * 86_400)
        return DateInterval(start: start, end: end)
    }
}
