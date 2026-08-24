# Plan

Rebalance the Weather widget’s Small, Medium, and Large layouts so compact temperatures remain complete, seven-column forecasts breathe horizontally, and expanded forecasts use their vertical space deliberately.

## Scope
- In: Family-specific Weather layout metrics, small day-column sizing, medium forecast typography and gaps, large forecast vertical distribution, regression contracts, and Weather appearance documentation.
- Out: Weather data behavior, configuration options, signing setup, widget background treatment, or a broader visual redesign.

## Action items
[x] Add family-specific layout contracts for minimum temperature width, scaling, and expanded vertical distribution in `WeatherPresentation.swift`.
[x] Refactor the day row and temperature label in `WeatherWidget.swift` so Small preserves the complete temperature and high/low values.
[x] Reduce Medium forecast density while retaining all seven days and readable weather symbols.
[x] Spread Large forecast columns through the available lower section instead of leaving one unused vertical band.
[x] Extend `WeatherConfigurationTests.swift` with explicit anti-clipping, spacing, and expanded-layout assertions.
[x] Update `docs/Weather-Widget.md` to describe the revised family-specific layout behavior and acceptance checks.
[x] Run the complete widget verification gate, review the diff for unrelated changes, and save the current Weather feature branch.

## Open questions
- None.
