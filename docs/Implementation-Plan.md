# Plan

Restore the stable Time & Date, Battery, and Calendar WidgetKit kinds so macOS's cached gallery descriptors and existing placements continue to resolve, while retaining all newly added optional configuration fields and widget-specific features. Lock the identity compatibility rule into tests, metadata verification, runtime guidance, and documentation.

## Scope
- In: Revert the three unintended `v3` kind changes to their established `v2` values, preserve new intent parameters and defaults, add regression coverage, update migration guidance, rebuild/register, and verify the live descriptor mismatch is gone.
- Out: New widget kinds, duplicate legacy aliases, editing macOS's private widget database, removing user widgets, or changing Weather's existing identity.

## Action items
[x] Add a failing identity regression that requires Time & Date, Battery, and Calendar to retain their established `v2` kinds while their new optional parameters remain exported.
[x] Restore the three stable identifiers in `Shared/Models/WidgetIdentifier.swift` and align embedded-extension verification.
[x] Verify old serialized configurations remain safe through documented defaults for the new secondary-clock, battery-diagnostic, and next-event parameters.
[x] Remove one-time re-add instructions from the app and widget documentation and explain that optional editor additions preserve placed-widget compatibility.
[x] Run targeted identity/configuration tests, the complete `Scripts/verify-widgets.sh` release gate, and a signed Debug build/runtime refresh.
[x] Re-run the live kind-mismatch assertion against the registered extension, clean up diagnostic artifacts, then commit and push the fix.

## Open questions
- None.
