# Weather Widget

The Weather module contains the complete configurable widget:

- `WeatherConfiguration.swift` defines searchable city entities, stable Week/Day/Hour and unit choices, and a size-aware selectable detail list.
- `WeatherModels.swift` contains provider-neutral forecasts, WMO condition mapping, deterministic sample data, and display formatting.
- `OpenMeteoWeatherService.swift` performs city-suggestion and weather requests and maintains a bounded local cache of recent forecasts.
- `WeatherWidget.swift` creates timelines and adaptive small, medium, and large WidgetKit presentations.

This personal, noncommercial build uses the keyless Open-Meteo API. It does not use WeatherKit because WeatherKit requires paid Apple Developer Program provisioning. See [`docs/Weather-Widget.md`](../../docs/Weather-Widget.md) for setup, attribution, privacy, and validation details.
