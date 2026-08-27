import Foundation

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

struct DesktopWidgetsInstallationStatus: Equatable {
    let bundleURL: URL
    let expectedBundleURL: URL
    let bundleIdentifier: String
    let teamIdentifier: String
    let appGroupIdentifier: String
    let refreshCommandURL: URL?
    let refreshCommandExists: Bool

    init(
        bundleURL: URL,
        infoDictionary: [String: Any],
        homeDirectory: URL,
        fileExists: (String) -> Bool = FileManager.default.fileExists(atPath:)
    ) {
        self.bundleURL = bundleURL.standardizedFileURL
        expectedBundleURL = homeDirectory
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("Desktop Widgets.app", isDirectory: true)
            .standardizedFileURL
        bundleIdentifier = infoDictionary["CFBundleIdentifier"] as? String ?? "Unknown"
        teamIdentifier = infoDictionary["DesktopWidgetsDevelopmentTeam"] as? String ?? ""
        appGroupIdentifier = infoDictionary["WidgetThemeAppGroupIdentifier"] as? String ?? ""

        let configuredRefreshPath = (infoDictionary["DesktopWidgetsRefreshCommandPath"] as? String ?? "")
            .replacingOccurrences(of: "$(HOME)", with: homeDirectory.path)
            .replacingOccurrences(of: "$HOME", with: homeDirectory.path)
        if configuredRefreshPath.isEmpty {
            refreshCommandURL = nil
            refreshCommandExists = false
        } else {
            let commandURL = URL(fileURLWithPath: configuredRefreshPath).standardizedFileURL
            refreshCommandURL = commandURL
            refreshCommandExists = fileExists(commandURL.path)
        }
    }

    static func current(
        bundle: Bundle = .main,
        fileManager: FileManager = .default
    ) -> Self {
        Self(
            bundleURL: bundle.bundleURL,
            infoDictionary: bundle.infoDictionary ?? [:],
            homeDirectory: fileManager.homeDirectoryForCurrentUser,
            fileExists: fileManager.fileExists(atPath:)
        )
    }

    var isInPreferredLocation: Bool {
        bundleURL == expectedBundleURL
    }

    var hasRequiredSigningConfiguration: Bool {
        teamIdentifier.count == 10
            && appGroupIdentifier.hasPrefix(teamIdentifier + ".")
    }

    var isReady: Bool {
        isInPreferredLocation && hasRequiredSigningConfiguration
    }
}
