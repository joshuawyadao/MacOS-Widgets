# Plan

Prepare a repeatable Developer ID signed, notarized disk image with clear manual updates and a conservative migration from existing personal installations.

## Scope
- In: release configuration and packaging, distribution-aware onboarding, identifier preservation checks, safe migration guidance, tests and documentation.
- Out: App Store submission, automatic updater, credentials in source control, automatic deletion of installed apps or containers, guaranteed migration between different Apple teams.

## Action items
- [x] Inspect signing, installation helpers, widget identities, contract tests, README, Installation Guide, Personal-Team-Installation and Paid-Distribution-Path; confirm current Apple notarization and macOS App Group requirements.
- [x] Add an isolated Developer ID configuration and archive/sign/notarize/staple/DMG workflow with explicit account inputs, identity checks, and mocked failure-path tests.
- [x] Add distribution-aware installation and manual-update guidance, support both Applications locations, and keep the Personal Team development flow available.
- [x] Preserve widget kinds and preference keys; guard development helpers from replacing Developer ID releases and document disabling the old scheduler and comparing installed identifiers before migration.
- [x] Extend Swift installation-status tests and shell release/refresh tests; update verification and CI to exercise the new behavior.
- [x] Update README, Installation Guide, Personal-Team-Installation and Paid-Distribution-Path with release operations, migration limits, manual updates, and clean-Mac acceptance checks.
- [x] Run targeted shell tests, Swift tests, project verification and a universal unsigned release archive; obtain an Apple-platform correctness review and resolve actionable findings.
- [x] Commit coherent checkpoints, push the feature branch, and report account prerequisites separately from the implemented and locally verified workflow.

## Open questions
- None blocking implementation. Actual signing/notarization requires a Developer ID Application certificate/private key and a Keychain notarization profile. Existing recipient identifiers and signing team must be compared before distributing a migration build; do not guess or silently migrate across teams.

## Validation evidence
- Initial app slice: all Swift tests and rendering smoke tests passed on Xcode 27.2; personal installation and automatic refresh shell suites passed, including Developer ID downgrade guards. Actual signing and notarization are pending account prerequisites.
- Full `Scripts/verify-widgets.sh` passed: shell installer/package/runtime/release tests, 133 Swift tests including rendering smoke coverage, Release compilation, embedding, widget identities and App Intents metadata.
- `Config/DeveloperID.xcconfig` produced an unsigned generic macOS archive with arm64 and x86_64 in the app and extension, macOS 14 minimum, developer-id channel and empty development helper paths.
- Final release shell suite passed after adding system-tool parsing, custom identifier/manifest replay coverage, publication locking and self-contained DMG instructions. Successful packaging and build/signing/entitlement/notarization failures are mocked; no account upload occurred.
- Apple-platform read-only review found no further confirmed correctness issue. Real Developer ID signing/export, accepted notarization and clean-Mac/manual-update acceptance remain pending. No valid Developer ID Application identity was visible to the release tools during this work.
- Checkpoints: 1a4e051 (resolved plan), 0121bae (app guidance and migration guards), followed by the release-tooling save commit. The feature branch is codex/notarized-dmg-release; no PR or merge is requested.
