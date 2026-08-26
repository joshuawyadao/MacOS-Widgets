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

struct CalendarDayFocusPresentation: Equatable, Sendable {
    let weekdayText: String
    let dayText: String
    let monthYearText: String
    let accessibilityLabel: String

    init(date: Date, calendar: Calendar, locale: Locale) {
        weekdayText = Self.formatted(date, pattern: "EEEE", calendar: calendar, locale: locale).uppercased(with: locale)
        dayText = Self.formatted(date, pattern: "d", calendar: calendar, locale: locale)
        monthYearText = Self.formatted(date, pattern: "MMMM yyyy", calendar: calendar, locale: locale).uppercased(with: locale)
        accessibilityLabel = Self.formatted(date, pattern: "EEEE, MMMM d, yyyy", calendar: calendar, locale: locale)
    }

    private static func formatted(
        _ date: Date,
        pattern: String,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
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
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.calendar = calendar
            weekdayFormatter.locale = locale
            weekdayFormatter.timeZone = calendar.timeZone
            weekdayFormatter.dateFormat = "EEE"
            let labelFormatter = DateFormatter()
            labelFormatter.calendar = calendar
            labelFormatter.locale = locale
            labelFormatter.timeZone = calendar.timeZone
            labelFormatter.dateFormat = "EEEE, MMMM d, yyyy"
            let isToday = calendar.isDate(day, inSameDayAs: today)
            var label = labelFormatter.string(from: day)
            if isToday { label += ", Today" }

            return CalendarDayPresentation(
                id: position,
                date: day,
                weekdayText: weekdayFormatter.string(from: day).uppercased(with: locale),
                dayText: String(calendar.component(.day, from: day)),
                isInDisplayedMonth: true,
                isToday: isToday,
                accessibilityLabel: "\(weekdayFormatter.string(from: day)), \(label)"
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

        let displayComponents = calendar.dateComponents([.era, .year, .month], from: displayDate)
        let monthStart = calendar.date(from: displayComponents) ?? displayDate

        monthText = Self.formatted(
            monthStart,
            pattern: "LLLL",
            calendar: calendar,
            locale: locale
        ).uppercased(with: locale)
        abbreviatedMonthText = Self.formatted(
            monthStart,
            pattern: "LLL",
            calendar: calendar,
            locale: locale
        ).uppercased(with: locale)
        yearText = Self.formatted(
            monthStart,
            pattern: "yyyy",
            calendar: calendar,
            locale: locale
        )
        accessibilityLabel = Self.formatted(
            monthStart,
            pattern: "LLLL yyyy",
            calendar: calendar,
            locale: locale
        )

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
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
            let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
            let isInDisplayedMonth = components.era == displayComponents.era
                && components.year == displayComponents.year
                && components.month == displayComponents.month
            let isToday = calendar.isDate(date, inSameDayAs: today)
            var label = Self.formatted(
                date,
                pattern: "EEEE, MMMM d, yyyy",
                calendar: calendar,
                locale: locale
            )
            if isToday {
                label += ", Today"
            }

            return CalendarDayPresentation(
                id: position,
                date: date,
                weekdayText: Self.formatted(
                    date,
                    pattern: "EEE",
                    calendar: calendar,
                    locale: locale
                ).uppercased(with: locale),
                dayText: String(components.day ?? 0),
                isInDisplayedMonth: isInDisplayedMonth,
                isToday: isToday,
                accessibilityLabel: label
            )
        }
    }

    private static func formatted(
        _ date: Date,
        pattern: String,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
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
        switch family {
        case .systemSmall:
            headerFontSize = 11
            weekdayFontSize = 7.5
            dayFontSize = 9
            arrowSize = 11
            dayCircleSize = 14
            sectionSpacing = 2
            rowSpacing = 1
            usesCompactMonth = true
            usesCompactWeekdays = true
        case .systemLarge:
            headerFontSize = 20
            weekdayFontSize = 12
            dayFontSize = 16
            arrowSize = 20
            dayCircleSize = 29
            sectionSpacing = 9
            rowSpacing = 7
            usesCompactMonth = false
            usesCompactWeekdays = false
        default:
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
        eventsEnabled: Bool = false
    ) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let midnight = calendar.date(byAdding: .day, value: 1, to: startOfDay)
            ?? date.addingTimeInterval(86_400)
        guard eventsEnabled else { return midnight }
        return min(midnight, date.addingTimeInterval(30 * 60))
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
