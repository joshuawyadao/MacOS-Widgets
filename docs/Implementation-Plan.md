# Plan

Create a friendly, repeatable Personal Team installer and refresher that keeps signing data local, installs without administrator access, validates the signed app and widget entitlements, and gives the companion app a plain-language setup path. Preserve widget contracts and use the existing guarded runtime refresh while making every system-changing test run through mocks or dry-run mode.

## Scope
- In: Double-clickable install/refresh commands, Personal Team discovery and local configuration, stable per-team identifiers, signed build/install/runtime refresh, diagnostic logging, companion-app status and guidance, handoff packaging, non-developer and paid-distribution documentation, shell/UI contract tests, and verification updates.
- Out: Paid Apple Developer enrollment, Developer ID signing/notarization implementation, automatic desktop widget placement, password/token handling, background refresh services, and removal of required capabilities.

## Action items
- [x] Document the feasibility result from Apple’s current macOS capability matrix and this project’s App Group, sandbox, network, and calendar entitlements, including the seven-day Personal Team reprovisioning limit and the remaining signed end-to-end manual check.
- [x] Add shared installer tooling plus `Install Desktop Widgets.command` and `Refresh Desktop Widgets.command` to detect full initialized Xcode, discover a selected Personal Team without exposing account credentials, generate ignored local signing configuration, and explain required Xcode account steps plainly.
- [x] Generate stable team-derived app, extension, and App Group identifiers; connect them to automatic signing without changing widget kinds or App Intent schemas; and retain legacy identifiers when an existing local configuration requires compatibility.
- [x] Build with provisioning updates, validate signatures and required entitlements, install atomically to `~/Applications/Desktop Widgets.app`, reuse the guarded widget-runtime refresh, open the app, and produce a redacted diagnostic log with actionable failures and idempotent repeated runs.
- [x] Add a safe handoff packager that includes tracked source and friendly commands/guides but excludes Git metadata, products, credentials, logs, and machine-specific configuration; keep a stable local installer copy so future refreshes remain easy.
- [x] Add companion-app installation state and a concise checklist for install, macOS-controlled placement, appearance, seven-day refresh, helper access, and technical troubleshooting disclosed only when requested.
- [x] Add mocked/dry-run tests for Personal Team parsing, local configuration, stable identifiers, destination safety, build commands, existing installations, idempotent refresh, and failures for missing/uninitialized Xcode, no Personal Team, unavailable capabilities, and provisioning errors.
- [ ] Update `Scripts/verify-widgets.sh`, README, and focused installation/distribution docs; run shell syntax and focused tests throughout, then the complete verification script and `git diff --check`.
- [ ] Save cohesive checkpoints and push `codex/feature/easier-personal-installation` without modifying prior feature-branch history.

## Open questions
- None.
