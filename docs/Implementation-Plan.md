# Plan

Support Xcode 26.6’s valid profile-free macOS Personal Team output without weakening signing or entitlement checks. Validate the Apple Development signature, Team ID, App Group, sandbox, Calendar, and extension network entitlement directly, then use a conservative seven-day local signing window for automatic maintenance when no profile supplies an expiration date.

## Scope
- In: Profile-optional macOS validation, complete required-entitlement checks, profile-free maintenance deadlines, regression tests, accurate user/operations documentation, replacement package, and branch save.
- Out: Accepting ad-hoc or wrong-team signatures, removing App Group or sandbox security, sharing certificates, paid distribution, and the paused GitHub-update feature.

## Action items
- [x] Add fixture-driven validation tests for the complete app/extension entitlement contracts and rejection of missing App Group, sandbox, Calendar, or network access.
- [x] Accept an absent macOS provisioning profile only after both products pass strict Apple Development signature, Team ID, and required-entitlement validation; continue validating any embedded profile that Xcode does provide.
- [x] Add profile-free maintenance deadline helpers based on the signed product timestamp, retaining the seven-day/48-hour conservative refresh policy and rejecting invalid or inconsistent signing state.
- [x] Extend automatic-maintenance tests for healthy and near-renewal profile-free builds, invalid signatures, normal profiles, failures, idempotency, and notification throttling.
- [x] Update companion wording, the installation guide, README, and Personal Team documentation to distinguish real profile expiration from the conservative profile-free renewal deadline.
- [x] Run focused installer/maintenance tests, the exact identifier embedding build, the complete verification gate, and `git diff --check`.
- [ ] Save and push the fix on `codex/feature/easier-personal-installation`, then generate a clean replacement ZIP for the target Mac.

## Open questions
- None.

## Verification result

- Focused installer, automatic-maintenance, packaging, and shell-syntax tests passed.
- The unsigned Release build passed with the generated app identifier and corrected child extension identifier.
- `Scripts/verify-widgets.sh` passed the full macOS test suite, Release build, App Intents metadata checks, and runtime-registration safety checks.
- `git diff --check` passed.
