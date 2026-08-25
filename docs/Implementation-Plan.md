# Plan

Correct the Personal Team signing helper identified during PR #4 review so automatic setup reads Xcode’s actual Team ID from the certificate subject instead of a different valid-looking identifier in its display name.

## Scope
- In: Certificate-subject parsing, automatic identity lookup, a deterministic verification fixture, signing setup documentation, Brooks review history, full validation, and branch saving.
- Out: Widget behavior, layout, weather data, provisioning-policy changes, or paid Apple Developer distribution.

## Action items
[x] Add a deterministic signing fixture that distinguishes the certificate display-name identifier from its `OU` Team ID.
[x] Refactor `Scripts/configure-personal-team.sh` to parse and validate the `OU` from the selected valid Apple Development certificate.
[x] Preserve explicit `TEAM_ID` overrides and refusal to overwrite an existing `Local.xcconfig`.
[x] Update `Scripts/verify-widgets.sh` so CI protects the certificate-field distinction without requiring a developer account.
[x] Clarify the automatic Team ID detection behavior in `README.md` and record the Brooks review result.
[x] Run shell syntax checks and `./Scripts/verify-widgets.sh`, review the scoped diff, commit, and push the PR branch.

## Open questions
- None.
