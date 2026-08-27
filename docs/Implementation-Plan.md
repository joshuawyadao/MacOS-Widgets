# Plan

Add opt-in automatic Personal Team maintenance without a resident process: a user LaunchAgent will perform a lightweight profile-expiry check at login and daily, then run the existing guarded refresh at low priority only inside a 48-hour renewal window. Keep success silent, make failures actionable, preserve the manual fallback, and expose clear enablement/status guidance in the companion app.

## Scope
- In: Enable/disable commands, safe LaunchAgent generation and lifecycle, profile-expiry inspection, near-expiry refresh, redacted bounded logs, failure notification, installer opt-in, companion status, packaging/docs, mocked system-command tests, and complete verification.
- Out: Password/token automation, a continuously running daemon, changes to WidgetKit refresh budgets, paid signing/notarization, automatic desktop placement, and unrelated app functionality.

## Action items
- [x] Add pure scheduling/profile helpers and a low-priority automatic-refresh runner that exits immediately while profiles have more than 48 hours remaining and invokes the existing refresh noninteractively only near expiry.
- [x] Add idempotent Enable and Disable commands that install or remove only Desktop Widgets’ LaunchAgent, run at login and daily without `KeepAlive`, retain bounded redacted logs, and never require administrator access.
- [x] Extend the friendly installer to offer automatic maintenance with an explicit default-yes prompt, suppress app opening during scheduled refresh, and keep manual Refresh as a safe fallback.
- [x] Persist non-sensitive automatic-refresh state in the signed App Group container and show enabled, healthy, refreshed, or needs-attention guidance in the companion app with helper access and technical details.
- [x] Extend handoff packaging, the direct installation guide, README, and Personal Team operations documentation with resource usage, five-day/48-hour behavior, retry semantics, limitations, and uninstall instructions.
- [x] Add mocked tests for expiry parsing and thresholds, healthy no-op checks, near-expiry refresh, missing/expired profiles, refresh failure/notification, LaunchAgent construction, idempotent enable/disable, and exact-target safety.
- [x] Update `Scripts/verify-widgets.sh`, run shell syntax and focused tests, then complete Xcode verification and `git diff --check`.
- [x] Save and push cohesive commits on `codex/feature/easier-personal-installation` without rewriting existing history.

## Open questions
- None.

## Verification result

- Mocked automatic-maintenance, personal-installation, packaging, and guarded runtime-refresh tests pass.
- The complete Debug Swift test suite and a fresh unsigned Release app/widget build pass through `Scripts/verify-widgets.sh`.
- Widget embedding, stable identities, App Intent metadata, App Group configuration, helper metadata, and `git diff --check` pass.
- A signed Personal Team installation and one observed real seven-day renewal cycle still require the target Mac owner's Apple Account interaction; no credentials were automated or accessed during repository verification.
