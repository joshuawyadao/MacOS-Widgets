import AppIntents
import Foundation
import WidgetKit

enum CalendarNavigationStore {
    static let minimumMonthOffset = -120
    static let maximumMonthOffset = 120

    private static let monthOffsetKey = "calendar.displayedMonthOffset"

    static func monthOffset(defaults: UserDefaults = .standard) -> Int {
        clamped(defaults.integer(forKey: monthOffsetKey))
    }

    @discardableResult
    static func shiftMonth(by delta: Int, defaults: UserDefaults = .standard) -> Int {
        let newOffset = clamped(monthOffset(defaults: defaults) + delta)
        defaults.set(newOffset, forKey: monthOffsetKey)
        return newOffset
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: monthOffsetKey)
    }

    private static func clamped(_ offset: Int) -> Int {
        min(maximumMonthOffset, max(minimumMonthOffset, offset))
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
