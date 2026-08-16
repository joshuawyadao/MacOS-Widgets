# Plan

Deepen the existing verification gate so it checks the content each widget will present for every supported size and configuration, without relying on brittle screenshots or launching the macOS widget editor.

## Scope
- In: Shared presentation contracts used by both SwiftUI views and tests; Weather family/view/preset/state behavior; Time & Date family/layout/format behavior; accessibility strings; existing configuration, timeline, service, cache, Release bundle, identity, and App Intent metadata checks.
- Out: macOS-owned desktop placement, Edit Widget persistence, Liquid Glass/tinted rendering, live VoiceOver traversal, link activation, and real-world WidgetKit scheduling.

## Action items
- [x] Add a Weather presentation contract and make the SwiftUI view consume its family adaptation, forecast selection, titles, detail limits, state, location, and attribution decisions.
- [x] Test all 54 Weather family/view/preset combinations plus stale data, permanent failure, exhausted hourly data, and forecast-city midnight rollover.
- [x] Add a Time & Date presentation contract and make the SwiftUI view consume its layout adaptation, formatted date/time/period, and combined accessibility label.
- [x] Test all family/layout combinations and all family/date-format/time-format combinations.
- [x] Run the complete verification gate from fresh build artifacts and record the result (37 tests plus Release bundle and metadata checks passed on August 16, 2026).
- [ ] Save the isolated feature branch and complete the PR review cycle against the Weather feature branch.

## Open questions
- None. The remaining acceptance checks exercise operating-system UI or visual behavior that XCTest cannot control reliably.
