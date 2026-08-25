import Foundation
import IOKit.ps

struct SystemBatteryReader {
    func snapshot() -> BatterySnapshot? {
        guard let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let powerSources = IOPSCopyPowerSourcesList(powerSourcesInfo)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return nil
        }

        for powerSource in powerSources {
            guard let rawDescription = IOPSGetPowerSourceDescription(powerSourcesInfo, powerSource)?
                .takeUnretainedValue() as? [String: Any]
            else {
                continue
            }

            if let snapshot = BatteryPowerSourceParser.snapshot(from: rawDescription) {
                return snapshot
            }
        }

        return nil
    }
}
