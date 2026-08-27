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
    let healthPercentage: Int?
    let cycleCount: Int?

    init(
        percentage: Int,
        state: BatteryPowerState,
        timeRemainingMinutes: Int?,
        healthPercentage: Int? = nil,
        cycleCount: Int? = nil
    ) {
        self.percentage = min(max(percentage, 0), 100)
        self.state = state
        self.timeRemainingMinutes = timeRemainingMinutes.flatMap { $0 > 0 ? $0 : nil }
        self.healthPercentage = healthPercentage.map { min(max($0, 0), 100) }
        self.cycleCount = cycleCount.flatMap { $0 >= 0 ? $0 : nil }
    }

    func adding(_ hardware: BatteryHardwareMetrics?) -> Self {
        Self(
            percentage: percentage,
            state: state,
            timeRemainingMinutes: timeRemainingMinutes,
            healthPercentage: hardware?.healthPercentage,
            cycleCount: hardware?.cycleCount
        )
    }

    static let sample = BatterySnapshot(
        percentage: 85,
        state: .discharging,
        timeRemainingMinutes: 366
    )
}

struct BatteryHardwareMetrics: Equatable, Sendable {
    let healthPercentage: Int?
    let cycleCount: Int?
}

enum BatteryHardwareKey {
    static let cycleCount = "CycleCount"
    static let designCapacity = "DesignCapacity"
    static let appleRawMaximumCapacity = "AppleRawMaxCapacity"
    static let maximumCapacity = "MaxCapacity"
}

enum BatteryHardwareParser {
    static func metrics(from properties: [String: Any]) -> BatteryHardwareMetrics? {
        let designCapacity = number(for: BatteryHardwareKey.designCapacity, in: properties)?.doubleValue
        let rawMaximumCapacity = number(
            for: BatteryHardwareKey.appleRawMaximumCapacity,
            in: properties
        )?.doubleValue
        let normalizedMaximumCapacity = number(
            for: BatteryHardwareKey.maximumCapacity,
            in: properties
        )?.doubleValue
        let healthPercentage: Int? = if let designCapacity,
                                        designCapacity > 0,
                                        let rawMaximumCapacity {
            Int((rawMaximumCapacity / designCapacity * 100).rounded())
        } else if let normalizedMaximumCapacity,
                  (0...100).contains(normalizedMaximumCapacity) {
            Int(normalizedMaximumCapacity.rounded())
        } else {
            nil
        }
        let cycleCount = number(for: BatteryHardwareKey.cycleCount, in: properties)?.intValue

        guard healthPercentage != nil || cycleCount != nil else { return nil }
        return BatteryHardwareMetrics(
            healthPercentage: healthPercentage.map { min(max($0, 0), 100) },
            cycleCount: cycleCount.flatMap { $0 >= 0 ? $0 : nil }
        )
    }

    private static func number(for key: String, in values: [String: Any]) -> NSNumber? {
        values[key] as? NSNumber
    }
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
