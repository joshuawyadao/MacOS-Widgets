# Plan

Address every actionable Codex review finding on PR #13 with test-backed, separately saved safety fixes, then re-run the complete merge-readiness gates.

## Scope
- In: Personal Team installation and refresh reliability, signing preservation, concurrency safety, handoff privacy and completeness, bounded diagnostics, accurate status reporting, tests, documentation, and PR verification.
- Out: New widget features, signing-capability changes, persistent background resource use, paid distribution, or rewriting feature-branch history.

## Action items
- [x] Preserve an existing ignored `Local.xcconfig` when creating the stable private installer copy, with migration and no-overwrite tests.
- [x] Reclaim automatic-refresh locks only when their recorded owner process is gone, with active- and stale-lock tests.
- [x] Exclude Xcode `xcuserdata` from handoff ZIPs and verify the archive cannot contain it.
- [x] Rotate the installer diagnostic log before append so repeated scheduled failures stay bounded.
- [x] Distinguish failures before versus after app replacement.
- [x] Leave automatic maintenance unchanged during noninteractive installs unless the caller explicitly opts in.
- [x] Publish automatic-refresh status through per-process temporary files and cover the concurrency-safe path.
- [x] Reuse the saved `Local.xcconfig` Personal Team for unattended refreshes when multiple free teams exist.
- [x] Include the default Xcode DerivedData root when migrating a legacy developer install so stale same-identifier registrations are removed.
- [x] Keep installer `errexit` active while still capturing the redacted logging pipeline status.
- [x] Publish refresh success only when the recomputed signing deadline moves outside the renewal window.
- [x] Inherit the friendly failure trap inside installer functions while preserving classified Xcode diagnostics.
- [x] Serialize scheduled and interactive installer runs through one stale-safe lock.
- [x] Include project test sources in both the handoff and reusable installer copy.
- [x] Reload automatic-maintenance status when the companion app becomes active.
- [x] Reject all ignored secret patterns and output destinations inside packaged source trees.
- [x] Force manual and scheduled refreshes to clean their old products before re-signing.
- [x] Keep attention status accurate when local configuration disappears, after manual refresh, and during agent startup.
- [x] Protect the lock-owner publication gap and validate profiled products before reporting healthy signing.
- [x] Resolve the real account home outside the app sandbox and reveal configured helper locations without sandboxed file probing.
- [x] Recover interrupted app replacements and allow maintenance to be disabled with damaged signing settings.
- [x] Run focused checks after each fix, then the complete verifier and `git diff --check`.
- [x] Push every feedback checkpoint and acknowledge each addressed Codex comment.

## Final handoff gate
Confirm the complete verifier, fresh Codex review, CI, and mergeability on the final pushed head. Report those operational results in the PR handoff without editing this plan again and invalidating the reviewed commit.

## Evidence
- The target-Mac Personal Team install and widget-gallery acceptance succeeded: the companion app launched and Desktop Widgets appeared in the macOS widget gallery.
- Codex review findings were addressed as isolated commits with focused regression coverage and acknowledgements on the corresponding review comments.
- Updated `main` is incorporated through merge commits so feature history remains intact.

## Open questions
- None.
