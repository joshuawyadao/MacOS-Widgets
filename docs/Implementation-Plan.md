# Plan

Make Weather configuration easier and safer in the native macOS widget editor: searchable city suggestions, one clickable details list, and family-specific selection limits that prevent cramped layouts.

## Scope
- In: Native city search, disambiguated city choices, a single multi-select detail list, Small/Medium/Large limits, resize protection, user guidance, tests, docs, clean builds, and a local branch checkpoint.
- Out: Device-location permission, a custom companion-app settings store, replacing Apple's WidgetKit editor, and changes to the weather provider.

## Action items
- [x] Replace free-form city text with a searchable App Entity that stores a resolved city and coordinate.
- [x] Replace separate detail controls with a single clickable App Entity collection.
- [x] Enforce 2/3/5 detail limits for Small/Medium/Large in the native editor and defensively cap rendering after a resize.
- [x] Explain the limits in the editor, companion app, on-widget resize notice, and documentation.
- [x] Add deterministic tests for city identity, suggestions, detail choices, and selection limits.
- [x] Run the complete test suite plus fresh unsigned Debug and Release builds.
- [x] Review the scoped diff and commit the completed enhancement to the current feature branch.

## Open questions
- None. WidgetKit owns the visual presentation of search results and checkmarks; the app supplies searchable entities, rich labels, and per-family collection limits through supported App Intents APIs.
