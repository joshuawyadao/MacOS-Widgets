# Plan

Fix the reproduced blank-today marker by making its treatment explicit for WidgetKit rendering modes: a composited filled marker in full color and a high-contrast outlined marker in vibrant/accented appearances. Lock the mode decision down in tests, validate the supplied screenshot symptom at pixel level, and refresh the signed local widget.

## Scope
- In: Today-marker rendering-mode behavior in Week/Month, event-dot contrast within that marker, regression coverage, Calendar documentation, build number, live runtime verification, commit, and push.
- Out: Calendar data/configuration, non-today cells, Day view, navigation, and unrelated widgets.

## Action items
[x] Preserve the supplied screenshot as a deterministic pixel-level failing signal for a blank today circle.
[x] Add a testable today-marker style contract that selects filled treatment only in full color and outlined treatment in vibrant/accented modes.
[x] Refactor the shared Week/Month marker to composite filled content and keep numeral/dots visible in every rendering mode.
[x] Update Calendar appearance guidance and increment the development build.
[x] Run targeted Calendar tests, the screenshot/render regression, and `./Scripts/verify-widgets.sh`.
[x] Build/register the signed extension, verify the live marker, review the diff, mark the plan complete, commit, and push `codex/feature/calendar-widget`.

## Open questions
- None.
