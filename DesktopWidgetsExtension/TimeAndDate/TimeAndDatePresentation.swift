import Foundation
import WidgetKit

enum TimeAndDateArrangement: Equatable, Sendable {
    case classicWide
    case verticalDateFirst
    case verticalTimeFirst
    case centeredDateFirst
    case horizontalDateFirst
}

struct TimeAndDatePresentation: Equatable, Sendable {
    let arrangement: TimeAndDateArrangement
    let dateText: String
    let timeText: String
    let periodText: String?
    let secondaryClockText: String?
    let accessibilityLabel: String

    init(
        date: Date,
        configuration: TimeAndDateStringConfigurationIntent,
        family: WidgetFamily,
        locale: Locale,
        timeZone: TimeZone
    ) {
        dateText = configuration.resolvedDateFormat.string(
            from: date,
            locale: locale,
            timeZone: timeZone
        )
        timeText = configuration.resolvedTimeFormat.timeString(
            from: date,
            locale: locale,
            timeZone: timeZone
        )
        periodText = configuration.resolvedTimeFormat.periodString(
            from: date,
            locale: locale,
            timeZone: timeZone
        )

        if let secondaryTimeZone = configuration.resolvedSecondaryZone.timeZone {
            let secondaryTime = configuration.resolvedTimeFormat.timeString(
                from: date,
                locale: locale,
                timeZone: secondaryTimeZone
            )
            let secondaryPeriod = configuration.resolvedTimeFormat.periodString(
                from: date,
                locale: locale,
                timeZone: secondaryTimeZone
            )
            secondaryClockText = [
                configuration.resolvedSecondaryLabel.uppercased(with: locale),
                secondaryTime,
                secondaryPeriod,
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        } else {
            secondaryClockText = nil
        }

        switch configuration.resolvedLayout {
        case .reference:
            arrangement = family == .systemSmall ? .verticalDateFirst : .classicWide
        case .stacked:
            arrangement = .verticalDateFirst
        case .timeFirst:
            arrangement = .verticalTimeFirst
        case .centered:
            arrangement = .centeredDateFirst
        case .inline:
            arrangement = family == .systemSmall ? .verticalDateFirst : .horizontalDateFirst
        }

        accessibilityLabel = [dateText, timeText, periodText, secondaryClockText]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}
