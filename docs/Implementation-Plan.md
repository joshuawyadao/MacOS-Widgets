# Plan

Improve Weather city selection and legibility by supplying a larger, uniquely labeled result set to macOS and applying explicit Small, Medium, and Large layout metrics with safer forecast-detail budgets.

## Scope
- In: Open-Meteo result count and labeling, Weather family-specific spacing and typography, detail-density limits, regression coverage, build migration guidance, and Weather documentation.
- Out: Replacing macOS's system-owned App Intent editor, changing Liquid Glass behavior, or adding a custom companion-app configuration store.

## Action items
- [x] Confirm the screenshot's editor identity and preserve the build-13 string-backed Search City and Matching City transport.
- [x] Return up to 20 geocoding matches and give same-named cities unique visible titles with state and country context.
- [x] Add explicit Small, Medium, and Large layout metrics for headers, day summaries, forecast columns, and inter-item spacing.
- [x] Reduce Week and Hour detail density where narrow columns would clip or crowd labels while retaining the existing limit notice.
- [x] Extend tests for result counts, unique city labels, family layout metrics, and every family/view/preset combination.
- [x] Update the host guidance, README, and Weather documentation with the current editor flow, size behavior, and build migration step.
- [x] Run the complete widget verification gate: all 44 tests, fresh Release compilation, extension embedding, widget identities, and App Intent editor metadata passed.
- [x] Commit and push the completed implementation to the current Weather feature branch.

## Open questions
- None.
