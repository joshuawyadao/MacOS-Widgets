# Plan

Make Weather details quicker to configure in the native macOS widget editor by replacing the system's one-at-a-time collection picker with one-click presets while preserving size-safe rendering.

## Scope
- In: Six useful detail presets, Small/Medium/Large render limits, resize protection, user guidance, tests, docs, clean builds, and a local branch checkpoint.
- Out: Device-location permission, a custom companion-app settings store, replacing Apple's WidgetKit editor, and changes to the weather provider.

## Action items
- [x] Replace the collection picker with Minimal, Simple, Rain, Comfort, Detailed, and Full presets.
- [x] Keep 2/3/5 render limits for Small/Medium/Large and preserve the resize warning.
- [x] Explain each preset and its intended widget sizes in the editor, companion app, and documentation.
- [x] Add deterministic coverage for every preset, fallback behavior, and size limiting.
- [x] Run the complete test suite plus fresh unsigned Debug and Release builds.
- [x] Review the scoped diff, install build 9 locally, and commit the completed enhancement.

## Open questions
- None. WidgetKit does not expose a persistent multi-select popup, so a single preset parameter is the supported native interaction that avoids repeated picker navigation.
