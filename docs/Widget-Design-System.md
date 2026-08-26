# Widget Design System

All four widgets share one visual and behavioral shell while keeping the controls, data, and interactions that belong to their individual jobs. This contract applies to Time & Date, Weather, Battery, and Calendar.

## Shared contract

- Support Small, Medium, and Large widget families.
- Map those families to compact, standard, and expanded information density.
- Preserve the primary value before adding secondary details as space grows.
- Keep every placed widget's App Intent configuration independent.
- Use a clear removable WidgetKit container background.
- Render white content with one shared contrast shadow in Full Color and system-primary content without that shadow in accented or vibrant modes.
- Use rounded system typography for shared labels and status chrome, monospaced digits where alignment matters, and SF Symbols for semantic icons.
- Present stale, constrained, unavailable, or action-required information with the shared compact status treatment when the layout has room.
- Combine noninteractive summaries into concise VoiceOver labels and expose real controls as separate accessible elements.
- Respect the Mac's locale, time zone, calendar, units, and first-weekday conventions wherever they apply.

The shared primitives live in `Shared/Styling/WidgetTheme.swift`. Widget-specific presentation metrics may still choose different hero sizes or grids, but should build on the common family density and surface treatment rather than defining their own foreground, shadow, or background behavior.

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

- **Time & Date:** arrangements, date and clock formats, separate hero fonts, AM/PM behavior, and minute scheduling.
- **Weather:** searchable city, forecast views, units, detail presets, caching, offline/error handling, and provider attribution.
- **Battery:** internal battery gauge, power-state details, runtime estimates, no-battery handling, and five-minute local readings.
- **Calendar:** Day/Week/Month selection, locale-aware grids, optional private event indicators, Calendar permission state, and month navigation.

Do not add fonts, provider links, permission prompts, timestamps, or interactive buttons to every widget solely for symmetry. Consistency comes from predictable hierarchy, configuration, state language, accessibility, and rendering behavior.

## Verification

The shared test contract covers family-to-density mapping and progressively sized chrome metrics. Rendering smoke tests must include all four widgets across Small, Medium, and Large, plus representative stale, unavailable, permission, or long-content states. Widget-specific suites remain responsible for formatters, data normalization, privacy boundaries, refresh policies, and interactions.

Run `./Scripts/verify-widgets.sh` before committing or pushing widget changes.
