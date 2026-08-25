import SwiftUI
import WidgetKit

struct BatteryEntry: TimelineEntry {
    let date: Date
    let snapshot: BatterySnapshot?
}

struct BatteryProvider: TimelineProvider {
    private let reader = SystemBatteryReader()

    func placeholder(in context: Context) -> BatteryEntry {
        BatteryEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (BatteryEntry) -> Void) {
        completion(BatteryEntry(
            date: .now,
            snapshot: context.isPreview ? .sample : reader.snapshot()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryEntry>) -> Void) {
        let now = Date.now
        let entry = BatteryEntry(date: now, snapshot: reader.snapshot())
        completion(Timeline(
            entries: [entry],
            policy: .after(BatteryTimelinePolicy.refreshDate(after: now))
        ))
    }
}

struct BatteryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    let entry: BatteryEntry

    private var presentation: BatteryWidgetPresentation {
        BatteryWidgetPresentation(snapshot: entry.snapshot)
    }

    private var metrics: BatteryWidgetLayoutMetrics {
        BatteryWidgetLayoutMetrics(family: family)
    }

    var body: some View {
        HStack(spacing: metrics.contentSpacing) {
            VStack(alignment: .leading, spacing: 2) {
                Text(presentation.percentageText)
                    .font(.system(size: metrics.percentageFontSize, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(presentation.statusText)
                    .font(.system(size: metrics.statusFontSize, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            BatteryGauge(
                fillFraction: presentation.fillFraction,
                isAvailable: presentation.showsBattery
            )
            .frame(width: metrics.iconWidth, height: metrics.iconHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(renderingMode == .fullColor ? Color.white : Color.primary)
        .shadow(
            color: renderingMode == .fullColor ? .black.opacity(0.5) : .clear,
            radius: 1.5,
            x: 0,
            y: 1
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityLabel)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct BatteryGauge: View {
    let fillFraction: Double
    let isAvailable: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let terminalHeight = max(4, height * 0.09)
            let bodyTop = terminalHeight * 0.72
            let bodyHeight = height - bodyTop
            let lineWidth = max(2, width * 0.065)
            let inset = lineWidth * 2.1
            let fillHeight = max(0, bodyHeight - inset * 2) * fillFraction

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: width * 0.08, style: .continuous)
                    .fill(.primary)
                    .frame(width: width * 0.30, height: terminalHeight)

                RoundedRectangle(cornerRadius: width * 0.13, style: .continuous)
                    .stroke(.primary, lineWidth: lineWidth)
                    .frame(width: width, height: bodyHeight)
                    .offset(y: bodyTop)

                if isAvailable {
                    RoundedRectangle(cornerRadius: width * 0.055, style: .continuous)
                        .fill(.primary)
                        .frame(width: width - inset * 2, height: fillHeight)
                        .offset(y: bodyTop + bodyHeight - inset - fillHeight)
                } else {
                    Rectangle()
                        .fill(.primary)
                        .frame(width: width * 0.65, height: lineWidth)
                        .rotationEffect(.degrees(-45))
                        .offset(y: bodyTop + bodyHeight * 0.48)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct BatteryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: WidgetIdentifier.battery.rawValue,
            provider: BatteryProvider()
        ) { entry in
            BatteryWidgetView(entry: entry)
        }
        .configurationDisplayName("Battery")
        .description("Battery percentage, current power state, and macOS time estimate at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .containerBackgroundRemovable(true)
    }
}

#if DEBUG
struct BatteryWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BatteryWidgetView(entry: BatteryEntry(date: .now, snapshot: .sample))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            BatteryWidgetView(entry: BatteryEntry(
                date: .now,
                snapshot: BatterySnapshot(
                    percentage: 42,
                    state: .charging,
                    timeRemainingMinutes: 72
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            BatteryWidgetView(entry: BatteryEntry(
                date: .now,
                snapshot: BatterySnapshot(
                    percentage: 100,
                    state: .charged,
                    timeRemainingMinutes: nil
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
#endif
