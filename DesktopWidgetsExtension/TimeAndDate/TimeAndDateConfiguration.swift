import AppIntents
import Foundation
import SwiftUI

enum TimeAndDateLayout: String, AppEnum {
    case reference
    case stacked
    case timeFirst
    case centered
    case inline

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Layout"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .reference: "Reference",
        .stacked: "Date Above Time",
        .timeFirst: "Time Above Date",
        .centered: "Centered",
        .inline: "Side by Side",
    ]
}

enum TimeAndDateDateFormat: String, AppEnum {
    case reference
    case monthFirstWords
    case monthDayYear
    case dayMonthYear
    case iso

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Date Format"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .reference: "Sunday 09 Aug",
        .monthFirstWords: "Sun Aug 09",
        .monthDayYear: "MM/dd/yyyy",
        .dayMonthYear: "dd/MM/yyyy",
        .iso: "yyyy-MM-dd",
    ]

    func string(from date: Date, locale: Locale, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .autoupdatingCurrent
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date).uppercased(with: locale)
    }

    private var pattern: String {
        switch self {
        case .reference:
            "EEEE  dd MMM"
        case .monthFirstWords:
            "EEE MMM dd"
        case .monthDayYear:
            "MM/dd/yyyy"
        case .dayMonthYear:
            "dd/MM/yyyy"
        case .iso:
            "yyyy-MM-dd"
        }
    }
}

enum TimeAndDateTimeFormat: String, AppEnum {
    case twelveHour
    case twentyFourHour

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Time Format"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .twelveHour: "12-hour",
        .twentyFourHour: "24-hour",
    ]

    func timeString(from date: Date, locale: Locale, timeZone: TimeZone) -> String {
        formatted(date, pattern: self == .twelveHour ? "hh:mm" : "HH:mm", locale: locale, timeZone: timeZone)
    }

    func periodString(from date: Date, locale: Locale, timeZone: TimeZone) -> String? {
        guard self == .twelveHour else { return nil }
        return formatted(date, pattern: "a", locale: locale, timeZone: timeZone).uppercased(with: locale)
    }

    private func formatted(
        _ date: Date,
        pattern: String,
        locale: Locale,
        timeZone: TimeZone
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .autoupdatingCurrent
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}

enum TimeAndDateFont: String, AppEnum {
    case systemBold
    case systemRounded
    case systemSerif
    case systemMonospaced
    case avenirNext
    case noteworthy
    case chalkboard
    case bradleyHand
    case markerFelt
    case snellRoundhand

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Font"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .systemBold: "System Bold",
        .systemRounded: "System Rounded",
        .systemSerif: "System Serif",
        .systemMonospaced: "System Monospaced",
        .avenirNext: "Avenir Next",
        .noteworthy: "Noteworthy",
        .chalkboard: "Chalkboard SE",
        .bradleyHand: "Bradley Hand",
        .markerFelt: "Marker Felt",
        .snellRoundhand: "Snell Roundhand",
    ]

    func font(size: CGFloat, role: TimeAndDateFontRole) -> Font {
        switch self {
        case .systemBold:
            .system(size: size, weight: role == .date ? .black : .bold)
        case .systemRounded:
            .system(size: size, weight: role == .date ? .heavy : .semibold, design: .rounded)
        case .systemSerif:
            .system(size: size, weight: role == .date ? .bold : .regular, design: .serif)
        case .systemMonospaced:
            .system(size: size, weight: role == .date ? .bold : .regular, design: .monospaced)
        case .avenirNext:
            .custom(role == .date ? "AvenirNext-Heavy" : "AvenirNext-Medium", size: size)
        case .noteworthy:
            .custom(role == .date ? "Noteworthy-Bold" : "Noteworthy-Light", size: size)
        case .chalkboard:
            .custom(role == .date ? "ChalkboardSE-Bold" : "ChalkboardSE-Regular", size: size)
        case .bradleyHand:
            .custom("BradleyHandITCTT-Bold", size: size)
        case .markerFelt:
            .custom(role == .date ? "MarkerFelt-Wide" : "MarkerFelt-Thin", size: size)
        case .snellRoundhand:
            .custom(role == .date ? "SnellRoundhand-Bold" : "SnellRoundhand", size: size)
        }
    }
}

enum TimeAndDateFontRole {
    case date
    case time
}

struct TimeAndDateConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Time and Date"
    static let description = IntentDescription("Choose how the date and time look on the desktop.")

    @Parameter(title: "Layout", default: .reference)
    var layout: TimeAndDateLayout

    @Parameter(title: "Date Format", default: .reference)
    var dateFormat: TimeAndDateDateFormat

    @Parameter(title: "Time Format", default: .twelveHour)
    var timeFormat: TimeAndDateTimeFormat

    @Parameter(title: "Date Font", default: .systemBold)
    var dateFont: TimeAndDateFont

    @Parameter(title: "Time Font", default: .noteworthy)
    var timeFont: TimeAndDateFont

    static func referencePreview() -> Self {
        let configuration = Self()
        configuration.layout = .reference
        configuration.dateFormat = .reference
        configuration.timeFormat = .twelveHour
        configuration.dateFont = .systemBold
        configuration.timeFont = .noteworthy
        return configuration
    }
}
