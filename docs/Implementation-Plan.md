# Plan

Normalize only the Large Weather widget’s vertical rhythm by separating section filling from item spacing, keeping its expanded dashboard useful without stretching the weekday, icon, and temperature apart.

## Scope
- In: Large forecast-column spacing behavior, a focused regression contract, Weather appearance documentation, full verification, and branch saving.
- Out: Small and Medium layouts, forecast data, city configuration, signing, background treatment, or a broader redesign.

## Action items
[x] Add a red regression contract proving Large must fill its forecast section without flexible gaps inside each forecast column.
[x] Split section-height behavior from forecast-item spacing in `WeatherPresentation.swift`.
[x] Update `WeatherWidget.swift` so Large keeps fixed, coherent spacing between weekday, condition, and temperature.
[x] Confirm Small and Medium layout metrics remain unchanged.
[x] Update `docs/Weather-Widget.md` to describe the revised Large vertical rhythm.
[x] Run the focused regression and `./Scripts/verify-widgets.sh`, review the scoped diff, and save the Weather feature branch.

## Open questions
- None.
