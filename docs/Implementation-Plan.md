# Plan

Complete the first real notarized disk-image release by resolving Xcode configuration precedence, preserving the installed identities, and validating the final downloadable artifact.

## Scope
- In: release-script configuration fix, regression coverage, real Developer ID signing and notarization, read-only disk-image validation, release evidence, branch save.
- Out: replacing the installed app, changing widget kinds or preference keys, automatic updates, publishing a GitHub/App Store release, modifying credentials or certificate trust settings.

## Action items
- [x] Read release tooling, mocked tests and Paid-Distribution-Path; validate the installed app and Keychain identity/profile outside the sandbox. Diagnose the real archive failure: the -xcconfig defaults override command-line team/identity values.
- [x] Generate one resolved release xcconfig containing the reviewed team, certificate and preserved identifiers after the base include; update regression tests to inspect the effective configuration instead of only argv.
- [x] Run release safety tests and inspect real Xcode resolved settings for both targets, including identifiers and empty maintenance paths.
- [x] Retry the signed archive/export, app notarization and signed/stapled DMG notarization with the saved Keychain profile.
- [x] Mount the final image read-only and validate both binaries, signatures, entitlements, identifiers, architecture, tickets and Gatekeeper; preserve the installed app and shared container untouched.
- [x] Update Paid-Distribution-Path with the corrected configuration contract and actual release evidence; retain clean-Mac/widget-runtime/manual-update checks as pending.
- [x] Save and push the corrected release workflow on codex/notarized-dmg-release, then deliver the DMG and identity manifest outside the repository.

## Open questions
- None. The user authorized the build and Apple submissions. Use team UNBNJA6WRF, Keychain profile desktop-widgets-notary, and --existing-app for the verified installed copy. Credentials stay in Keychain.

## Validation evidence
- Mocked release suite passes with captured resolved configuration and preserved nondefault IDs; real Xcode -showBuildSettings checks pass for both app and widget with RELEASE_TEST_REAL_XCODEBUILD=1. CI now enables that regression check.
- The installed app passed signature/team/App Group checks outside the sandbox. Sandboxed Keychain/codesign results were not used to bypass validation.
- Actual Developer ID archive/export succeeded after the configuration fix. Apple accepted app submission 09cacb3a-553b-4c29-9ad8-6668f6877195 and DMG submission 16a3dfd2-c5da-4146-a696-6c439ca596a0; both service logs report no issues.
- Final read-only image validation passed strict app/extension and image signatures, Gatekeeper, stapled tickets, hardened runtime, timestamps, preserved identities/entitlements, versions and universal architectures. Neither the installed app nor its container was modified.
- Delivered Desktop-Widgets-1.0.0-21.dmg (4,837,252 bytes) to Downloads with SHA-256 715dd385f029f940ef30c54c27ee1efc8fe4355e91d6f1779f1df2f6ed79b26f; saved a separate release-records folder including the identity manifest and Apple receipts.
- Clean-Mac installation and live widget/manual-update acceptance remain pending and are explicitly left open in Paid-Distribution-Path. No app/widget Swift source changed in this fix; targeted shell and Xcode settings regressions plus the actual signed release were the relevant checks. The earlier 133-test project suite was not needlessly repeated.
- Checkpoints: b24f70a (resolved real-release plan) and 9dbf38d (configuration precedence fix and regression tests), followed by the release-evidence documentation save. No artifacts or credentials are staged in Git.
