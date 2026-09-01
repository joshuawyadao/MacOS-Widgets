# Plan

Address the two actionable Brooks PR-review suggestions without changing widget behavior: centralize Battery diagnostic-read policy inside the provider and make the configured Calendar the single source of truth for next-event time zones.

## Scope
- In: Battery provider helper extraction, Calendar next-event formatter parameter simplification, focused regression tests, full repository verification, and PR branch save.
- Out: Refresh schedules, displayed or accessibility text, new test scenarios, user documentation changes, configuration schemas, and additional performance work.

## Action items
- [x] Extract the repeated Battery detail-selection and hardware-read decision into one provider helper used by snapshot and timeline generation.
- [x] Remove the redundant Calendar next-event `timeZone` parameter and format with the supplied calendar's time zone.
- [x] Confirm existing Battery visibility and Calendar localized-text tests cover the behavior-preserving refactor; add tests only if a coverage gap appears.
- [x] Leave canonical widget guides unchanged because resource behavior and user-visible contracts do not change; retain this plan as the review-remediation record.
- [x] Run focused Battery and Calendar tests, `./Scripts/verify-widgets.sh`, and `git diff --check`.
- [x] Commit and push the Brooks fixes to `codex/widget-render-performance`, then re-check PR review, CI, and mergeability state.

## Open questions
- None.
