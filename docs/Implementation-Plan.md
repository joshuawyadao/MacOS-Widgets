# Plan

Reduce Weather network/decoding work and Calendar event-processing overhead while preserving current refresh schedules, visible content, privacy boundaries, and fallback behavior. Prefer short-lived reuse and bounded queries so smoother updates do not create resident background work or consume more battery.

## Scope
- In: 15-minute fresh Weather cache reuse, in-flight Open-Meteo request coalescing, a 24-hour hourly forecast payload with seven daily forecasts, overlapping Calendar query consolidation, linear next-event selection, focused tests, and Weather/Calendar documentation.
- Out: More frequent WidgetKit refreshes, always-on performance logging, global long-lived presentation caches, visual-effect changes, App Intent migrations, or changes to displayed data and accessibility output.

## Action items
- [x] Add a fresh-cache path that reuses only matching city/unit snapshots no older than 15 minutes while retaining the 24-hour stale fallback after failures.
- [x] Coalesce simultaneous identical Open-Meteo forecasts in memory without retaining completed tasks or affecting different locations and units.
- [x] Limit Open-Meteo hourly data to 24 forecast hours while preserving seven daily forecasts and the existing timeline/view horizon.
- [x] Consolidate overlapping Calendar display and upcoming intervals into one bounded EventKit query, while keeping disjoint navigated-month intervals separate.
- [x] Replace Calendar next-event sorting with a single-pass earliest eligible event selection.
- [x] Extend Weather and Calendar tests for freshness boundaries, request reuse, request parameters, query planning, event ordering, and existing fallback behavior.
- [x] Update `docs/Weather-Widget.md` and `docs/Calendar-Widget.md` with the resource-efficiency behavior and unchanged privacy/refresh contracts.
- [x] Run focused tests, `./Scripts/verify-widgets.sh`, `git diff --check`, and a final concurrency/localization/privacy review.

## Open questions
- None.
