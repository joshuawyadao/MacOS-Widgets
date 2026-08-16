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

The Time and Date and Weather widgets are ready to use and can be customized independently from the desktop. Battery and Calendar remain isolated modules ready for later implementation.

## Open and run

1. Open `DesktopWidgets.xcodeproj` in Xcode.
2. Select **My Mac** and run the `DesktopWidgets` scheme once. The project uses **Sign to Run Locally**, so a paid Apple Developer Program membership or selected development team is not required.
3. If a Time and Date widget from build 3 or earlier is still on the desktop, remove it once. Build 4 introduced a fresh configuration identity to avoid the broken AppEnum schema cached by macOS 26.5.
4. If an earlier Weather widget is still on the desktop, remove it once. Build 8 introduces a fresh searchable-city and size-aware configuration identity.
5. Control-click the desktop, choose **Edit Widgets**, and add **Time & Date** or **Weather**.
6. Control-click a placed widget and choose **Edit**. Time & Date offers arrangements, formats, and separate font menus. Weather offers searchable city suggestions, Week/Day/Hour views, automatic or explicit temperature units, and one clickable detail list capped at 2 choices on Small, 3 on Medium, and 5 on Large.

The companion app includes a two-step setup guide and a short explanation of every customization group. Time & Date uses string-backed dynamic options because macOS 26.5 can save AppEnum selections while still delivering their defaults to a widget timeline. Weather uses searchable App Entities for cities and its size-aware detail list. Font choices retain an `Aa` specimen rendered in the selected typeface when the macOS editor displays App Intent option images. The widgets declare clear, removable backgrounds; macOS may still apply its own Liquid Glass or tint treatment.

Weather uses Open-Meteo's keyless API for this personal, noncommercial build, displays the required provider link, and keeps one recent forecast per city/unit combination in a small local cache. It declares the same clear, removable background as Time & Date; macOS may still apply system-owned Liquid Glass.

See [Time and Date widget](docs/Time-And-Date-Widget.md) and [Weather widget](docs/Weather-Widget.md) for customization, data-source, privacy, and display notes.

## Test widget configuration and weather mapping

The shared `DesktopWidgets` scheme covers date and clock styles, Weather editor defaults, Open-Meteo request/response mapping, unit formatting, city errors, and cached fallback data. Run it from Xcode with **Product → Test**, or use:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project DesktopWidgets.xcodeproj -scheme DesktopWidgets -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

The free teamless signing setup intentionally omits Apple's provisioning-profile-only Data Protection entitlement. macOS can therefore replace the widget with an opaque privacy placeholder while the Mac is locked.
