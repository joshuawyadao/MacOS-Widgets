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

The project currently includes a neutral Time and Date widget foundation. Weather, Battery,
and Calendar remain isolated modules ready for later implementation.

## Open and run

1. Open `DesktopWidgets.xcodeproj` in Xcode.
2. Select the `DesktopWidgets` target and choose an Apple development team under Signing & Capabilities.
3. Select **My Mac** and run the app once.
4. Control-click the desktop, choose **Edit Widgets**, and add **Time and Date**.
