# Plan

Reduce WidgetKit render work without changing widget appearance or refresh behavior by resolving view models and typography once per render, reusing calendar formatters, and preparing weather forecast labels once before building columns.

## Scope
- In: Time & Date, Weather, Battery, and Calendar render-context resolution; Calendar date formatting; Weather forecast label preparation; focused behavior and rendering tests; performance notes in the Calendar, Weather, and design-system docs.
- Out: Refresh-interval changes, new caching semantics, EventKit query restructuring, visual redesign, App Intent schema changes, and macOS-owned WidgetKit scheduling behavior.

## Action items
- [x] Create the `codex/widget-render-performance` feature branch and preserve the existing widget contracts.
- [x] Refactor each widget root view to resolve typography, layout metrics, and presentation data once per SwiftUI body evaluation.
- [x] Rework Calendar day, week, and month presentation formatting to reuse bounded formatter instances while preserving locale, time-zone, first-weekday, and accessibility output.
- [x] Prepare Weather forecast titles and accessibility labels once per render and pass them through forecast-column construction.
- [x] Extend focused tests where needed and retain the existing rendering smoke coverage for every family, state, typography theme, and coverage mode.
- [x] Update Calendar, Weather, and shared design-system documentation with the render-preparation contract and unchanged refresh behavior.
- [x] Run focused Calendar, Weather, and rendering tests, then `./Scripts/verify-widgets.sh` and `git diff --check`.
- [x] Review the diff for behavior, localization, accessibility, and concurrency regressions before committing and pushing the branch.

## Open questions
- None.
