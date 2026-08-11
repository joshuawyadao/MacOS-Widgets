import AppIntents
import Foundation
import SwiftUI

protocol TimeAndDateStringOption: CaseIterable, RawRepresentable where RawValue == String {
    var displayName: LocalizedStringResource { get }
}

enum TimeAndDateLayout: String, CaseIterable, Sendable, TimeAndDateStringOption {
    case reference
    case stacked
    case timeFirst
    case centered
    case inline

    var displayName: LocalizedStringResource {
        switch self {
        case .reference: "Classic — Date above time"
        case .stacked: "Compact — Date above time"
        case .timeFirst: "Time first — Time above date"
        case .centered: "Centered — Date above time"
        case .inline: "Side by side — Date then time"
        }
    }
}

enum TimeAndDateDateFormat: String, CaseIterable, Sendable, TimeAndDateStringOption {
    case reference
    case monthFirstWords
    case monthDayYear
    case dayMonthYear
    case iso

    var displayName: LocalizedStringResource {
        switch self {
        case .reference: "Words — Sunday 09 Aug"
        case .monthFirstWords: "Short words — Sun Aug 09"
        case .monthDayYear: "Month first — 08/09/2026"
        case .dayMonthYear: "Day first — 09/08/2026"
        case .iso: "ISO — 2026-08-09"
        }
    }

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

enum TimeAndDateTimeFormat: String, CaseIterable, Sendable, TimeAndDateStringOption {
    case twelveHour
    case twentyFourHour

    var displayName: LocalizedStringResource {
        switch self {
        case .twelveHour: "12-hour — 9:09 AM"
        case .twentyFourHour: "24-hour — 09:09"
        }
    }

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

enum TimeAndDateFont: String, CaseIterable, Sendable, TimeAndDateStringOption {
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

    var displayName: LocalizedStringResource {
        switch self {
        case .systemBold: "System Bold"
        case .systemRounded: "System Rounded"
        case .systemSerif: "System Serif"
        case .systemMonospaced: "System Monospaced"
        case .avenirNext: "Avenir Next"
        case .noteworthy: "Noteworthy"
        case .chalkboard: "Chalkboard SE"
        case .bradleyHand: "Bradley Hand"
        case .markerFelt: "Marker Felt"
        case .snellRoundhand: "Snell Roundhand"
        }
    }

    var previewImageName: String {
        switch self {
        case .systemBold: "FontPreviewSystemBold"
        case .systemRounded: "FontPreviewSystemRounded"
        case .systemSerif: "FontPreviewSystemSerif"
        case .systemMonospaced: "FontPreviewSystemMonospaced"
        case .avenirNext: "FontPreviewAvenirNext"
        case .noteworthy: "FontPreviewNoteworthy"
        case .chalkboard: "FontPreviewChalkboard"
        case .bradleyHand: "FontPreviewBradleyHand"
        case .markerFelt: "FontPreviewMarkerFelt"
        case .snellRoundhand: "FontPreviewSnellRoundhand"
        }
    }

    var category: TimeAndDateFontCategory {
        switch self {
        case .systemBold, .systemRounded, .systemSerif, .systemMonospaced, .avenirNext:
            .cleanAndClassic
        case .noteworthy, .chalkboard, .bradleyHand, .markerFelt, .snellRoundhand:
            .handwritten
        }
    }

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

enum TimeAndDateFontCategory {
    case cleanAndClassic
    case handwritten
}

enum TimeAndDateFontRole {
    case date
    case time
}

private enum TimeAndDateOptionItems {
    static func collection<Option: TimeAndDateStringOption>(
        for optionType: Option.Type,
        prompt: LocalizedStringResource
    ) -> IntentItemCollection<String> {
        let items = Option.allCases.map { option in
            IntentItem(option.rawValue, title: option.displayName)
        }

        return IntentItemCollection(
            promptLabel: prompt,
            sections: [IntentItemSection(items: items)]
        )
    }

    static func fontCollection(prompt: LocalizedStringResource) -> IntentItemCollection<String> {
        func items(in category: TimeAndDateFontCategory) -> [IntentItem<String>] {
            TimeAndDateFont.allCases.filter { $0.category == category }.map { font in
                IntentItem(
                    font.rawValue,
                    title: font.displayName,
                    image: DisplayRepresentation.Image(
                        named: font.previewImageName,
                        isTemplate: true,
                        displayStyle: .default
                    )
                )
            }
        }

        return IntentItemCollection(
            promptLabel: prompt,
            sections: [
                IntentItemSection("Clean & Classic", items: items(in: .cleanAndClassic)),
                IntentItemSection("Handwritten", items: items(in: .handwritten)),
            ]
        )
    }
}

struct TimeAndDateLayoutOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        TimeAndDateOptionItems.collection(for: TimeAndDateLayout.self, prompt: "Choose a layout")
    }

    func defaultResult() async -> String? {
        TimeAndDateLayout.reference.rawValue
    }
}

struct TimeAndDateDateFormatOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        TimeAndDateOptionItems.collection(for: TimeAndDateDateFormat.self, prompt: "Choose a date format")
    }

    func defaultResult() async -> String? {
        TimeAndDateDateFormat.reference.rawValue
    }
}

struct TimeAndDateTimeFormatOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        TimeAndDateOptionItems.collection(for: TimeAndDateTimeFormat.self, prompt: "Choose a time format")
    }

    func defaultResult() async -> String? {
        TimeAndDateTimeFormat.twelveHour.rawValue
    }
}

struct TimeAndDateDateFontOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        TimeAndDateOptionItems.fontCollection(prompt: "Choose a date font")
    }

    func defaultResult() async -> String? {
        TimeAndDateFont.systemBold.rawValue
    }
}

struct TimeAndDateTimeFontOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        TimeAndDateOptionItems.fontCollection(prompt: "Choose a time font")
    }

    func defaultResult() async -> String? {
        TimeAndDateFont.noteworthy.rawValue
    }
}

struct TimeAndDateStringConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Customize Time and Date"
    static let description = IntentDescription("Choose the arrangement, formats, and fonts for this widget.")

    @Parameter(title: "Arrangement", optionsProvider: TimeAndDateLayoutOptionsProvider())
    var layout: String?

    @Parameter(title: "Date Style", optionsProvider: TimeAndDateDateFormatOptionsProvider())
    var dateFormat: String?

    @Parameter(title: "Date Font", optionsProvider: TimeAndDateDateFontOptionsProvider())
    var dateFont: String?

    @Parameter(title: "Clock Style", optionsProvider: TimeAndDateTimeFormatOptionsProvider())
    var timeFormat: String?

    @Parameter(title: "Time Font", optionsProvider: TimeAndDateTimeFontOptionsProvider())
    var timeFont: String?

    var resolvedLayout: TimeAndDateLayout {
        layout.flatMap(TimeAndDateLayout.init(rawValue:)) ?? .reference
    }

    var resolvedDateFormat: TimeAndDateDateFormat {
        dateFormat.flatMap(TimeAndDateDateFormat.init(rawValue:)) ?? .reference
    }

    var resolvedTimeFormat: TimeAndDateTimeFormat {
        timeFormat.flatMap(TimeAndDateTimeFormat.init(rawValue:)) ?? .twelveHour
    }

    var resolvedDateFont: TimeAndDateFont {
        dateFont.flatMap(TimeAndDateFont.init(rawValue:)) ?? .systemBold
    }

    var resolvedTimeFont: TimeAndDateFont {
        timeFont.flatMap(TimeAndDateFont.init(rawValue:)) ?? .noteworthy
    }

    static func referencePreview() -> Self {
        let configuration = Self()
        configuration.layout = TimeAndDateLayout.reference.rawValue
        configuration.dateFormat = TimeAndDateDateFormat.reference.rawValue
        configuration.timeFormat = TimeAndDateTimeFormat.twelveHour.rawValue
        configuration.dateFont = TimeAndDateFont.systemBold.rawValue
        configuration.timeFont = TimeAndDateFont.noteworthy.rawValue
        return configuration
    }
}
