import SwiftUI

struct HomePage: View {
    @Binding var destination: CompanionAppDestination?
    @ObservedObject var calendarPermission: CalendarPermissionController

    var body: some View {
        AppPage(
            title: "Home",
            subtitle: "Everything you need to set up and personalize your desktop widgets."
        ) {
            header
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
                title: "Set up in two steps",
                subtitle: "You only need the app to install and update the widget."
            )

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
}
