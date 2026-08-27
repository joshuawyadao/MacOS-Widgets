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
6. run `Refresh Desktop Widgets.command` again to confirm placements and preferences survive the idempotent reinstall.

Do not describe Personal Team installation as verified on a release until that checklist passes on the target Mac.

## Local state and stable identity

The installer reads Xcode’s local Personal Team metadata without printing Apple Account addresses. It writes `Local.xcconfig` with mode `0600`; Git ignores that file. New installations derive stable app, extension, and App Group identifiers from the selected Team ID. Repeated runs reuse them. An older `Local.xcconfig` that predates the installer keeps the historic bundle IDs so macOS has the best chance to preserve existing widget placement and preferences.

The stable source copy lives at `~/Library/Application Support/Desktop Widgets/Installer`, build intermediates live beside it, the app installs at `~/Applications/Desktop Widgets.app`, and the redacted log lives at `~/Library/Logs/Desktop Widgets/installation.log`.

The runtime refresh delegates to `Scripts/refresh-widget-runtime.sh`. Its stale-registration guard unregisters only other matching Desktop Widgets development extensions under the selected DerivedData root. It never unregisters unrelated extensions, removes unrelated apps, deletes placed-widget configuration, or starts a background service.

## Handoff packaging

Run `Package Desktop Widgets for Another Mac.command` or `Scripts/package-personal-installer.sh`. The resulting `Desktop-Widgets-Personal-Installer.zip` contains the source, project, guide, and friendly commands required to build on the other Mac. It intentionally excludes Git metadata, `Local.xcconfig`, certificates, profiles, build products, and logs.
