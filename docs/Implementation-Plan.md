# Plan

Promote the selected Layered Dashboard concept into the Desktop Widgets companion app so macOS can display a distinctive icon in Finder and the widget gallery. Add a complete macOS icon set to an app-only asset catalog, wire it into both app build configurations, and make release verification fail if the compiled icon disappears.

## Scope
- In: Production size variants derived from concept 02, the companion-app asset catalog and Xcode settings, release-bundle verification, selection documentation, full repository verification, and branch save.
- Out: Redesigning the selected artwork, changing widget rendering, adding branding inside the companion app, or removing the unselected concept files.

## Action items
- [x] Create `DesktopWidgetsApp/Resources/Assets.xcassets/AppIcon.appiconset` with the standard 16, 32, 128, 256, 512, and 1024 px macOS representations derived from concept 02.
- [x] Add the app-only asset catalog to the `DesktopWidgets` resources phase and set `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` for Debug and Release.
- [x] Extend `Scripts/verify-widgets.sh` to require the source icon contract and the compiled Release app icon resource.
- [x] Update `docs/App-Icon-Concepts.md` to mark Layered Dashboard as selected and record the completed integration.
- [x] Inspect the smallest generated representations for legibility and validate every PNG's dimensions and format.
- [x] Run the targeted shell syntax check, `./Scripts/verify-widgets.sh`, and `git diff --check`.
- [x] Review the scoped diff, commit the production icon and completed plan, and push `codex/desktop-widget-app-icons`.

## Open questions
- None.
