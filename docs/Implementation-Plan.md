# Plan

Prepare the widget-efficiency pull request for merge by addressing Brooks and Codex review feedback without increasing steady-state widget resource use.

## Scope
- In: Battery provider helper extraction, Calendar next-event formatter parameter simplification, weather cache correctness fixes, focused regression tests, full repository verification, and PR branch save.
- Out: Refresh schedules, displayed or accessibility text, user documentation changes, configuration schemas, and additional performance work.

## Action items
- [x] Extract the repeated Battery detail-selection and hardware-read decision into one provider helper used by snapshot and timeline generation.
- [x] Remove the redundant Calendar next-event `timeZone` parameter and format with the supplied calendar's time zone.
- [x] Confirm existing Battery visibility and Calendar localized-text tests cover the behavior-preserving refactor; add tests only if a coverage gap appears.
- [x] Leave canonical widget guides unchanged because resource behavior and user-visible contracts do not change; retain this plan as the review-remediation record.
- [x] Run focused Battery and Calendar tests, `./Scripts/verify-widgets.sh`, and `git diff --check`.
- [x] Commit and push the Brooks fixes to `codex/widget-render-performance`, then re-check PR review, CI, and mergeability state.
- [x] Reject future-dated weather snapshots as fresh so clock corrections cannot indefinitely suppress network refreshes.
- [x] Include weather location presentation identity in cache and in-flight request keys so coordinate-identical selections cannot share the wrong displayed location.
- [x] Run focused Weather tests, `./Scripts/verify-widgets.sh`, and `git diff --check`.
- [x] Commit and push the Codex fixes, acknowledge the addressed review comments, and complete the final PR audit.

## Open questions
- None.
