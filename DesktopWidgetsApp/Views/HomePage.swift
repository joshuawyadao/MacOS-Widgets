import AppKit
import SwiftUI

struct HomePage: View {
    @Binding var destination: CompanionAppDestination?
    @ObservedObject var calendarPermission: CalendarPermissionController
    let automaticStatusRevision: Int

    var body: some View {
        AppPage(
            title: "Home",
            subtitle: "Everything you need to set up and personalize your desktop widgets."
        ) {
            header
            installationCard
            automaticMaintenanceCard
            shortcuts
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

    private var automaticMaintenanceCard: some View {
        _ = automaticStatusRevision
        let installation = installationStatus
        let automatic = DesktopWidgetsAutomaticRefreshStatus.current(
            appGroupIdentifier: installation.appGroupIdentifier
        )
        let color: Color = automatic.state == .needsAttention
            ? .orange
            : (automatic.isEnabled ? .green : WidgetTheme.accent)
        let helperURL = automatic.isEnabled
            ? installation.disableAutomaticRefreshCommandURL
            : installation.enableAutomaticRefreshCommandURL
        let helperExists = automatic.isEnabled
            ? installation.disableAutomaticRefreshCommandExists
            : installation.enableAutomaticRefreshCommandExists

        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: automatic.state == .needsAttention
                  ? "exclamationmark.triangle.fill"
                  : "clock.arrow.circlepath")
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 5) {
                Text(automatic.title)
                    .font(.headline)
                Text(automatic.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The check runs briefly at login and daily, then exits. Xcode only rebuilds inside the final 48 hours of free signing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if helperExists, let helperURL {
                    Button(automatic.isEnabled ? "Show Disable Command" : "Show Enable Command") {
                        NSWorkspace.shared.activateFileViewerSelecting([helperURL])
                    }
                    .buttonStyle(.link)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.22), lineWidth: 1)
        }
    }

    private var installationStatus: DesktopWidgetsInstallationStatus {
        .current()
    }

    private var installationCard: some View {
        let status = installationStatus
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: status.isReady ? "checkmark.seal.fill" : "wrench.and.screwdriver.fill")
                .font(.title2)
                .foregroundStyle(status.isReady ? .green : WidgetTheme.accent)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 5) {
                Text(status.isReady ? "Installed and ready" : "Finish the friendly setup")
                    .font(.headline)

                Text(status.isReady
                     ? "Desktop Widgets is in your Applications folder and has the shared signing setup its widgets need."
                     : "Double-click Install Desktop Widgets.command in the folder you received. It will explain any one-time Xcode step.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if status.refreshCommandExists, let refreshURL = status.refreshCommandURL {
                    Button("Show Refresh Command") {
                        NSWorkspace.shared.activateFileViewerSelecting([refreshURL])
                    }
                    .buttonStyle(.link)
                    .accessibilityHint("Shows the manual refresh command in Finder")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background((status.isReady ? Color.green : WidgetTheme.accent).opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke((status.isReady ? Color.green : WidgetTheme.accent).opacity(0.22), lineWidth: 1)
        }
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

    private var shortcuts: some View {
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
            SectionTitle(
                title: "Ready widgets",
                subtitle: "Add any of these widgets from the macOS widget gallery."
            )

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

    private var setupGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(
                title: "Your setup checklist",
                subtitle: "The installer handles the technical work. macOS leaves placement and style up to you."
            )

            SetupStep(
                number: 1,
                title: "Install once",
                detail: "Double-click Install Desktop Widgets.command. If asked, add your Apple Account in Xcode; the installer never sees your password."
            )

            SetupStep(
                number: 2,
                title: "Add it to the desktop",
                detail: "Control-click the desktop, choose Edit Widgets, search for Desktop Widgets, then drag a widget into place. Apple requires you to place widgets yourself; this app cannot arrange the desktop."
            )

            SetupStep(
                number: 3,
                title: "Make it yours",
                detail: "Open Appearance here to choose a shared style, or Control-click a placed widget and choose Edit to customize only that copy."
            )

            SetupStep(
                number: 4,
                title: "Let maintenance stay easy",
                detail: "Choose automatic maintenance during installation. A tiny daily check exits immediately unless free signing has less than 48 hours left. Refresh Desktop Widgets.command remains the manual fallback if Xcode ever needs attention."
            )
        }
    }
}
