# Plan

Increase visual separation between the transparent widget views and their public showcase background without changing the widgets' production appearance. Use a dark, code-generated presentation surface for both the README preview and GitHub social card, then validate contrast, dimensions, privacy, and the full project gate before protected publication.

## Scope
- In: Dark showcase backdrop and card treatment, deterministic contrast coverage, automatic social-preview generation, regenerated README/social images, documentation, validation, and protected publication.
- Out: Production widget themes or behavior, user-specific screenshots, signed distribution, repository security settings, and GitHub's manual social-preview upload.

## Action items
[x] Update `PortfolioPreview` in `DesktopWidgetsTests/WidgetRenderingSmokeTests.swift` with a dark backdrop, stronger card surfaces, readable title/attribution styling, and a focused contrast assertion.
[x] Extend `Scripts/generate-portfolio-preview.sh` to regenerate both `docs/images/widgets-preview.png` and a 1280 × 640, sub-1 MB `docs/images/widgets-social-preview.jpg` from the same synthetic render.
[x] Update `README.md` so the documented generator accurately names both public assets without duplicating design-system documentation.
[x] Generate and visually inspect both images for card separation, legibility, complete widget framing, deterministic synthetic data, dimensions, size, and absence of private text.
[x] Run the focused generator test, shell/Markdown checks, `git diff --check`, and the complete `./Scripts/verify-widgets.sh` gate.
[ ] Commit and push the scoped changes on `codex/darker-showcase`, open a pull request, address review feedback, confirm public CI passes, and prepare the change for protected squash merge.

## Open questions
- None. The existing synthetic data, widget layouts, and manual GitHub upload workflow remain unchanged.
