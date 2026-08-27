# Plan

Add shared font-aware layout compensation so every curated typography theme gets enough breathing room without changing widget identities or reducing the information shown. Centralize conservative font scaling, glyph padding, and spacing adjustments in the typography layer, then apply them consistently across all four widget families.

## Scope
- In: Theme-specific layout profiles, adaptive display/supporting font sizing, text-safe vertical padding, stack/grid spacing adjustments, tighter minimum-scale safeguards, all-widget/family rendering coverage, and typography documentation.
- Out: User-facing spacing controls, per-widget padding settings, widget family redesigns, App Intent schema changes, font downloads, SF Symbol scaling, and widget identity changes.

## Action items
[x] Add bounded `WidgetTypographyLayoutProfile` values and reusable font-size, spacing, padding, and minimum-scale helpers to `Shared/Styling/WidgetTypography.swift`.
[x] Apply the shared typography compensation to Time & Date and shared status chrome while preserving the existing System and per-copy-font layouts.
[x] Apply adaptive spacing, text padding, and scaling safeguards to Weather, Battery, and Calendar, including dense forecast columns, detail cards, and calendar day markers.
[x] Extend contract tests for every layout profile and rendering smoke tests for all six themes, both coverage modes, all four widgets, and all three widget families.
[x] Update `README.md`, `Shared/Styling/README.md`, and `docs/Widget-Design-System.md` with the automatic clipping protection and its deliberate limits.
[x] Run targeted typography/rendering tests and `./Scripts/verify-widgets.sh`, inspect layout, identity, and accessibility risks, then commit and push the scoped change.

## Open questions
- None.
