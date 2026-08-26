import Foundation
import WidgetKit

struct BatteryWidgetPresentation: Equatable {
    let percentageText: String
    let statusText: String
    let compactStatusText: String
    let powerSourceText: String
    let stateDetailText: String
    let estimateDetailText: String
    let updatedText: String
    let fillFraction: Double
    let accessibilityLabel: String
    let showsBattery: Bool

    init(
        snapshot: BatterySnapshot?,
        updatedAt: Date? = nil,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) {
        guard let snapshot else {
            percentageText = "—"
            statusText = "No Battery"
            compactStatusText = "No Battery"
            powerSourceText = "Unavailable"
            stateDetailText = "No Battery"
            estimateDetailText = "Unavailable"
            updatedText = Self.updatedText(updatedAt, locale: locale, timeZone: timeZone)
            fillFraction = 0
            accessibilityLabel = "No internal battery detected"
            showsBattery = false
            return
        }

        percentageText = "\(snapshot.percentage)%"
        statusText = Self.statusText(for: snapshot)
        compactStatusText = Self.compactStatusText(for: snapshot)
        powerSourceText = Self.powerSourceText(for: snapshot)
        stateDetailText = Self.stateDetailText(for: snapshot)
        estimateDetailText = Self.estimateDetailText(for: snapshot)
        updatedText = Self.updatedText(updatedAt, locale: locale, timeZone: timeZone)
        fillFraction = min(max(Double(snapshot.percentage) / 100, 0), 1)
        accessibilityLabel = Self.accessibilityLabel(for: snapshot)
        showsBattery = true
    }

    private static func statusText(for snapshot: BatterySnapshot) -> String {
        switch snapshot.state {
        case .discharging:
            return snapshot.timeRemainingMinutes.map(durationText) ?? "Calculating"
        case .charging:
            return snapshot.timeRemainingMinutes.map { "Full in \(durationText($0))" } ?? "Charging"
        case .charged:
            return "AC Power"
        case .pluggedIn:
            return "AC Power"
        case .unknown:
            return "Calculating"
        }
    }

    private static func compactStatusText(for snapshot: BatterySnapshot) -> String {
        switch snapshot.state {
        case .discharging:
            return snapshot.timeRemainingMinutes.map(durationText) ?? "Calculating"
        case .charging:
            return snapshot.timeRemainingMinutes.map { "\(durationText($0)) full" } ?? "Charging"
        case .charged, .pluggedIn:
            return "AC Power"
        case .unknown:
            return "Calculating"
        }
    }

    private static func powerSourceText(for snapshot: BatterySnapshot) -> String {
        switch snapshot.state {
        case .discharging:
            return "Battery"
        case .charging, .charged, .pluggedIn:
            return "AC Power"
        case .unknown:
            return "Unknown"
        }
    }

    private static func stateDetailText(for snapshot: BatterySnapshot) -> String {
        switch snapshot.state {
        case .discharging:
            return "Discharging"
        case .charging:
            return "Charging"
        case .charged:
            return "Fully Charged"
        case .pluggedIn:
            return "Not Charging"
        case .unknown:
            return "Unknown"
        }
    }

    private static func estimateDetailText(for snapshot: BatterySnapshot) -> String {
        switch snapshot.state {
        case .discharging:
            return snapshot.timeRemainingMinutes.map { "\(durationText($0)) remaining" } ?? "Calculating"
        case .charging:
            return snapshot.timeRemainingMinutes.map { "\(durationText($0)) to full" } ?? "Calculating"
        case .charged, .pluggedIn:
            return "Unavailable on AC"
        case .unknown:
            return "Unavailable"
        }
    }

    private static func updatedText(
        _ date: Date?,
        locale: Locale,
        timeZone: TimeZone
    ) -> String {
        guard let date else { return "Just now" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        return formatter.string(from: date)
    }

    private static func accessibilityLabel(for snapshot: BatterySnapshot) -> String {
        let percentage = "Battery \(snapshot.percentage) percent"
        switch snapshot.state {
        case .discharging:
            guard let minutes = snapshot.timeRemainingMinutes else {
                return "\(percentage), remaining time is calculating"
            }
            return "\(percentage), \(spokenDuration(minutes)) remaining"
        case .charging:
            guard let minutes = snapshot.timeRemainingMinutes else {
                return "\(percentage), charging"
            }
            return "\(percentage), charging, full in \(spokenDuration(minutes))"
        case .charged:
            return "\(percentage), fully charged, using AC power"
        case .pluggedIn:
            return "\(percentage), connected to AC power, not charging"
        case .unknown:
            return "\(percentage), power state unknown"
        }
    }

    private static func durationText(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        return String(format: "%.1f h", Double(minutes) / 60)
    }

    private static func spokenDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        }

        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        return "\(hours) hours \(remainder) minutes"
    }
}

struct BatteryWidgetLayoutMetrics: Equatable {
    let percentageFontSize: Double
    let statusFontSize: Double
    let iconWidth: Double
    let iconHeight: Double
    let contentSpacing: Double
    let showsExpandedDetails: Bool
    let usesDetailGrid: Bool

    init(family: WidgetFamily) {
        switch WidgetInformationDensity(family: family) {
        case .compact:
            percentageFontSize = 26
            statusFontSize = 14
            iconWidth = 38
            iconHeight = 62
            contentSpacing = 10
            showsExpandedDetails = false
            usesDetailGrid = false
        case .expanded:
            percentageFontSize = 50
            statusFontSize = 24
            iconWidth = 72
            iconHeight = 118
            contentSpacing = 28
            showsExpandedDetails = true
            usesDetailGrid = true
        case .standard:
            percentageFontSize = 34
            statusFontSize = 17
            iconWidth = 48
            iconHeight = 78
            contentSpacing = 16
            showsExpandedDetails = true
            usesDetailGrid = false
        }
    }
}

enum BatteryTimelinePolicy {
    static let refreshInterval: TimeInterval = 5 * 60

    static func refreshDate(after date: Date) -> Date {
        date.addingTimeInterval(refreshInterval)
    }
}
