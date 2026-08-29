# Plan

Keep every synthetic widget's text inside the rounded showcase cards by adding presentation-only content insets and a deterministic edge-clearance regression check. Regenerate both public image assets on `codex/fix-preview-text-clipping`, validate them, and stop for user review without opening a pull request or merging to `main`.

## Scope
- In: Showcase-only card insets, edge-clearance rendering coverage, regenerated README and social-preview images, focused/full validation, and a reviewable feature branch.
- Out: Production WidgetKit layouts, typography choices, widget behavior, a pull request, and any merge to `main` before explicit user approval.

## Action items
[x] Add a consistent content inset inside `PortfolioPreview` cards while preserving their dimensions and dark presentation styling.
[x] Extend `WidgetRenderingSmokeTests` with a pixel-level safe-edge assertion that catches bright widget content touching any card boundary.
[x] Regenerate `docs/images/widgets-preview.png` and `docs/images/widgets-social-preview.jpg` from the real synthetic widget views.
[x] Visually inspect both assets for unclipped text, balanced spacing, complete widget framing, and unchanged privacy-safe sample data.
[x] Run the focused generator, `git diff --check`, and the complete `./Scripts/verify-widgets.sh` gate; no README prose change is expected because the generation workflow is unchanged.
[x] Prepare the validated implementation on `codex/fix-preview-text-clipping` for user review, then stop without opening a pull request or merging.

## Open questions
- None. The requested review checkpoint is the end of this pass; publication remains a separate, explicitly approved step.
