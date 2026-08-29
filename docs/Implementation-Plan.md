# Plan

Make every installer question visible through the same terminal-safe input path so selecting among multiple Personal Teams cannot look like a stalled installation.

## Scope
- In: Shared interactive-choice handling, Personal Team selection, automatic-maintenance confirmation, regression coverage, verification, and branch save.
- Out: Changes to signing capabilities, widget identifiers, provisioning policy, or the already validated installation destination.

## Action items
- [x] Add a failing regression test for a visible, piped fallback choice and selection from multiple Personal Teams.
- [x] Add one terminal-safe interactive-choice helper to the personal-installation library.
- [x] Route Personal Team selection and automatic-maintenance confirmation through the shared helper while preserving noninteractive defaults.
- [x] Run focused installation, automatic-refresh, packaging, and shell-syntax tests.
- [x] Run the complete widget verification script and `git diff --check`.
- [x] Save and push the review fix on `codex/feature/easier-personal-installation`.

## Evidence
- The target-Mac installer previously appeared stalled when a maintenance prompt was hidden behind piped diagnostic logging.
- Brooks review found the multiple-Personal-Team prompt still used direct stdin/stderr handling and could reproduce the same failure mode.

## Open questions
- None.
