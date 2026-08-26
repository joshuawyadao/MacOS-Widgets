# Plan

Unify the four widgets around a shared visual and behavioral contract while preserving each widget's domain-specific controls, data states, and interactions. Introduce reusable widget styling/status primitives, migrate every widget and the companion app to them, document the contract, and expand cross-widget rendering coverage before saving the branch.

## Scope
- In: Shared rendering-mode styling, family-density and status primitives, Time & Date tint support, consistent status presentation, aligned companion-app guide sections, Calendar render smoke coverage, design-system documentation, full widget verification, commit, and push.
- Out: New data sources, new permissions, new widget families, changes to WidgetKit identities or persisted App Intent schemas, and forcing identical layouts or controls onto widgets with different jobs.

## Action items
[x] Add shared widget surface, family-density, visual token, and compact status-line primitives in `Shared/Styling/WidgetTheme.swift`.
[x] Migrate Time & Date, Weather, Battery, and Calendar to the shared surface treatment while retaining their distinct content hierarchies and interactions.
[x] Reuse the shared status treatment for stale, constrained, unavailable, and permission-required states where space and semantics allow.
[x] Restructure `DesktopWidgetsApp/Views/ContentView.swift` so every widget has the same purpose/options guide pattern, while retaining Calendar permission and Weather attribution content.
[x] Add Calendar family/state rendering smoke coverage and shared-style contract assertions without weakening existing widget-specific tests.
[x] Create `docs/Widget-Design-System.md` and update the root and widget documentation to describe the common contract and deliberate widget-specific exceptions.
[x] Run targeted tests, the complete `./Scripts/verify-widgets.sh` gate, and review the final diff for App Intent identity, accessibility, localization, and small-family layout risks.
[x] Commit the scoped implementation and documentation, then push the saved feature branch.

## Open questions
- None.
