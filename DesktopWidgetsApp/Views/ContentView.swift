import SwiftUI

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
            HomePage(
                destination: $destination,
                calendarPermission: calendarPermission
            )
        case .appearance:
            AppearancePage(typography: typography)
        case .timeAndDate, .weather, .battery, .calendar:
            WidgetGuidePage(
                widget: destination,
                destination: $destination,
                calendarPermission: calendarPermission
            )
        case .helpAndPrivacy:
            HelpAndPrivacyPage(calendarPermission: calendarPermission)
        }
    }
}

#Preview {
    ContentView()
}
