# Plan

Provide one repeatable, local verification gate for the ready Time & Date and Weather widgets so deterministic behavior and packaging do not need to be retested manually before each commit.

## Scope
- In: Configuration round trips, timeline policies, Weather size limits, existing formatting/data/cache coverage, fresh Debug tests, an unsigned Release build, extension embedding, widget identities, App Intent metadata, and contributor guidance.
- Out: Automating macOS's system-owned desktop placement, Edit Widget popover, Liquid Glass appearance, and real-world WidgetKit refresh timing.

## Action items
- [x] Add shared contract tests for stable, distinct widget identities and minute/hour timeline scheduling.
- [x] Cover every Time & Date layout/date/clock combination and every independent date/time font pair.
- [x] Extract and test one Weather detail-presentation policy across Small, Medium, and Large families.
- [x] Add `Scripts/verify-widgets.sh` as the single pre-commit verification command.
- [x] Make the command run all tests, build Release from fresh artifacts, and validate the embedded WidgetKit extension and both App Intent schemas.
- [x] Run the complete gate, review its output, and document the final result (31 tests plus Release bundle and metadata checks passed on August 16, 2026).

## Open questions
- None. A short hands-on acceptance check remains appropriate before releases that change editor or visual behavior because those surfaces belong to macOS rather than the app's test process.
