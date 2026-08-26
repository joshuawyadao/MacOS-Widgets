# Plan

Expand Calendar into a configurable, family-aware widget with Day, Week, and Month presentations plus optional EventKit indicators. Automatic mode will use Day on Small, Week on Medium, and Month on Large, while each placed copy can override the view and independently opt into privacy-conscious event counts/dots.

## Scope
- In: App Intent Day/Week/Month/Automatic configuration, family-specific layouts, optional event counts/dots, EventKit full-access onboarding, calendar sandbox entitlement, permission/failure states, adaptive refresh, accessibility, fresh widget identity, tests, docs, commit, push, and local runtime refresh.
- Out: Event titles or notes, calendar-account selection, event creation/editing, reminders, shared-container caching, and interactive navigation outside Month view.

## Action items
[x] Add a stable `CalendarConfigurationIntent` with Automatic/Day/Week/Month choices, an opt-in event-indicator toggle, family defaults, and defensive fallbacks.
[x] Add EventKit access/state models and an extension reader that fetches bounded event intervals and exposes counts only, never titles or notes.
[x] Refactor Calendar presentation and SwiftUI into distinct Day, Week, and Month layouts with accessible event signifiers and Month-only navigation.
[x] Add containing-app Calendar permission onboarding, required privacy strings and macOS calendar entitlements, a fresh widget identity, and build-19 migration guidance.
[x] Expand Calendar tests for configuration independence, family defaults, day/week/month contracts, event overlap counting, denied/disabled states, refresh policy, and responsive budgets.
[x] Update `docs/Calendar-Widget.md`, module/host guidance, the root README, Xcode project, and `Scripts/verify-widgets.sh` for the configurable EventKit behavior and metadata.
[x] Run targeted Calendar tests and `./Scripts/verify-widgets.sh`, then review code, test, entitlement, privacy, and documentation diffs for consistency.
[x] Mark the plan complete, commit and push `codex/feature/calendar-widget`, then rebuild and register the signed local extension so the new editor appears.

## Open questions
- None.
