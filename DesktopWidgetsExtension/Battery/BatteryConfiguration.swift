import AppIntents
import WidgetKit

enum BatteryDetail: String, CaseIterable, Hashable, Sendable {
    case power
    case status
    case estimate
    case updated
}

enum BatteryDetailLimits {
    static func maximum(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            0
        case .systemMedium:
            2
        case .systemLarge:
            4
        default:
            0
        }
    }

    static func priority(for family: WidgetFamily) -> [BatteryDetail] {
        switch family {
        case .systemMedium:
            [.status, .updated, .power, .estimate]
        default:
            BatteryDetail.allCases
        }
    }
}

struct BatteryDetailSelection: Equatable, Sendable {
    let visibleDetails: [BatteryDetail]
    let selectedCount: Int
    let limit: Int

    var hiddenCount: Int {
        max(0, selectedCount - visibleDetails.count)
    }

    init(configuration: BatteryConfigurationIntent, family: WidgetFamily) {
        let selected = configuration.resolvedDetails
        let priority = BatteryDetailLimits.priority(for: family)
        let limit = BatteryDetailLimits.maximum(for: family)
        self.visibleDetails = priority.filter(selected.contains).prefix(limit).map { $0 }
        self.selectedCount = selected.count
        self.limit = limit
    }
}

struct BatteryConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Customize Battery"
    static let description = IntentDescription(
        "Choose the extra details shown beside the battery. Small shows none, Medium shows up to two, and Large shows up to four."
    )

    @Parameter(
        title: "Show Power Source",
        description: "Battery or AC Power.",
        default: true
    )
    var showPower: Bool

    @Parameter(
        title: "Show Charging Status",
        description: "Charging, discharging, fully charged, or not charging.",
        default: true
    )
    var showStatus: Bool

    @Parameter(
        title: "Show Time Estimate",
        description: "Remaining use or time to full when macOS provides it.",
        default: true
    )
    var showEstimate: Bool

    @Parameter(
        title: "Show Last Updated",
        description: "The time of the most recent WidgetKit battery reading.",
        default: true
    )
    var showUpdated: Bool

    init() {}

    var resolvedDetails: Set<BatteryDetail> {
        var details = Set<BatteryDetail>()
        if showPower { details.insert(.power) }
        if showStatus { details.insert(.status) }
        if showEstimate { details.insert(.estimate) }
        if showUpdated { details.insert(.updated) }
        return details
    }

    static func referencePreview() -> Self {
        Self()
    }
}
