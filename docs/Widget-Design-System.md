# Widget Design System

All four widgets share one visual and behavioral shell while keeping the controls, data, and interactions that belong to their individual jobs. This contract applies to Time & Date, Weather, Battery, and Calendar.

## Shared contract

- Support Small, Medium, and Large widget families.
- Map those families to compact, standard, and expanded information density.
- Preserve the primary value before adding secondary details as space grows.
- Keep every placed widget's App Intent configuration independent.
- Use a clear removable WidgetKit container background.
- Render white content with one shared contrast shadow in Full Color and system-primary content without that shadow in accented or vibrant modes.
- Apply the selected shared typography theme to hero values and display headers, while keeping compact labels, status chrome, dense data, and alignment-sensitive digits in the readable shared system style.
- Present stale, constrained, unavailable, or action-required information with the shared compact status treatment when the layout has room.
- Combine noninteractive summaries into concise VoiceOver labels and expose real controls as separate accessible elements.
- Respect the Mac's locale, time zone, calendar, units, and first-weekday conventions wherever they apply.

The shared primitives live in `Shared/Styling/WidgetTheme.swift` and `Shared/Styling/WidgetTypography.swift`. Widget-specific presentation metrics may still choose different hero sizes or grids, but should build on the common family density, surface treatment, and typography resolution rather than defining their own foreground, shadow, background, or preference storage behavior.

## Typography

The companion app owns one global display theme: **System** (system rounded), **Modern** (Avenir Next), **Editorial** (system serif), **Technical** (system monospaced), **Playful** (Noteworthy), or **Handmade** (Marker Felt). System is the safe default. Each widget type may follow that theme or select another curated theme, keeping a coordinated baseline without making every widget identical.

Only display roles adopt the chosen font: Time & Date's date and clock, Weather's location and hero temperature, Battery's percentage, and Calendar's primary date or period headers. Supporting forecast values, detail cards, status messages, calendar grids, and accessibility structure retain the system style so dense information remains legible.

Time & Date has one deliberate exception: **Use Each Widget's Fonts** defers to the separate date and time font choices stored in each placed widget's configuration. Weather, Battery, and Calendar overrides apply per widget type because adding font fields to their App Intents would change persisted configuration schemas and create editor complexity.

The host app and extension share selections through a team-ID-prefixed macOS App Group. Preference changes reload every WidgetKit timeline; unknown or unavailable stored values resolve safely to the global theme or System. No fonts are downloaded or bundled.

## Information density

| Family | Density | Content priority |
| --- | --- | --- |
| Small | Compact | One hero value or focused view plus one essential status |
| Medium | Standard | Hero content plus a comparison, forecast strip, week, or selected details |
| Large | Expanded | Full dashboard, month, or complete selected-detail presentation |

Size limits are part of the product contract. A compact widget should simplify content instead of shrinking every available detail until it becomes difficult to read.

## Configuration order

Use this order when a category applies:

1. **Source** — city, device source, calendar source, or other context.
2. **View** — arrangement or time range.
3. **Details** — optional secondary information.
4. **Format or appearance** — units, date/clock format, or typography.

Domain-specific editor labels should remain clear. The common order does not require irrelevant controls, generic wording, or a new App Intent identity.

## Deliberate widget-specific features

- **Time & Date:** arrangements, date and clock formats, optional per-copy hero fonts, AM/PM behavior, and minute scheduling.
- **Weather:** searchable city, forecast views, units, detail presets, caching, offline/error handling, and provider attribution.
- **Battery:** internal battery gauge, power-state details, runtime estimates, no-battery handling, and five-minute local readings.
- **Calendar:** Day/Week/Month selection, locale-aware grids, optional private event indicators, Calendar permission state, and month navigation.

Do not add per-copy font fields, provider links, permission prompts, timestamps, or interactive buttons to every widget solely for symmetry. Consistency comes from the shared display-theme layer plus predictable hierarchy, configuration, state language, accessibility, and rendering behavior.

## Verification

The shared test contract covers family-to-density mapping, progressively sized chrome metrics, typography preference persistence and fallback, and every curated theme rendered through all four widgets. Rendering smoke tests must also include all four widgets across Small, Medium, and Large, plus representative stale, unavailable, permission, or long-content states. Widget-specific suites remain responsible for formatters, data normalization, privacy boundaries, refresh policies, and interactions.

Run `./Scripts/verify-widgets.sh` before committing or pushing widget changes.
