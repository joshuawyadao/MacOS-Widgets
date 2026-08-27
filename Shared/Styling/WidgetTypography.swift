import Foundation
import SwiftUI

enum WidgetTypographyTheme: String, CaseIterable, Hashable, Identifiable {
    case system
    case modern
    case editorial
    case technical
    case playful
    case handmade

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .modern: "Modern"
        case .editorial: "Editorial"
        case .technical: "Technical"
        case .playful: "Playful"
        case .handmade: "Handmade"
        }
    }

    var detail: String {
        switch self {
        case .system: "System Rounded"
        case .modern: "Avenir Next"
        case .editorial: "System Serif"
        case .technical: "System Monospaced"
        case .playful: "Noteworthy"
        case .handmade: "Marker Felt"
        }
    }

    func displayFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch self {
        case .system:
            .system(size: size, weight: weight, design: .rounded)
        case .modern:
            .custom("Avenir Next", size: size).weight(weight)
        case .editorial:
            .system(size: size, weight: weight, design: .serif)
        case .technical:
            .system(size: size, weight: weight, design: .monospaced)
        case .playful:
            .custom("Noteworthy", size: size).weight(weight)
        case .handmade:
            .custom("Marker Felt", size: size).weight(weight)
        }
    }
}

enum WidgetTypographyTarget: String, CaseIterable, Hashable, Identifiable {
    case timeAndDate
    case weather
    case battery
    case calendar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .timeAndDate: "Time & Date"
        case .weather: "Weather"
        case .battery: "Battery"
        case .calendar: "Calendar"
        }
    }

    var symbolName: String {
        switch self {
        case .timeAndDate: "clock"
        case .weather: "cloud.sun"
        case .battery: "battery.75percent"
        case .calendar: "calendar"
        }
    }
}

enum WidgetTypographyOverride: String, CaseIterable, Hashable, Identifiable {
    case followGlobal
    case system
    case modern
    case editorial
    case technical
    case playful
    case handmade
    case widgetFonts

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .followGlobal: "Follow Global Theme"
        case .widgetFonts: "Use Each Widget's Fonts"
        case .system: WidgetTypographyTheme.system.displayName
        case .modern: WidgetTypographyTheme.modern.displayName
        case .editorial: WidgetTypographyTheme.editorial.displayName
        case .technical: WidgetTypographyTheme.technical.displayName
        case .playful: WidgetTypographyTheme.playful.displayName
        case .handmade: WidgetTypographyTheme.handmade.displayName
        }
    }

    var theme: WidgetTypographyTheme? {
        WidgetTypographyTheme(rawValue: rawValue)
    }

    static func options(for target: WidgetTypographyTarget) -> [Self] {
        target == .timeAndDate ? allCases : allCases.filter { $0 != .widgetFonts }
    }
}

enum WidgetTypographyCoverage: String, CaseIterable, Hashable, Identifiable {
    case displayText
    case allText

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .displayText: "Display Text"
        case .allText: "All Text"
        }
    }

    var detail: String {
        switch self {
        case .displayText: "Theme heroes and headers; keep dense text system-rounded"
        case .allText: "Theme every textual label and value"
        }
    }
}

enum WidgetTypographyResolution: Equatable {
    case theme(WidgetTypographyTheme)
    case widgetFonts

    func displayFont(
        size: CGFloat,
        weight: Font.Weight = .bold,
        fallback: @autoclosure () -> Font
    ) -> Font {
        switch self {
        case let .theme(theme):
            theme.displayFont(size: size, weight: weight)
        case .widgetFonts:
            fallback()
        }
    }
}

struct WidgetTypographyLayoutProfile: Equatable, Sendable {
    let displayFontScale: CGFloat
    let supportingFontScale: CGFloat
    let horizontalSpacingScale: CGFloat
    let verticalSpacingScale: CGFloat
    let glyphVerticalPadding: CGFloat
    let displayMinimumScaleFactor: CGFloat
    let supportingMinimumScaleFactor: CGFloat

    static let neutral = Self(
        displayFontScale: 1,
        supportingFontScale: 1,
        horizontalSpacingScale: 1,
        verticalSpacingScale: 1,
        glyphVerticalPadding: 0,
        displayMinimumScaleFactor: 1,
        supportingMinimumScaleFactor: 1
    )

    init(theme: WidgetTypographyTheme) {
        switch theme {
        case .system:
            self = .neutral
        case .modern:
            self.init(
                displayFontScale: 0.98,
                supportingFontScale: 0.97,
                horizontalSpacingScale: 0.99,
                verticalSpacingScale: 1.02,
                glyphVerticalPadding: 0.25,
                displayMinimumScaleFactor: 0.65,
                supportingMinimumScaleFactor: 0.65
            )
        case .editorial:
            self.init(
                displayFontScale: 0.97,
                supportingFontScale: 0.95,
                horizontalSpacingScale: 0.985,
                verticalSpacingScale: 1.025,
                glyphVerticalPadding: 0.35,
                displayMinimumScaleFactor: 0.62,
                supportingMinimumScaleFactor: 0.62
            )
        case .technical:
            self.init(
                displayFontScale: 0.95,
                supportingFontScale: 0.93,
                horizontalSpacingScale: 0.94,
                verticalSpacingScale: 1.015,
                glyphVerticalPadding: 0.2,
                displayMinimumScaleFactor: 0.58,
                supportingMinimumScaleFactor: 0.58
            )
        case .playful:
            self.init(
                displayFontScale: 0.94,
                supportingFontScale: 0.92,
                horizontalSpacingScale: 0.96,
                verticalSpacingScale: 1.035,
                glyphVerticalPadding: 0.5,
                displayMinimumScaleFactor: 0.58,
                supportingMinimumScaleFactor: 0.58
            )
        case .handmade:
            self.init(
                displayFontScale: 0.93,
                supportingFontScale: 0.91,
                horizontalSpacingScale: 0.95,
                verticalSpacingScale: 1.04,
                glyphVerticalPadding: 0.6,
                displayMinimumScaleFactor: 0.56,
                supportingMinimumScaleFactor: 0.56
            )
        }
    }

    private init(
        displayFontScale: CGFloat,
        supportingFontScale: CGFloat,
        horizontalSpacingScale: CGFloat,
        verticalSpacingScale: CGFloat,
        glyphVerticalPadding: CGFloat,
        displayMinimumScaleFactor: CGFloat,
        supportingMinimumScaleFactor: CGFloat
    ) {
        self.displayFontScale = displayFontScale
        self.supportingFontScale = supportingFontScale
        self.horizontalSpacingScale = horizontalSpacingScale
        self.verticalSpacingScale = verticalSpacingScale
        self.glyphVerticalPadding = glyphVerticalPadding
        self.displayMinimumScaleFactor = displayMinimumScaleFactor
        self.supportingMinimumScaleFactor = supportingMinimumScaleFactor
    }
}

struct WidgetTypographyStyle: Equatable {
    let resolution: WidgetTypographyResolution
    let coverage: WidgetTypographyCoverage

    static let systemDefault = Self(
        resolution: .theme(.system),
        coverage: .displayText
    )

    var layoutProfile: WidgetTypographyLayoutProfile {
        switch resolution {
        case let .theme(theme): WidgetTypographyLayoutProfile(theme: theme)
        case .widgetFonts: .neutral
        }
    }

    var displayTextVerticalPadding: CGFloat {
        layoutProfile.glyphVerticalPadding
    }

    var supportingTextVerticalPadding: CGFloat {
        coverage == .allText ? layoutProfile.glyphVerticalPadding : 0
    }

    func displayFont(
        size: CGFloat,
        weight: Font.Weight = .bold,
        fallback: @autoclosure () -> Font
    ) -> Font {
        resolution.displayFont(
            size: size * layoutProfile.displayFontScale,
            weight: weight,
            fallback: fallback()
        )
    }

    func supportingFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        fallback: @autoclosure () -> Font
    ) -> Font {
        guard coverage == .allText else { return fallback() }
        return resolution.displayFont(
            size: size * layoutProfile.supportingFontScale,
            weight: weight,
            fallback: fallback()
        )
    }

    func horizontalSpacing(_ base: CGFloat) -> CGFloat {
        base * layoutProfile.horizontalSpacingScale
    }

    func verticalSpacing(_ base: CGFloat) -> CGFloat {
        base * layoutProfile.verticalSpacingScale
    }

    func displayMinimumScaleFactor(_ base: CGFloat) -> CGFloat {
        min(base, layoutProfile.displayMinimumScaleFactor)
    }

    func supportingMinimumScaleFactor(_ base: CGFloat) -> CGFloat {
        guard coverage == .allText else { return base }
        return min(base, layoutProfile.supportingMinimumScaleFactor)
    }
}

struct WidgetTypographyStore {
    static let appGroupInfoKey = "WidgetThemeAppGroupIdentifier"
    static let globalThemeKey = "widgetTypography.globalTheme"
    static let coverageKey = "widgetTypography.coverage"
    static let overrideKeyPrefix = "widgetTypography.override."

    let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    static var live: Self {
        guard let identifier = Bundle.main.object(
            forInfoDictionaryKey: appGroupInfoKey
        ) as? String,
        !identifier.isEmpty,
        !identifier.hasPrefix(".")
        else {
            return Self(defaults: .standard)
        }

        return Self(defaults: UserDefaults(suiteName: identifier) ?? .standard)
    }

    var globalTheme: WidgetTypographyTheme {
        get {
            defaults.string(forKey: Self.globalThemeKey)
                .flatMap(WidgetTypographyTheme.init(rawValue:)) ?? .system
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Self.globalThemeKey)
        }
    }

    var coverage: WidgetTypographyCoverage {
        get {
            defaults.string(forKey: Self.coverageKey)
                .flatMap(WidgetTypographyCoverage.init(rawValue:)) ?? .displayText
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Self.coverageKey)
        }
    }

    func override(for target: WidgetTypographyTarget) -> WidgetTypographyOverride {
        let key = Self.overrideKeyPrefix + target.rawValue
        guard let rawValue = defaults.string(forKey: key),
              let override = WidgetTypographyOverride(rawValue: rawValue),
              override != .followGlobal,
              override != .widgetFonts || target == .timeAndDate
        else {
            return .followGlobal
        }
        return override
    }

    func setOverride(
        _ override: WidgetTypographyOverride,
        for target: WidgetTypographyTarget
    ) {
        let key = Self.overrideKeyPrefix + target.rawValue
        guard override != .followGlobal else {
            defaults.removeObject(forKey: key)
            return
        }

        guard override != .widgetFonts || target == .timeAndDate else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(override.rawValue, forKey: key)
    }

    func resolution(for target: WidgetTypographyTarget) -> WidgetTypographyResolution {
        let override = override(for: target)
        if override == .widgetFonts {
            return .widgetFonts
        }
        return .theme(override.theme ?? globalTheme)
    }

    func style(for target: WidgetTypographyTarget) -> WidgetTypographyStyle {
        WidgetTypographyStyle(resolution: resolution(for: target), coverage: coverage)
    }

    func reset() {
        defaults.removeObject(forKey: Self.globalThemeKey)
        defaults.removeObject(forKey: Self.coverageKey)
        for target in WidgetTypographyTarget.allCases {
            defaults.removeObject(forKey: Self.overrideKeyPrefix + target.rawValue)
        }
    }
}
