# Plan

Finish the Weather widget's selected-city delivery, searchable editor flow, and expanded large-family presentation while preserving the automated presentation contracts.

## Scope
- In: Search-backed city suggestions with exact coordinate delivery, an expanded large-family dashboard, a fresh WidgetKit/App Intent identity, regression tests, and migration guidance.
- Out: macOS-owned Liquid Glass/tinted rendering, live VoiceOver traversal, and real-world WidgetKit scheduling.

## Action items
- [x] Reproduce the remaining selected-city failure from the live build-11 timeline: macOS serialized Tokyo correctly, then rejected the custom entity type before calling its query and delivered `WeatherV5LocationEntity(nil)` to the provider.
- [x] Reproduce the build-12 editor issue in exported App Intents metadata: the `CLPlacemark` City parameter had no dynamic-options support, so macOS had no app-provided city list to show.
- [x] Replace the placemark parameter with primitive string transport: Search City feeds a dependent Matching City provider, and the selected result safely encodes the exact provider-neutral location.
- [x] Restore Open-Meteo geocoding with state/country subtitles so duplicate city names remain distinguishable.
- [x] Give large Week and Hour widgets a current-conditions hero, high/low, selected detail values, and a separate forecast strip instead of stretching the medium layout.
- [x] Assign a fresh build-13 Weather widget and intent identity so macOS cannot reuse the broken build-12 configuration payload.
- [x] Add focused regression tests for city-result round trips, duplicate-name geocoding, selected-location provider delivery, and large-family layout selection.
- [x] Run the complete verification gate from fresh build artifacts: all 42 Debug tests passed, followed by a fresh unsigned Release build, extension embedding, the v7 widget identity, and a dynamic Matching City parameter in exported metadata.
- [ ] Re-add the build-13 Weather widget and repeat the searchable-city and expanded-large desktop acceptance checks.

## Open questions
- The build 13 re-add is required because WidgetKit and LinkServices configuration storage is system-owned and the earlier placemark payload cannot be migrated reliably into the new primitive string schema.
