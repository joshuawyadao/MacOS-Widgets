import Foundation
import WidgetKit
import XCTest

final class CalendarWidgetTests: XCTestCase {
    func testAugust2026MatchesReferenceGridAndHighlightsTheNinth() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let referenceDate = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 9,
            hour: 12
        )))

        let presentation = CalendarMonthPresentation(
            displayDate: referenceDate,
            today: referenceDate,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(presentation.monthText, "AUGUST")
        XCTAssertEqual(presentation.abbreviatedMonthText, "AUG")
        XCTAssertEqual(presentation.yearText, "2026")
        XCTAssertEqual(presentation.weekdayTexts, ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        XCTAssertEqual(presentation.days.count, 42)
        XCTAssertEqual(presentation.days.first?.dayText, "26")
        XCTAssertEqual(presentation.days.last?.dayText, "5")
        XCTAssertEqual(presentation.days.filter(\.isInDisplayedMonth).count, 31)

        let today = try XCTUnwrap(presentation.days.first(where: \.isToday))
        XCTAssertEqual(today.dayText, "9")
        XCTAssertEqual(today.id, 14)
        XCTAssertEqual(today.accessibilityLabel, "Sunday, August 9, 2026, Today")
    }

    func testMondayFirstCalendarRotatesLabelsAndGridStart() throws {
        let calendar = gregorianCalendar(firstWeekday: 2)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))

        let presentation = CalendarMonthPresentation(
            displayDate: date,
            today: date,
            calendar: calendar,
            locale: Locale(identifier: "en_GB")
        )

        XCTAssertEqual(presentation.weekdayTexts, ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        XCTAssertEqual(presentation.days.first?.dayText, "27")
        XCTAssertEqual(presentation.days.first?.isInDisplayedMonth, false)
        XCTAssertEqual(presentation.days.first(where: \.isToday)?.id, 13)
    }

    func testLeapFebruaryIncludesAdjacentMonthDaysInSixStableRows() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2024, month: 2, day: 29)))

        let presentation = CalendarMonthPresentation(
            displayDate: date,
            today: date,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(presentation.days.count, 42)
        XCTAssertEqual(presentation.days.filter(\.isInDisplayedMonth).count, 29)
        XCTAssertEqual(presentation.days.first?.dayText, "28")
        XCTAssertEqual(presentation.days.last?.dayText, "9")
        XCTAssertEqual(presentation.days.first(where: \.isToday)?.dayText, "29")
    }

    func testNavigationPersistsAndClampsMonthOffset() throws {
        let suiteName = "CalendarWidgetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertEqual(CalendarNavigationStore.monthOffset(defaults: defaults), 0)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: 1, defaults: defaults), 1)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: -2, defaults: defaults), -1)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: 1_000, defaults: defaults), 120)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: -1_000, defaults: defaults), -120)

        CalendarNavigationStore.reset(defaults: defaults)
        XCTAssertEqual(CalendarNavigationStore.monthOffset(defaults: defaults), 0)
    }

    func testTimelineRefreshesAtNextLocalMidnightAcrossDST() throws {
        var calendar = gregorianCalendar(firstWeekday: 1)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 8,
            hour: 1,
            minute: 30
        )))

        let refresh = CalendarTimelinePolicy.nextRefresh(after: date, calendar: calendar)

        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day, .hour, .minute], from: refresh),
            DateComponents(year: 2026, month: 3, day: 9, hour: 0, minute: 0)
        )
    }

    func testFamilyMetricsKeepTheSmallGridCompactAndLargeGridReadable() {
        let small = CalendarWidgetLayoutMetrics(family: .systemSmall)
        let medium = CalendarWidgetLayoutMetrics(family: .systemMedium)
        let large = CalendarWidgetLayoutMetrics(family: .systemLarge)

        XCTAssertTrue(small.usesCompactMonth)
        XCTAssertTrue(small.usesCompactWeekdays)
        XCTAssertFalse(medium.usesCompactMonth)
        XCTAssertFalse(large.usesCompactWeekdays)
        XCTAssertLessThan(small.dayCircleSize, medium.dayCircleSize)
        XCTAssertLessThan(medium.dayCircleSize, large.dayCircleSize)
        XCTAssertLessThanOrEqual(small.rowSpacing * 5 + small.dayCircleSize * 6, 89)
        XCTAssertLessThanOrEqual(medium.rowSpacing * 5 + medium.dayCircleSize * 6, 95)
    }

    private func gregorianCalendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = firstWeekday
        return calendar
    }
}
