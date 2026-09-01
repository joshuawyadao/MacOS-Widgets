import Foundation
import IOKit
import IOKit.ps

struct SystemBatteryReader {
    func snapshot(includeHardwareMetrics: Bool) -> BatterySnapshot? {
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
                guard includeHardwareMetrics else { return snapshot }
                return snapshot.adding(hardwareMetrics())
            }
        }

        return nil
    }

    private func hardwareMetrics() -> BatteryHardwareMetrics? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        var rawProperties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(
            service,
            &rawProperties,
            kCFAllocatorDefault,
            0
        ) == KERN_SUCCESS,
        let properties = rawProperties?.takeRetainedValue() as? [String: Any]
        else {
            return nil
        }
        return BatteryHardwareParser.metrics(from: properties)
    }
}
