enum CompanionAppDestination: String, CaseIterable, Hashable, Identifiable {
    case home
    case appearance
    case timeAndDate
    case weather
    case battery
    case calendar
    case helpAndPrivacy

    static let overview: [Self] = [.home]
    static let customize: [Self] = [.appearance]
    static let widgets: [Self] = [.timeAndDate, .weather, .battery, .calendar]
    static let support: [Self] = [.helpAndPrivacy]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .appearance: "Appearance"
        case .timeAndDate: "Time & Date"
        case .weather: "Weather"
        case .battery: "Battery"
        case .calendar: "Calendar"
        case .helpAndPrivacy: "Help & Privacy"
        }
    }

    var symbolName: String {
        switch self {
        case .home: "house"
        case .appearance: "paintbrush"
        case .timeAndDate: "clock"
        case .weather: "cloud.sun"
        case .battery: "battery.75percent"
        case .calendar: "calendar"
        case .helpAndPrivacy: "questionmark.circle"
        }
    }

    var isWidget: Bool {
        Self.widgets.contains(self)
    }
}
