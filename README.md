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

Time & Date, Weather, Battery, and Calendar are ready to use. Time & Date and Weather can be customized independently from the desktop, Battery follows the Mac automatically, and Calendar provides native month-browsing controls without requesting access to event data.

## One-time free signing setup

Weather's searchable City control uses an App Intent entity. macOS only restores that entity for a widget extension with a registered development identity; **Sign to Run Locally** produces an ad-hoc signature without one and makes every saved city fall back to Portland.

The required Xcode Personal Team is free and does not enroll you in the $99/year Apple Developer Program:

1. Open **Xcode → Settings → Accounts**, press **+**, and sign in with your Apple Account. The account should expose a team ending in **(Personal Team)**.
2. Select the account, choose **Manage Certificates**, press **+**, and create an **Apple Development** certificate if one is not already listed.
3. From this repository, run `./Scripts/configure-personal-team.sh`. It reads Xcode's signing Team ID from the Apple Development certificate's Team field, rather than the different identifier that may appear in the certificate name. If needed, pass the 10-character Team ID shown by Xcode: `./Scripts/configure-personal-team.sh ABC123DE45`.
4. The helper writes only `Local.xcconfig`, which is ignored by Git. Do not add this file or a literal Team ID to a commit.

Free Personal Team provisioning is intended for personal development and can require periodic rebuilding. App Store, notarized Developer ID, or dependable direct-download distribution still requires the paid program.

## Open and run

1. Open `DesktopWidgets.xcodeproj` in Xcode.
2. Select **My Mac** and run the `DesktopWidgets` scheme once. The app and widget extension use the same free Personal Team from ignored local configuration. The shared Run scheme refreshes the local widget extension and macOS descriptor cache before opening the app, so Xcode cannot leave an older intent schema running beside a newer build.
3. If a Time and Date widget from build 3 or earlier is still on the desktop, remove it once. Build 4 introduced a fresh configuration identity to avoid the broken AppEnum schema cached by macOS 26.5.
4. Remove any earlier Weather widget once before adding the current one. Build 15 replaces the awkward two-row city editor with one searchable **City** field and therefore has a new WidgetKit identity; an existing build-14 Weather instance cannot migrate and appears as a blank system placeholder. If the widget is blank or its editor still shows **Location** or separate **Search City / Matching City** rows, remove that older widget and add Weather again.
5. Remove any Battery widget installed from build 16 or earlier. Build 17 adds per-widget detail toggles under a fresh WidgetKit identity, so the earlier static Battery instance cannot migrate.
6. Control-click the desktop, choose **Edit Widgets**, and add **Time & Date**, **Weather**, **Battery**, or **Calendar**.
7. Control-click a configurable widget and choose **Edit** to change its options. Battery reads this Mac's internal battery automatically and lets each copy toggle Power, Status, Estimate, and Updated details. Calendar uses its visible arrows to browse months; select its month/year title to return to the current month.

The companion app includes a two-step setup guide and a short explanation of every widget. Time & Date uses string-backed dynamic options because macOS 26.5 can save AppEnum selections while still delivering their defaults to a widget timeline. Weather uses one native searchable **City** field: typing at least two letters opens a list of up to 20 city, state, and country-labeled matches, while the selected result's exact coordinates flow into its forecast request. It also uses a string-backed preset menu that applies several details at once. Battery reads local IOKit power-source values, shows macOS's current time estimate when one is available, and proportionally fills its icon to match the reported charge. Each Battery copy can toggle Power, Status, Estimate, and Updated; Small shows no extra rows, Medium caps them at two, and Large allows all four. A connected Mac reports **AC Power** because macOS does not provide an unplugged runtime while it is charging or fully charged. Calendar builds a local six-week month grid, follows the Mac's locale and first-weekday preference, highlights today, and persists a bounded shared month offset for its interactive arrows. The widgets declare clear, removable backgrounds; macOS may still apply its own Liquid Glass or tint treatment.

Weather uses Open-Meteo's keyless API for this personal, noncommercial build, displays the required provider link, and keeps up to 12 recent city/unit forecasts in a small local cache. It declares the same clear, removable background as Time & Date; macOS may still apply system-owned Liquid Glass.

See [Time and Date widget](docs/Time-And-Date-Widget.md), [Weather widget](docs/Weather-Widget.md), [Battery widget](docs/Battery-Widget.md), and [Calendar widget](docs/Calendar-Widget.md) for customization, data-source, privacy, and display notes.

## Verify all widgets before committing

Run the repository's verification gate before committing or pushing:

```sh
./Scripts/verify-widgets.sh
```

The command starts with fresh build artifacts, runs the complete `DesktopWidgetsTests` suite, builds the app and extension in Release mode, and verifies all four widget identities, the three configurable widgets' schemas, and Calendar's three interactive App Intents in the embedded extension. The behavior suite uses presentation contracts shared with the SwiftUI views to cover every Time & Date size/layout/format combination, every Weather size/view/preset combination, Battery parsing, state labels, proportional fill, accessibility, responsive metrics, and refresh scheduling, plus Calendar month boundaries, first-weekday localization, navigation, accessibility, responsive metrics, and midnight scheduling. It also covers Weather loading/stale/failure states, cross-midnight and exhausted-hour fallbacks, Open-Meteo request/response mapping, unit formatting, city errors, and cached fallback data.

This removes the need to manually retest deterministic configuration, layout selection, and data behavior before every commit. Apple still owns desktop placement, the Edit Widget interface and persistence, Liquid Glass rendering, live VoiceOver navigation, and refresh scheduling, so use each widget's short desktop acceptance checklist before a release or after a visual/editor change.

You can still run the tests alone from Xcode with **Product → Test**. Set `KEEP_WIDGET_VERIFY_ARTIFACTS=1` when running the script if you want to inspect its temporary build products after it finishes.

Repository verification builds unsigned artifacts deliberately, so CI and contributors without an Apple Account can still run the complete automated suite. Live searchable-city persistence requires the local Personal Team setup above.
