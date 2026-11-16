# Plan

Preserve release tooling coverage and verify post-merge changes while tracking recipient acceptance separately.

## Scope
- In: Scoped CI enforcement, automated validation, meaningful orchestration regressions, and canonical verification documentation for MacOS Widgets.
- Out: Product feature changes, deployment, paid services or account changes, personal data, physical-device operation, and release signing/publishing.

## Action items
- [ ] Read Paid-Distribution-Path and installation docs plus current release and CI regression checks.
- [ ] Confirm CI Verify remains required by the existing ruleset.
- [ ] Add main push verification alongside PR/manual checks while preserving unsigned Release/archive and mocked release coverage.
- [ ] Reuse existing identity/team/App Group tests; add cases only if a concrete uncovered contract is found.
- [ ] Run safe mocked release/shell/repository checks without signing credentials, install or widget reload.
- [ ] Update distribution acceptance status and README, then save and push the isolated release-workstream branch.

## Discovery notes
- Baseline: `94d5bba9405abdbc7a742b7d8744e3a616cca355` (`codex/notarized-dmg-release`), isolated from the original checkout.
- Existing in-progress changes in original project folders remain untouched.
- Missing hosting/account capabilities are reported as concrete limitations; they are not permission to weaken required checks.
