# Plan

Add a global Font Coverage preference so the selected typography theme can style either display roles only or every textual label and value across all widgets. Keep Display Text as the readable default, apply All Text without changing SF Symbols or layout geometry, and share the choice through the existing App Group.

## Scope
- In: Coverage model and persistence, companion-app control and preview, supporting-text typography in all four widgets, shared status typography, timeline reloads, rendering/persistence tests, documentation, commit, and push.
- Out: Per-widget-type coverage overrides, changes to theme choices, font downloads, SF Symbol styling, layout redesign, App Intent schema changes, and widget identity changes.

## Action items
[x] Add `WidgetTypographyCoverage` and a resolved typography style to `Shared/Styling/WidgetTypography.swift`, with Display Text defaults and safe persistence fallback.
[x] Add a Font Coverage menu to the companion app, update its preview/supporting copy, reset behavior, and timeline reload handling.
[x] Apply the resolved supporting font to textual labels and values in Time & Date, Weather, Battery, Calendar, and shared status components while leaving symbols unchanged.
[x] Extend contract and rendering tests for coverage persistence, invalid values, Display Text compatibility, and All Text rendering across all four widgets.
[x] Update `README.md`, `docs/Widget-Design-System.md`, and all four widget guides with the two coverage modes and readability tradeoff.
[x] Run targeted tests and `./Scripts/verify-widgets.sh`, inspect identity/layout/accessibility risks, then commit and push the scoped implementation.

## Open questions
- None.
