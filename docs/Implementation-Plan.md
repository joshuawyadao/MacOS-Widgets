# Plan

Address the three actionable Codex review findings with narrow behavior fixes and regression tests, saving each feedback item as an independent commit before rechecking the full PR. Preserve existing widget identities, configuration schemas, and refresh budgets except where an earlier event boundary requires a more accurate Calendar update.

## Scope
- In: Current-hour UV selection, Calendar next-event boundary scheduling, Battery health normalization, focused regression tests, per-comment commits and acknowledgements, and final PR verification.
- Out: New widget options, unrelated presentation changes, installation work, signing changes, and broader data-source refactors.

## Action items
[x] Match Weather current UV to the hourly interval containing `current.time`, add a non-hour-aligned fixture regression, run the Weather suite, commit/push the fix, and acknowledge the review comment.
[ ] Carry a next event's end boundary through the private Calendar timing model, refresh at an earlier start/end boundary, add timeline regressions, run the Calendar suite, commit/push the fix, and acknowledge the review comment.
[ ] Treat normalized Battery `MaxCapacity` as an already-computed percentage while calculating ratios only from raw compatible capacity, add parser regressions, run the Battery suite, commit/push the fix, and acknowledge the review comment.
[ ] Run `git diff --check` and the complete `Scripts/verify-widgets.sh` gate after all three fixes.
[ ] Recheck Codex threads, CI Verify, merge conflicts, and GitHub mergeability; leave PR #8 open and merge-ready.

## Open questions
- None.
