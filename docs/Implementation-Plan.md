# Plan

Address the Brooks review warning on pull request #12 by giving the showcase layout one source of truth for dimensions, spacing, and card pixel rectangles. Preserve the approved visual output while making the clipping regression resistant to future layout changes, then validate and push the focused review fix.

## Scope
- In: Shared showcase layout metrics, derived card-edge scan rectangles, explicit render-size coverage, Brooks review history, regenerated assets if needed, validation, and a follow-up commit on `codex/fix-preview-text-clipping`.
- Out: Production WidgetKit layouts, approved showcase styling or content, unrelated refactors, and merging pull request #12.

## Action items
[x] Extract the preview canvas, padding, header, row, card, inset, and pixel-scan metrics into a shared `PortfolioPreviewLayout` definition.
[x] Update `PortfolioPreview` to consume the shared metrics and give the header an explicit layout height so card origins are deterministic.
[x] Derive all card rectangles and edge-clearance ranges from the same point-based metrics and renderer scale; assert the expected bitmap dimensions before scanning.
[x] Record the Brooks PR review result and verify the approved README/social assets remain visually unchanged apart from any deterministic re-encoding.
[x] Run the focused generator, `git diff --check`, and complete `./Scripts/verify-widgets.sh` gate.
[x] Prepare the Brooks review fix for pull request #12 and re-check Codex review, CI Verify, and mergeability without merging.

## Open questions
- None. The shared metrics remain private test/showcase infrastructure and do not affect production widget behavior.
