import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var calendarPermission = CalendarPermissionController()
    @StateObject private var typography = WidgetTypographyController()
    @State private var destination: CompanionAppDestination? = .home

    var body: some View {
        NavigationSplitView {
            List(selection: $destination) {
                sidebarRows(destinations: CompanionAppDestination.overview)

                Section("Customize") {
                    sidebarRows(destinations: CompanionAppDestination.customize)
                }

                Section("Widgets") {
                    sidebarRows(destinations: CompanionAppDestination.widgets)
                }

                Section("Support") {
                    sidebarRows(destinations: CompanionAppDestination.support)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Desktop Widgets")
            .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 250)
        } detail: {
            detailPage(for: destination ?? .home)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 820, minHeight: 620)
        .onAppear {
            calendarPermission.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            calendarPermission.refreshAndReloadWidget()
        }
    }

    @ViewBuilder
    private func sidebarRows(destinations: [CompanionAppDestination]) -> some View {
        ForEach(destinations) { destination in
            sidebarRow(destination)
        }
    }

    private func sidebarRow(_ item: CompanionAppDestination) -> some View {
        HStack(spacing: 8) {
            Label(item.title, systemImage: item.symbolName)
            Spacer(minLength: 4)
            if item == .appearance && typography.hasPendingChanges {
                Circle()
                    .fill(WidgetTheme.accent)
                    .frame(width: 7, height: 7)
                    .accessibilityLabel("Unapplied appearance changes")
            }
        }
        .tag(item)
        .accessibilityHint("Shows the \(item.title) page")
    }

    @ViewBuilder
    private func detailPage(for destination: CompanionAppDestination) -> some View {
        switch destination {
        case .home:
            homePage
        case .appearance:
            appearancePage
        case .timeAndDate, .weather, .battery, .calendar:
            widgetPage(destination)
        case .helpAndPrivacy:
            helpAndPrivacyPage
        }
    }

    private var homePage: some View {
        appPage(title: "Home", subtitle: "Everything you need to set up and personalize your desktop widgets.") {
            header
            homeShortcuts
            readyWidgets
            setupGuide

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(
                    title: "Optional Calendar features",
                    subtitle: "Calendar access is only needed for private event dots, counts, or next-event timing."
                )
                CalendarPermissionCard(controller: calendarPermission)
            }
        }
    }

    private var appearancePage: some View {
        appPage(
            title: "Appearance",
            subtitle: "Preview one coordinated style, then apply it to all four widget types."
        ) {
            typographyGuide
            appearanceTip
        }
    }

    private func widgetPage(_ widget: CompanionAppDestination) -> some View {
        appPage(title: widget.title, subtitle: widgetSubtitle(widget)) {
            editWidgetCard(widget)
            widgetGuide(widget)

            if widget == .weather {
                weatherDetailLimitsTip
            }

            if widget == .calendar {
                CalendarPermissionCard(controller: calendarPermission)
            }

            Button {
                destination = .appearance
            } label: {
                Label("Customize \(widget.title) appearance", systemImage: "paintbrush")
            }
        }
    }

    private var helpAndPrivacyPage: some View {
        appPage(
            title: "Help & Privacy",
            subtitle: "Find editing help, permission controls, data details, and quick troubleshooting."
        ) {
            helpGuide

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(
                    title: "Calendar access",
                    subtitle: "Optional, local, and used only for event timing."
                )
                CalendarPermissionCard(controller: calendarPermission)
            }

            weatherDataTip
            appearanceTip
        }
    }

    private func appPage<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeader(title: title, subtitle: subtitle)
                content()
            }
            .frame(maxWidth: 940, alignment: .leading)
            .padding(28)
        }
        .navigationTitle(title)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome")
                .font(.title.bold())

            Text("Simple, personal widgets without subscriptions or upgrade prompts. Choose a widget below whenever you want help changing it.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var homeShortcuts: some View {
        HStack(spacing: 12) {
            Button {
                destination = .appearance
            } label: {
                HomeShortcutCard(
                    symbol: "paintbrush",
                    title: "Personalize the look",
                    detail: "Preview fonts and apply one coordinated theme."
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens Appearance")

            Button {
                destination = .helpAndPrivacy
            } label: {
                HomeShortcutCard(
                    symbol: "questionmark.circle",
                    title: "Get help",
                    detail: "Find editing, privacy, and troubleshooting guidance."
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens Help and Privacy")
        }
    }

    private var readyWidgets: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Ready widgets", subtitle: "Add any of these widgets from the macOS widget gallery.")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                widgetCard(
                    destination: .timeAndDate,
                    detail: "Arrange and style the clock, with an optional second time zone."
                )
                widgetCard(
                    destination: .weather,
                    detail: "Choose a city, forecast view, units, and details."
                )
                widgetCard(
                    destination: .battery,
                    detail: "See charge and runtime, then choose which extra details each copy shows."
                )
                widgetCard(
                    destination: .calendar,
                    detail: "Choose Day, Week, or Month with private event timing options."
                )
            }
        }
    }

    private func widgetCard(
        destination widget: CompanionAppDestination,
        detail: String
    ) -> some View {
        Button {
            destination = widget
        } label: {
            ReadyWidgetCard(
                symbol: widget.symbolName,
                title: widget.title,
                detail: detail
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(widget.title) options and setup help")
    }

    private var typographyGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(
                title: "Appearance theme",
                subtitle: "Preview a coordinated style here, then apply the finished appearance to all widgets with one update request."
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
                    typography.previewSystemStyle()
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

            HStack(spacing: 12) {
                Group {
                    if typography.hasPendingChanges {
                        Label(
                            "Preview only — apply when it looks right",
                            systemImage: "eye"
                        )
                    } else if let applicationFeedback = typography.applicationFeedback {
                        Label(applicationFeedback, systemImage: "checkmark.circle.fill")
                    } else {
                        Label("Desktop widgets match this preview", systemImage: "checkmark.circle")
                    }
                }
                .font(.caption)
                .foregroundStyle(typography.hasPendingChanges ? WidgetTheme.accent : .secondary)

                Spacer(minLength: 0)

                Button("Revert") {
                    typography.revertPreview()
                }
                .disabled(!typography.hasPendingChanges)

                Button("Apply Theme") {
                    typography.apply()
                }
                .buttonStyle(.borderedProminent)
                .tint(WidgetTheme.accent)
                .disabled(!typography.hasPendingChanges)
            }
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
                detail: "Control-click configurable widgets to edit their options. Calendar can use Automatic, Day, Week, or Month, with optional event indicators or next-event timing after you enable access below."
            )
        }
    }

    private func widgetSubtitle(_ widget: CompanionAppDestination) -> String {
        switch widget {
        case .timeAndDate:
            "Arrange the clock, choose date and time formats, and optionally add a second time zone."
        case .weather:
            "Choose a city, forecast view, units, and the weather details that matter to you."
        case .battery:
            "See this Mac's charge and power state with optional runtime and battery-health details."
        case .calendar:
            "Choose a focused Day, Week, or Month view with optional private event timing."
        default:
            ""
        }
    }

    private func editWidgetCard(_ widget: CompanionAppDestination) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "slider.horizontal.3")
                .font(.title2)
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text("Edit a placed \(widget.title) widget")
                    .font(.headline)
                Text("Control-click the widget on your desktop, choose Edit \(widget.title), then adjust the options for that copy.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(WidgetTheme.accent.opacity(0.18), lineWidth: 1)
        }
    }

    private func widgetGuide(_ widget: CompanionAppDestination) -> some View {
        WidgetGuideSection(
            title: widget.title,
            subtitle: widgetGuideSubtitle(widget),
            items: widgetGuideItems(widget)
        )
    }

    private func widgetGuideSubtitle(_ widget: CompanionAppDestination) -> String {
        switch widget {
        case .timeAndDate:
            "Every placed copy keeps its own layout and format choices."
        case .weather:
            "Forecast content adapts to the widget's size and selected view."
        case .battery:
            "All readings stay local to this Mac and require no account."
        case .calendar:
            "Event features use timing only and never display event titles or notes."
        default:
            ""
        }
    }

    private func widgetGuideItems(_ widget: CompanionAppDestination) -> [WidgetGuideItem] {
        switch widget {
        case .timeAndDate:
            [
                WidgetGuideItem(symbol: "rectangle.3.group", title: "View", detail: "Classic, compact, centered, time first, or side by side."),
                WidgetGuideItem(symbol: "calendar", title: "Date", detail: "Choose a word-based, month-first, day-first, or ISO date."),
                WidgetGuideItem(symbol: "clock", title: "Time", detail: "Use a 12-hour or 24-hour clock; AM/PM adapts automatically."),
                WidgetGuideItem(symbol: "globe", title: "Second Clock", detail: "Add a world time zone and an optional label such as Home or Family."),
                WidgetGuideItem(symbol: "textformat", title: "Appearance", detail: "Follow the app theme or preserve separate date and time fonts for each copy."),
            ]
        case .weather:
            [
                WidgetGuideItem(symbol: "building.2", title: "City", detail: "Search for a city and choose the exact region and country."),
                WidgetGuideItem(symbol: "calendar.day.timeline.leading", title: "View", detail: "Switch between the week, today, and the next six hours."),
                WidgetGuideItem(symbol: "square.stack.3d.up", title: "Details", detail: "Choose presets for comfort, rain, outdoor conditions, UV, sunrise, and sunset."),
                WidgetGuideItem(symbol: "thermometer.medium", title: "Units", detail: "Follow this Mac or choose Fahrenheit or Celsius."),
            ]
        case .battery:
            [
                WidgetGuideItem(symbol: "battery.75percent", title: "Source", detail: "Reads this Mac's internal battery through the local system API."),
                WidgetGuideItem(symbol: "rectangle.3.group", title: "Size", detail: "Small emphasizes charge; Medium and Large progressively add details."),
                WidgetGuideItem(symbol: "timer", title: "Details", detail: "Toggle Power, Status, Estimate, Updated, Health, and Cycles for each copy."),
                WidgetGuideItem(symbol: "bolt.fill", title: "Status", detail: "Distinguishes charging, discharging, AC power, calculating, and no battery."),
            ]
        case .calendar:
            [
                WidgetGuideItem(symbol: "calendar", title: "Source", detail: "Uses this Mac's calendar, locale, time zone, and first-weekday preference."),
                WidgetGuideItem(symbol: "rectangle.3.group", title: "View", detail: "Automatic chooses Day, Week, or Month by size; each copy can override it."),
                WidgetGuideItem(symbol: "circle.grid.2x2.fill", title: "Event Marks", detail: "Optional counts and dots show busy days without revealing event text."),
                WidgetGuideItem(symbol: "calendar.badge.clock", title: "Next Event", detail: "Optionally show only the next timed event's start time, never its title."),
                WidgetGuideItem(symbol: "arrow.left.arrow.right", title: "Navigation", detail: "Month view can move backward, forward, or return to the current month."),
            ]
        default:
            []
        }
    }

    private var helpGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(
                title: "Quick help",
                subtitle: "The most common widget tasks are available from the desktop."
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                CustomizationItem(
                    symbol: "plus.rectangle.on.rectangle",
                    title: "Add a widget",
                    detail: "Control-click the desktop, choose Edit Widgets, then search for Desktop Widgets."
                )
                CustomizationItem(
                    symbol: "slider.horizontal.3",
                    title: "Edit a widget",
                    detail: "Control-click a placed widget and choose Edit to change only that copy."
                )
                CustomizationItem(
                    symbol: "arrow.clockwise",
                    title: "Appearance update",
                    detail: "After Apply Theme, macOS updates each placed widget independently; they may finish a few moments apart."
                )
                CustomizationItem(
                    symbol: "rectangle.dashed.badge.record",
                    title: "Blank placeholder",
                    detail: "Close Edit Widgets and reopen Desktop Widgets. Time & Date, Battery, and Calendar should stay in place; only a legacy Weather copy may need to be added again."
                )
            }
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
    @Published private var selection: WidgetTypographySelection
    @Published private(set) var applicationFeedback: String?

    private let applier: WidgetTypographyApplier
    private var appliedSelection: WidgetTypographySelection

    init(
        store: WidgetTypographyStore = .live,
        requestReload: @escaping () -> Void = {
            WidgetCenter.shared.reloadAllTimelines()
        }
    ) {
        self.applier = WidgetTypographyApplier(
            store: store,
            requestReload: requestReload
        )
        let storedSelection = WidgetTypographySelection(store: store)
        self.selection = storedSelection
        self.appliedSelection = storedSelection
    }

    var globalTheme: WidgetTypographyTheme {
        selection.globalTheme
    }

    var coverage: WidgetTypographyCoverage {
        selection.coverage
    }

    var usesSystemDefaults: Bool {
        selection.usesSystemDefaults
    }

    var hasPendingChanges: Bool {
        selection != appliedSelection
    }

    func override(for target: WidgetTypographyTarget) -> WidgetTypographyOverride {
        selection.override(for: target)
    }

    func resolution(for target: WidgetTypographyTarget) -> WidgetTypographyResolution {
        selection.resolution(for: target)
    }

    func setGlobalTheme(_ theme: WidgetTypographyTheme) {
        selection.globalTheme = theme
        applicationFeedback = nil
    }

    func setCoverage(_ coverage: WidgetTypographyCoverage) {
        selection.coverage = coverage
        applicationFeedback = nil
    }

    func setOverride(
        _ override: WidgetTypographyOverride,
        for target: WidgetTypographyTarget
    ) {
        selection.setOverride(override, for: target)
        applicationFeedback = nil
    }

    func previewSystemStyle() {
        selection = .systemDefault
        applicationFeedback = nil
    }

    func revertPreview() {
        selection = appliedSelection
        applicationFeedback = nil
    }

    func apply() {
        guard hasPendingChanges else { return }
        applier.apply(selection)
        appliedSelection = selection
        applicationFeedback = "Theme applied — macOS is updating the widgets"
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
                VStack(
                    alignment: .leading,
                    spacing: typographyStyle(for: target).verticalSpacing(7)
                ) {
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
                        .minimumScaleFactor(
                            typographyStyle(for: target).supportingMinimumScaleFactor(0.7)
                        )
                        .padding(
                            .vertical,
                            typographyStyle(for: target).supportingTextVerticalPadding
                        )

                    Text(sampleText(for: target))
                        .font(
                            typographyStyle(for: target).displayFont(
                                size: 24,
                                weight: .black,
                                fallback: .custom("Noteworthy-Bold", size: 24)
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(
                            typographyStyle(for: target).displayMinimumScaleFactor(0.7)
                        )
                        .padding(
                            .vertical,
                            typographyStyle(for: target).displayTextVerticalPadding
                        )

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
                        .minimumScaleFactor(
                            typographyStyle(for: target).supportingMinimumScaleFactor(0.7)
                        )
                        .padding(
                            .vertical,
                            typographyStyle(for: target).supportingTextVerticalPadding
                        )
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

            VStack(alignment: .trailing, spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Ready")

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 106, alignment: .topLeading)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(WidgetTheme.accent.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.largeTitle.bold())

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HomeShortcutCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 42, height: 42)
                .background(WidgetTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
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
        case .notDetermined: "Calendar event features are off"
        case .fullAccess: "Calendar access enabled"
        case .denied: "Calendar access is off"
        }
    }

    private var statusDetail: String {
        switch controller.state {
        case .notDetermined:
            "Enable access only if you want event counts, dots, or next-event timing. The widget never displays event titles or notes."
        case .fullAccess:
            "Calendar widgets can use event timing for private counts, dots, or a title-free next-event time."
        case .denied:
            "Open Privacy & Security → Calendars to allow optional event indicators or next-event timing."
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

#Preview {
    ContentView()
}
