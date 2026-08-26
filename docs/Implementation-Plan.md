# Plan

Close the test-suite gaps found by the coverage audit while keeping the fast logic-heavy suite intact. Add deterministic weather transport and timeline tests, complete the Battery parser state matrix, add representative SwiftUI render smoke tests, and surface coverage in local and CI verification.

## Scope
- In: Open-Meteo transport/error tests, WeatherProvider timeline-policy seams and tests, Battery parser edge cases, representative widget render smoke tests, coverage-enabled verification, CI reporting, and affected test documentation.
- Out: Live-network tests, pixel-perfect golden snapshots, blanket coverage thresholds, macOS-owned widget editor/persistence automation, or production behavior changes beyond a deterministic timeline test seam.

## Action items
[x] Add deterministic URLProtocol-backed forecast and city-search tests for success, short-query, HTTP, decoding, empty-data, and transport failures.
[x] Extract a date-injectable WeatherProvider timeline seam and verify loaded, stale, retryable, and permanent-failure scheduling.
[x] Complete the Battery parser matrix for charged, plugged-in, unknown, and missing charging metadata states.
[x] Add representative render smoke tests for every widget family and the no-battery, stale/failure weather, long-location, and 12/24-hour layout states.
[x] Enable Xcode coverage collection and print target summaries in local verification and CI without imposing a brittle repository-wide percentage gate.
[x] Update the README and widget docs so automated coverage and remaining macOS-owned acceptance checks stay accurate.
[x] Run targeted tests, the complete coverage-enabled suite, the repository verification gate, and inspect the final coverage/diff.
[x] Commit and push the verified coverage additions on the current branch.

## Open questions
- None.
