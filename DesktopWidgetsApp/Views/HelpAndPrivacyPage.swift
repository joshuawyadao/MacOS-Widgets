import AppKit
import SwiftUI

struct HelpAndPrivacyPage: View {
    @ObservedObject var calendarPermission: CalendarPermissionController
    let automaticStatusRevision: Int

    var body: some View {
        AppPage(
            title: "Help & Privacy",
            subtitle: "Find editing help, permission controls, data details, and quick troubleshooting."
        ) {
            helpGuide
            installationHelp

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

    private var installationHelp: some View {
        _ = automaticStatusRevision
        let status = DesktopWidgetsInstallationStatus.current()
        let automatic = DesktopWidgetsAutomaticRefreshStatus.current(
            appGroupIdentifier: status.appGroupIdentifier
        )
        return VStack(alignment: .leading, spacing: 12) {
            SectionTitle(
                title: "Installation & refresh",
                subtitle: "Automatic maintenance handles normal expiry; manual Refresh is the fallback."
            )

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .foregroundStyle(WidgetTheme.accent)

                VStack(alignment: .leading, spacing: 6) {
                    Text(automatic.title)
                        .font(.headline)
                    Text(automatic.message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("The scheduled check has no KeepAlive process. It runs at login and 11:00 AM, exits when signing is healthy, and starts a low-priority build only inside the final 48 hours of a profile or conservative profile-free renewal window.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        if status.refreshCommandExists, let refreshURL = status.refreshCommandURL {
                            Button("Show Manual Refresh") {
                                NSWorkspace.shared.activateFileViewerSelecting([refreshURL])
                            }
                            .buttonStyle(.link)
                        }
                        if automatic.isEnabled,
                           status.disableAutomaticRefreshCommandExists,
                           let disableURL = status.disableAutomaticRefreshCommandURL {
                            Button("Show Disable Command") {
                                NSWorkspace.shared.activateFileViewerSelecting([disableURL])
                            }
                            .buttonStyle(.link)
                        } else if status.enableAutomaticRefreshCommandExists,
                                  let enableURL = status.enableAutomaticRefreshCommandURL {
                            Button("Show Enable Command") {
                                NSWorkspace.shared.activateFileViewerSelecting([enableURL])
                            }
                            .buttonStyle(.link)
                        }
                    }

                    if !status.refreshCommandExists {
                        Text("If the button is missing, run Install Desktop Widgets.command again from the folder you received.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    DisclosureGroup("Technical details") {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("App: \(status.bundleURL.path)")
                            Text("Expected: \(status.expectedBundleURL.path)")
                            Text("Bundle ID: \(status.bundleIdentifier)")
                            Text("Signing team: \(status.teamIdentifier.isEmpty ? "Not detected" : status.teamIdentifier)")
                            Text("App Group: \(status.appGroupIdentifier.isEmpty ? "Not detected" : status.appGroupIdentifier)")
                            Text("Automatic state: \(automatic.state.rawValue)")
                            Text("Last check: \(automatic.lastCheck ?? "Not reported")")
                            Text("Last success: \(automatic.lastSuccess ?? "Not reported")")
                            Text("Renewal deadline: \(automatic.profileExpiration ?? "Not reported")")
                        }
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .padding(.top, 5)
                    }
                    .font(.caption)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(.quaternary.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
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
