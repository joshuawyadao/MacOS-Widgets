import Foundation
import WidgetKit
import XCTest

final class BatteryWidgetTests: XCTestCase {
    func testParserNormalizesCapacityAndUsesDischargeEstimate() throws {
        let snapshot = try XCTUnwrap(BatteryPowerSourceParser.snapshot(from: description(
            current: 4_250,
            maximum: 5_000,
            source: BatteryPowerSourceKey.batteryPower,
            timeToEmpty: 366
        )))

        XCTAssertEqual(snapshot.percentage, 85)
        XCTAssertEqual(snapshot.state, .discharging)
        XCTAssertEqual(snapshot.timeRemainingMinutes, 366)
    }

    func testParserUsesTimeToFullWhileCharging() throws {
        var values = description(
            current: 2_100,
            maximum: 5_000,
            source: BatteryPowerSourceKey.acPower,
            timeToEmpty: 999
        )
        values[BatteryPowerSourceKey.isCharging] = true
        values[BatteryPowerSourceKey.timeToFullCharge] = 72

        let snapshot = try XCTUnwrap(BatteryPowerSourceParser.snapshot(from: values))

        XCTAssertEqual(snapshot.percentage, 42)
        XCTAssertEqual(snapshot.state, .charging)
        XCTAssertEqual(snapshot.timeRemainingMinutes, 72)
    }

    func testParserRejectsNonBatteryAndInvalidCapacitySources() {
        var external = description(current: 50, maximum: 100)
        external[BatteryPowerSourceKey.type] = "UPS"
        XCTAssertNil(BatteryPowerSourceParser.snapshot(from: external))

        XCTAssertNil(BatteryPowerSourceParser.snapshot(from: description(current: 50, maximum: 0)))
    }

    func testSnapshotClampsPercentageAndDropsInvalidEstimates() {
        XCTAssertEqual(
            BatterySnapshot(percentage: 150, state: .charged, timeRemainingMinutes: -1),
            BatterySnapshot(percentage: 100, state: .charged, timeRemainingMinutes: nil)
        )
        XCTAssertEqual(
            BatterySnapshot(percentage: -5, state: .unknown, timeRemainingMinutes: 0).percentage,
            0
        )
    }

    func testReferencePresentationMatchesPercentageRuntimeAndFill() {
        let presentation = BatteryWidgetPresentation(snapshot: .sample)

        XCTAssertEqual(presentation.percentageText, "85%")
        XCTAssertEqual(presentation.statusText, "6.1 h")
        XCTAssertEqual(presentation.fillFraction, 0.85, accuracy: 0.001)
        XCTAssertEqual(presentation.accessibilityLabel, "Battery 85 percent, 6 hours 6 minutes remaining")
        XCTAssertTrue(presentation.showsBattery)
    }

    func testPresentationHandlesEveryPowerStateAndMissingEstimate() {
        let cases: [(BatterySnapshot, String)] = [
            (BatterySnapshot(percentage: 55, state: .discharging, timeRemainingMinutes: nil), "Calculating"),
            (BatterySnapshot(percentage: 42, state: .charging, timeRemainingMinutes: 72), "Full in 1.2 h"),
            (BatterySnapshot(percentage: 42, state: .charging, timeRemainingMinutes: nil), "Charging"),
            (BatterySnapshot(percentage: 100, state: .charged, timeRemainingMinutes: nil), "Charged"),
            (BatterySnapshot(percentage: 96, state: .pluggedIn, timeRemainingMinutes: nil), "Plugged In"),
            (BatterySnapshot(percentage: 71, state: .unknown, timeRemainingMinutes: nil), "Calculating"),
        ]

        for (snapshot, expectedStatus) in cases {
            let presentation = BatteryWidgetPresentation(snapshot: snapshot)
            XCTAssertEqual(presentation.statusText, expectedStatus, "state=\(snapshot.state)")
            XCTAssertFalse(presentation.accessibilityLabel.isEmpty)
        }

        let unavailable = BatteryWidgetPresentation(snapshot: nil)
        XCTAssertEqual(unavailable.statusText, "No Battery")
        XCTAssertEqual(unavailable.fillFraction, 0)
        XCTAssertFalse(unavailable.showsBattery)
    }

    func testEverySupportedFamilyUsesProgressivelyLargerMetrics() {
        let small = BatteryWidgetLayoutMetrics(family: .systemSmall)
        let medium = BatteryWidgetLayoutMetrics(family: .systemMedium)
        let large = BatteryWidgetLayoutMetrics(family: .systemLarge)

        XCTAssertLessThan(small.percentageFontSize, medium.percentageFontSize)
        XCTAssertLessThan(medium.percentageFontSize, large.percentageFontSize)
        XCTAssertLessThan(small.iconHeight, medium.iconHeight)
        XCTAssertLessThan(medium.iconHeight, large.iconHeight)
        XCTAssertGreaterThan(small.iconWidth, 0)
    }

    func testTimelineRequestsAnotherBatteryReadingAfterFiveMinutes() {
        let date = Date(timeIntervalSince1970: 1_786_262_940)
        XCTAssertEqual(BatteryTimelinePolicy.refreshInterval, 300)
        XCTAssertEqual(
            BatteryTimelinePolicy.refreshDate(after: date),
            date.addingTimeInterval(300)
        )
    }

    private func description(
        current: Int,
        maximum: Int,
        source: String = BatteryPowerSourceKey.batteryPower,
        timeToEmpty: Int = -1
    ) -> [String: Any] {
        [
            BatteryPowerSourceKey.type: BatteryPowerSourceKey.internalBatteryType,
            BatteryPowerSourceKey.currentCapacity: current,
            BatteryPowerSourceKey.maximumCapacity: maximum,
            BatteryPowerSourceKey.isCharging: false,
            BatteryPowerSourceKey.powerSourceState: source,
            BatteryPowerSourceKey.timeToEmpty: timeToEmpty,
        ]
    }
}
