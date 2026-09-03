# Plan

Create a focused app-icon exploration for Desktop Widgets so the companion app can gain a recognizable identity in the macOS widget gallery. Generate four distinct, small-size-friendly concepts rooted in the existing indigo, navy, and white visual system, preserve the prompts and selection guidance, and defer Xcode target wiring until a concept is selected.

## Scope
- In: Four square app-icon concept PNGs, a documented concept comparison and prompt record, asset validation, and a saved feature branch.
- Out: Selecting a final concept, producing the complete production icon set, adding a companion-app asset catalog, or changing Xcode app-icon build settings.

## Action items
- [x] Confirm the existing widget palette, visual motifs, companion-app resource setup, and macOS build verification path.
- [x] Generate four original 1024 × 1024 icon concepts with strong silhouettes, no text, and distinct visual directions.
- [x] Inspect the generated concepts at full and reduced size, refining any candidate that loses clarity or violates the visual constraints.
- [x] Save every reviewable concept under `docs/images/app-icon-concepts/` with stable descriptive filenames.
- [x] Add `docs/App-Icon-Concepts.md` with a comparison, selection criteria, exact generation prompts, and the implementation step that follows selection.
- [x] Record why executable tests and canonical behavior docs do not change during this visual exploration.
- [x] Validate image formats and dimensions, run `git diff --check`, and review the scoped diff.
- [x] Commit and push `codex/desktop-widget-app-icons` for review.

## Open questions
- None.
