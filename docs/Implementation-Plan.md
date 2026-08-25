# Plan

Address the actionable GitHub Codex feedback on PR #4 with isolated fixes: prevent stale Weather data from crossing between same-named coordinates and preserve the verification script’s explicit Xcode prerequisite failure.

## Scope
- In: Coordinate-stable Weather cache identity, collision regression coverage, developer-directory initialization, shell failure checks, implementation-plan tracking, validation, separate commits, and review-comment reactions.
- Out: The verified Open-Meteo current precipitation request, widget layouts, configuration UI, provider selection, or unrelated refactoring.

## Action items
[x] Add a regression proving two locations with identical display labels but different coordinates cannot share cached forecasts.
[x] Give `WeatherLocation` a stable coordinate-aware cache identity and use it in `WeatherLoader`.
[ ] Run the focused Weather cache tests, full verification, commit the P2 fix, push it, and acknowledge the Codex comment.
[ ] Add a shell regression for a failed developer-directory resolution and separate assignment from readonly declaration.
[ ] Run shell and full verification, commit the P3 fix separately, push it, and acknowledge the Codex comment.
[ ] Re-read review threads, CI, and mergeability; record the live Open-Meteo evidence for skipping the non-actionable P1 comment.

## Open questions
- None.
