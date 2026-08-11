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
3. If a Time and Date widget from build 3 or earlier is still on the desktop, remove it once. Build 4 introduced a fresh configuration identity to avoid the broken AppEnum schema cached by macOS 26.5.
4. Control-click the desktop, choose **Edit Widgets**, and add **Time & Date**.
5. Control-click the placed widget and choose **Edit Time & Date**. The editor presents plain-language arrangements, date and clock examples, and separate date and time font menus grouped into clean and handwritten styles.

The companion app includes a two-step setup guide and a short explanation of every customization group. Native editor choices use string-backed dynamic options because macOS 26.5 can save AppEnum selections while still delivering their defaults to a widget timeline. Font choices retain an `Aa` specimen rendered in the selected typeface when the macOS editor displays App Intent option images. The widget declares a clear, removable background; macOS may still apply its own Liquid Glass or tint treatment.

See [Time and Date widget](docs/Time-And-Date-Widget.md) for every customization option and display notes.

## Test the Time and Date configuration

The `DesktopWidgetsTests` scheme covers all date and clock styles, stable dynamic-option IDs and defaults, safe fallback behavior, and independent widget configurations. Run it from Xcode with **Product → Test**, or use:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project DesktopWidgets.xcodeproj -scheme DesktopWidgetsTests -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

The free teamless signing setup intentionally omits Apple's provisioning-profile-only Data Protection entitlement. macOS can therefore replace the widget with an opaque privacy placeholder while the Mac is locked.
