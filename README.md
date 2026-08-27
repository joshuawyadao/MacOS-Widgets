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

Time & Date, Weather, Battery, and Calendar are ready to use. Every Calendar copy can use Automatic, Day, Week, or Month; Automatic maps Small to Day, Medium to Week, and Large to Month. Optional event indicators require Calendar permission but expose counts and dots only, never event titles or notes.

The companion app also controls typography across the complete widget set. Choose **System**, **Modern**, **Editorial**, **Technical**, **Playful**, or **Handmade** once, preview the result for all four widgets, then add a per-widget-type exception only where it helps. **Font Coverage** defaults to **Display Text**, which themes hero values and headers while keeping dense supporting data system-rounded for readability. Choose **All Text** to extend the theme to every textual label and value without changing SF Symbols or information density. Curated themes automatically use small, bounded point-size, horizontal-gap, vertical-spacing, and glyph-padding adjustments so wider or taller letterforms fit the same widget layouts without clipping. Time & Date additionally offers **Use Each Widget's Fonts**, which restores the separate date and time fonts configured on each placed copy and preserves those copies' original layout metrics.

## One-time free signing setup

Weather's searchable City control uses an App Intent entity. macOS only restores that entity for a widget extension with a registered development identity; **Sign to Run Locally** produces an ad-hoc signature without one and makes every saved city fall back to Portland. Shared typography preferences also use a team-ID-prefixed macOS App Group so the companion app and widget extension read the same setting.

The required Xcode Personal Team is free and does not enroll you in the $99/year Apple Developer Program:

1. Open **Xcode → Settings → Accounts**, press **+**, and sign in with your Apple Account. The account should expose a team ending in **(Personal Team)**.
2. Select the account, choose **Manage Certificates**, press **+**, and create an **Apple Development** certificate if one is not already listed.
3. From this repository, run `./Scripts/configure-personal-team.sh`. It reads Xcode's signing Team ID from the Apple Development certificate's Team field, rather than the different identifier that may appear in the certificate name. If needed, pass the 10-character Team ID shown by Xcode: `./Scripts/configure-personal-team.sh ABC123DE45`.
4. The helper writes only `Local.xcconfig`, which is ignored by Git. Do not add this file or a literal Team ID to a commit.

Free Personal Team provisioning is intended for personal development and can require periodic rebuilding. App Store, notarized Developer ID, or dependable direct-download distribution still requires the paid program.

## Open and run

1. Open `DesktopWidgets.xcodeproj` in Xcode.
2. Select **My Mac** and run the `DesktopWidgets` scheme once. The app and widget extension use the same free Personal Team from ignored local configuration. The shared Run scheme unregisters stale copies of this extension from other Xcode DerivedData/worktree builds, registers the current extension, and refreshes the macOS widget runtime before opening the app. It never deletes a build, placed widget, or saved configuration, and it leaves matching installed copies outside DerivedData registered.
3. If a Time and Date widget from build 3 or earlier is still on the desktop, remove it once. Build 4 introduced a fresh configuration identity to avoid the broken AppEnum schema cached by macOS 26.5.
4. Remove any earlier Weather widget once before adding the current one. Build 15 replaces the awkward two-row city editor with one searchable **City** field and therefore has a new WidgetKit identity; an existing build-14 Weather instance cannot migrate and appears as a blank system placeholder. If the widget is blank or its editor still shows **Location** or separate **Search City / Matching City** rows, remove that older widget and add Weather again.
5. Remove any Battery widget installed from build 16 or earlier. Build 17 adds per-widget detail toggles under a fresh WidgetKit identity, so the earlier static Battery instance cannot migrate.
6. Remove any Calendar widget installed from build 18. Build 19 adds per-widget Day/Week/Month and event-indicator controls under a fresh WidgetKit identity, so the earlier static Calendar instance cannot migrate.
7. Control-click the desktop, choose **Edit Widgets**, and add **Time & Date**, **Weather**, **Battery**, or **Calendar**.
8. Control-click a configurable widget and choose **Edit** to change its options. Calendar defaults to a size-appropriate view; Month keeps its navigation arrows. To use event indicators, enable Calendar access in the companion app and turn on **Show Event Indicators** for the desired widget copies.
9. In the companion app, choose an **Appearance theme** for the whole set. Use **Widget overrides** for exceptions; changes ask WidgetKit to reload every timeline automatically.

The companion app includes setup guidance and a short explanation of every widget. Time & Date uses string-backed dynamic options because macOS 26.5 can save AppEnum selections while still delivering their defaults to a widget timeline. Weather uses one native searchable **City** field and a preset menu. Battery reads local IOKit power-source values and lets each copy toggle Power, Status, Estimate, and Updated details. Calendar follows the Mac's locale and first-weekday preference; its configurable Automatic mode selects a focused Day, seven-column Week, or six-row Month layout by family. Event indicators are off by default. If enabled, EventKit supplies only timing intervals that are normalized into per-day counts; widget models and views never receive event titles, notes, locations, attendees, or calendar names. The widgets declare clear, removable backgrounds; macOS may still apply its own Liquid Glass or tint treatment.

Weather uses Open-Meteo's keyless API for this personal, noncommercial build, displays the required provider link, and keeps up to 12 recent city/unit forecasts in a small local cache. It declares the same clear, removable background as Time & Date; macOS may still apply system-owned Liquid Glass.

See [Time and Date widget](docs/Time-And-Date-Widget.md), [Weather widget](docs/Weather-Widget.md), [Battery widget](docs/Battery-Widget.md), and [Calendar widget](docs/Calendar-Widget.md) for customization, data-source, privacy, and display notes.

All four widgets follow the shared family-density, rendering-mode, state, accessibility, and configuration guidance in [Widget Design System](docs/Widget-Design-System.md). Their data sources and domain-specific controls remain intentionally distinct.

## Verify all widgets before committing

Run the repository's verification gate before committing or pushing:

```sh
./Scripts/verify-widgets.sh
```

The command starts with fresh build artifacts, runs the complete `DesktopWidgetsTests` suite with code coverage, prints a target coverage summary, builds the app and extension in Release mode, and verifies all four widget identities and configurable-widget App Intent schemas in the embedded extension. It also verifies the shared typography App Group metadata, Calendar navigation actions, Calendar View and event-indicator parameters, privacy strings, and sandbox entitlements. Typography coverage checks theme and coverage persistence, bounded layout compensation, safe fallbacks, override resolution, and all six themes rendered through every widget in both coverage modes and all three families. Calendar coverage includes Automatic and explicit family resolution, Day/Week/Month contracts, event overlap counting, permission states, month boundaries, first-weekday localization, navigation, accessibility, responsive budgets, rendering modes, and adaptive refresh scheduling. The existing suites retain their Time & Date, Weather, and Battery behavior coverage, while representative render smoke tests exercise important edge states without storing brittle pixel-perfect golden images.

This removes the need to manually retest deterministic configuration, layout selection, data behavior, and basic SwiftUI rendering before every commit. Apple still owns desktop placement, the Edit Widget interface and persistence, Liquid Glass rendering, live VoiceOver navigation, and actual refresh timing, so use each widget's short desktop acceptance checklist before a release or after a visual/editor change. The shared Xcode scheme and CI job also collect coverage; coverage remains a diagnostic signal rather than a blanket percentage gate.

You can still run the tests alone from Xcode with **Product → Test**. Set `KEEP_WIDGET_VERIFY_ARTIFACTS=1` when running the script if you want to inspect its temporary build products after it finishes.

Repository verification builds unsigned artifacts deliberately, so CI and contributors without an Apple Account can still run the complete automated suite. Live searchable-city persistence requires the local Personal Team setup above.
