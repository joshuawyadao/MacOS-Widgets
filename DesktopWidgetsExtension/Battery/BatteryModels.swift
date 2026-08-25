import Foundation

enum BatteryPowerState: Equatable, Sendable {
    case discharging
    case charging
    case charged
    case pluggedIn
    case unknown
}

struct BatterySnapshot: Equatable, Sendable {
    let percentage: Int
    let state: BatteryPowerState
    let timeRemainingMinutes: Int?

    init(percentage: Int, state: BatteryPowerState, timeRemainingMinutes: Int?) {
        self.percentage = min(max(percentage, 0), 100)
        self.state = state
        self.timeRemainingMinutes = timeRemainingMinutes.flatMap { $0 > 0 ? $0 : nil }
    }

    static let sample = BatterySnapshot(
        percentage: 85,
        state: .discharging,
        timeRemainingMinutes: 366
    )
}

enum BatteryPowerSourceKey {
    static let type = "Type"
    static let internalBatteryType = "InternalBattery"
    static let currentCapacity = "Current Capacity"
    static let maximumCapacity = "Max Capacity"
    static let isCharging = "Is Charging"
    static let powerSourceState = "Power Source State"
    static let batteryPower = "Battery Power"
    static let acPower = "AC Power"
    static let timeToEmpty = "Time to Empty"
    static let timeToFullCharge = "Time to Full Charge"
}

enum BatteryPowerSourceParser {
    static func snapshot(from description: [String: Any]) -> BatterySnapshot? {
        guard description[BatteryPowerSourceKey.type] as? String == BatteryPowerSourceKey.internalBatteryType,
              let currentCapacity = number(for: BatteryPowerSourceKey.currentCapacity, in: description),
              let maximumCapacity = number(for: BatteryPowerSourceKey.maximumCapacity, in: description),
              maximumCapacity.doubleValue > 0
        else {
            return nil
        }

        let rawPercentage = currentCapacity.doubleValue / maximumCapacity.doubleValue * 100
        let percentage = Int(rawPercentage.rounded())
        let isCharging = bool(for: BatteryPowerSourceKey.isCharging, in: description)
        let sourceState = description[BatteryPowerSourceKey.powerSourceState] as? String
        let state = resolvedState(
            percentage: percentage,
            isCharging: isCharging,
            powerSourceState: sourceState
        )

        let estimateKey = state == .charging
            ? BatteryPowerSourceKey.timeToFullCharge
            : BatteryPowerSourceKey.timeToEmpty
        let estimate = number(for: estimateKey, in: description)?.intValue

        return BatterySnapshot(
            percentage: percentage,
            state: state,
            timeRemainingMinutes: estimate
        )
    }

    private static func resolvedState(
        percentage: Int,
        isCharging: Bool,
        powerSourceState: String?
    ) -> BatteryPowerState {
        if isCharging {
            return .charging
        }
        if powerSourceState == BatteryPowerSourceKey.batteryPower {
            return .discharging
        }
        if powerSourceState == BatteryPowerSourceKey.acPower {
            return percentage >= 100 ? .charged : .pluggedIn
        }
        return .unknown
    }

    private static func number(for key: String, in description: [String: Any]) -> NSNumber? {
        description[key] as? NSNumber
    }

    private static func bool(for key: String, in description: [String: Any]) -> Bool {
        number(for: key, in: description)?.boolValue ?? false
    }
}
