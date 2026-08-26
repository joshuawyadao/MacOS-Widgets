# Calendar Widget

The Calendar widget adapts its content to the available space while retaining the supplied reference's bold, wallpaper-forward styling. In **Automatic** mode, Small shows a focused day, Medium shows the current week, and Large shows a full six-row month grid.

## Add and configure it

1. Open `DesktopWidgets.xcodeproj`, select **My Mac**, and run the `DesktopWidgets` scheme once.
2. Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and add **Calendar** in Small, Medium, or Large.
3. Control-click the placed widget and choose **Edit “Calendar”**.
4. Leave **View** set to **Automatic**, or choose **Day**, **Week**, or **Month** for that widget copy.
5. Turn on **Show Event Indicators** if you want event counts and dots.

Build 19 gives the configurable Calendar a fresh WidgetKit identity. If a Calendar from build 18 is still on the desktop, remove it once and add Calendar again so macOS creates the new configurable version.

## Views by size

- **Small · Day:** a large weekday and date with an optional event count.
- **Medium · Week:** seven day columns with today highlighted and optional event dots.
- **Large · Month:** the reference-style month grid with today circled, adjacent-month dates softened, optional event dots, and interactive month navigation.

An explicit Day, Week, or Month selection overrides the automatic family mapping. Layout metrics continue to adapt to the physical widget size, so every view remains available in every supported family. Large Week also has room to show event counts beneath its indicators.

The widget follows the Mac's current calendar, locale, time zone, and first-weekday preference. The month grid always contains 42 dates so its header and rows remain stable.

## Event indicators and permission

Event indicators are off by default. To enable them:

1. Open the **Desktop Widgets** app.
2. In **Calendar event indicators**, select **Enable Access**.
3. Approve Calendar access in the macOS prompt.
4. Edit a Calendar widget and turn on **Show Event Indicators**.

If access was denied, the app provides an **Open Settings** button. A widget configured to show indicators displays a compact permission signifier until access is available.

The extension queries only the bounded interval needed by the current view. It immediately reduces matching events to a count for each date; event titles, notes, locations, attendees, URLs, calendar names, and account details are never placed in the widget timeline or displayed. Data stays on the Mac and no network or analytics service is used.

## Navigation and refresh behavior

Only Month view includes navigation arrows. Select the left or right arrow to move one month, or select the month and year to return to the current month. Day and Week stay anchored to today so their compact layouts remain predictable.

Month navigation is capped at ten years in either direction. WidgetKit does not provide a placed-widget instance identifier to these button actions, so the displayed month is shared by all Calendar copies. Moving one Month copy refreshes every Calendar widget; its chosen view and event-indicator setting remain independent.

Without event indicators, the next timeline refresh is requested for the next local midnight. With indicators enabled, the widget requests a refresh every 30 minutes so event changes can appear while still using a bounded query. Local calendar arithmetic keeps the midnight transition correct across daylight-saving changes; macOS owns actual scheduling and may delay or combine reloads.

## Appearance and accessibility

- Full-color mode uses bold rounded white text, subtle shadows, and a white today treatment matching the reference.
- Event dots use a compact, non-textual signifier; VoiceOver announces the event count for the date.
- Adjacent-month dates remain readable at reduced opacity in Month view.
- macOS may add Liquid Glass, tint, or blur even though the widget requests a clear removable background.
- VoiceOver receives localized dates, today state, event counts, permission state, and labels for Month navigation actions.

## Desktop acceptance checklist

`./Scripts/verify-widgets.sh` covers automatic and explicit view selection, event-count normalization, the August 2026 reference grid, Sunday- and Monday-first calendars, leap-month boundaries, DST-safe refreshes, responsive metrics, App Intent metadata, Calendar privacy configuration, Debug tests, and Release embedding. The remaining macOS-owned checks are:

- [ ] Remove any build-18 Calendar, then add Small, Medium, and Large Calendar widgets.
- [ ] Confirm Automatic shows Day, Week, and Month respectively without clipping.
- [ ] Edit each copy, select every explicit view, and confirm the choice persists after reopening Edit Widget.
- [ ] Confirm indicators are absent by default and the permission signifier appears when enabled without access.
- [ ] Grant access in the app, add events on today and another visible day, and confirm counts/dots update without revealing event text.
- [ ] Deny or revoke access and confirm the app offers Settings while the widget remains usable.
- [ ] In Month view, use both arrows and the title, then confirm navigation refreshes all Calendar copies consistently.
- [ ] Compare Clear Light, Clear Dark, and Tinted appearances over the intended wallpaper.
- [ ] Use VoiceOver to confirm dates, today state, event counts, permission state, and Month controls are announced naturally.
