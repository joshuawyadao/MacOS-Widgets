# Plan

Replace the Weather widget's two-field primitive city editor with one native searchable city entity so macOS presents a familiar search field with readable matching locations and never exposes the stored identifier.

## Scope

- In: A fresh searchable city entity/query, a single City configuration parameter, a new widget configuration identity, location identifier round-tripping, automated coverage, build-number migration, and user documentation.
- Out: A custom SwiftUI replacement for the macOS-owned widget editor, forecast-service changes, or unrelated Weather layout changes.

## Action items

- [x] Reproduce the two-field/raw-identifier editor regression at the App Intent source seam.
- [x] Add a fresh Weather city entity and string query that return labeled Open-Meteo matches and restore saved identifiers.
- [x] Replace Search City and Matching City with one searchable City parameter and migrate the widget to a fresh configuration identity.
- [x] Add tests for readable entity presentation, multiple matches, identifier restoration, and selected-location delivery.
- [x] Update metadata verification, the companion-app guidance, README, and Weather documentation for the one-field workflow.
- [x] Run the full widget verification suite and inspect the generated App Intents metadata.
- [x] Commit and push the completed change to the current feature branch.

## Open questions

- None.
