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

The companion app uses a native macOS sidebar instead of one long settings page. **Home** provides setup steps and clickable cards for each ready widget; **Appearance** owns the shared typography preview and Apply flow; Time & Date, Weather, Battery, and Calendar each have a focused guidance page; and **Help & Privacy** contains editing help, Calendar permission controls, data-source notes, and troubleshooting. Appearance drafts and Calendar permission state live above navigation so switching pages never discards unfinished theme choices or resets permission feedback.

Time & Date, Weather, Battery, and Calendar are ready to use. Time & Date can add a labeled second time zone; Weather includes comfort, UV, and sun-time presets; Battery can optionally show health and cycle diagnostics; and Calendar can show only the next timed event's start time. Every Calendar copy can use Automatic, Day, Week, or Month; Automatic maps Small to Day, Medium to Week, and Large to Month. Optional event indicators and next-event timing require Calendar permission but never expose event titles, notes, or other event text.

The companion app also controls typography across the complete widget set. Choose **System**, **Modern**, **Editorial**, **Technical**, **Playful**, or **Handmade**, preview the complete appearance locally, then select **Apply Theme** once to save the draft and request one coordinated WidgetKit reload. **Revert** returns the preview to the last applied appearance without touching desktop widgets, and no appearance edit changes the widgets' regular data-refresh schedules. Add a per-widget-type exception only where it helps. **Font Coverage** defaults to **Display Text**, which themes hero values and headers while keeping dense supporting data system-rounded for readability. Choose **All Text** to extend the theme to every textual label and value without changing SF Symbols or information density. Curated themes automatically use small, bounded point-size, horizontal-gap, vertical-spacing, and glyph-padding adjustments so wider or taller letterforms fit the same widget layouts without clipping. Time & Date additionally offers **Use Each Widget's Fonts**, which restores the separate date and time fonts configured on each placed copy and preserves those copies' original layout metrics.

## Friendly personal installation

Weather's searchable City control needs a registered development identity, and shared appearance preferences need the same signed App Group on the app and widget extension. An ad-hoc **Sign to Run Locally** build is not sufficient.

Apple’s current macOS capability table lists App Groups and App Sandbox for no-cost Apple Developer accounts, but this repository does not treat documentation alone as proof that a particular Personal Team works. `Install Desktop Widgets.command` builds with Xcode automatic provisioning and refuses to install unless the app and extension have valid Apple Development signatures from the selected team and contain the complete required sandbox, App Group, Calendar, and extension-network entitlement contract. If Xcode embeds provisioning profiles, they must also grant the expected Team ID and App Group. Xcode 26.6 may validly omit profiles for this macOS entitlement set. See [Personal Team installation](docs/Personal-Team-Installation.md) for the feasibility evidence and remaining signed manual validation.

For a non-developer, start with [Installation Guide.md](Installation%20Guide.md):

1. Install and open full Xcode once.
2. Add an Apple Account in **Xcode → Settings → Accounts**.
3. Double-click **Install Desktop Widgets.command**. It discovers the free Personal Team, writes private ignored settings, builds, installs to `~/Applications/Desktop Widgets.app`, registers the widget, and opens the app. Press Return when it recommends low-resource automatic maintenance.
4. Control-click the desktop, choose **Edit Widgets**, and place the desired widgets. macOS requires user placement; the app cannot arrange the desktop.
5. Automatic maintenance briefly checks at login and once daily. It normally does nothing until the final 48 hours of the profile expiration or a conservative seven-day profile-free signing window, then runs the same guarded refresh at low priority. It has no `KeepAlive` process and successful runs are quiet.
6. If macOS reports that attention is needed, open Xcode to complete any requested sign-in or 2FA step, then double-click **Refresh Desktop Widgets.command**. Repeated runs reuse stable identifiers and the same safe destination.

The installer never requests, prints, or stores an Apple password or authentication token. It writes bounded redacted logs under `~/Library/Logs/Desktop Widgets`, keeps its reusable source under `~/Library/Application Support/Desktop Widgets/Installer`, and uses the existing guarded runtime refresh that never unregisters unrelated extensions. **Enable Automatic Refresh.command** and **Disable Automatic Refresh.command** safely control only Desktop Widgets' own user schedule; the manual refresher always remains available.

Run **Package Desktop Widgets for Another Mac.command** to create a clean handoff ZIP without Git history, build products, local signing settings, certificates, profiles, or logs. A future paid Developer ID/notarization route is documented separately in [Paid distribution path](docs/Paid-Distribution-Path.md); it is not implemented or required here.

Existing Time & Date, Battery, and Calendar widget identities and configurations remain compatible. The Weather build-15 identity still requires replacing only older build-14 Weather copies. Appearance themes, App Intent schemas, per-widget options, and existing placed widgets remain unchanged whenever macOS can preserve them under the stable local bundle identifiers.

The companion app includes setup guidance and a short explanation of every widget. Time & Date uses string-backed dynamic options and can add a per-copy labeled clock from a curated time-zone list. Weather uses one native searchable **City** field and presets spanning temperature, condition, apparent temperature, humidity, precipitation, wind, UV, sunrise, and sunset. Battery reads local IOKit power-source values plus optional AppleSmartBattery capacity and cycle diagnostics; each copy can toggle Power, Status, Estimate, Updated, Health, and Cycles. Calendar follows the Mac's locale and first-weekday preference; its configurable Automatic mode selects a focused Day, seven-column Week, or six-row Month layout by family. Event indicators and next-event timing are off by default. If enabled, EventKit supplies only timing intervals that are normalized into counts and an optional start time; widget models and views never receive event titles, notes, locations, attendees, or calendar names. The widgets declare clear, removable backgrounds; macOS may still apply its own Liquid Glass or tint treatment.

Weather uses Open-Meteo's keyless API for this personal, noncommercial build, displays the required provider link, and keeps up to 12 recent city/unit forecasts in a small local cache. It declares the same clear, removable background as Time & Date; macOS may still apply system-owned Liquid Glass.

See [Time and Date widget](docs/Time-And-Date-Widget.md), [Weather widget](docs/Weather-Widget.md), [Battery widget](docs/Battery-Widget.md), and [Calendar widget](docs/Calendar-Widget.md) for customization, data-source, privacy, and display notes.

All four widgets follow the shared family-density, rendering-mode, state, accessibility, and configuration guidance in [Widget Design System](docs/Widget-Design-System.md). Their data sources and domain-specific controls remain intentionally distinct.

## Verify all widgets before committing

Run the repository's verification gate before committing or pushing:

```sh
./Scripts/verify-widgets.sh
```

The command starts with fresh build artifacts, runs the complete `DesktopWidgetsTests` suite with code coverage, prints a target coverage summary, builds the app and extension in Release mode, and verifies all four widget identities and configurable-widget App Intent schemas in the embedded extension. It also verifies the companion-app destination contract, shared typography App Group metadata, second-clock fields, battery diagnostic toggles, Calendar navigation actions, Calendar event controls, privacy strings, and sandbox entitlements. Typography coverage checks theme and coverage persistence, bounded layout compensation, safe fallbacks, override resolution, and all six themes rendered through every widget in both coverage modes and all three families. Widget-specific coverage includes secondary-zone formatting, expanded weather decoding, battery diagnostic normalization and unavailable fallbacks, and Calendar next-event privacy and selection behavior. Representative render smoke tests exercise the new options and important edge states without storing brittle pixel-perfect golden images.

This removes the need to manually retest deterministic configuration, layout selection, data behavior, and basic SwiftUI rendering before every commit. Apple still owns desktop placement, the Edit Widget interface and persistence, Liquid Glass rendering, live VoiceOver navigation, and actual refresh timing, so use each widget's short desktop acceptance checklist before a release or after a visual/editor change. The shared Xcode scheme and CI job also collect coverage; coverage remains a diagnostic signal rather than a blanket percentage gate.

You can still run the tests alone from Xcode with **Product → Test**. Set `KEEP_WIDGET_VERIFY_ARTIFACTS=1` when running the script if you want to inspect its temporary build products after it finishes.

Repository verification builds unsigned artifacts deliberately, so CI and contributors without an Apple Account can still run the complete automated suite. Live searchable-city persistence requires the local Personal Team setup above.
