# Plan

Finish the low-resource widget pass by avoiding Battery diagnostics that cannot be displayed, retaining one decoded Weather fallback through a failed refresh, and removing redundant Calendar formatting and offscreen composition. Preserve every refresh interval, visible state, privacy boundary, and configuration contract.

## Scope
- In: visible-detail-driven Battery hardware reads, single-read Weather stale fallback, prepared Calendar next-event text, removal of the Calendar today-marker drawing group, focused tests, and canonical Battery/Weather/Calendar documentation.
- Out: refresh-frequency changes, persistent monitoring, new caches, visual redesign, App Intent migrations, or changes to displayed and accessibility text.

## Action items
- [x] Derive Battery hardware-reading requirements from the details visible for the configured widget family and skip `AppleSmartBattery` registry access otherwise.
- [x] Retain one decoded Weather cache candidate across the refresh attempt so offline fallback does not reread and redecode the same file.
- [x] Prepare Calendar next-event display and accessibility strings together with one locale-aware formatter per render.
- [x] Remove the Calendar today marker's unnecessary offscreen `drawingGroup` while preserving its composition and render coverage.
- [x] Extend Battery, Weather, and Calendar unit tests for visible diagnostic requirements, retained fallback behavior, and next-event text states.
- [x] Update `docs/Battery-Widget.md`, `docs/Weather-Widget.md`, and `docs/Calendar-Widget.md` with the final resource-efficiency contracts.
- [x] Run focused suites, `./Scripts/verify-widgets.sh`, `git diff --check`, and a final refresh/privacy/render review.
- [x] Commit and push the completed plan to `codex/widget-render-performance` with the save-branch workflow.

## Open questions
- None.
