import AppIntents
import WidgetKit

enum CalendarViewMode: String, CaseIterable, Sendable {
    case automatic
    case day
    case week
    case month

    var displayName: LocalizedStringResource {
        switch self {
        case .automatic: "Automatic — Day / Week / Month by size"
        case .day: "Day — Focus on today"
        case .week: "Week — Seven-day overview"
        case .month: "Month — Full calendar grid"
        }
    }
}

enum CalendarResolvedView: Equatable, Sendable {
    case day
    case week
    case month
}

struct CalendarViewModeOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        let items = CalendarViewMode.allCases.map { mode in
            IntentItem(mode.rawValue, title: mode.displayName)
        }
        return IntentItemCollection(
            promptLabel: "Choose a calendar view",
            sections: [IntentItemSection(items: items)]
        )
    }

    func defaultResult() async -> String? {
        CalendarViewMode.automatic.rawValue
    }
}

struct CalendarConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Customize Calendar"
    static let description = IntentDescription(
        "Choose Day, Week, or Month and optionally show private event counts or the next event time."
    )

    @Parameter(title: "Calendar View", optionsProvider: CalendarViewModeOptionsProvider())
    var viewMode: String?

    @Parameter(
        title: "Show Event Indicators",
        description: "Show counts and dots for days with events. Event titles never appear.",
        default: false
    )
    var showEvents: Bool

    @Parameter(
        title: "Show Next Event Time",
        description: "Show only when the next timed event starts. Titles and other event details never appear.",
        default: false
    )
    var showNextEventTime: Bool

    init() {}

    var resolvedViewMode: CalendarViewMode {
        viewMode.flatMap(CalendarViewMode.init(rawValue:)) ?? .automatic
    }

    func resolvedView(for family: WidgetFamily) -> CalendarResolvedView {
        switch resolvedViewMode {
        case .day: .day
        case .week: .week
        case .month: .month
        case .automatic:
            switch family {
            case .systemSmall: .day
            case .systemLarge: .month
            default: .week
            }
        }
    }

    static func referencePreview(
        showEvents: Bool = true,
        showNextEventTime: Bool = false
    ) -> Self {
        let configuration = Self()
        configuration.viewMode = CalendarViewMode.automatic.rawValue
        configuration.showEvents = showEvents
        configuration.showNextEventTime = showNextEventTime
        return configuration
    }
}
