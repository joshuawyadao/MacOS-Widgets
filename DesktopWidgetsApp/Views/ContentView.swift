import SwiftUI

struct ContentView: View {
    private let widgets = [
        WidgetStatus(name: "Time and Date", symbol: "clock", status: "Foundation ready", isAvailable: true),
        WidgetStatus(name: "Weather", symbol: "cloud.sun", status: "Coming next", isAvailable: false),
        WidgetStatus(name: "Battery", symbol: "battery.75percent", status: "Coming next", isAvailable: false),
        WidgetStatus(name: "Calendar", symbol: "calendar", status: "Coming next", isAvailable: false),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Desktop Widgets")
                    .font(.largeTitle.bold())

                Text("Personal widgets, built without subscriptions or upgrade prompts.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(widgets) { widget in
                    WidgetStatusCard(widget: widget)
                }
            }

            Spacer()

            Label(
                "After running the app, control-click the desktop and choose Edit Widgets.",
                systemImage: "info.circle"
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(minWidth: 560, minHeight: 400)
    }
}

private struct WidgetStatusCard: View {
    let widget: WidgetStatus

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: widget.symbol)
                .font(.title2)
                .frame(width: 34, height: 34)
                .foregroundStyle(widget.isAvailable ? WidgetTheme.accent : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(widget.name)
                    .font(.headline)

                Text(widget.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: widget.isAvailable ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(widget.isAvailable ? .green : .secondary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
