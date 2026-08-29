# Plan

Finish the friendly Personal Team installer after target-Mac validation exposed a blocking maintenance wake-up. Keep the terminal prompt visible, avoid the redundant blocking `launchctl kickstart`, and open the companion app only after setup has actually completed.

## Scope
- In: Installer completion ordering, visible terminal input, non-blocking automatic-maintenance activation, regression tests, full verification, replacement package, and branch save.
- Out: Changes to widget identities, placement, signing capabilities, or the paused GitHub-update feature.

## Action items
- [x] Add a regression test proving automatic-maintenance enablement does not issue a blocking `launchctl kickstart`.
- [x] Write the maintenance question directly to the interactive terminal and read its answer from that terminal so logging cannot hide it.
- [x] Register the widget first, configure maintenance second, and open the installed companion app only after setup completes.
- [x] Extend installer dry-run coverage to verify app-opening order and scheduled-refresh behavior.
- [x] Run focused installer and maintenance tests, the complete verification script, and `git diff --check`.
- [x] Save and push the fix on `codex/feature/easier-personal-installation`, then generate a clean replacement ZIP.

## Evidence
- Target-Mac process inspection showed `manage-automatic-refresh.sh enable` blocked for several minutes in `/bin/launchctl kickstart -k` after the installed app was already present.
- `bootstrap` had already loaded a `RunAtLoad` LaunchAgent and written enabled status, making the synchronous extra kickstart redundant.

## Open questions
- None.

## Verification result

- Focused installer, automatic-maintenance, packaging, and shell-syntax tests passed.
- `Scripts/verify-widgets.sh` passed the complete macOS tests, Release build, extension metadata checks, and registration-safety checks.
- `git diff --check` passed.
