# Plan

Prevent macOS from keeping a placed widget attached to an older development extension when the same bundle is built from multiple Xcode worktrees. Make the Run refresh script unregister only stale DerivedData copies before registering the current extension, lock the behavior down with an isolated shell regression test, and preserve installed/non-development copies.

## Scope
- In: Duplicate extension discovery by bundle identifier, safe DerivedData path filtering, stale-registration removal, injectable command seams for testing, verification integration, runtime documentation, commit, and push.
- Out: Deleting DerivedData or app bundles, removing placed widgets or their configuration, unregistering installed copies outside DerivedData, changing widget identities, and changing production runtime behavior.

## Action items
[x] Refactor `Scripts/refresh-widget-runtime.sh` to discover registrations for the current extension bundle identifier and unregister stale copies under the configured DerivedData root.
[x] Preserve the current extension registration and ignore matching bundle registrations outside DerivedData before registering the current bundle and restarting its runtime.
[x] Add an isolated shell regression test with fake PluginKit/process commands covering current, stale-development, and external registration paths.
[x] Run the regression test from `Scripts/verify-widgets.sh` and retain the existing script syntax and Xcode Run-action checks.
[x] Update `README.md` and `docs/Weather-Widget.md` to describe automatic duplicate development-registration cleanup and its non-destructive limits.
[x] Run targeted shell checks and the complete `./Scripts/verify-widgets.sh` gate, review the final diff, then commit and push the scoped fix.

## Open questions
- None.
