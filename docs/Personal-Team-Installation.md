# Personal Team installation

## Feasibility result

Desktop Widgets requires a signed macOS host app and WidgetKit extension with:

- App Sandbox on both targets;
- the same `com.apple.security.application-groups` entitlement on both targets;
- outgoing network access on the widget extension for Weather; and
- Calendar sandbox access on both targets for optional private event timing.

Apple’s current [Supported capabilities (macOS)](https://developer.apple.com/help/account/reference/supported-capabilities-macos) table marks **App groups** and **App Sandbox** as available in the no-cost **Apple Developer** column. The network and Calendar keys used here are sandbox resource entitlements, not paid Apple services. Apple’s [developer account overview](https://developer.apple.com/help/account/basics/about-your-developer-account) says a free Personal Team can install personal test builds but its App IDs, device registrations, and provisioning profiles expire after 7 days.

That documentation makes the complete feature set eligible for free macOS development provisioning. It is not, by itself, proof that a particular account and Xcode version produced a valid build. The installer therefore treats the Xcode build as the authority and refuses to install unless all of these checks succeed:

1. automatic signing finishes with `-allowProvisioningUpdates`;
2. `codesign --verify --deep --strict` succeeds;
3. the app and embedded widget report the selected Team ID;
4. both signed products contain the exact generated App Group entitlement; and
5. both products contain a readable embedded provisioning profile.

If Xcode reports that App Groups are unavailable to the Personal Team, installation stops. The capability, sandbox, shared preferences, and security model are never silently removed.

## What remains to validate manually

The development Mac used for this implementation has Xcode 26.6 installed and initialized, but no valid Apple Development signing identity was available. Automated tests and unsigned app/extension builds can run here; a signed Personal Team end-to-end check still requires the account owner to:

1. add their Apple Account to Xcode and expose a **(Personal Team)**;
2. run `Install Desktop Widgets.command`;
3. confirm the installer’s signature, profile, and App Group validation succeeds;
4. confirm `~/Applications/Desktop Widgets.app` launches;
5. add one of each widget through Edit Widgets and confirm Appearance changes reach placed widgets; and
6. run `Refresh Desktop Widgets.command` again to confirm placements and preferences survive the idempotent reinstall;
7. enable automatic maintenance and confirm `~/Library/LaunchAgents/io.desktopwidgets.automatic-refresh.plist` is loaded; and
8. inspect the companion app after the first check to confirm it reports a healthy profile. The 48-hour renewal path can be exercised with the mocked test suite, but production renewal still needs one observed cycle on the target Personal Team.

Do not describe Personal Team installation as verified on a release until that checklist passes on the target Mac.

## Local state and stable identity

The installer reads Xcode’s local Personal Team metadata without printing Apple Account addresses. It writes `Local.xcconfig` with mode `0600`; Git ignores that file. New installations derive stable app, extension, and App Group identifiers from the selected Team ID. Repeated runs reuse them. An older `Local.xcconfig` that predates the installer keeps the historic bundle IDs so macOS has the best chance to preserve existing widget placement and preferences.

The generated widget-extension identifier begins with the generated host-app identifier, as required by Xcode’s `ValidateEmbeddedBinary` check. Installer builds created before this correction are migrated automatically on the next run: the app identifier, App Group, preferences, and Team ID stay unchanged while the not-yet-valid extension identifier is repaired.

The stable source copy lives at `~/Library/Application Support/Desktop Widgets/Installer`, build intermediates live beside it, the app installs at `~/Applications/Desktop Widgets.app`, and redacted logs live under `~/Library/Logs/Desktop Widgets`.

The runtime refresh delegates to `Scripts/refresh-widget-runtime.sh`. Its stale-registration guard unregisters only other matching Desktop Widgets development extensions under the selected DerivedData root. It never unregisters unrelated extensions, removes unrelated apps, or deletes placed-widget configuration.

## Automatic maintenance

The installer recommends an opt-in user LaunchAgent. This is a scheduler, not a resident daemon: it starts at login and at 11:00 AM, performs one expiration check, and exits. There is no `KeepAlive` setting. The normal daily check reads the app and extension provisioning-profile dates without launching Xcode or rebuilding. When the earliest profile has 48 hours or less remaining—normally around day 5 of a seven-day profile—it runs the same validated refresh at low CPU and I/O priority. Scheduled refreshes do not open the companion app.

The LaunchAgent is `~/Library/LaunchAgents/io.desktopwidgets.automatic-refresh.plist`. `Enable Automatic Refresh.command` creates or reloads only that exact file; `Disable Automatic Refresh.command` unloads and removes only that exact file. Both operations are idempotent and require no administrator access. Disabling the schedule does not remove the app, its settings, or the manual refresh command.

Non-sensitive status is stored at `~/Library/Group Containers/<generated-app-group>/DesktopWidgetsAutomaticRefresh.plist` so the companion app can report enabled, healthy, refreshed, or needs-attention state. The bounded redacted log is `~/Library/Logs/Desktop Widgets/automatic-refresh.log`.

A failed renewal is retried at the next daily check. The user is notified at most once per day for the same failure, with the manual `Refresh Desktop Widgets.command` kept as the fallback. Common attention cases are a required Xcode sign-in or 2FA confirmation, no network, an unavailable signing certificate, a missing profile, or a capability/provisioning rejection. No password, authentication token, or Apple Account secret is requested, printed, or stored.

## Handoff packaging

Run `Package Desktop Widgets for Another Mac.command` or `Scripts/package-personal-installer.sh`. The resulting `Desktop-Widgets-Personal-Installer.zip` contains the source, project, guide, installer, manual refresher, and automatic-maintenance enable/disable commands required on the other Mac. It intentionally excludes Git metadata, `Local.xcconfig`, certificates, profiles, build products, and logs.
