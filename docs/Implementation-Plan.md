# Plan

Replace the companion app's single long page with a native macOS sidebar that organizes setup, appearance, widget-specific guidance, permissions, privacy, and help around the task the user is trying to complete. Keep shared controllers above the navigation switch so Calendar state and unapplied appearance previews remain intact while moving between pages.

## Scope
- In: Sidebar navigation, Home dashboard, dedicated Appearance and widget pages, consolidated Help & Privacy content, navigation-state tests, accessibility labels, window sizing, and app-flow documentation.
- Out: Changes to widget rendering, configuration schemas, refresh schedules, App Group storage, or unsupported attempts to open or inspect the macOS widget gallery programmatically.

## Action items
[x] Add a stable, testable companion-app destination model grouped into Overview, Customize, Widgets, and Support.
[x] Replace `ContentView`'s single scroll view with `NavigationSplitView` and keep typography and Calendar controllers at the root so state survives page changes.
[x] Build a focused Home page with clickable widget cards, short setup steps, and clear paths to Appearance and Calendar permission help.
[x] Move appearance controls to a dedicated page and preserve pending-change indication, Apply Theme, Revert, and System Style behavior across navigation.
[x] Give Time & Date, Weather, Battery, and Calendar dedicated pages with relevant editing guidance and only their domain-specific tips or permissions.
[x] Consolidate privacy, data-source, glass-background, and troubleshooting guidance under Help & Privacy using plain language and accessible controls.
[x] Add navigation contract tests and update `README.md` plus `docs/Widget-Design-System.md` with the companion-app information architecture.
[x] Run targeted contract tests, the complete `Scripts/verify-widgets.sh` gate, a signed Debug build, and a final scope/accessibility review.
[x] Commit and push the verified navigation redesign on the current feature branch.

## Open questions
- None.
