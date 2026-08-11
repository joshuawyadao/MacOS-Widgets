import AppIntents
import Foundation
import XCTest

final class TimeAndDateConfigurationTests: XCTestCase {
    private let locale = Locale(identifier: "en_US_POSIX")
    private let timeZone = TimeZone(secondsFromGMT: 0)!

    func testEveryDateStyleFormatsTheReferenceDate() {
        let date = makeDate(year: 2026, month: 8, day: 9, hour: 21, minute: 9)
        let expected: [TimeAndDateDateFormat: String] = [
            .reference: "SUNDAY  09 AUG",
            .monthFirstWords: "SUN AUG 09",
            .monthDayYear: "08/09/2026",
            .dayMonthYear: "09/08/2026",
            .iso: "2026-08-09",
        ]

        for format in TimeAndDateDateFormat.allCases {
            XCTAssertEqual(
                format.string(from: date, locale: locale, timeZone: timeZone),
                expected[format],
                "Unexpected output for \(format.rawValue)"
            )
        }
    }

    func testEveryClockStyleFormatsTheReferenceTime() {
        let date = makeDate(year: 2026, month: 8, day: 9, hour: 21, minute: 9)

        XCTAssertEqual(
            TimeAndDateTimeFormat.twelveHour.timeString(from: date, locale: locale, timeZone: timeZone),
            "09:09"
        )
        XCTAssertEqual(
            TimeAndDateTimeFormat.twelveHour.periodString(from: date, locale: locale, timeZone: timeZone),
            "PM"
        )
        XCTAssertEqual(
            TimeAndDateTimeFormat.twentyFourHour.timeString(from: date, locale: locale, timeZone: timeZone),
            "21:09"
        )
        XCTAssertNil(
            TimeAndDateTimeFormat.twentyFourHour.periodString(from: date, locale: locale, timeZone: timeZone)
        )
    }

    func testTwelveHourEditorExampleMatchesRenderedLeadingZero() {
        XCTAssertEqual(
            String(localized: TimeAndDateTimeFormat.twelveHour.displayName),
            "12-hour — 09:09 AM"
        )
    }

    func testUnknownAndMissingConfigurationIDsUseDocumentedDefaults() {
        for value in [nil, "unknown-choice"] {
            let configuration = TimeAndDateStringConfigurationIntent()
            configuration.layout = value
            configuration.dateFormat = value
            configuration.timeFormat = value
            configuration.dateFont = value
            configuration.timeFont = value

            XCTAssertEqual(configuration.resolvedLayout, .reference)
            XCTAssertEqual(configuration.resolvedDateFormat, .reference)
            XCTAssertEqual(configuration.resolvedTimeFormat, .twelveHour)
            XCTAssertEqual(configuration.resolvedDateFont, .systemBold)
            XCTAssertEqual(configuration.resolvedTimeFont, .noteworthy)
        }
    }

    func testTwoConfigurationsResolveIndependently() {
        let first = TimeAndDateStringConfigurationIntent.referencePreview()
        let second = TimeAndDateStringConfigurationIntent()
        second.layout = TimeAndDateLayout.inline.rawValue
        second.dateFormat = TimeAndDateDateFormat.iso.rawValue
        second.timeFormat = TimeAndDateTimeFormat.twentyFourHour.rawValue
        second.dateFont = TimeAndDateFont.snellRoundhand.rawValue
        second.timeFont = TimeAndDateFont.systemMonospaced.rawValue

        XCTAssertEqual(first.resolvedLayout, .reference)
        XCTAssertEqual(first.resolvedTimeFormat, .twelveHour)
        XCTAssertEqual(second.resolvedLayout, .inline)
        XCTAssertEqual(second.resolvedDateFormat, .iso)
        XCTAssertEqual(second.resolvedTimeFormat, .twentyFourHour)
        XCTAssertEqual(second.resolvedDateFont, .snellRoundhand)
        XCTAssertEqual(second.resolvedTimeFont, .systemMonospaced)
    }

    func testEveryOptionsProviderReturnsAllStableIDsAndAValidDefault() async throws {
        try await assertProvider(
            results: try await TimeAndDateLayoutOptionsProvider().results(),
            defaultResult: await TimeAndDateLayoutOptionsProvider().defaultResult(),
            expected: TimeAndDateLayout.allCases.map(\.rawValue)
        )
        try await assertProvider(
            results: try await TimeAndDateDateFormatOptionsProvider().results(),
            defaultResult: await TimeAndDateDateFormatOptionsProvider().defaultResult(),
            expected: TimeAndDateDateFormat.allCases.map(\.rawValue)
        )
        try await assertProvider(
            results: try await TimeAndDateTimeFormatOptionsProvider().results(),
            defaultResult: await TimeAndDateTimeFormatOptionsProvider().defaultResult(),
            expected: TimeAndDateTimeFormat.allCases.map(\.rawValue)
        )
        try await assertProvider(
            results: try await TimeAndDateDateFontOptionsProvider().results(),
            defaultResult: await TimeAndDateDateFontOptionsProvider().defaultResult(),
            expected: TimeAndDateFont.allCases.map(\.rawValue)
        )
        try await assertProvider(
            results: try await TimeAndDateTimeFontOptionsProvider().results(),
            defaultResult: await TimeAndDateTimeFontOptionsProvider().defaultResult(),
            expected: TimeAndDateFont.allCases.map(\.rawValue)
        )
    }

    private func assertProvider(
        results: IntentItemCollection<String>,
        defaultResult: String?,
        expected: [String]
    ) async throws {
        XCTAssertEqual(Set(results.items), Set(expected))
        XCTAssertEqual(results.items.count, expected.count)
        XCTAssertNotNil(defaultResult)
        XCTAssertTrue(defaultResult.map(results.items.contains) ?? false)
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(
            from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        )!
    }
}
