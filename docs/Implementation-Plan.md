# Plan

Make Battery details configurable like Weather while enforcing family-specific display budgets that prevent crowding and clipping. Add four independent detail toggles, keep the compact hero in every family, cap Medium at two selected details, and let Large show up to all four.

## Scope
- In: Battery App Intent configuration, Power/Status/Estimate/Updated toggles, deterministic size limits and priority, reduced Medium density, fresh widget identity, metadata verification, tests, docs, commit, and push.
- Out: Reordering details by drag-and-drop, custom fonts/colors, more battery data fields, external accessory batteries, or changes to other widgets.

## Action items
[x] Add a stable `BatteryConfigurationIntent` with four independently persisted Boolean detail toggles and documented defaults.
[x] Add a presentation selection contract that shows zero extras on Small, at most two on Medium, and at most four on Large, including empty and partial selections.
[x] Convert the Battery provider and widget to App Intent configuration under a fresh WidgetKit identity so macOS exports the editor schema safely.
[x] Refactor Medium and Large to render only the selected, size-limited details and collapse unused separators/grid space cleanly.
[x] Expand Battery configuration, size-budget, fallback, accessibility, identity, and editor-metadata verification coverage.
[x] Update `docs/Battery-Widget.md`, the root README, host-app guidance, and build migration notes for the new detail controls and one-time re-add requirement.
[x] Run the complete widget verification gate and inspect the final code/docs diff for clipping and persistence risks.
[x] Commit and push the verified configurable Battery widget to `codex/feature/battery-widget`.

## Open questions
- None.
