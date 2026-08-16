# Weather Widget

The Weather module contains the complete configurable widget:

- `WeatherConfiguration.swift` defines stable App Intent choices for city, Week/Day/Hour view, units, and detail toggles.
- `WeatherModels.swift` contains provider-neutral forecasts, WMO condition mapping, deterministic sample data, and display formatting.
- `OpenMeteoWeatherService.swift` performs city lookup and weather requests and maintains bounded local caches for recent city matches and forecasts.
- `WeatherWidget.swift` creates timelines and adaptive small, medium, and large WidgetKit presentations.

This personal, noncommercial build uses the keyless Open-Meteo API. It does not use WeatherKit because WeatherKit requires paid Apple Developer Program provisioning. See [`docs/Weather-Widget.md`](../../docs/Weather-Widget.md) for setup, attribution, privacy, and validation details.
