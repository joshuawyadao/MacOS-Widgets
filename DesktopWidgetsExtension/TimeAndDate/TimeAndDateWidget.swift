import SwiftUI
import WidgetKit

struct TimeAndDateEntry: TimelineEntry {
    let date: Date
}

struct TimeAndDateProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeAndDateEntry {
        TimeAndDateEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeAndDateEntry) -> Void) {
        completion(TimeAndDateEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeAndDateEntry>) -> Void) {
        let calendar = Calendar.autoupdatingCurrent
        let entries = calendar
            .minuteTimeline(startingAt: .now, count: 60)
            .map(TimeAndDateEntry.init)

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct TimeAndDateWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: TimeAndDateEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 5 : 8) {
            Text(entry.date.formatted(.dateTime.weekday(.wide)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WidgetTheme.accent)

            Text(entry.date.formatted(.dateTime.month(.wide).day()))
                .font(family == .systemSmall ? .title2 : .title)
                .fontWeight(.bold)

            Spacer(minLength: 4)

            Text(entry.date.formatted(date: .omitted, time: .shortened))
                .font(family == .systemSmall ? .title : .system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.7)
        }
        .containerBackground(WidgetTheme.background, for: .widget)
    }
}

struct TimeAndDateWidget: Widget {
    static let kind = WidgetIdentifier.timeAndDate.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TimeAndDateProvider()) { entry in
            TimeAndDateWidgetView(entry: entry)
        }
        .configurationDisplayName("Time and Date")
        .description("Shows the current time, weekday, and date.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    TimeAndDateWidget()
} timeline: {
    TimeAndDateEntry(date: .now)
}

#Preview(as: .systemMedium) {
    TimeAndDateWidget()
} timeline: {
    TimeAndDateEntry(date: .now)
}
