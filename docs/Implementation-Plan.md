# Plan

Strengthen the widget render smoke tests so a renderer that returns an encoded but visually blank image fails. Inspect decoded bitmap pixels for visible, non-uniform content while preserving the existing representative family and state coverage.

## Scope
- In: The render assertion helper, targeted render-test validation, the full repository verification gate, and the Codex review acknowledgement workflow.
- Out: Pixel-perfect golden snapshots, production widget behavior changes, new visual states, or documentation changes beyond this implementation plan because the existing docs already describe these as render smoke tests.

## Action items
[x] Inspect the Codex P2 review thread and the existing `WidgetRenderingSmokeTests` helper.
[x] Replace the TIFF byte-count assertion with decoded bitmap checks for visible, non-uniform pixels.
[x] Preserve scenario-specific failure messages so a blank rendering identifies the affected widget case.
[x] Run the targeted widget rendering smoke tests and the complete `Scripts/verify-widgets.sh` gate.
[x] Inspect the final diff and confirm no unrelated files or behavior changed.
[x] Commit and push the focused fix, then add a thumbs-up reaction to the addressed Codex comment.

## Open questions
- None.
