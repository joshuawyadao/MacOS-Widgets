# Plan

Address every actionable Codex review finding on PR #13 with test-backed, separately saved safety fixes, then re-run the complete merge-readiness gates.

## Scope
- In: Legacy signing preservation, automatic-refresh locking and status writes, handoff privacy, bounded diagnostics, accurate partial-failure reporting, explicit maintenance consent, tests, documentation, and PR verification.
- Out: New widget features, signing-capability changes, background resource increases, or paid distribution.

## Action items
- [x] Preserve an existing ignored `Local.xcconfig` when creating the stable private installer copy, with migration and no-overwrite tests.
- [x] Reclaim automatic-refresh locks only when their recorded owner process is gone, with active- and stale-lock tests.
- [x] Exclude Xcode `xcuserdata` from handoff ZIPs and verify the archive cannot contain it.
- [ ] Rotate the installer diagnostic log before append and distinguish failures before versus after app replacement.
- [ ] Leave automatic maintenance unchanged during noninteractive installs unless the caller explicitly opts in.
- [ ] Publish automatic-refresh status through per-process temporary files and cover the concurrency-safe path.
- [ ] Run focused checks after each fix, then the complete verifier and `git diff --check`.
- [ ] Push every feedback checkpoint, acknowledge each addressed Codex comment, and confirm fresh Codex review, CI, and mergeability.

## Evidence
- Codex review on commit `a629b51` reported seven unresolved actionable threads: one P1 data/identity-preservation issue and six P2 reliability, privacy, or consent issues.
- The target-Mac Personal Team install and widget-gallery acceptance already succeeded; these fixes harden migration and unattended maintenance without changing the validated signing contract.

## Open questions
- None.
