import SwiftUI

struct HelpAndPrivacyPage: View {
    @ObservedObject var calendarPermission: CalendarPermissionController

    var body: some View {
        AppPage(
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
            GlassBackgroundTip()
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
