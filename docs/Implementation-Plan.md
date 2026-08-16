# Plan

Build a configurable Weather widget that matches the supplied clear seven-column forecast while remaining useful in day and hour modes. Use Open-Meteo for keyless noncommercial weather and city lookup, isolate transport from presentation, preserve the Time and Date widget, and document the provider's attribution, privacy, and macOS transparency constraints.

## Scope
- In: Per-widget city entry, Week/Day/Hour modes, temperature units, detail toggles, Open-Meteo geocoding and forecast mapping, stale-cache/error states, clear WidgetKit presentation, accessibility, host-app onboarding, tests, docs, clean builds, and branch save.
- Out: Current-location permission, paid WeatherKit provisioning, commercial weather-service support, severe-weather alerts, radar, and background push updates.

## Action items
- [x] Add stable string-backed Weather configuration choices, city entry, unit selection, and detail toggles with documented defaults.
- [x] Add normalized weather models, Open-Meteo geocoding/forecast transport, WMO condition mapping, local last-success cache, and deterministic sample data.
- [x] Build adaptive Week, Day, and Hour WidgetKit layouts for small, medium, and large families with clear container treatment, attribution, stale/error states, and accessibility labels.
- [x] Register the Weather widget, update the host app to present both ready widgets and intuitive setup/customization guidance, and update the Xcode project graph.
- [x] Add deterministic tests for configuration fallback, request construction, decoding/mapping, units, WMO conditions, detail selection, city errors, and cached fallback behavior.
- [x] Update the Weather module README, root README, and focused Weather documentation with setup, privacy, attribution, free-use, signing, and Liquid Glass notes.
- [x] Run tests plus clean unsigned Debug and Release builds with fresh DerivedData, and document the desktop acceptance checklist for WidgetKit behavior that automation cannot cover.
- [x] Inspect the scoped diff, commit the Weather implementation and plan, and push `codex/feature/weather-widget`.

## Open questions
- None. This personal, subscription-free build will use Open-Meteo's keyless noncommercial API and default to Portland, Oregon; a future commercial release must replace or commercially license the provider.
