# Battery Widget

This module contains the local IOKit power-source reader, normalized Battery model, App Intent configuration, presentation contract, timeline provider, and SwiftUI widget.

The Battery widget follows the Mac's internal battery automatically and never reads external accessory batteries. Each instance can toggle Power, Status, Estimate, and Updated details; the presentation contract caps visible extras at zero on Small, two on Medium, and four on Large. See `docs/Battery-Widget.md` for runtime behavior, privacy notes, verification, and the desktop acceptance checklist.
