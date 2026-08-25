# Plan

Build the final Calendar widget from the supplied month-grid reference, using a testable presentation model and native WidgetKit interactions. The widget will follow the Mac's calendar, locale, and time zone, preserve the reference's clear white-on-wallpaper styling, and keep month navigation local and subscription-free.

## Scope
- In: Current-month grid, localized weekday order, adjacent-month dates, today highlight, previous/next month controls, Small/Medium/Large layouts, daily refresh, accessibility, host-app guidance, widget registration, automated tests, Release verification, commit, and push.
- Out: EventKit access, event/agenda rows, calendar-account selection, event creation, reminders, custom wallpaper imagery, and synchronization outside macOS-managed widget state.

## Action items
[x] Add testable Calendar month, navigation, timeline, and responsive-layout presentation contracts under `DesktopWidgetsExtension/Calendar`.
[x] Build the SwiftUI Calendar widget with the reference hierarchy, interactive month arrows, clear removable background, today selection, adjacent-month treatment, accessibility, and previews.
[x] Register the Calendar source files and tests in the Xcode project, widget bundle, stable identifier contract, and Release verification script.
[x] Add Calendar unit coverage for the August 2026 reference grid, locale-dependent week starts, leap/adjacent months, navigation bounds, midnight refresh, accessibility, and family metrics.
[x] Update the host app and module guidance so Calendar moves from “Coming next” to the ready-widget and setup experience.
[x] Create `docs/Calendar-Widget.md` and update the root README with appearance, interaction, privacy, refresh, and desktop acceptance guidance.
[x] Run `./Scripts/verify-widgets.sh`, review the full diff for scope and consistency, and resolve any build or test failures.
[x] Mark the plan complete, commit the feature and documentation, and push `codex/feature/calendar-widget` to `origin`.

## Open questions
- None.
