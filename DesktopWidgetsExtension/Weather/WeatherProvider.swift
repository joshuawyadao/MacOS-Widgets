import AppIntents
import Foundation
import WidgetKit

struct WeatherEntry: TimelineEntry {
    let date: Date
    let configuration: WeatherV7ConfigurationIntent
    let snapshot: WeatherSnapshot?
    let state: WeatherEntryState
}

struct WeatherProvider: AppIntentTimelineProvider {
    private let service: any WeatherServing
    private let cache: WeatherSnapshotCache

    init(
        service: any WeatherServing = OpenMeteoWeatherService(),
        cache: WeatherSnapshotCache = WeatherSnapshotCache()
    ) {
        self.service = service
        self.cache = cache
    }

    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(
            date: .now,
            configuration: .referencePreview(),
            snapshot: .sample(),
            state: .loaded
        )
    }

    func snapshot(
        for configuration: WeatherV7ConfigurationIntent,
        in context: Context
    ) async -> WeatherEntry {
        if context.isPreview {
            return WeatherEntry(
                date: .now,
                configuration: configuration,
                snapshot: .sample(),
                state: .loaded
            )
        }
        return await entry(for: configuration, date: .now)
    }

    func timeline(
        for configuration: WeatherV7ConfigurationIntent,
        in context: Context
    ) async -> Timeline<WeatherEntry> {
        let now = Date.now
        let loaded = await entry(for: configuration, date: now)

        switch loaded.state {
        case let .failed(_, retryable):
            return Timeline(
                entries: [loaded],
                policy: retryable ? .after(now.addingTimeInterval(30 * 60)) : .never
            )
        case .loaded, .stale:
            let dates = WeatherTimelinePolicy.dates(
                startingAt: now,
                count: 7,
                timeZone: loaded.snapshot?.timeZone ?? .autoupdatingCurrent
            )
            let entries = dates.map { date in
                WeatherEntry(
                    date: date,
                    configuration: configuration,
                    snapshot: loaded.snapshot,
                    state: loaded.state
                )
            }
            return Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60)))
        }
    }

    func entry(
        for configuration: WeatherV7ConfigurationIntent,
        date: Date
    ) async -> WeatherEntry {
        let outcome = await WeatherLoader(service: service, cache: cache).load(
            location: configuration.resolvedLocation,
            unit: configuration.resolvedTemperatureUnit,
            locale: .autoupdatingCurrent
        )

        switch outcome {
        case let .fresh(snapshot):
            return WeatherEntry(date: date, configuration: configuration, snapshot: snapshot, state: .loaded)
        case let .stale(snapshot, message):
            return WeatherEntry(date: date, configuration: configuration, snapshot: snapshot, state: .stale(message))
        case let .failed(message, retryable):
            return WeatherEntry(
                date: date,
                configuration: configuration,
                snapshot: nil,
                state: .failed(message, retryable: retryable)
            )
        }
    }
}
