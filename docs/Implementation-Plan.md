# Plan

Close the iconless upgrade path discovered during real installation and Codex review by teaching the widget-runtime refresh to remove known legacy Desktop Widgets registrations from DerivedData or from a retired database record at the exact current extension path. Preserve the safety boundary for every other installed path, add focused regression coverage, update the runtime documentation, then re-run the PR review and CI gates.

## Scope
- In: Legacy Desktop Widgets extension-ID cleanup under configured DerivedData roots and at the exact current extension path, external registration preservation, focused shell coverage, runtime-refresh documentation, full verification, branch save, and PR re-review.
- Out: Deleting DerivedData products, unregistering apps outside DerivedData, changing current Personal Team identifiers, removing placed widgets or preferences, and paid distribution.

## Action items
- [x] Extend `Scripts/refresh-widget-runtime.sh` with the known pre-installer extension identifier and query it separately when the current extension uses a Personal Team identifier.
- [x] Remove a known retired-ID database record at the exact current extension path immediately before re-registering the current ID, while preserving every other matching registration outside the configured DerivedData roots.
- [x] Update `Scripts/test-refresh-widget-runtime.sh` with separate current-ID and legacy-ID registrations, including the same-path upgrade case identified by Codex.
- [x] Update the canonical runtime-refresh notes in `docs/Personal-Team-Installation.md` and `docs/Weather-Widget.md`.
- [x] Run the focused runtime-refresh test, shell syntax checks, a live legacy-registration migration check, the complete `./Scripts/verify-widgets.sh` gate, `git diff --check`, and regenerate the ignored handoff ZIP.
- [x] Prepare the scoped Brooks fix for branch save and fresh Codex review, CI Verify, review-thread, and mergeability checks.

## Open questions
- None.
