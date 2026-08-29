# Plan

Correct the Personal Team bundle-identifier generator so the embedded widget extension satisfies Xcode’s required parent-app prefix while preserving the already-generated app and App Group identities. Lock the real Xcode 26.6 failure into tests, verify both the helper and an unsigned embedding build, then package and push a replacement installer.

## Scope
- In: Generated Personal Team extension identifiers, existing local-configuration migration, regression coverage, installer documentation note, verification, replacement handoff ZIP, and branch save.
- Out: Apple certificate sharing, paid signing, unrelated widget identities, and the paused GitHub-update feature.

## Action items
- [x] Add a regression assertion that generated extension bundle IDs begin with the generated app bundle ID and reproduce the current failure.
- [x] Change the Personal Team identifier generator from sibling `…widgets` to embedded-safe `…app.widgets` while retaining the app and App Group identifiers.
- [x] Verify that rerunning the installer updates an existing generated `Local.xcconfig` idempotently without changing its Team ID, app ID, or App Group.
- [x] Update focused documentation to explain the corrected embedded-extension identity and replacement-installer step.
- [x] Run the personal-installation tests, the exact unsigned Xcode embedding reproduction, the complete verification gate, and `git diff --check`.
- [x] Save and push the fix on `codex/feature/easier-personal-installation`, then generate a clean replacement ZIP.

## Open questions
- None.

## Verification result

- The Xcode 26.6 reproduction fails with the former sibling extension ID and succeeds with the corrected app-prefixed extension ID.
- Personal-installation tests cover fresh generation and migration of the invalid generated configuration while preserving the app ID, App Group, and Team ID.
- The complete Debug test suite, fresh unsigned Release build, embedded extension checks, package tests, and `git diff --check` pass.
