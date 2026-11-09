# Plan

Prepare a repeatable Developer ID signed, notarized disk image with clear manual updates and a conservative migration from existing personal installations.

## Scope
- In: release configuration and packaging, distribution-aware onboarding, identifier preservation checks, safe migration guidance, tests and documentation.
- Out: App Store submission, automatic updater, credentials in source control, automatic deletion of installed apps or containers, guaranteed migration between different Apple teams.

## Action items
- [x] Inspect signing, installation helpers, widget identities, contract tests, README, Installation Guide, Personal-Team-Installation and Paid-Distribution-Path; confirm current Apple notarization and macOS App Group requirements.
- [ ] Add an isolated Developer ID configuration and archive/sign/notarize/staple/DMG workflow with explicit account inputs, identity checks, and mocked failure-path tests.
- [x] Add distribution-aware installation and manual-update guidance, support both Applications locations, and keep the Personal Team development flow available.
- [x] Preserve widget kinds and preference keys; guard development helpers from replacing Developer ID releases and document disabling the old scheduler and comparing installed identifiers before migration.
- [ ] Extend Swift installation-status tests and shell release/refresh tests; update verification and CI to exercise the new behavior.
- [ ] Update README, Installation Guide, Personal-Team-Installation and Paid-Distribution-Path with release operations, migration limits, manual updates, and clean-Mac acceptance checks.
- [ ] Run targeted shell tests, Swift tests, project verification and a universal unsigned release archive; obtain an Apple-platform correctness review and resolve actionable findings.
- [ ] Commit coherent checkpoints, push the feature branch, and report account prerequisites separately from the implemented and locally verified workflow.

## Open questions
- None blocking implementation. Actual signing/notarization requires a Developer ID Application certificate/private key and a Keychain notarization profile. Existing recipient identifiers and signing team must be compared before distributing a migration build; do not guess or silently migrate across teams.

## Validation evidence
- Initial app slice: all Swift tests and rendering smoke tests passed on Xcode 27.2; personal installation and automatic refresh shell suites passed, including Developer ID downgrade guards. Actual signing and notarization are pending account prerequisites.
