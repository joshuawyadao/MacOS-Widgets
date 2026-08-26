# Plan

Keep the current day numeral permanently visible in Week and Month views by separating the date and event-dot layers instead of letting dots participate in the numeral's layout. Add a presentation regression contract, document the marker behavior, verify the complete widget bundle, and refresh the signed local build.

## Scope
- In: Week/Month day-marker layout, today/event-dot contrast, regression coverage, Calendar documentation, build number, validation, commit, push, and local runtime refresh.
- Out: Event data behavior, Day view, Calendar configuration options, navigation, and unrelated widgets.

## Action items
[x] Add a day-marker presentation contract proving an event indicator never replaces the date numeral, including today and zero/multiple-event cases.
[x] Refactor Week and Month markers so the date remains in its own centered layer and dots occupy a separate, bounded indicator position.
[x] Update Calendar appearance guidance and the desktop acceptance checklist for visible dates with event indicators.
[x] Increment the development build and run targeted Calendar tests plus `./Scripts/verify-widgets.sh`.
[x] Review the scoped diff, mark the plan complete, commit and push `codex/feature/calendar-widget`, then rebuild and register the signed local extension.

## Open questions
- None.
