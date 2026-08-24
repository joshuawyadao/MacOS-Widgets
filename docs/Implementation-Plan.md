# Plan

Fix the build-15 Weather placeholder by reproducing the installed extension/default-intent mismatch, isolating whether the stale process, cached descriptor, build product, or new entity transport causes it, and making the smallest durable change that keeps Xcode development reliable.

## Scope
- In: Installed Weather extension diagnostics, the Xcode run/reload workflow, App Intent compatibility, regression coverage, verification guidance, and the Weather development documentation.
- Out: Forecast layout redesign, unrelated widget features, or destructive macOS widget-store resets.

## Action items
[x] Capture a fast red runtime check showing that chronod receives the retired V7 Weather descriptor while build 15 only contains V8 metadata.
[x] Restart only the Weather extension and compare the newly loaded descriptor/intent to distinguish a stale process from persistent metadata or entity failures.
[x] Inspect the current Debug app's embedded binary and metadata identities to rule out a mismatched incremental build product.
[x] Implement the smallest durable fix for the confirmed cause and add a regression check at the closest reliable seam.
[x] Update the Weather setup/verification documentation with any required Xcode development step.
[x] Run the complete widget verification suite and rerun the installed-runtime feedback loop.
[x] Commit and push the verified fix to the current Weather feature branch.

## Open questions
- None.
