# Plan

Add a curated typography system that lets the companion app apply one cohesive style across all widgets while preserving deliberate per-widget-type exceptions. Persist the selection through a macOS team-prefixed App Group, keep system typography as the safe default, retain Time & Date's existing per-copy font controls, and avoid App Intent schema or widget-identity changes.

## Scope
- In: Six curated typography themes, shared App Group preferences, global and per-widget-type controls, a four-widget preview, theme-aware display typography in every widget, Time & Date custom-font fallback, reload behavior, tests, signing/verification updates, documentation, commit, and push.
- Out: Downloaded or bundled fonts, arbitrary installed-font browsing, per-placed-copy theme overrides for Weather/Battery/Calendar, color/background customization, and changes to existing App Intent schemas or widget identities.

## Action items
[x] Add shared typography theme, target, resolution, and injectable preference-store models under `Shared/Styling`.
[x] Configure a team-ID-prefixed macOS App Group for the app and extension without committing a machine-specific Team ID.
[x] Add a companion-app typography section with a global picker, four-widget preview, reset action, and per-widget-type overrides.
[x] Apply theme display fonts to readable hero/header roles in all four widgets while keeping supporting data text in the shared system style.
[x] Preserve Time & Date's existing per-copy date/time fonts behind a `Use Each Widget's Fonts` override and reload all timelines after preference changes.
[x] Add persistence, invalid-value fallback, override-resolution, theme rendering, entitlement, and bundle-metadata verification coverage.
[x] Update `README.md`, `docs/Widget-Design-System.md`, and the four widget guides with the global-theme workflow and signing/storage behavior.
[x] Run targeted tests and `./Scripts/verify-widgets.sh`, review identity/accessibility/readability risks, then commit and push the scoped branch.

## Open questions
- None.
