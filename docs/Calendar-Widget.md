# Calendar Widget

The Calendar widget adapts its content to the available space while retaining the supplied reference's bold, wallpaper-forward styling. In **Automatic** mode, Small shows a focused day, Medium shows the current week, and Large shows a full six-row month grid.

## Add and configure it

1. Open `DesktopWidgets.xcodeproj`, select **My Mac**, and run the `DesktopWidgets` scheme once.
2. Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and add **Calendar** in Small, Medium, or Large.
3. Control-click the placed widget and choose **Edit “Calendar”**.
4. Leave **View** set to **Automatic**, or choose **Day**, **Week**, or **Month** for that widget copy.
5. Turn on **Show Event Indicators** for counts and dots, **Show Next Event Time** for a title-free start time, or both.

The next-event field preserves Calendar's established WidgetKit identity and defaults to Off, so existing copies and macOS's cached gallery previews remain compatible.

## Views by size

- **Small · Day:** a large weekday and date with an optional event count.
- **Medium · Week:** seven day columns with today highlighted and optional event dots.
- **Large · Month:** the reference-style month grid with today circled, adjacent-month dates softened, optional event dots, and interactive month navigation.

An explicit Day, Week, or Month selection overrides the automatic family mapping. Layout metrics continue to adapt to the physical widget size, so every view remains available in every supported family. Large Week also has room to show event counts beneath its indicators.

The widget follows the Mac's current calendar, locale, time zone, and first-weekday preference. The month grid always contains 42 dates so its header and rows remain stable.

## Event indicators, next-event timing, and permission

Event indicators and next-event timing are off by default. To enable either:

1. Open the **Desktop Widgets** app.
2. In **Calendar event indicators**, select **Enable Access**.
3. Approve Calendar access in the macOS prompt.
4. Edit a Calendar widget and turn on **Show Event Indicators**, **Show Next Event Time**, or both.

If access was denied, the app provides an **Open Settings** button. A widget configured to show indicators displays a compact permission signifier until access is available.

The extension queries only the bounded interval needed by the current view plus, when requested, a seven-day upcoming window. It immediately reduces matching events to per-date counts and the start time of the first ongoing or upcoming timed event. All-day events are skipped for the next-event line. Event titles, notes, locations, attendees, URLs, calendar names, and account details are never placed in the widget timeline or displayed. Data stays on the Mac and no network or analytics service is used.

The next-event line appears in Day at every size, in Week on Medium and Large, and in Month on Large. Tighter combinations omit the line rather than shrinking the calendar below its readability budget. It says **Happening now**, a localized start time, **No timed events soon**, or an access status—never the event name.

## Navigation and refresh behavior

Only Month view includes navigation arrows. Select the left or right arrow to move one month, or select the month and year to return to the current month. Day and Week stay anchored to today so their compact layouts remain predictable.

Month navigation is capped at ten years in either direction. WidgetKit does not provide a placed-widget instance identifier to these button actions, so the displayed month is shared by all Calendar copies. Moving one Month copy refreshes every Calendar widget; its chosen view and event-indicator setting remain independent.

Without event features, the next timeline refresh is requested for the next local midnight. With indicators or next-event timing enabled, the widget requests a refresh every 30 minutes so event changes can appear while still using bounded queries. Local calendar arithmetic keeps the midnight transition correct across daylight-saving changes; macOS owns actual scheduling and may delay or combine reloads.

## Appearance and accessibility

- Calendar uses the shared compact/standard/expanded family density, widget surface, and action-required badge treatment. Its today marker and Month navigation remain calendar-specific.
- The companion app's global or Calendar-specific typography theme styles the primary day number and Day, Week, or Month headers in Display Text mode. All Text extends it to weekday labels, grid numerals, event counts, and permission status; Display Text remains the safer choice for dense Month layouts.
- Full-color mode uses bold rounded white text, subtle shadows, and a composited white today circle with a dark numeral. Vibrant and accented modes use an outlined today circle so system color remapping cannot erase the numeral.
- Event dots occupy a separate marker layer and never replace the date numeral, including inside today's selection marker; VoiceOver announces the event count for the date.
- Adjacent-month dates remain readable at reduced opacity in Month view.
- macOS may add Liquid Glass, tint, or blur even though the widget requests a clear removable background.
- VoiceOver receives localized dates, today state, optional event counts, title-free next-event timing, permission state, and labels for Month navigation actions.

## Desktop acceptance checklist

`./Scripts/verify-widgets.sh` covers automatic and explicit view selection, event-count normalization, upcoming and ongoing timed-event selection, all-day and ended-event filtering, independent feature toggles, the August 2026 reference grid, calendar boundaries, DST-safe refreshes, responsive metrics, App Intent metadata, Calendar privacy configuration, rendering, and Release embedding. The remaining macOS-owned checks are:

- [ ] Keep an existing Calendar in place, then add Small, Medium, and Large Calendar widgets and confirm both old and new copies render.
- [ ] Confirm Automatic shows Day, Week, and Month respectively without clipping.
- [ ] Edit each copy, select every explicit view, and confirm the choice persists after reopening Edit Widget.
- [ ] Confirm indicators are absent by default and the permission signifier appears when enabled without access.
- [ ] Grant access in the app, add events on today and another visible day, and confirm counts/dots update without revealing event text.
- [ ] Enable only Next Event Time, confirm no count or dot leaks into the widget, and confirm the line reveals only a localized time or Happening now.
- [ ] Confirm today's numeral remains clearly visible alongside its event dots in both Week and Month views across Full Color, Vibrant, and Accented appearances.
- [ ] Deny or revoke access and confirm the app offers Settings while the widget remains usable.
- [ ] In Month view, use both arrows and the title, then confirm navigation refreshes all Calendar copies consistently.
- [ ] Compare Clear Light, Clear Dark, and Tinted appearances over the intended wallpaper.
- [ ] Change the global theme and Calendar override in the companion app, then confirm Day, Week, and Month headers update while grid dates stay readable.
- [ ] Use VoiceOver to confirm dates, today state, event counts, permission state, and Month controls are announced naturally.
