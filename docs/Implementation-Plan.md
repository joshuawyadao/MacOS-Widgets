# Plan

Replace the Time and Date widget's AppEnum-backed configuration transport with string-backed dynamic options so macOS 26.5 can deliver the user's selections to the timeline provider. Preserve the existing native editor choices, font specimen images, internal type-safe rendering, per-widget customization, and documented appearance behavior.

## Scope
- In: String-backed DynamicOptionsProvider choices for layout, date format, time format, date font, and time font; safe conversion to internal enums; a fresh widget schema identity/build; documentation; build and metadata validation; commit; and push.
- Out: A companion settings app, shared preference storage, legacy SiriKit intents, changes to the visual design, and workarounds for macOS-owned glass or tint rendering.

## Action items
- [x] Confirm the current App Intent schema, generated metadata, and cached timeline evidence for the AppEnum default-value regression.
- [x] Refactor the configuration catalogs into internal CaseIterable enums with stable raw identifiers and display metadata.
- [x] Add concrete DynamicOptionsProvider implementations that expose labeled string choices and reuse the existing font specimen images.
- [x] Change all five intent parameters to string-backed options with safe typed fallbacks and preview defaults.
- [x] Update the widget view and configuration identity to consume the resolved selections without changing its visual layouts.
- [x] Update the Time and Date documentation with the transport workaround, migration instructions, and native editor limitations.
- [x] Build the macOS app, inspect generated App Intent metadata, and verify every option provider and fallback mapping is represented correctly.
- [x] Inspect the final diff, commit the implementation plan and workaround, and push `feature/time-and-date-widget`.

## Open questions
- None. Use stable existing raw values so the workaround changes only the App Intents transport layer.
