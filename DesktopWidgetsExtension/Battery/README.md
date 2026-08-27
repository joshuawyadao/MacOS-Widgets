# Battery Widget

This module contains the local IOKit power-source and AppleSmartBattery diagnostic reader, normalized Battery model, App Intent configuration, presentation contract, timeline provider, and SwiftUI widget.

The Battery widget follows the Mac's internal battery automatically and never reads external accessory batteries. Each instance can toggle Power, Status, Estimate, Updated, Health, and Cycles; diagnostic toggles default off and unavailable values are explicit. The presentation contract caps visible extras at zero on Small, two on Medium, and six on Large. See `docs/Battery-Widget.md` for runtime behavior, privacy notes, verification, and the desktop acceptance checklist.
