# Plan

Make appearance customization resource-conscious by separating the companion app's live preview from the settings currently applied to desktop widgets. Theme, font coverage, and widget overrides will be staged together, then persisted with one WidgetKit reload when the user chooses Apply Theme.

## Scope
- In: Draft appearance state, Apply/Revert controls and feedback, one reload per apply action, preference-model tests, and appearance workflow documentation.
- Out: Changes to periodic Time, Weather, Battery, or Calendar refresh schedules; retries; polling; or attempting an unsupported atomic WidgetKit redraw.

## Action items
[x] Add a testable appearance selection model that can load, compare, reset, and persist the complete typography configuration.
[x] Refactor the companion app controller so menus update draft preview state without writing shared preferences or requesting WidgetKit reloads.
[x] Add Apply Theme, Revert, pending-change, and update-requested UI states while preserving the existing preview grid and System Style behavior.
[x] Add regression tests proving preview edits remain uncommitted, apply persists the complete selection, and System Style restores safe defaults.
[x] Update `README.md` and `docs/Widget-Design-System.md` to describe the preview/apply workflow and its single explicit reload without changing regular refresh cadence.
[x] Run targeted typography tests, the complete `Scripts/verify-widgets.sh` gate, and review the finished diff for scope and documentation consistency.
[x] Commit and push the verified implementation on the current feature branch.

## Open questions
- None.
