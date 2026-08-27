import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var calendarPermission = CalendarPermissionController()
    @StateObject private var typography = WidgetTypographyController()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                typographyGuide
                readyWidgets
                setupGuide
                widgetGuides
                weatherDetailLimitsTip
                appearanceTip
                weatherDataTip
            }
            .padding(28)
        }
        .frame(minWidth: 680, minHeight: 560)
        .onAppear {
            calendarPermission.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            calendarPermission.refreshAndReloadWidget()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Desktop Widgets")
                .font(.largeTitle.bold())

            Text("Simple, personal widgets without subscriptions or upgrade prompts.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var readyWidgets: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Ready widgets", subtitle: "Add any of these widgets from the macOS widget gallery.")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ReadyWidgetCard(
                    symbol: "clock",
                    title: "Time & Date",
                    detail: "Arrange and style the date and clock."
                )
                ReadyWidgetCard(
                    symbol: "cloud.sun",
                    title: "Weather",
                    detail: "Choose a city, forecast view, units, and details."
                )
                ReadyWidgetCard(
                    symbol: "battery.75percent",
                    title: "Battery",
                    detail: "See charge and runtime, then choose which extra details each copy shows."
                )
                ReadyWidgetCard(
                    symbol: "calendar",
                    title: "Calendar",
                    detail: "Browse a full month and keep today easy to spot."
                )
            }
        }
    }

    private var typographyGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(
                title: "Appearance theme",
                subtitle: "Choose one style for all widgets, decide how much text it covers, then add only the exceptions you want."
            )

            HStack(spacing: 12) {
                Menu {
                    ForEach(WidgetTypographyTheme.allCases) { theme in
                        Button {
                            typography.setGlobalTheme(theme)
                        } label: {
                            if typography.globalTheme == theme {
                                Label(
                                    "\(theme.displayName) — \(theme.detail)",
                                    systemImage: "checkmark"
                                )
                            } else {
                                Text("\(theme.displayName) — \(theme.detail)")
                            }
                        }
                    }
                } label: {
                    Label(
                        "\(typography.globalTheme.displayName) — \(typography.globalTheme.detail)",
                        systemImage: "textformat"
                    )
                }
                .frame(maxWidth: 280, alignment: .leading)

                Menu {
                    ForEach(WidgetTypographyCoverage.allCases) { coverage in
                        Button {
                            typography.setCoverage(coverage)
                        } label: {
                            if typography.coverage == coverage {
                                Label(coverage.displayName, systemImage: "checkmark")
                            } else {
                                Text(coverage.displayName)
                            }
                        }
                    }
                } label: {
                    Label(typography.coverage.displayName, systemImage: "character.cursor.ibeam")
                }
                .help(typography.coverage.detail)

                Spacer(minLength: 0)
                Button("Use System Style") {
                    typography.reset()
                }
                .disabled(typography.usesSystemDefaults)
            }

            TypographyPreviewGrid(
                resolutions: Dictionary(
                    uniqueKeysWithValues: WidgetTypographyTarget.allCases.map {
                        ($0, typography.resolution(for: $0))
                    }
                ),
                coverage: typography.coverage
            )

            Text(typography.coverage.detail)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("Widget overrides")
                .font(.headline)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 10
            ) {
                ForEach(WidgetTypographyTarget.allCases) { target in
                    WidgetTypographyOverrideRow(
                        target: target,
                        selection: typography.override(for: target),
                        onSelect: { typography.setOverride($0, for: target) }
                    )
                }
            }

            Text("Time & Date can follow the global theme, use another theme, or preserve the separate date and time fonts configured on each placed copy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(WidgetTheme.accent.opacity(0.20), lineWidth: 1)
        }
    }

    private var setupGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Set up in two steps", subtitle: "You only need the app to install and update the widget.")

            SetupStep(
                number: 1,
                title: "Add it to the desktop",
                detail: "Control-click the desktop, choose Edit Widgets, search for Desktop Widgets, then drag Time & Date, Weather, Battery, or Calendar onto the desktop."
            )

            SetupStep(
                number: 2,
                title: "Make it yours",
                detail: "Control-click configurable widgets to edit their options. Calendar can use Automatic, Day, Week, or Month, with optional event indicators after you enable access below."
            )
        }
    }

    private var widgetGuides: some View {
        VStack(alignment: .leading, spacing: 22) {
            WidgetGuideSection(
                title: "Time & Date",
                subtitle: "Local time with independent layouts and formats, plus optional per-copy fonts.",
                items: [
                    WidgetGuideItem(symbol: "rectangle.3.group", title: "View", detail: "Classic, compact, centered, time first, or side by side."),
                    WidgetGuideItem(symbol: "calendar", title: "Details", detail: "Choose a word-based, month-first, day-first, or ISO date."),
                    WidgetGuideItem(symbol: "clock", title: "Format", detail: "Use a 12-hour or 24-hour clock; AM/PM adapts automatically."),
                    WidgetGuideItem(symbol: "textformat", title: "Appearance", detail: "Follow the app theme, or preserve separate date and time fonts for each copy."),
                ]
            )

            WidgetGuideSection(
                title: "Weather",
                subtitle: "A cached city forecast with size-aware views, details, and provider attribution.",
                items: [
                    WidgetGuideItem(symbol: "building.2", title: "Source", detail: "Search for a city and choose the exact region and country."),
                    WidgetGuideItem(symbol: "calendar.day.timeline.leading", title: "View", detail: "Switch between the week, today, and the next six hours."),
                    WidgetGuideItem(symbol: "square.stack.3d.up", title: "Details", detail: "Apply Minimal, Simple, Rain, Comfort, Detailed, or Full."),
                    WidgetGuideItem(symbol: "thermometer.medium", title: "Format", detail: "Follow this Mac or choose Fahrenheit or Celsius."),
                ]
            )

            WidgetGuideSection(
                title: "Battery",
                subtitle: "Local charge and power information with no account, network, or accessory access.",
                items: [
                    WidgetGuideItem(symbol: "battery.75percent", title: "Source", detail: "Reads this Mac's internal battery through the local system API."),
                    WidgetGuideItem(symbol: "rectangle.3.group", title: "View", detail: "Small emphasizes charge; Medium and Large progressively add details."),
                    WidgetGuideItem(symbol: "timer", title: "Details", detail: "Toggle Power, Status, Estimate, and Updated for each copy."),
                    WidgetGuideItem(symbol: "bolt.fill", title: "Status", detail: "Distinguishes charging, discharging, AC power, calculating, and no battery."),
                ]
            )

            WidgetGuideSection(
                title: "Calendar",
                subtitle: "Locale-aware Day, Week, and Month views with optional private event indicators.",
                items: [
                    WidgetGuideItem(symbol: "calendar", title: "Source", detail: "Uses this Mac's calendar, locale, time zone, and first-weekday preference."),
                    WidgetGuideItem(symbol: "rectangle.3.group", title: "View", detail: "Automatic chooses Day, Week, or Month by size; each copy can override it."),
                    WidgetGuideItem(symbol: "circle.grid.2x2.fill", title: "Details", detail: "Optional counts and dots show busy days without revealing event text."),
                    WidgetGuideItem(symbol: "arrow.left.arrow.right", title: "Interaction", detail: "Month view can move backward, forward, or return to the current month."),
                ]
            )

            CalendarPermissionCard(controller: calendarPermission)
        }
    }

    private var weatherDetailLimitsTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checklist.checked")
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Weather detail presets")
                    .font(.headline)

                Text("Day view fits 2 details on Small, 3 on Medium, and 5 on Large. Narrow Week and Hour columns show 1 detail on Small or Medium and 2 on Large so labels stay readable. Larger presets keep the first details that fit and show a “Showing X of Y” notice.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }

    private var appearanceTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("About the glass background")
                    .font(.headline)

                Text("With the Clear icon and widget style, macOS replaces widget backgrounds with Liquid Glass. Clear Light gives the softest appearance; place white widget text over a darker wallpaper area for the best readability.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }

    private var weatherDataTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "cloud.sun")
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)

            VStack(alignment: .leading, spacing: 5) {
                Text("About Weather data")
                    .font(.headline)

                Text("Weather sends your city search and the selected coordinate to Open-Meteo. Recent forecasts are cached locally to reduce requests and remain useful while offline. Values are normalized and rounded for display.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Link("Weather data by Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
                    Text("•")
                    Link("CC BY 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!)
                    Text("•")
                    Link("City data by GeoNames", destination: URL(string: "https://www.geonames.org/")!)
                }
                .font(.caption)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }

}

@MainActor
private final class WidgetTypographyController: ObservableObject {
    @Published private(set) var globalTheme: WidgetTypographyTheme
    @Published private(set) var coverage: WidgetTypographyCoverage
    @Published private var overrides: [WidgetTypographyTarget: WidgetTypographyOverride]

    private let store: WidgetTypographyStore

    init(store: WidgetTypographyStore = .live) {
        self.store = store
        self.globalTheme = store.globalTheme
        self.coverage = store.coverage
        self.overrides = Dictionary(
            uniqueKeysWithValues: WidgetTypographyTarget.allCases.map {
                ($0, store.override(for: $0))
            }
        )
    }

    var usesSystemDefaults: Bool {
        globalTheme == .system
            && coverage == .displayText
            && overrides.values.allSatisfy { $0 == .followGlobal }
    }

    func override(for target: WidgetTypographyTarget) -> WidgetTypographyOverride {
        overrides[target] ?? .followGlobal
    }

    func resolution(for target: WidgetTypographyTarget) -> WidgetTypographyResolution {
        let override = override(for: target)
        if override == .widgetFonts {
            return .widgetFonts
        }
        return .theme(override.theme ?? globalTheme)
    }

    func setGlobalTheme(_ theme: WidgetTypographyTheme) {
        globalTheme = theme
        store.globalTheme = theme
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setCoverage(_ coverage: WidgetTypographyCoverage) {
        self.coverage = coverage
        store.coverage = coverage
        WidgetCenter.shared.reloadAllTimelines()
    }

    func setOverride(
        _ override: WidgetTypographyOverride,
        for target: WidgetTypographyTarget
    ) {
        overrides[target] = override
        store.setOverride(override, for: target)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func reset() {
        store.reset()
        globalTheme = .system
        coverage = .displayText
        overrides = Dictionary(
            uniqueKeysWithValues: WidgetTypographyTarget.allCases.map { ($0, .followGlobal) }
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private struct TypographyPreviewGrid: View {
    let resolutions: [WidgetTypographyTarget: WidgetTypographyResolution]
    let coverage: WidgetTypographyCoverage

    var body: some View {
        LazyVGrid(
            columns: WidgetTypographyTarget.allCases.map { _ in GridItem(.flexible(), spacing: 8) },
            spacing: 8
        ) {
            ForEach(WidgetTypographyTarget.allCases) { target in
                VStack(alignment: .leading, spacing: 7) {
                    Label(target.displayName, systemImage: target.symbolName)
                        .font(
                            typographyStyle(for: target).supportingFont(
                                size: 12,
                                weight: .semibold,
                                fallback: .caption.weight(.semibold)
                            )
                        )
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(sampleText(for: target))
                        .font(
                            (resolutions[target] ?? .theme(.system)).displayFont(
                                size: 24,
                                weight: .black,
                                fallback: .custom("Noteworthy-Bold", size: 24)
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(sampleDetail(for: target))
                        .font(
                            typographyStyle(for: target).supportingFont(
                                size: 10,
                                weight: .medium,
                                fallback: .system(size: 10, weight: .medium, design: .rounded)
                            )
                        )
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func sampleText(for target: WidgetTypographyTarget) -> String {
        switch target {
        case .timeAndDate: "09:09"
        case .weather: "72°"
        case .battery: "82%"
        case .calendar: "AUG 09"
        }
    }

    private func sampleDetail(for target: WidgetTypographyTarget) -> String {
        if resolutions[target] == .widgetFonts {
            return "Each copy's fonts"
        }
        return coverage == .allText ? "All text" : "Display text"
    }

    private func typographyStyle(for target: WidgetTypographyTarget) -> WidgetTypographyStyle {
        WidgetTypographyStyle(
            resolution: resolutions[target] ?? .theme(.system),
            coverage: coverage
        )
    }
}

private struct WidgetTypographyOverrideRow: View {
    let target: WidgetTypographyTarget
    let selection: WidgetTypographyOverride
    let onSelect: (WidgetTypographyOverride) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: target.symbolName)
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 22)

            Text(target.displayName)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 4)

            Menu {
                ForEach(WidgetTypographyOverride.options(for: target)) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        if selection == option {
                            Label(option.displayName, systemImage: "checkmark")
                        } else {
                            Text(option.displayName)
                        }
                    }
                }
            } label: {
                Text(selection.displayName)
                    .lineLimit(1)
            }
            .accessibilityLabel("Typography for \(target.displayName)")
            .frame(maxWidth: 190, alignment: .trailing)
        }
        .padding(11)
        .background(.quaternary.opacity(0.22), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ReadyWidgetCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 46, height: 46)
                .background(WidgetTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Ready")
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(WidgetTheme.accent.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.bold())

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(WidgetTheme.accent, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct WidgetGuideItem: Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String { title }
}

private struct WidgetGuideSection: View {
    let title: String
    let subtitle: String
    let items: [WidgetGuideItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "\(title) options", subtitle: subtitle)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(items) { item in
                    CustomizationItem(
                        symbol: item.symbol,
                        title: item.title,
                        detail: item.detail
                    )
                }
            }
        }
    }
}

private struct CustomizationItem: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct CalendarPermissionCard: View {
    @ObservedObject var controller: CalendarPermissionController

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: statusSymbol)
                .font(.title2)
                .foregroundStyle(statusColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(buttonTitle) {
                if controller.state == .denied {
                    controller.openPrivacySettings()
                } else {
                    controller.requestAccess()
                }
            }
            .disabled(controller.state == .fullAccess || controller.isRequesting)
        }
        .padding(14)
        .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
    }

    private var statusSymbol: String {
        switch controller.state {
        case .notDetermined: "calendar.badge.plus"
        case .fullAccess: "checkmark.circle.fill"
        case .denied: "calendar.badge.exclamationmark"
        }
    }

    private var statusColor: Color {
        controller.state == .fullAccess ? .green : WidgetTheme.accent
    }

    private var statusTitle: String {
        switch controller.state {
        case .notDetermined: "Event indicators are off"
        case .fullAccess: "Calendar access enabled"
        case .denied: "Calendar access is off"
        }
    }

    private var statusDetail: String {
        switch controller.state {
        case .notDetermined:
            "Enable access only if you want event counts and dots. The widget never displays event titles or notes."
        case .fullAccess:
            "Calendar widgets with Show Event Indicators enabled can read event timing and display counts."
        case .denied:
            "Open Privacy & Security → Calendars to allow optional event indicators."
        }
    }

    private var buttonTitle: String {
        if controller.isRequesting { return "Requesting…" }
        return switch controller.state {
        case .notDetermined: "Enable Access"
        case .fullAccess: "Enabled"
        case .denied: "Open Settings"
        }
    }
}

private struct WidgetStatusCard: View {
    let widget: WidgetStatus

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: widget.symbol)
                .font(.title3)
                .frame(width: 28, height: 28)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(widget.name)
                    .font(.subheadline.weight(.semibold))

                Text(widget.status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.20), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
