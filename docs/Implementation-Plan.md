# Plan

Complete the first real notarized disk-image release by resolving Xcode configuration precedence, preserving the installed identities, and validating the final downloadable artifact.

## Scope
- In: release-script configuration fix, regression coverage, real Developer ID signing and notarization, read-only disk-image validation, release evidence, branch save.
- Out: replacing the installed app, changing widget kinds or preference keys, automatic updates, publishing a GitHub/App Store release, modifying credentials or certificate trust settings.

## Action items
- [x] Read release tooling, mocked tests and Paid-Distribution-Path; validate the installed app and Keychain identity/profile outside the sandbox. Diagnose the real archive failure: the -xcconfig defaults override command-line team/identity values.
- [ ] Generate one resolved release xcconfig containing the reviewed team, certificate and preserved identifiers after the base include; update regression tests to inspect the effective configuration instead of only argv.
- [ ] Run release safety tests and inspect real Xcode resolved settings for both targets, including identifiers and empty maintenance paths.
- [ ] Retry the signed archive/export, app notarization and signed/stapled DMG notarization with the saved Keychain profile.
- [ ] Mount the final image read-only and validate both binaries, signatures, entitlements, identifiers, architecture, tickets and Gatekeeper; preserve the installed app and shared container untouched.
- [ ] Update Paid-Distribution-Path with the corrected configuration contract and actual release evidence; retain clean-Mac/widget-runtime/manual-update checks as pending.
- [ ] Save and push the corrected release workflow on codex/notarized-dmg-release, then deliver the DMG and identity manifest outside the repository.

## Open questions
- None. The user authorized the build and Apple submissions. Use team UNBNJA6WRF, Keychain profile desktop-widgets-notary, and --existing-app for the verified installed copy. Credentials stay in Keychain.
