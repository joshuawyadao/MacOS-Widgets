import Foundation
import WidgetKit

struct CalendarDayPresentation: Equatable, Identifiable, Sendable {
    let id: Int
    let date: Date
    let dayText: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let accessibilityLabel: String
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
    static func nextRefresh(after date: Date, calendar: Calendar) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)
            ?? date.addingTimeInterval(86_400)
    }
}
