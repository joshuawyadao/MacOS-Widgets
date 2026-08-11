# Plan

Prepare the Time and Date widget for its pull request by adding focused configuration tests, aligning its editor examples with rendered output, improving multi-size validation, and safely evaluating the lock-screen Data Protection entitlement without sacrificing teamless local signing.

## Scope
- In: A macOS unit-test target; date/time/provider/fallback coverage; the corrected 12-hour example; deterministic previews for all supported sizes; a manual desktop acceptance checklist; Data Protection entitlement evaluation; documentation; clean build validation; commit; and push.
- Out: New customization choices, a companion settings app, changing the stable App Intent transport or widget identity, bypassing system-owned Liquid Glass, and claiming unobserved desktop checks passed.

## Action items
- [x] Add a `DesktopWidgetsTests` target and write failing behavioral tests for all formatters, fallback resolution, independent configurations, and provider choices/defaults.
- [x] Correct the 12-hour editor example and make the new test suite pass without changing stable option identifiers.
- [x] Add deterministic small, medium, and large previews, including a visibly different second configuration.
- [x] Add an exact manual desktop checklist for two instances, all sizes, edit persistence, and restart persistence.
- [x] Evaluate the Data Protection entitlement, confirm that it requires a provisioning profile, and document its deferral to preserve teamless local signing.
- [x] Run the test suite plus fresh-DerivedData unsigned Debug and Release builds, checking successful App Intents metadata export.
- [x] Run a locally signed build and inspect the extension's embedded entitlements.
- [x] Update implementation and user documentation, inspect the final diff, commit, and push `feature/time-and-date-widget`.

## Validation record

- The red test run failed only on the mismatched 12-hour example; the green run passed all six test cases.
- Fresh unsigned Debug and Release app builds succeeded and exported `Metadata.appintents` in the widget extension.
- A teamless local signed build succeeded after the provisioning-only Data Protection entitlement was removed. The signed extension contains only the App Sandbox and debug `get-task-allow` entitlements.
- Actual desktop sizing and restart persistence remain the explicit human checks in `docs/Time-And-Date-Widget.md`; they are not represented as automated passes.

## Open questions
- None. Desktop interaction that Xcode cannot automate will remain an explicit human acceptance gate rather than an assumed pass.
