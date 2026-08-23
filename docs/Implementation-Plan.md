# Plan

Investigate recent Weather-widget commits for concrete regressions and apply the smallest safe fix backed by repo evidence. The current verification gate fails at build time on widget `#Preview` macros, so this run will replace the macro-based previews with compile-safe preview providers and re-run the widget verification script.

## Scope
- In: Recent commit inspection, widget preview build failure, minimal preview-only code changes, verification rerun, and a short note in docs if behavior changed.
- Out: Weather feature refactors, visual redesigns, data-flow changes, or speculative fixes without failing evidence.

## Action items
- [x] Inspect recent commits since the last week and identify candidate regressions with concrete evidence.
- [x] Run `./Scripts/verify-widgets.sh` to capture the current failing signal on `HEAD`.
- [x] Replace `#Preview` macro blocks in the widget sources with non-macro preview providers that preserve the same sample states.
- [x] Re-run `./Scripts/verify-widgets.sh` and confirm the build/test gate passes or capture any remaining concrete failure.
- [x] Confirm no durable behavior or verification guidance changed beyond the build fix, so no additional docs updates were needed.
- [ ] Commit and push the minimal fix on the current branch.

## Open questions
- None.
