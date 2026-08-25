# Plan

Build the Battery widget from the supplied reference as a native, configuration-free WidgetKit experience. It will read the Mac's local power-source state, present percentage and contextual runtime text beside a proportionally filled battery icon, and adapt the same visual hierarchy across supported widget sizes.

## Scope
- In: Local macOS battery-state loading, charge-aware runtime/status formatting, proportional battery presentation, Small/Medium/Large layouts, accessibility, bundle/app registration, automated contracts, verification, and Battery documentation.
- Out: Monitoring batteries in external accessories, historical battery analytics, user-selectable styling, notifications, Calendar work, or changes to Weather and Time & Date behavior.

## Action items
[x] Add testable Battery domain models and an IOKit-backed system power-source reader with defensive handling for desktops, missing estimates, charging, charged, and invalid capacity values.
[x] Add a presentation contract that formats percentage/runtime text, clamps the icon fill level, exposes accessibility text, and defines responsive metrics for Small, Medium, and Large families.
[x] Build and register the Battery timeline provider and SwiftUI widget using a clear removable background and a battery outline whose fill tracks the current charge.
[x] Promote Battery to the host app's ready-widget guidance, leave Calendar as upcoming, and update stable identifier and bundle contracts.
[x] Add focused unit coverage for power-source parsing, formatting/status edge cases, responsive presentation, accessibility, and refresh scheduling.
[x] Extend the repository verification gate to assert the Battery widget identity in the built extension and update its three-widget status output.
[x] Replace the Battery scaffold notes with durable implementation/acceptance documentation, add `docs/Battery-Widget.md`, and update the root README.
[x] Run the complete widget verification gate, resolve failures, and re-check the documented desktop-only acceptance risks before saving the branch.

## Open questions
- None.
