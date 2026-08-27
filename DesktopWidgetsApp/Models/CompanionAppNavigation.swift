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
    let enableAutomaticRefreshCommandURL: URL?
    let enableAutomaticRefreshCommandExists: Bool
    let disableAutomaticRefreshCommandURL: URL?
    let disableAutomaticRefreshCommandExists: Bool

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

        func command(forKey key: String) -> (URL?, Bool) {
            let configuredPath = (infoDictionary[key] as? String ?? "")
                .replacingOccurrences(of: "$(HOME)", with: homeDirectory.path)
                .replacingOccurrences(of: "$HOME", with: homeDirectory.path)
            guard !configuredPath.isEmpty else { return (nil, false) }
            let commandURL = URL(fileURLWithPath: configuredPath).standardizedFileURL
            return (commandURL, fileExists(commandURL.path))
        }

        let refreshCommand = command(forKey: "DesktopWidgetsRefreshCommandPath")
        refreshCommandURL = refreshCommand.0
        refreshCommandExists = refreshCommand.1
        let enableCommand = command(forKey: "DesktopWidgetsEnableAutomaticRefreshCommandPath")
        enableAutomaticRefreshCommandURL = enableCommand.0
        enableAutomaticRefreshCommandExists = enableCommand.1
        let disableCommand = command(forKey: "DesktopWidgetsDisableAutomaticRefreshCommandPath")
        disableAutomaticRefreshCommandURL = disableCommand.0
        disableAutomaticRefreshCommandExists = disableCommand.1
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

enum DesktopWidgetsAutomaticRefreshState: String, Equatable {
    case unavailable
    case disabled
    case enabled
    case healthy
    case refreshing
    case refreshed
    case needsAttention
}

struct DesktopWidgetsAutomaticRefreshStatus: Equatable {
    let isEnabled: Bool
    let state: DesktopWidgetsAutomaticRefreshState
    let message: String
    let lastCheck: String?
    let lastSuccess: String?
    let profileExpiration: String?

    init(dictionary: [String: Any]?) {
        guard let dictionary else {
            isEnabled = false
            state = .unavailable
            message = "Automatic maintenance has not reported status yet."
            lastCheck = nil
            lastSuccess = nil
            profileExpiration = nil
            return
        }

        isEnabled = dictionary["Enabled"] as? Bool ?? false
        state = DesktopWidgetsAutomaticRefreshState(
            rawValue: dictionary["State"] as? String ?? ""
        ) ?? .unavailable
        message = dictionary["Message"] as? String ?? "Automatic maintenance status is unavailable."
        lastCheck = dictionary["LastCheck"] as? String
        lastSuccess = dictionary["LastSuccess"] as? String
        profileExpiration = dictionary["ProfileExpiration"] as? String
    }

    static func current(
        appGroupIdentifier: String,
        fileManager: FileManager = .default
    ) -> Self {
        guard !appGroupIdentifier.isEmpty,
              let containerURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupIdentifier
              ) else {
            return Self(dictionary: nil)
        }
        let statusURL = containerURL.appendingPathComponent("DesktopWidgetsAutomaticRefresh.plist")
        let dictionary = NSDictionary(contentsOf: statusURL) as? [String: Any]
        return Self(dictionary: dictionary)
    }

    var title: String {
        switch state {
        case .healthy: "Automatic maintenance is ready"
        case .refreshing: "Refreshing in the background"
        case .refreshed: "Automatic refresh succeeded"
        case .needsAttention: "Automatic refresh needs attention"
        case .enabled: "Automatic maintenance is on"
        case .disabled: "Automatic maintenance is off"
        case .unavailable: "Automatic maintenance is not set up"
        }
    }
}
