import AppIntents
import Foundation
import WidgetKit
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

    func testISODateUsesGregorianCalendarRegardlessOfUserCalendar() {
        let date = makeDate(year: 2026, month: 8, day: 9, hour: 21, minute: 9)

        XCTAssertEqual(
            TimeAndDateDateFormat.iso.string(
                from: date,
                locale: locale,
                timeZone: timeZone,
                calendar: Calendar(identifier: .buddhist)
            ),
            "2026-08-09"
        )
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
            configuration.secondaryTimeZone = value
            configuration.secondaryLabel = ""

            XCTAssertEqual(configuration.resolvedLayout, .reference)
            XCTAssertEqual(configuration.resolvedDateFormat, .reference)
            XCTAssertEqual(configuration.resolvedTimeFormat, .twelveHour)
            XCTAssertEqual(configuration.resolvedDateFont, .systemBold)
            XCTAssertEqual(configuration.resolvedTimeFont, .noteworthy)
            XCTAssertEqual(configuration.resolvedSecondaryZone, .off)
            XCTAssertEqual(configuration.resolvedSecondaryLabel, "")
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

    func testEveryLayoutDateAndClockCombinationRoundTrips() {
        for layout in TimeAndDateLayout.allCases {
            for dateFormat in TimeAndDateDateFormat.allCases {
                for timeFormat in TimeAndDateTimeFormat.allCases {
                    let configuration = TimeAndDateStringConfigurationIntent()
                    configuration.layout = layout.rawValue
                    configuration.dateFormat = dateFormat.rawValue
                    configuration.timeFormat = timeFormat.rawValue

                    XCTAssertEqual(configuration.resolvedLayout, layout)
                    XCTAssertEqual(configuration.resolvedDateFormat, dateFormat)
                    XCTAssertEqual(configuration.resolvedTimeFormat, timeFormat)
                }
            }
        }
    }

    func testEveryDateAndTimeFontPairRoundTripsIndependently() {
        for dateFont in TimeAndDateFont.allCases {
            for timeFont in TimeAndDateFont.allCases {
                let configuration = TimeAndDateStringConfigurationIntent()
                configuration.dateFont = dateFont.rawValue
                configuration.timeFont = timeFont.rawValue

                XCTAssertEqual(configuration.resolvedDateFont, dateFont)
                XCTAssertEqual(configuration.resolvedTimeFont, timeFont)
            }
        }
    }

    func testSecondaryClockUsesItsZoneAndOptionalLabelWithoutChangingPrimaryClock() {
        let date = makeDate(year: 2026, month: 8, day: 9, hour: 21, minute: 9)
        let configuration = TimeAndDateStringConfigurationIntent.referencePreview()
        configuration.secondaryTimeZone = TimeAndDateSecondaryZone.tokyo.rawValue
        configuration.secondaryLabel = "  Family  "

        let presentation = TimeAndDatePresentation(
            date: date,
            configuration: configuration,
            family: .systemMedium,
            locale: locale,
            timeZone: timeZone
        )

        XCTAssertEqual(presentation.timeText, "09:09")
        XCTAssertEqual(presentation.periodText, "PM")
        XCTAssertEqual(presentation.secondaryClockText, "FAMILY 06:09 AM")
        XCTAssertTrue(presentation.accessibilityLabel.contains("FAMILY 06:09 AM"))
    }

    func testSecondaryClockUsesZoneNameAsFallbackAndCapsCustomLabels() {
        let configuration = TimeAndDateStringConfigurationIntent.referencePreview()
        configuration.secondaryTimeZone = TimeAndDateSecondaryZone.london.rawValue
        configuration.secondaryLabel = ""
        XCTAssertEqual(configuration.resolvedSecondaryLabel, "London")

        configuration.secondaryLabel = "A label that is intentionally too long"
        XCTAssertEqual(configuration.resolvedSecondaryLabel, "A label that is in")
        XCTAssertEqual(configuration.resolvedSecondaryLabel.count, 18)
    }

    func testPresentationAdaptsEveryLayoutToEveryWidgetFamily() {
        let expected: [TimeAndDateLayout: [WidgetFamily: TimeAndDateArrangement]] = [
            .reference: [.systemSmall: .verticalDateFirst, .systemMedium: .classicWide, .systemLarge: .classicWide],
            .stacked: [.systemSmall: .verticalDateFirst, .systemMedium: .verticalDateFirst, .systemLarge: .verticalDateFirst],
            .timeFirst: [.systemSmall: .verticalTimeFirst, .systemMedium: .verticalTimeFirst, .systemLarge: .verticalTimeFirst],
            .centered: [.systemSmall: .centeredDateFirst, .systemMedium: .centeredDateFirst, .systemLarge: .centeredDateFirst],
            .inline: [.systemSmall: .verticalDateFirst, .systemMedium: .horizontalDateFirst, .systemLarge: .horizontalDateFirst],
        ]
        let date = makeDate(year: 2026, month: 8, day: 9, hour: 21, minute: 9)

        for layout in TimeAndDateLayout.allCases {
            for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
                let context = "layout=\(layout.rawValue), family=\(family)"
                let configuration = TimeAndDateStringConfigurationIntent.referencePreview()
                configuration.layout = layout.rawValue
                let presentation = TimeAndDatePresentation(
                    date: date,
                    configuration: configuration,
                    family: family,
                    locale: locale,
                    timeZone: timeZone
                )

                XCTAssertEqual(presentation.arrangement, expected[layout]?[family], context)
                XCTAssertFalse(presentation.dateText.isEmpty, context)
                XCTAssertFalse(presentation.timeText.isEmpty, context)
                XCTAssertFalse(presentation.accessibilityLabel.isEmpty, context)
            }
        }
    }

    func testPresentationCoversEveryFormatAndFamilyCombination() {
        let date = makeDate(year: 2026, month: 8, day: 9, hour: 21, minute: 9)

        for family in [WidgetFamily.systemSmall, .systemMedium, .systemLarge] {
            for dateFormat in TimeAndDateDateFormat.allCases {
                for timeFormat in TimeAndDateTimeFormat.allCases {
                    let context = "family=\(family), date=\(dateFormat.rawValue), time=\(timeFormat.rawValue)"
                    let configuration = TimeAndDateStringConfigurationIntent.referencePreview()
                    configuration.dateFormat = dateFormat.rawValue
                    configuration.timeFormat = timeFormat.rawValue
                    let presentation = TimeAndDatePresentation(
                        date: date,
                        configuration: configuration,
                        family: family,
                        locale: locale,
                        timeZone: timeZone
                    )

                    XCTAssertEqual(presentation.periodText == nil, timeFormat == .twentyFourHour, context)
                    XCTAssertTrue(presentation.accessibilityLabel.contains(presentation.dateText), context)
                    XCTAssertTrue(presentation.accessibilityLabel.contains(presentation.timeText), context)
                    if let period = presentation.periodText {
                        XCTAssertTrue(presentation.accessibilityLabel.contains(period), context)
                    }
                }
            }
        }
    }

    func testEveryOptionsProviderReturnsAllStableIDsAndAValidDefault() async throws {
        assertProvider(
            results: try await TimeAndDateLayoutOptionsProvider().results(),
            defaultResult: await TimeAndDateLayoutOptionsProvider().defaultResult(),
            expectedDefault: TimeAndDateLayout.reference.rawValue,
            expected: TimeAndDateLayout.allCases.map(\.rawValue)
        )
        assertProvider(
            results: try await TimeAndDateDateFormatOptionsProvider().results(),
            defaultResult: await TimeAndDateDateFormatOptionsProvider().defaultResult(),
            expectedDefault: TimeAndDateDateFormat.reference.rawValue,
            expected: TimeAndDateDateFormat.allCases.map(\.rawValue)
        )
        assertProvider(
            results: try await TimeAndDateTimeFormatOptionsProvider().results(),
            defaultResult: await TimeAndDateTimeFormatOptionsProvider().defaultResult(),
            expectedDefault: TimeAndDateTimeFormat.twelveHour.rawValue,
            expected: TimeAndDateTimeFormat.allCases.map(\.rawValue)
        )
        assertProvider(
            results: try await TimeAndDateSecondaryZoneOptionsProvider().results(),
            defaultResult: await TimeAndDateSecondaryZoneOptionsProvider().defaultResult(),
            expectedDefault: TimeAndDateSecondaryZone.off.rawValue,
            expected: TimeAndDateSecondaryZone.allCases.map(\.rawValue)
        )
        assertProvider(
            results: try await TimeAndDateDateFontOptionsProvider().results(),
            defaultResult: await TimeAndDateDateFontOptionsProvider().defaultResult(),
            expectedDefault: TimeAndDateFont.systemBold.rawValue,
            expected: TimeAndDateFont.allCases.map(\.rawValue)
        )
        assertProvider(
            results: try await TimeAndDateTimeFontOptionsProvider().results(),
            defaultResult: await TimeAndDateTimeFontOptionsProvider().defaultResult(),
            expectedDefault: TimeAndDateFont.noteworthy.rawValue,
            expected: TimeAndDateFont.allCases.map(\.rawValue)
        )
    }

    private func assertProvider(
        results: IntentItemCollection<String>,
        defaultResult: String?,
        expectedDefault: String,
        expected: [String]
    ) {
        XCTAssertEqual(Set(results.items), Set(expected))
        XCTAssertEqual(results.items.count, expected.count)
        XCTAssertEqual(defaultResult, expectedDefault)
        XCTAssertTrue(results.items.contains(expectedDefault))
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
