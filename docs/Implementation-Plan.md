# Plan

Refine the Weather widget’s Small, Medium, and Large layouts with stronger family-specific constraints so compact temperatures remain complete, seven-day forecasts have clearer separation, and expanded forecasts use their full height without clipping the location.

## Scope
- In: Weather layout metrics, adaptive temperature rendering, family-specific headers, forecast section sizing, layout regression tests, and Weather appearance documentation.
- Out: Forecast fetching, city selection, configuration behavior, signing, background treatment, and unrelated widget designs.

## Action items
[x] Add explicit compact-temperature, medium-grid, and large-header layout contracts in `WeatherPresentation.swift`.
[x] Replace Small’s truncation-prone temperature scaling with bounded `ViewThatFits` fallbacks in `WeatherWidget.swift`.
[x] Increase Medium’s visual separation while keeping all seven forecast columns readable.
[x] Give Large a dedicated location row and balance its current summary and forecast across the available height.
[x] Extend `WeatherConfigurationTests.swift` with regression assertions for the revised family-specific metrics.
[x] Update `docs/Weather-Widget.md` with the new layout behavior and visual acceptance criteria.
[x] Run `./Scripts/verify-widgets.sh`, review the scoped diff, and save the current Weather feature branch.

## Open questions
- None.
