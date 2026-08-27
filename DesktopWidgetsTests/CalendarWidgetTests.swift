import Foundation
import WidgetKit
import XCTest

final class CalendarWidgetTests: XCTestCase {
    func testAutomaticConfigurationUsesDayWeekAndMonthByFamily() {
        let configuration = CalendarConfigurationIntent()

        XCTAssertEqual(configuration.resolvedViewMode, .automatic)
        XCTAssertFalse(configuration.showEvents)
        XCTAssertFalse(configuration.showNextEventTime)
        XCTAssertEqual(configuration.resolvedView(for: .systemSmall), .day)
        XCTAssertEqual(configuration.resolvedView(for: .systemMedium), .week)
        XCTAssertEqual(configuration.resolvedView(for: .systemLarge), .month)
    }

    func testExplicitViewsOverrideEveryFamilyAndUnknownValuesFallBack() {
        let configuration = CalendarConfigurationIntent()

        for mode in [CalendarViewMode.day, .week, .month] {
            configuration.viewMode = mode.rawValue
            for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
                XCTAssertEqual(
                    configuration.resolvedView(for: family),
                    mode == .day ? .day : (mode == .week ? .week : .month)
                )
            }
        }

        configuration.viewMode = "unknown"
        XCTAssertEqual(configuration.resolvedViewMode, .automatic)
    }

    func testCalendarViewOptionsExposeStableChoicesAndDefault() async throws {
        let provider = CalendarViewModeOptionsProvider()
        let results = try await provider.results()
        let defaultResult = await provider.defaultResult()

        XCTAssertEqual(Set(results.items), Set(CalendarViewMode.allCases.map(\.rawValue)))
        XCTAssertEqual(defaultResult, CalendarViewMode.automatic.rawValue)
    }

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

    func testDayAndWeekPresentationsUseFocusedFamilyContent() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))

        let day = CalendarDayFocusPresentation(
            date: date,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(day.weekdayText, "SUNDAY")
        XCTAssertEqual(day.dayText, "9")
        XCTAssertEqual(day.monthYearText, "AUGUST 2026")

        let week = CalendarWeekPresentation(
            date: date,
            today: date,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
        XCTAssertEqual(week.days.count, 7)
        XCTAssertEqual(week.days.map(\.dayText), ["9", "10", "11", "12", "13", "14", "15"])
        XCTAssertEqual(week.days.map(\.weekdayText), ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"])
        XCTAssertEqual(week.days.filter(\.isToday).count, 1)
    }

    func testWeekAndMonthDayNumeralsRespectTheLocale() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))
        let locale = Locale(identifier: "ar_SA")

        let week = CalendarWeekPresentation(
            date: date,
            today: date,
            calendar: calendar,
            locale: locale
        )
        let month = CalendarMonthPresentation(
            displayDate: date,
            today: date,
            calendar: calendar,
            locale: locale
        )

        XCTAssertEqual(week.days.first(where: \.isToday)?.dayText, "٩")
        XCTAssertEqual(month.days.first(where: \.isToday)?.dayText, "٩")
    }

    func testTodayMarkerKeepsDateTextWhenEventDotsAreVisible() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))
        let week = CalendarWeekPresentation(
            date: date,
            today: date,
            calendar: calendar,
            locale: Locale(identifier: "en_US")
        )
        let today = try XCTUnwrap(week.days.first(where: \.isToday))

        let busyMarker = CalendarDayMarkerPresentation(
            day: today,
            eventCount: 5,
            showsEventIndicators: true
        )
        XCTAssertEqual(busyMarker.dayText, "9")
        XCTAssertTrue(busyMarker.isToday)
        XCTAssertEqual(busyMarker.eventDotCount, 3)

        let hiddenMarker = CalendarDayMarkerPresentation(
            day: today,
            eventCount: 2,
            showsEventIndicators: false
        )
        XCTAssertEqual(hiddenMarker.dayText, "9")
        XCTAssertEqual(hiddenMarker.eventDotCount, 0)

        XCTAssertEqual(CalendarTodayMarkerStyle(renderingMode: .fullColor), .filled)
        XCTAssertEqual(CalendarTodayMarkerStyle(renderingMode: .vibrant), .outlined)
        XCTAssertEqual(CalendarTodayMarkerStyle(renderingMode: .accented), .outlined)
    }

    func testDayAccessibilityLabelDescribesEveryEventAccessState() {
        let dateLabel = "Sunday, August 9, 2026"

        XCTAssertEqual(
            CalendarDayFocusAccessibility.label(
                dateLabel: dateLabel,
                accessState: .disabled,
                eventCount: 0
            ),
            dateLabel
        )
        XCTAssertEqual(
            CalendarDayFocusAccessibility.label(
                dateLabel: dateLabel,
                accessState: .available,
                eventCount: 1
            ),
            "Sunday, August 9, 2026, 1 event"
        )
        XCTAssertEqual(
            CalendarDayFocusAccessibility.label(
                dateLabel: dateLabel,
                accessState: .requiresPermission,
                eventCount: 0
            ),
            "Sunday, August 9, 2026, Enable Calendar access in the Desktop Widgets app"
        )
        XCTAssertEqual(
            CalendarDayFocusAccessibility.label(
                dateLabel: dateLabel,
                accessState: .denied,
                eventCount: 0
            ),
            "Sunday, August 9, 2026, Calendar access is turned off"
        )
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

    func testLeapMonthDoesNotIncludeTheRegularMonthWithTheSameNumber() throws {
        let gregorian = gregorianCalendar(firstWeekday: 1)
        let regularFourthMonthDate = try XCTUnwrap(gregorian.date(from: DateComponents(
            year: 2020,
            month: 5,
            day: 22
        )))
        let leapFourthMonthDate = try XCTUnwrap(gregorian.date(from: DateComponents(
            year: 2020,
            month: 5,
            day: 23
        )))

        var chinese = Calendar(identifier: .chinese)
        chinese.locale = Locale(identifier: "en_US")
        chinese.timeZone = TimeZone(secondsFromGMT: 0)!
        chinese.firstWeekday = 1

        XCTAssertEqual(chinese.component(.month, from: regularFourthMonthDate), 4)
        XCTAssertEqual(chinese.component(.month, from: leapFourthMonthDate), 4)
        XCTAssertFalse(chinese.dateComponents([.isLeapMonth], from: regularFourthMonthDate).isLeapMonth ?? true)
        XCTAssertTrue(chinese.dateComponents([.isLeapMonth], from: leapFourthMonthDate).isLeapMonth ?? false)

        let presentation = CalendarMonthPresentation(
            displayDate: leapFourthMonthDate,
            today: leapFourthMonthDate,
            calendar: chinese,
            locale: Locale(identifier: "en_US")
        )
        let regularMonthCell = try XCTUnwrap(presentation.days.first {
            chinese.isDate($0.date, inSameDayAs: regularFourthMonthDate)
        })
        let leapMonthCell = try XCTUnwrap(presentation.days.first {
            chinese.isDate($0.date, inSameDayAs: leapFourthMonthDate)
        })

        XCTAssertFalse(regularMonthCell.isInDisplayedMonth)
        XCTAssertTrue(leapMonthCell.isInDisplayedMonth)
    }

    func testNavigationPersistsAndClampsMonthOffset() throws {
        let suiteName = "CalendarWidgetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let calendar = gregorianCalendar(firstWeekday: 1)
        let august = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 31)))

        XCTAssertEqual(CalendarNavigationStore.monthOffset(referenceDate: august, calendar: calendar, defaults: defaults), 0)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: 1, referenceDate: august, calendar: calendar, defaults: defaults), 1)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: -2, referenceDate: august, calendar: calendar, defaults: defaults), -1)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: 1_000, referenceDate: august, calendar: calendar, defaults: defaults), 120)
        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: -1_000, referenceDate: august, calendar: calendar, defaults: defaults), -120)

        CalendarNavigationStore.reset(defaults: defaults)
        XCTAssertEqual(CalendarNavigationStore.monthOffset(referenceDate: august, calendar: calendar, defaults: defaults), 0)
    }

    func testNavigationKeepsDisplayedMonthStableWhenCurrentMonthChanges() throws {
        let suiteName = "CalendarWidgetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let calendar = gregorianCalendar(firstWeekday: 1)
        let august = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 31)))
        let september = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))

        XCTAssertEqual(CalendarNavigationStore.shiftMonth(by: 1, referenceDate: august, calendar: calendar, defaults: defaults), 1)
        XCTAssertEqual(CalendarNavigationStore.monthOffset(referenceDate: september, calendar: calendar, defaults: defaults), 0)
    }

    func testEventCounterMarksEveryOverlappingDayWithoutCountingMidnightEnd() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let queryStart = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))
        let queryEnd = try XCTUnwrap(calendar.date(byAdding: .day, value: 4, to: queryStart))
        let noon = try XCTUnwrap(calendar.date(byAdding: .hour, value: 12, to: queryStart))
        let nextMidnight = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: queryStart))
        let thirdDayNoon = try XCTUnwrap(calendar.date(byAdding: .hour, value: 60, to: queryStart))

        let counts = CalendarEventCounter.counts(
            for: [
                CalendarEventInterval(start: noon, end: nextMidnight),
                CalendarEventInterval(start: noon, end: thirdDayNoon),
            ],
            within: DateInterval(start: queryStart, end: queryEnd),
            calendar: calendar
        )

        XCTAssertEqual(counts[queryStart], 2)
        XCTAssertEqual(counts[nextMidnight], 1)
        let thirdDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 2, to: queryStart))
        XCTAssertEqual(counts[thirdDay], 1)
    }

    func testEventSnapshotSeparatesDisabledPermissionAndAvailableStates() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))

        XCTAssertEqual(CalendarEventSnapshot.disabled.accessState, .disabled)
        XCTAssertEqual(CalendarEventSnapshot.disabled.count(on: date, calendar: calendar), 0)

        let available = CalendarEventSnapshot(accessState: .available, countsByDay: [date: 3])
        XCTAssertEqual(available.count(on: date, calendar: calendar), 3)
        XCTAssertEqual(CalendarEventSnapshot(accessState: .requiresPermission, countsByDay: [:]).accessState, .requiresPermission)
        XCTAssertEqual(CalendarEventSnapshot(accessState: .denied, countsByDay: [:]).accessState, .denied)
    }

    func testNextEventTimingIgnoresAllDayAndEndedEventsWithoutReadingEventText() throws {
        let reference = Date(timeIntervalSince1970: 1_786_262_940)
        let query = DateInterval(start: reference, duration: 7 * 86_400)
        let ended = CalendarEventInterval(
            start: reference.addingTimeInterval(-7_200),
            end: reference.addingTimeInterval(-3_600)
        )
        let allDay = CalendarEventInterval(
            start: reference.addingTimeInterval(3_600),
            end: reference.addingTimeInterval(86_400),
            isAllDay: true
        )
        let upcoming = CalendarEventInterval(
            start: reference.addingTimeInterval(7_200),
            end: reference.addingTimeInterval(10_800)
        )

        let timing = try XCTUnwrap(CalendarEventCounter.nextTiming(
            for: [allDay, upcoming, ended],
            after: reference,
            within: query
        ))

        XCTAssertEqual(timing.start, upcoming.start)
        XCTAssertFalse(timing.isOngoing)
    }

    func testNextEventTimingPrefersAnOngoingTimedEvent() throws {
        let reference = Date(timeIntervalSince1970: 1_786_262_940)
        let query = DateInterval(start: reference, duration: 7 * 86_400)
        let upcoming = CalendarEventInterval(
            start: reference.addingTimeInterval(3_600),
            end: reference.addingTimeInterval(7_200)
        )
        let ongoing = CalendarEventInterval(
            start: reference.addingTimeInterval(-1_800),
            end: reference.addingTimeInterval(1_800)
        )

        let timing = try XCTUnwrap(CalendarEventCounter.nextTiming(
            for: [upcoming, ongoing],
            after: reference,
            within: query
        ))

        XCTAssertEqual(timing.start, ongoing.start)
        XCTAssertTrue(timing.isOngoing)
    }

    func testNextEventTimeCanBeEnabledWithoutEventIndicators() {
        let configuration = CalendarConfigurationIntent()
        configuration.showEvents = false
        configuration.showNextEventTime = true

        XCTAssertFalse(configuration.showEvents)
        XCTAssertTrue(configuration.showNextEventTime)
    }

    func testDisplayIntervalsMatchDayWeekAndSixWeekMonthBudgets() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 9)))

        XCTAssertEqual(CalendarDisplayInterval.interval(for: .day, date: date, monthOffset: 0, calendar: calendar).duration, 86_400)
        XCTAssertEqual(CalendarDisplayInterval.interval(for: .week, date: date, monthOffset: 0, calendar: calendar).duration, 7 * 86_400)
        XCTAssertEqual(CalendarDisplayInterval.interval(for: .month, date: date, monthOffset: 0, calendar: calendar).duration, 42 * 86_400)
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

        XCTAssertEqual(
            CalendarTimelinePolicy.nextRefresh(after: date, calendar: calendar, eventsEnabled: true),
            date.addingTimeInterval(30 * 60)
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
