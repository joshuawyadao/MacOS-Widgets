# Plan

Add one high-value, domain-specific capability to each widget while preserving the shared visual system: a secondary time zone, richer weather metrics, optional battery health data, and privacy-preserving next-event timing. Treat new editor parameters as intentional widget migrations, keep unavailable data safe, and verify every configuration and family before saving.

## Scope
- In: Per-copy secondary clock and label, apparent temperature/UV/sunrise/sunset Weather details, optional battery health and cycle cards, opt-in next-event timing without event text, required WidgetKit identity migrations, tests, privacy and usage documentation.
- Out: Seconds, alarms or notifications, radar or severe-weather alerts, battery history, accessory batteries, calendar titles/notes/locations, calendar selection, and background behavior beyond WidgetKit’s existing refresh policies.

## Action items
[x] Add secondary-time-zone configuration, presentation, rendering, accessibility, tests, and a fresh Time & Date widget identity.
[x] Extend Open-Meteo requests, normalized models, formatters, presets, and layouts for apparent temperature, UV index, sunrise, and sunset while retaining cache compatibility and the Weather identity.
[x] Read optional AppleSmartBattery diagnostics, expose health and cycle toggles/cards with unavailable fallbacks, extend accessibility, and migrate Battery to a fresh identity.
[x] Add opt-in Calendar next-event timing, query only timing intervals, prevent indicator leakage when counts are off, fit the label by family/view budget, and migrate Calendar to a fresh identity.
[x] Update widget, configuration, service, rendering, privacy, identity, and metadata tests for the new behavior and migration contracts.
[x] Update `README.md`, all four widget guides, and `docs/Widget-Design-System.md` with controls, limitations, privacy, and one-time re-add instructions.
[x] Run targeted suites and `./Scripts/verify-widgets.sh`, inspect unavailable-data, layout, identity, cache, and accessibility risks, then commit and push the scoped release.

## Open questions
- None.
