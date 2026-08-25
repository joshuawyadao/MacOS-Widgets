# Battery Widget

The Battery widget follows the supplied reference's compact hierarchy: a bold percentage and macOS runtime estimate sit beside a simple white battery outline. The icon fills vertically in proportion to the Mac's reported charge, and the widget declares a clear removable background so the desktop wallpaper remains visually dominant.

## Add it

1. Open `DesktopWidgets.xcodeproj`, select **My Mac**, and run the `DesktopWidgets` scheme once.
2. Remove any Battery widget installed from build 16 or earlier. Build 17 adds per-widget detail controls under a fresh WidgetKit identity, so the older static instance cannot migrate.
3. Control-click the desktop, choose **Edit Widgets**, and search for **Desktop Widgets**.
4. Add **Battery** in Small, Medium, or Large.
5. Control-click the placed widget, choose **Edit Battery**, and toggle any of these extra details:

| Detail | Value |
| --- | --- |
| Power Source | Battery or AC Power |
| Charging Status | Discharging, Charging, Fully Charged, or Not Charging |
| Time Estimate | Remaining use or time to full when macOS supplies it |
| Last Updated | Time of the latest WidgetKit battery reading |

Every instance follows the same internal battery but keeps its own detail toggles. Small preserves the compact reference composition and shows no extra rows. Medium shows at most two enabled details, prioritizing Status and Updated by default. Large shows up to all four enabled details in its card grid. If a preferred detail is disabled, the next enabled detail fills the available slot; disabling every detail collapses the extra section entirely.

## Display behavior

- The bold value is the current charge rounded to a whole percentage.
- The inner battery fill uses the same normalized percentage and is clamped between empty and full.
- While discharging, the secondary label shows macOS's time-to-empty estimate, such as `6.1 h` or `45 min`.
- While charging, it shows the estimated time to full when available; otherwise it says **Charging**.
- A connected battery says **AC Power** in the primary status. Medium and Large separately identify whether it is **Charging**, **Fully Charged**, or **Not Charging**.
- Medium and Large show only the enabled details that fit their size budget. The estimate distinguishes remaining runtime from time to full and explicitly says when an estimate is unavailable on AC power.
- macOS can temporarily report no usable estimate after a power-state or workload change. The widget says **Calculating** rather than deriving an unreliable duration from recent percentage changes.
- A Mac with no internal battery says **No Battery** and displays a crossed empty outline.

WidgetKit requests a new system reading after five minutes. macOS owns actual refresh scheduling and can delay or combine reloads, so the widget is a periodic status view rather than a second-by-second battery meter.

## Data source and privacy

The extension reads the internal power source through Apple's local IOKit power-source API. It normalizes current and maximum capacity, charge state, time to empty, and time to full into a small in-memory snapshot. It does not request a permission, use the network, store battery history, identify the device, or inspect Bluetooth and other accessory batteries.

The time value is an operating-system estimate based on current conditions. Workload, display brightness, charging behavior, temperature, and recent power changes can make it fluctuate or disappear temporarily. When the charger is connected, macOS normally reports time to empty as zero because the Mac is not discharging; the widget does not fabricate an unplugged runtime from that state.

## Appearance and accessibility

- Full-color mode uses white rounded text and a white battery outline/fill, with a small shadow for contrast over textured wallpaper.
- Tinted and accented widget modes use the system's primary rendering color.
- The battery graphic is decorative. VoiceOver receives one combined label containing charge percentage, power state, and a spoken duration when available.
- macOS may place Liquid Glass, tint, or blur behind widgets even though this widget requests a clear removable container background.

## Desktop acceptance checklist

`./Scripts/verify-widgets.sh` covers configuration defaults and independent toggles, zero/two/four-detail family budgets, empty and partial selections, battery dictionary parsing, invalid and non-battery inputs, charge clamping, all power-state and detail labels, duration and update-time formatting, accessibility labels, the Small clipping budget, five-minute refresh policy, App Intent metadata, Release compilation, embedding, and widget identity. The remaining macOS-owned checks are:

- [ ] Add Small, Medium, and Large Battery widgets and confirm Small shows no extras, Medium shows at most two readable rows, and Large shows up to four cards.
- [ ] Toggle different detail combinations on two Battery instances, reopen both editors, and confirm each copy preserves its own choices.
- [ ] Compare the displayed percentage and charging state with the macOS menu bar.
- [ ] Unplug and reconnect power, then confirm the label and fill update after WidgetKit refreshes the timeline.
- [ ] Confirm an unplugged runtime is formatted as hours or minutes, while a fully charged connected Mac says **AC Power** and marks its runtime estimate unavailable.
- [ ] Compare Clear Light, Clear Dark, and Tinted appearances over the intended wallpaper.
- [ ] Use VoiceOver once to confirm the combined percentage, state, and duration are announced naturally.
