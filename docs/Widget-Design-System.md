# Widget Design System

All four widgets share one visual and behavioral shell while keeping the controls, data, and interactions that belong to their individual jobs. This contract applies to Time & Date, Weather, Battery, and Calendar.

## Companion app navigation

The companion app uses a two-column `NavigationSplitView` with a persistent macOS sidebar. Destinations have one stable order and one clear responsibility:

- **Home** is the starting dashboard with two-step setup, clickable widget cards, an Appearance shortcut, and optional Calendar access.
- **Appearance** contains the complete draft preview, global theme, Font Coverage, widget overrides, System Style, Revert, and Apply Theme flow. A sidebar indicator remains visible while the draft differs from the last applied selection.
- **Time & Date**, **Weather**, **Battery**, and **Calendar** each explain how to edit a placed copy and show only controls or caveats relevant to that widget. Weather owns detail-capacity guidance; Calendar owns a direct permission control.
- **Help & Privacy** consolidates add/edit instructions, refresh expectations, blank-placeholder guidance, Calendar permission management, Weather provider links, and Liquid Glass readability guidance.

Typography and Calendar permission controllers belong to the root view rather than an individual destination. Navigation must not discard an unapplied appearance draft, repeat a reload, or recreate permission state. Sidebar rows and clickable Home cards use native labels, selection, and accessibility hints; pages remain independently scrollable so the sidebar stays available throughout longer guidance.

## Shared contract

- Support Small, Medium, and Large widget families.
- Map those families to compact, standard, and expanded information density.
- Preserve the primary value before adding secondary details as space grows.
- Keep every placed widget's App Intent configuration independent.
- Use a clear removable WidgetKit container background.
- Render white content with one shared contrast shadow in Full Color and system-primary content without that shadow in accented or vibrant modes.
- Apply the selected shared typography theme according to Font Coverage: Display Text themes hero values and headers, while All Text also themes compact labels, status chrome, dense data, and alignment-sensitive values.
- Resolve font-aware layout compensation from the same typography theme so wider or taller curated faces get conservative point-size reduction, tighter horizontal gaps, looser vertical spacing, glyph padding, and minimum-scale protection instead of clipping.
- Present stale, constrained, unavailable, or action-required information with the shared compact status treatment when the layout has room.
- Combine noninteractive summaries into concise VoiceOver labels and expose real controls as separate accessible elements.
- Respect the Mac's locale, time zone, calendar, units, and first-weekday conventions wherever they apply.
- Resolve shared typography preferences, family metrics, and widget-specific presentation data once at each widget root, then pass those immutable values through the render tree instead of rebuilding them in individual labels or grid cells.

The shared primitives live in `Shared/Styling/WidgetTheme.swift` and `Shared/Styling/WidgetTypography.swift`. Widget-specific presentation metrics may still choose different hero sizes or grids, but should build on the common family density, surface treatment, and typography resolution rather than defining their own foreground, shadow, background, or preference storage behavior.

The render-preparation rule is a performance boundary rather than a cache with independent lifetime. A new WidgetKit entry, family, locale, time zone, rendering mode, or applied typography selection creates a new resolved root value, preserving normal SwiftUI and WidgetKit invalidation behavior without global mutable formatter or presentation state.

## Typography

The companion app owns one global display theme: **System** (system rounded), **Modern** (Avenir Next), **Editorial** (system serif), **Technical** (system monospaced), **Playful** (Noteworthy), or **Handmade** (Marker Felt). System is the safe default. Each widget type may follow that theme or select another curated theme, keeping a coordinated baseline without making every widget identical.

**Font Coverage** controls where that resolved theme appears. **Display Text** is the default: only Time & Date's date and clock, Weather's location and hero temperature, Battery's percentage, and Calendar's primary date or period headers adopt the font. Supporting forecast values, detail cards, status messages, calendar grids, and attribution retain the system style so dense information remains legible. **All Text** also applies the resolved theme to those textual supporting roles. It does not replace SF Symbols, change information density, or alter accessibility labels.

Each curated theme also resolves a bounded layout profile. Wider or taller faces use a slight point-size reduction, fractional vertical glyph padding, modestly tighter horizontal gaps, looser vertical spacing, and a theme-safe minimum scale factor. These adjustments apply automatically across Small, Medium, and Large; System retains the original metrics, and Time & Date's **Use Each Widget's Fonts** keeps its established per-copy layout behavior. The profiles protect text without hiding data, changing controls, or giving users a second set of spacing preferences to manage.

Time & Date has one deliberate exception: **Use Each Widget's Fonts** defers to the separate date and time font choices stored in each placed widget's configuration. Weather, Battery, and Calendar overrides apply per widget type because adding font fields to their App Intents would change persisted configuration schemas and create editor complexity.

The host app and extension share theme, coverage, and overrides through a team-ID-prefixed macOS App Group. The app treats theme, coverage, and override edits as one draft: previews respond immediately, but shared preferences remain unchanged until **Apply Theme** persists the complete selection and makes one `reloadAllTimelines()` request. **Revert** restores the last applied selection locally, and **Use System Style** stages the safe System, Display Text, and Follow Global defaults for review before applying. This workflow does not add polling, retries, or any change to regular widget refresh schedules. WidgetKit still renders each placed widget independently, so macOS may show their transitions a few moments apart. Unknown or unavailable stored values resolve safely to the global theme, Display Text coverage, or System. No fonts are downloaded or bundled.

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

- **Time & Date:** arrangements, date and clock formats, optional per-copy hero fonts, an optional labeled secondary time zone, AM/PM behavior, and minute scheduling.
- **Weather:** searchable city, forecast views, units, comfort/UV/sun detail presets, caching, offline/error handling, and provider attribution.
- **Battery:** internal battery gauge, power-state details, runtime estimates, optional local health/cycle diagnostics, no-battery handling, and five-minute local readings.
- **Calendar:** Day/Week/Month selection, locale-aware grids, optional private event indicators and title-free next-event timing, Calendar permission state, and month navigation.

Do not add per-copy font fields, provider links, permission prompts, timestamps, or interactive buttons to every widget solely for symmetry. Consistency comes from the shared display-theme layer plus predictable hierarchy, configuration, state language, accessibility, and rendering behavior.

## Verification

The shared test contract covers family-to-density mapping, progressively sized chrome metrics, typography layout-profile bounds, draft-versus-applied preference behavior, safe reset and fallback, and every curated theme rendered through all four widgets in Display Text and All Text modes. Rendering smoke tests include every typography combination across Small, Medium, and Large, plus representative stale, unavailable, permission, and long-content states. Widget-specific suites remain responsible for formatters, data normalization, privacy boundaries, refresh policies, and interactions.

Run `./Scripts/verify-widgets.sh` before committing or pushing widget changes.
