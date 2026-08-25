import AppIntents
import SwiftUI
import WidgetKit

struct BatteryEntry: TimelineEntry {
    let date: Date
    let configuration: BatteryConfigurationIntent
    let snapshot: BatterySnapshot?
}

struct BatteryProvider: AppIntentTimelineProvider {
    private let reader = SystemBatteryReader()

    func placeholder(in context: Context) -> BatteryEntry {
        BatteryEntry(date: .now, configuration: .referencePreview(), snapshot: .sample)
    }

    func snapshot(
        for configuration: BatteryConfigurationIntent,
        in context: Context
    ) async -> BatteryEntry {
        BatteryEntry(
            date: .now,
            configuration: configuration,
            snapshot: context.isPreview ? .sample : reader.snapshot()
        )
    }

    func timeline(
        for configuration: BatteryConfigurationIntent,
        in context: Context
    ) async -> Timeline<BatteryEntry> {
        let now = Date.now
        let entry = BatteryEntry(
            date: now,
            configuration: configuration,
            snapshot: reader.snapshot()
        )
        return Timeline(
            entries: [entry],
            policy: .after(BatteryTimelinePolicy.refreshDate(after: now))
        )
    }
}

struct BatteryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone

    let entry: BatteryEntry

    private var presentation: BatteryWidgetPresentation {
        BatteryWidgetPresentation(
            snapshot: entry.snapshot,
            updatedAt: entry.date,
            locale: locale,
            timeZone: timeZone
        )
    }

    private var metrics: BatteryWidgetLayoutMetrics {
        BatteryWidgetLayoutMetrics(family: family)
    }

    private var detailSelection: BatteryDetailSelection {
        BatteryDetailSelection(configuration: entry.configuration, family: family)
    }

    var body: some View {
        Group {
            if !metrics.showsExpandedDetails {
                compactLayout
            } else if metrics.usesDetailGrid {
                largeLayout
            } else {
                mediumLayout
            }
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

    private var compactLayout: some View {
        HStack(spacing: metrics.contentSpacing) {
            heroText(compact: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            gauge
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: metrics.contentSpacing) {
            heroText(compact: false)
                .frame(minWidth: 78, alignment: .leading)

            gauge

            if !detailItems.isEmpty {
                Divider()
                    .overlay(Color.primary.opacity(0.35))
                    .frame(height: 76)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(detailItems) { item in
                        detailRow(item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var largeLayout: some View {
        VStack(spacing: 16) {
            HStack(spacing: metrics.contentSpacing) {
                heroText(compact: false)

                Spacer(minLength: 12)

                gauge
            }
            .frame(maxWidth: .infinity)

            if !detailItems.isEmpty {
                Divider()
                    .overlay(Color.primary.opacity(0.35))

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ],
                    spacing: 10
                ) {
                    ForEach(detailItems) { item in
                        detailCard(item)
                    }
                }
            }
        }
    }

    private func heroText(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 3) {
            Text(presentation.percentageText)
                .font(.system(size: metrics.percentageFontSize, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(compact ? presentation.compactStatusText : presentation.statusText)
                .font(.system(size: metrics.statusFontSize, weight: .medium, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(compact ? 0.55 : 0.7)
        }
        .layoutPriority(1)
    }

    private var gauge: some View {
        BatteryGauge(
            fillFraction: presentation.fillFraction,
            isAvailable: presentation.showsBattery
        )
        .frame(width: metrics.iconWidth, height: metrics.iconHeight)
        .fixedSize()
    }

    private var detailItems: [BatteryDetailItem] {
        detailSelection.visibleDetails.map { detail in
            switch detail {
            case .power:
                BatteryDetailItem(title: "Power", value: presentation.powerSourceText, symbol: "bolt.fill")
            case .status:
                BatteryDetailItem(title: "Status", value: presentation.stateDetailText, symbol: "battery.75percent")
            case .estimate:
                BatteryDetailItem(title: "Estimate", value: presentation.estimateDetailText, symbol: "timer")
            case .updated:
                BatteryDetailItem(title: "Updated", value: presentation.updatedText, symbol: "clock")
            }
        }
    }

    private func detailRow(_ item: BatteryDetailItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: item.symbol)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 0) {
                Text(item.title.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .opacity(0.72)

                Text(item.value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private func detailCard(_ item: BatteryDetailItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(item.title.uppercased(), systemImage: item.symbol)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .opacity(0.72)

            Text(item.value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct BatteryDetailItem: Identifiable {
    let title: String
    let value: String
    let symbol: String

    var id: String { title }
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
    static let kind = WidgetIdentifier.battery.rawValue

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: BatteryConfigurationIntent.self,
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
            BatteryWidgetView(entry: BatteryEntry(
                date: .now,
                configuration: .referencePreview(),
                snapshot: .sample
            ))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            BatteryWidgetView(entry: BatteryEntry(
                date: .now,
                configuration: .referencePreview(),
                snapshot: BatterySnapshot(
                    percentage: 42,
                    state: .charging,
                    timeRemainingMinutes: 72
                )
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            BatteryWidgetView(entry: BatteryEntry(
                date: .now,
                configuration: .referencePreview(),
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
