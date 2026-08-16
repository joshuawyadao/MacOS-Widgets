import SwiftUI

struct ContentView: View {
    private let upcomingWidgets = [
        WidgetStatus(name: "Weather", symbol: "cloud.sun", status: "Coming next", isAvailable: false),
        WidgetStatus(name: "Battery", symbol: "battery.75percent", status: "Coming next", isAvailable: false),
        WidgetStatus(name: "Calendar", symbol: "calendar", status: "Coming next", isAvailable: false),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                readyCard
                setupGuide
                customizationGuide
                appearanceTip
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

    private var readyCard: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: "clock")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(WidgetTheme.accent)
                .frame(width: 52, height: 52)
                .background(WidgetTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text("Time & Date")
                    .font(.title2.bold())

                Text("Choose how the date and clock are arranged, formatted, and styled.")
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            Label("Ready", systemImage: "checkmark.circle.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(.green.opacity(0.10), in: Capsule())
        }
        .padding(20)
        .background(WidgetTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(WidgetTheme.accent.opacity(0.20), lineWidth: 1)
        }
    }

    private var setupGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Set up in two steps", subtitle: "You only need the app to install and update the widget.")

            SetupStep(
                number: 1,
                title: "Add it to the desktop",
                detail: "Control-click the desktop, choose Edit Widgets, search for Desktop Widgets, then drag Time & Date onto the desktop."
            )

            SetupStep(
                number: 2,
                title: "Make it yours",
                detail: "Control-click the placed widget, choose Edit “Time & Date,” pick your options, then click anywhere outside the editor to save."
            )
        }
    }

    private var customizationGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "What you can change", subtitle: "Each copy of the widget can have its own look.")

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
        }
    }

    private var appearanceTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(WidgetTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("About the glass background")
                    .font(.headline)

                Text("With the Clear icon and widget style, macOS replaces widget backgrounds with Liquid Glass. Clear Light gives the softest appearance.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
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
