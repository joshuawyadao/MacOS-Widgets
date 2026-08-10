# macOS Widgets

One macOS app and WidgetKit extension containing four independently organized widgets:

- Weather
- Time and Date
- Battery
- Calendar

## Project layout

- `DesktopWidgetsApp` contains the host app, onboarding, settings, and permission flows.
- `DesktopWidgetsExtension` contains the WidgetKit bundle and each widget module.
- `Shared` contains models, styling, and utilities compiled into both targets.

The Time and Date widget is ready to use and can be customized from the desktop. Weather,
Battery, and Calendar remain isolated modules ready for later implementation.

## Open and run

1. Open `DesktopWidgets.xcodeproj` in Xcode.
2. Select **My Mac** and run the `DesktopWidgets` scheme once. The project uses **Sign to Run Locally**, so a paid Apple Developer Program membership or selected development team is not required.
3. If an earlier Time and Date widget is already on the desktop, remove it once. Build 4 uses a fresh configuration identity to avoid the broken AppEnum schema cached by macOS 26.5.
4. Control-click the desktop, choose **Edit Widgets**, and add **Time and Date (Custom)**.
5. Control-click the placed widget and choose **Edit Time and Date** to select its layout, date format, time format, date font, and time font.

The native editor choices use string-backed dynamic options because macOS 26.5 can save AppEnum selections while still delivering their defaults to a widget timeline. Font choices retain an `Aa` specimen rendered in the selected typeface when the macOS editor displays App Intent option images. The widget declares a clear, removable background; macOS may still apply its own glass or tint treatment in some system appearance modes.

See [Time and Date widget](docs/Time-And-Date-Widget.md) for every customization option and display notes.
