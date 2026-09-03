# Plan

Finish the free personal-handoff path for Desktop Widgets by promoting the build to 1.0, reducing gift-package clutter, and making the first-run and maintenance instructions immediately actionable for a non-developer. Strengthen regression coverage for the handoff contents and version contract, generate the final ZIP, then publish the branch through the full PR review cycle.

## Scope
- In: Version 1.0 build metadata, a prominent package-only `START HERE.txt`, concise post-install personalization guidance, exclusion of internal planning/icon-review artifacts from the gift ZIP, package and release verification, final ZIP generation, branch save, and PR shepherding.
- Out: Paid Developer ID/notarization, actions on the recipient's Mac, personalized city/theme choices that require her preferences, and non-user-facing Calendar/Weather presentation refactors.

## Action items
- [x] Set app, extension, and test build configurations to marketing version 1.0.0 and verify the built app/extension expose the same release version.
- [x] Replace the package's internal `Package Contents.txt` note with a prominent `START HERE.txt` that leads with the one-click installer and four short setup steps.
- [x] Exclude implementation plans, app-icon review documentation, and unselected concept images from the recipient ZIP while keeping production icon resources intact.
- [x] Make installer completion and `Installation Guide.md` explain the immediate add, appearance, Weather city, optional Calendar, and automatic-maintenance actions in plain language.
- [x] Extend package regression tests for `START HERE.txt`, production app-icon resources, version metadata, and excluded internal design artifacts.
- [x] Run targeted shell/package tests, the complete `./Scripts/verify-widgets.sh` gate, `git diff --check`, and generate the final ignored handoff ZIP.
- [x] Review the scoped diff, commit and push `codex/desktop-widget-app-icons`, then run the PR review cycle through green CI and merge-ready status.

## Open questions
- None.
