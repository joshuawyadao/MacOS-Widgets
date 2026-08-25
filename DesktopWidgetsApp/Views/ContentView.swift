import SwiftUI

struct ContentView: View {
    private let upcomingWidgets = [
        WidgetStatus(name: "Calendar", symbol: "calendar", status: "Coming next", isAvailable: false),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                readyWidgets
                setupGuide
                customizationGuide
                batteryGuide
                weatherDetailLimitsTip
                appearanceTip
                weatherDataTip
                upcomingSection
            }
            .padding(28)
        }
        .frame(minWidth: 680, minHeight: 560)
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

            HStack(alignment: .top, spacing: 12) {
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
            }
        }
    }

    private var setupGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Set up in two steps", subtitle: "You only need the app to install and update the widget.")

            SetupStep(
                number: 1,
                title: "Add it to the desktop",
                detail: "Control-click the desktop, choose Edit Widgets, search for Desktop Widgets, then drag Time & Date, Weather, or Battery onto the desktop."
            )

            SetupStep(
                number: 2,
                title: "Make it yours",
                detail: "Control-click a placed widget and choose Edit to set its options. Battery follows this Mac automatically and lets each copy choose its extra details."
            )
        }
    }

    private var customizationGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Time & Date options", subtitle: "Each copy can have its own layout, formats, and fonts.")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                CustomizationItem(
                    symbol: "rectangle.3.group",
                    title: "Arrangement",
                    detail: "Classic, compact, centered, time first, or side by side."
                )
                CustomizationItem(
                    symbol: "calendar",
                    title: "Date",
                    detail: "Choose a word-based, month-first, day-first, or ISO style."
                )
                CustomizationItem(
                    symbol: "clock",
                    title: "Clock",
                    detail: "Switch between a familiar 12-hour clock and a 24-hour clock."
                )
                CustomizationItem(
                    symbol: "textformat",
                    title: "Fonts",
                    detail: "Pick separate clean, classic, or handwritten fonts for date and time."
                )
            }

            SectionTitle(title: "Weather options", subtitle: "Each copy can track a different city and forecast.")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                CustomizationItem(
                    symbol: "building.2",
                    title: "City",
                    detail: "Open City, type at least two letters, then choose from up to 20 clearly labeled matching places."
                )
                CustomizationItem(
                    symbol: "calendar.day.timeline.leading",
                    title: "Forecast view",
                    detail: "Switch between the week, today, and the next six hours. Large widgets add an expanded current-weather dashboard."
                )
                CustomizationItem(
                    symbol: "thermometer.medium",
                    title: "Units",
                    detail: "Match this Mac automatically or choose Fahrenheit or Celsius."
                )
                CustomizationItem(
                    symbol: "square.stack.3d.up",
                    title: "Details preset",
                    detail: "Apply a useful group such as Simple, Rain, Comfort, Detailed, or Full with one click."
                )
            }
        }
    }

    private var batteryGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Battery at a glance", subtitle: "No account or accessory access is required.")

            HStack(spacing: 12) {
                CustomizationItem(
                    symbol: "battery.75percent",
                    title: "Live charge",
                    detail: "The percentage and battery fill follow this Mac's internal battery."
                )
                CustomizationItem(
                    symbol: "timer",
                    title: "Choose details",
                    detail: "Toggle Power, Status, Estimate, and Updated. Each size shows only what fits."
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

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Coming next", subtitle: "These widgets will appear here as they become ready.")

            HStack(spacing: 12) {
                ForEach(upcomingWidgets) { widget in
                    WidgetStatusCard(widget: widget)
                }
            }
        }
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
