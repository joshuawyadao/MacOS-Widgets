# Plan

Make the Time and Date widget use the maximum transparency WidgetKit permits on macOS and add real font-rendered previews to the native font choices. Keep the implementation within App Intents and document the system-owned glass/tint limitation honestly.

## Scope
- In: Removable clear WidgetKit background, rendering-mode awareness, font preview assets for every curated font, AppEnum display representations, documentation, build and metadata validation, commit, and push.
- Out: Wallpaper-cropping transparency tricks, a persistent desktop overlay window, third-party font files, and control over macOS-owned Liquid Glass or tint effects.

## Action items
- [x] Verify the current transparency and App Intent presentation APIs against Apple documentation.
- [x] Refactor the widget root to declare an explicitly removable clear container background and remain legible across rendering modes.
- [x] Generate template preview glyph assets using each built-in macOS font and add them to the extension resources.
- [x] Attach each preview asset to its matching AppEnum font display representation.
- [x] Update Time and Date documentation with preview behavior, transparency limits, and relevant macOS appearance settings.
- [x] Build the arm64 macOS app and verify the compiled App Intent metadata includes every font preview image.
- [x] Inspect the final diff, commit the implementation plan and feature changes, and push `feature/time-and-date-widget`.

## Open questions
- None. Native font-preview images are the closest supported representation because the system owns the picker row typography.
