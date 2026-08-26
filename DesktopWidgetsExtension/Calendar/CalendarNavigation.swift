import AppIntents
import Foundation
import WidgetKit

enum CalendarNavigationStore {
    static let minimumMonthOffset = -120
    static let maximumMonthOffset = 120

    private static let monthOffsetKey = "calendar.displayedMonthOffset"
    private static let displayedMonthAnchorKey = "calendar.displayedMonthAnchor"

    static func monthOffset(
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        defaults: UserDefaults = .standard
    ) -> Int {
        let currentAnchor = monthAnchor(for: referenceDate, calendar: calendar)

        if let displayedAnchor = defaults.object(forKey: displayedMonthAnchorKey) as? Date {
            let rawOffset = calendar.dateComponents(
                [.month],
                from: currentAnchor,
                to: displayedAnchor
            ).month ?? 0
            let offset = clamped(rawOffset)
            if offset != rawOffset {
                persistDisplayedMonth(
                    offset: offset,
                    currentAnchor: currentAnchor,
                    calendar: calendar,
                    defaults: defaults
                )
            }
            return offset
        }

        let legacyOffset = clamped(defaults.integer(forKey: monthOffsetKey))
        if defaults.object(forKey: monthOffsetKey) != nil {
            persistDisplayedMonth(
                offset: legacyOffset,
                currentAnchor: currentAnchor,
                calendar: calendar,
                defaults: defaults
            )
        }
        return legacyOffset
    }

    @discardableResult
    static func shiftMonth(
        by delta: Int,
        referenceDate: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        defaults: UserDefaults = .standard
    ) -> Int {
        let currentAnchor = monthAnchor(for: referenceDate, calendar: calendar)
        let newOffset = clamped(monthOffset(
            referenceDate: referenceDate,
            calendar: calendar,
            defaults: defaults
        ) + delta)
        persistDisplayedMonth(
            offset: newOffset,
            currentAnchor: currentAnchor,
            calendar: calendar,
            defaults: defaults
        )
        return newOffset
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: monthOffsetKey)
        defaults.removeObject(forKey: displayedMonthAnchorKey)
    }

    private static func clamped(_ offset: Int) -> Int {
        min(maximumMonthOffset, max(minimumMonthOffset, offset))
    }

    private static func monthAnchor(for date: Date, calendar: Calendar) -> Date {
        let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
        return calendar.date(byAdding: .day, value: 14, to: monthStart) ?? monthStart
    }

    private static func persistDisplayedMonth(
        offset: Int,
        currentAnchor: Date,
        calendar: Calendar,
        defaults: UserDefaults
    ) {
        let displayedAnchor = calendar.date(
            byAdding: .month,
            value: offset,
            to: currentAnchor
        ) ?? currentAnchor
        defaults.set(displayedAnchor, forKey: displayedMonthAnchorKey)
        defaults.set(offset, forKey: monthOffsetKey)
    }
}

struct PreviousCalendarMonthIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Previous Calendar Month"
    static let description = IntentDescription("Move the Calendar widget back by one month.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        CalendarNavigationStore.shiftMonth(by: -1)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetIdentifier.calendar.rawValue)
        return .result()
    }
}

struct NextCalendarMonthIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Next Calendar Month"
    static let description = IntentDescription("Move the Calendar widget forward by one month.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        CalendarNavigationStore.shiftMonth(by: 1)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetIdentifier.calendar.rawValue)
        return .result()
    }
}

struct CurrentCalendarMonthIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Current Calendar Month"
    static let description = IntentDescription("Return the Calendar widget to the current month.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        CalendarNavigationStore.reset()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetIdentifier.calendar.rawValue)
        return .result()
    }
}
