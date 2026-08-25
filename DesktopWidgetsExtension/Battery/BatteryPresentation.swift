import Foundation
import WidgetKit

struct BatteryWidgetPresentation: Equatable {
    let percentageText: String
    let statusText: String
    let fillFraction: Double
    let accessibilityLabel: String
    let showsBattery: Bool

    init(snapshot: BatterySnapshot?) {
        guard let snapshot else {
            percentageText = "—"
            statusText = "No Battery"
            fillFraction = 0
            accessibilityLabel = "No internal battery detected"
            showsBattery = false
            return
        }

        percentageText = "\(snapshot.percentage)%"
        statusText = Self.statusText(for: snapshot)
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
            return "Charged"
        case .pluggedIn:
            return "Plugged In"
        case .unknown:
            return "Calculating"
        }
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
            return "\(percentage), charged"
        case .pluggedIn:
            return "\(percentage), plugged in"
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

    init(family: WidgetFamily) {
        switch family {
        case .systemSmall:
            percentageFontSize = 28
            statusFontSize = 16
            iconWidth = 43
            iconHeight = 70
            contentSpacing = 15
        case .systemLarge:
            percentageFontSize = 48
            statusFontSize = 23
            iconWidth = 70
            iconHeight = 112
            contentSpacing = 34
        default:
            percentageFontSize = 34
            statusFontSize = 18
            iconWidth = 50
            iconHeight = 82
            contentSpacing = 22
        }
    }
}

enum BatteryTimelinePolicy {
    static let refreshInterval: TimeInterval = 5 * 60

    static func refreshDate(after date: Date) -> Date {
        date.addingTimeInterval(refreshInterval)
    }
}
