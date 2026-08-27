import EventKit
import Foundation

enum CalendarEventAccessState: Equatable, Sendable {
    case disabled
    case requiresPermission
    case denied
    case available
}

struct CalendarEventInterval: Equatable, Sendable {
    let start: Date
    let end: Date
    let isAllDay: Bool

    init(start: Date, end: Date, isAllDay: Bool = false) {
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
    }
}

struct CalendarNextEventTiming: Equatable, Sendable {
    let start: Date
    let isOngoing: Bool
}

struct CalendarEventSnapshot: Equatable, Sendable {
    let accessState: CalendarEventAccessState
    let countsByDay: [Date: Int]
    let nextEvent: CalendarNextEventTiming?

    init(
        accessState: CalendarEventAccessState,
        countsByDay: [Date: Int],
        nextEvent: CalendarNextEventTiming? = nil
    ) {
        self.accessState = accessState
        self.countsByDay = countsByDay
        self.nextEvent = nextEvent
    }

    static let disabled = CalendarEventSnapshot(accessState: .disabled, countsByDay: [:])

    func count(on date: Date, calendar: Calendar) -> Int {
        countsByDay[calendar.startOfDay(for: date), default: 0]
    }

    static func sample(referenceDate: Date, calendar: Calendar) -> Self {
        let day = calendar.startOfDay(for: referenceDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        let later = calendar.date(byAdding: .day, value: 3, to: day) ?? day
        return CalendarEventSnapshot(
            accessState: .available,
            countsByDay: [day: 2, tomorrow: 1, later: 3],
            nextEvent: CalendarNextEventTiming(
                start: calendar.date(byAdding: .hour, value: 3, to: referenceDate) ?? referenceDate,
                isOngoing: false
            )
        )
    }
}

enum CalendarEventCounter {
    static func counts(
        for intervals: [CalendarEventInterval],
        within query: DateInterval,
        calendar: Calendar
    ) -> [Date: Int] {
        var counts: [Date: Int] = [:]

        for interval in intervals {
            let clippedStart = max(interval.start, query.start)
            let clippedEnd = min(interval.end, query.end)
            guard clippedStart < clippedEnd else { continue }

            var day = calendar.startOfDay(for: clippedStart)
            while day < clippedEnd && day < query.end {
                counts[day, default: 0] += 1
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day), nextDay > day else {
                    break
                }
                day = nextDay
            }
        }

        return counts
    }

    static func nextTiming(
        for intervals: [CalendarEventInterval],
        after referenceDate: Date,
        within query: DateInterval
    ) -> CalendarNextEventTiming? {
        intervals
            .filter { !$0.isAllDay && $0.end > referenceDate && $0.start < query.end }
            .sorted { $0.start < $1.start }
            .first
            .map {
                CalendarNextEventTiming(
                    start: $0.start,
                    isOngoing: $0.start <= referenceDate
                )
            }
    }
}

struct SystemCalendarEventReader {
    func snapshot(
        in interval: DateInterval,
        upcomingWithin upcomingInterval: DateInterval? = nil,
        calendar: Calendar,
        enabled: Bool,
        referenceDate: Date
    ) -> CalendarEventSnapshot {
        guard enabled else { return .disabled }

        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            let store = EKEventStore()
            let predicate = store.predicateForEvents(
                withStart: interval.start,
                end: interval.end,
                calendars: nil
            )
            let eventIntervals = store.events(matching: predicate).map {
                CalendarEventInterval(
                    start: $0.startDate,
                    end: $0.endDate,
                    isAllDay: $0.isAllDay
                )
            }
            let upcomingEventIntervals: [CalendarEventInterval]
            if let upcomingInterval, upcomingInterval != interval {
                let upcomingPredicate = store.predicateForEvents(
                    withStart: upcomingInterval.start,
                    end: upcomingInterval.end,
                    calendars: nil
                )
                upcomingEventIntervals = store.events(matching: upcomingPredicate).map {
                    CalendarEventInterval(
                        start: $0.startDate,
                        end: $0.endDate,
                        isAllDay: $0.isAllDay
                    )
                }
            } else {
                upcomingEventIntervals = eventIntervals
            }
            return CalendarEventSnapshot(
                accessState: .available,
                countsByDay: CalendarEventCounter.counts(
                    for: eventIntervals,
                    within: interval,
                    calendar: calendar
                ),
                nextEvent: CalendarEventCounter.nextTiming(
                    for: upcomingEventIntervals,
                    after: referenceDate,
                    within: upcomingInterval ?? interval
                )
            )
        case .notDetermined:
            return CalendarEventSnapshot(accessState: .requiresPermission, countsByDay: [:])
        default:
            return CalendarEventSnapshot(accessState: .denied, countsByDay: [:])
        }
    }
}
