# Calendar Widget

The Calendar widget recreates the supplied reference's simple month view: an uppercase month and year between navigation arrows, bold weekday labels, a stable six-row grid, softened dates from adjacent months, and a white circle around today. It declares a clear removable background so the desktop wallpaper remains visually dominant.

## Add and use it

1. Open `DesktopWidgets.xcodeproj`, select **My Mac**, and run the `DesktopWidgets` scheme once.
2. Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and add **Calendar** in Small, Medium, or Large.
3. Select the left or right arrow to move one month backward or forward.
4. Select the month and year title to return directly to the current month.

The widget follows the Mac's current calendar, locale, time zone, and first-weekday preference. English-language Macs therefore show familiar localized weekday labels while regions that start weeks on Monday receive a Monday-first grid. Small uses abbreviated month and weekday text; Medium and Large retain the fuller reference labels.

Month navigation is intentionally capped at ten years in either direction. WidgetKit does not provide a placed-widget instance identifier to these button actions, so the displayed month is shared by all Calendar copies. Moving one copy refreshes every Calendar widget. Other widget types are unaffected.

## Refresh and data behavior

The month grid is generated entirely from Foundation's local calendar APIs. It always contains 42 dates so the header and rows remain visually stable as months begin on different weekdays. Dates outside the displayed month stay visible at lower opacity, and the current day remains circled only when its month is on screen.

WidgetKit requests a new entry at the next local midnight so the today circle and month boundary can advance. Calendar arithmetic uses the local calendar rather than adding a fixed number of seconds, which keeps refreshes correct across daylight-saving transitions. macOS owns actual scheduling and may delay or combine reloads.

## Privacy

The Calendar widget does not request Calendar/EventKit permission, read event titles or accounts, use the network, or send analytics. Its only stored value is a bounded month offset in the widget extension's local preferences so interactive navigation survives a timeline reload.

## Appearance and accessibility

- Full-color mode uses bold rounded white text, a subtle shadow, and a white today circle with a dark numeral to match the reference.
- Adjacent-month dates remain readable at reduced opacity rather than disappearing, preserving the six-week context.
- macOS may add Liquid Glass, tint, or blur even though the widget requests a clear removable background.
- VoiceOver receives the complete localized date for every cell, announces **Today** and selected state for the current date, and labels all three header actions.

## Desktop acceptance checklist

`./Scripts/verify-widgets.sh` covers the exact August 2026 reference grid, Sunday- and Monday-first calendars, leap-month boundaries, six-row stability, localized headings, current-day accessibility, navigation persistence and bounds, DST-safe midnight refresh, responsive metrics, all four widget identities, Calendar App Intent actions, Debug tests, and Release embedding. The remaining macOS-owned checks are:

- [ ] Add Small, Medium, and Large Calendar widgets and confirm every row fits without clipping.
- [ ] Compare the visible month, weekday order, and today circle with the macOS menu-bar calendar.
- [ ] Use both arrows, then select the title and confirm it returns to the current month.
- [ ] Add a second Calendar copy and confirm navigation refreshes both copies consistently.
- [ ] Compare Clear Light, Clear Dark, and Tinted appearances over the intended wallpaper.
- [ ] Use VoiceOver once to confirm the header controls and full dates are announced naturally.
