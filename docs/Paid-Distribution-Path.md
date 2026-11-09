# Developer ID notarized disk image releases

Desktop Widgets supports direct download with manual updates. Recipients install an already built app; only the release provider needs Xcode and Apple Developer Program access. This workflow does not submit an App Store listing or TestFlight build, and does not install anything on the release machine.

## Account prerequisites

1. In Xcode Settings → Accounts, add the enrolled account and confirm the paid Team ID. Complete any Apple enrollment or agreement steps there.
2. In Manage Certificates, create or import a **Developer ID Application** certificate and its private key. An Apple Development or Apple Distribution certificate is not a substitute. Keep the private key in Keychain.
3. Create a Keychain notary profile locally, for example `xcrun notarytool store-credentials desktop-widgets-notary`, and answer its prompts. It uses the Apple account, Team ID and an app-specific password (or supported App Store Connect API credentials). Do not paste passwords or keys into chat, source files, command history or Git.
4. Confirm a valid signing identity is available with `security find-identity -v -p codesigning`. Use its complete Developer ID Application name in the release command.

The release command stops when the requested certificate is unavailable. Xcode/Keychain may ask the account owner to authorize signing. No credentials are bundled in the disk image.

## Decide which identity to preserve

Keep app ID, widget-extension ID, widget kinds, App Intent schemas, preference keys, signing team, and App Group stable between releases. A filename or marketing version change does not justify changing those identities.

The command requires exactly one mode:

- `--existing-app '/path/Desktop Widgets.app'`: inspect a signed installed/exported copy and preserve its app, extension and shared-settings identifiers after checking both signed teams and entitlements. This is the preferred first migration when that app uses the same team as the Developer ID certificate. The source app is only read.
- `--identities-file /path/previous.identities.plist`: reuse the nonsecret manifest written beside a successful prior release. Keep that manifest with the release records and reuse it for subsequent updates.
- `--new-install`: explicitly choose the repository defaults for a new installation: `com.joshuawyadao.DesktopWidgets`, `com.joshuawyadao.DesktopWidgets.Widgets` and `<TEAM>.com.joshuawyadao.desktop-widgets`. Do not use this mode to bypass a migration mismatch without first planning a fresh installation.

The source installer can generate different `io.desktopwidgets.personal.<team>...` IDs. Inspect the recipient’s installed app, rather than assuming this worktree’s defaults match it. If her free account and the release provider’s paid account have different Team IDs, the release command intentionally refuses automatic preservation. Different teams cannot use the same App Group. In that case, record her theme/widget choices, disable the old schedule, back up the old app, retain container data, and use a new installation; re-adding widgets and granting Calendar access may be necessary. There is no automatic cross-team container migration.

The existing `<TEAM>.<group>` macOS App Group format is supported without portal registration or a provisioning profile. Do not rename it merely to adopt a `group.` prefix. Any future additional restricted capabilities need their own provisioning review.

## Build the release

From the repository root, run the command with your actual Team ID, Keychain identity name and profile:

```sh
Scripts/release-notarized-dmg.sh \
  --team ABC123DE45 \
  --identity 'Developer ID Application: Your Name (ABC123DE45)' \
  --notary-profile desktop-widgets-notary \
  --existing-app '/path/to/existing/Desktop Widgets.app' \
  --output '/absolute/path/releases/Desktop-Widgets-1.0.0-21.dmg'
```

For a new installation replace `--existing-app ...` with `--new-install`. For future updates use `--identities-file ...` with the previous manifest. Increment `CURRENT_PROJECT_VERSION` for both production targets and set the same `MARKETING_VERSION` on both before making an update. The tool checks matching versions/builds, but choosing a newer version is the release provider’s responsibility.

`Config/DeveloperID.xcconfig` isolates release behavior from local development. The release command explicitly supplies team, identity and bundle/group values, sets the `developer-id` channel, and clears all source-installer helper paths. Personal Team development keeps its own setup and guidance.

The tool archives both CPU architectures, exports with Developer ID signing, validates the app and nested widget signatures, entitlements, identity, timestamp, hardened runtime, and matching versions, then notarizes and staples the app. It creates a read-only `.dmg` containing **Desktop Widgets.app**, an Applications shortcut and installation/update instructions, signs and notarizes the image, staples its ticket and checks Gatekeeper. Only successful output is published alongside a nonsecret `.identities.plist` manifest. Never distribute a temporary or failed build as an approved release. If a release process is force-killed, its `<output>.release-lock` directory may remain; remove only that empty lock after confirming the original process has stopped, or choose a new output path. Failure diagnostics are saved beside the requested output when archive, export, or notarization fails.

A successful tool run is necessary but not sufficient for a release: the following acceptance checklist must also pass. No account upload or clean-Mac behavior is implied by unit tests or an unsigned archive.

## Recipient installation, migration and manual updates

Use [the installation guide](../Installation%20Guide.md) for the exact recipient steps. Before switching an existing source installation:

1. Run the previous **Disable Automatic Refresh.command** to unload only `io.desktopwidgets.automatic-refresh`. If Xcode or a manual refresh is currently building, let it finish before proceeding.
2. Compare the installed and release identities; record appearance/widget choices when they cannot be preserved.
3. Quit the app and replace it in the same Applications folder. Avoid duplicate installed copies in `/Applications` and `~/Applications`. Do not delete container data or placed widgets as an update step.
4. Open the installed copy once; stop using the old Install/Refresh/Enable commands. Older saved installers predate the release guard and must still be disabled.

For future manual updates, quit the app and replace it in the same folder, keeping placed widgets and preferences. Keep the previous release for rollback. An updater service, feed or automatic update daemon is not included.

## Release acceptance checklist

- [ ] Signing identity and Team ID match the intended release; app and widget share the expected App Group, sandbox and Calendar entitlements, with outgoing network allowed for Weather.
- [ ] Both binaries include arm64 and x86_64; deployment target remains macOS 14; app/extension versions and build numbers match.
- [ ] Notary service accepts both submitted artifacts, stapler validates both tickets, and signature/Gatekeeper checks pass.
- [ ] Download the final image through the real delivery channel on a clean Mac/user account without Xcode or developer credentials. Open it, drag into Applications, confirm the normal first-open prompt, eject the image and launch the installed app.
- [ ] All four widgets appear in Edit Widgets without development registration scripts. Place each; verify theme changes reach them.
- [ ] Calendar denied, granted and revoked states work; Weather city search, offline state and attribution work; Battery handles unavailable hardware cleanly.
- [ ] Test replacing a previous release: settings and placed widgets survive when identities match. Test the previous source-installer migration with its schedule disabled; verify no duplicate gallery entries or renewal prompts.
- [ ] Test on the recipient’s macOS version and architecture. Record which machines were actually tested; a universal archive alone does not verify every supported OS.

## References

- [Apple: Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Apple: Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)
- [Apple: Accessing app group containers in your existing macOS app](https://developer.apple.com/documentation/xcode/accessing-app-group-containers)

## Verification record

This branch adds release tooling and automated safety checks. A Developer ID signed/notarized artifact and the clean-Mac checklist remain pending until the account prerequisites are available. Record actual release evidence here when those steps are completed; do not treat mocked notarization or unsigned archives as Apple approval.
