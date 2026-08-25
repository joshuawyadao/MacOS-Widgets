# Plan

Refine the Battery widget so Small never clips, while Medium and Large use their extra canvas for clear power, estimate, and update details. Keep runtime reporting faithful to macOS: show remaining use only while macOS supplies a discharge estimate, and identify a fully charged connected Mac as using AC power instead of inventing an unplugged runtime.

## Scope
- In: Compact Small-family text and metrics, expanded Medium/Large layouts, power and estimate detail labels, clearer AC-power behavior, presentation contracts, Battery docs, full verification, commit, and push.
- Out: Calculating a custom runtime while connected, battery-health or cycle analytics, external accessory batteries, configuration options, or changes to other widgets.

## Action items
[x] Add a failing Small-family presentation contract for bounded compact status text and a safe horizontal layout budget.
[x] Add family-aware Battery presentation details for power source, estimate availability, and refreshed time without duplicating or fabricating system data.
[x] Refactor `BatteryWidgetView` into compact Small and information-rich Medium/Large layouts with family-specific typography, spacing, and battery sizing.
[x] Replace the ambiguous fully charged primary label with **AC Power**, while retaining **Fully Charged** as a larger-layout detail and discharge estimates when unplugged.
[x] Expand Battery tests across every state and family, including unavailable estimates, compact labels, detail visibility, and accessibility.
[x] Update `docs/Battery-Widget.md` and the root README to document family layouts and why connected Macs cannot show remaining-use hours.
[x] Run the complete widget verification gate, inspect the diff for layout and documentation consistency, and confirm the live AC-power state follows the new contract.
[x] Commit and push the verified refinement to `codex/feature/battery-widget`.

## Open questions
- None.
