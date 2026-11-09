# Install Desktop Widgets on Your Mac

## Install from a notarized download

Requires macOS 14 or later. Before installing over a previous Xcode/source build, follow **Switching from the source installer** below.

1. Download the `.dmg` from the person providing your release and open it.
2. Drag **Desktop Widgets.app** onto **Applications**. Open the installed app from Applications, rather than running it inside the disk image.
3. Confirm the normal macOS first-open prompt, then eject the disk image.
4. Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and add the widgets you want.
5. Open **Appearance** to choose a coordinated style. Edit a Weather widget to choose your city. Calendar access is optional.

This version needs no Xcode, developer-account sign-in, scheduled rebuild, or weekly renewal. If macOS cannot verify the app, ask the sender for a correctly signed and notarized download instead of disabling security checks.

## Manual updates

Compare the version/build in **Desktop Widgets → About DesktopWidgets** (the menu title may use the product name) with the supplied release notes. Quit the app, open the new disk image, then replace **the existing app in the same Applications folder**. If your current copy is in your home folder’s Applications, replace it there instead of creating a second copy in `/Applications`. Open the updated app and eject the disk image.

Leave placed widgets and app data in place. Releases with the same signing team, app ID, extension ID, widget kinds and shared-settings group offer the best continuity. If widgets remain stale, reopen the app and give macOS time to update them before considering removal. Keep the prior release download for rollback; do not run two installed copies together.

## Switching from the source installer

Do this once before installing the notarized version:

1. Run **Disable Automatic Refresh.command** from the previous installer, or the saved copy in `~/Library/Application Support/Desktop Widgets/Installer`. This unloads only Desktop Widgets’ old refresh schedule. It keeps widgets and preferences.
2. Quit Desktop Widgets. Ask the release provider to compare the signing team and identifiers of your installed app with the release; a build signed by your own free account may have a different identity from the provider’s release.
3. If the identities match, replace the app in its current Applications folder. If they differ, note your theme and widget choices first. Move the old app out of Applications to a backup location before installing the new one; you may need to re-add widgets, reapply appearance choices, and grant Calendar access again. Do not delete anything from Library/Containers or Library/Group Containers.
4. Stop using the old Install/Refresh/Enable Automatic Refresh commands. Updates now arrive as signed downloads.

New development helpers refuse to overwrite Developer ID releases. Older saved helper copies do not have that protection, so disabling the old schedule remains necessary. Container data is never automatically copied across Apple teams.

## Personal Team source installation

The following sections apply only to building the separate development version from source.

You do not need to know how to code. The setup command handles the build, installation, and widget refresh for you.

## First time

1. Install **Xcode** from the Mac App Store. It is large, but the Apple tools inside it are required for the free personal build.
2. Open Xcode once and let its setup finish.
3. In Xcode, choose **Xcode → Settings → Accounts**, press **+**, and sign in with your Apple Account. Xcode handles the sign-in; Desktop Widgets never asks for or sees your password.
4. Quit Xcode. In this folder, double-click **Install Desktop Widgets.command**.
5. When asked about automatic maintenance, press Return to choose **Yes**. This is the recommended choice.
6. When the app opens, Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and drag the widgets you want into place.
7. Use the short **Make it yours** checklist below.

Apple requires you to place widgets yourself. Desktop Widgets cannot automatically arrange your desktop.

## Make it yours

- Open **Appearance** in the Desktop Widgets app to choose one coordinated style for every widget.
- Control-click a placed Weather widget, choose **Edit Widget**, and select your city and preferred details.
- Calendar access is optional. Enable it from **Home** or **Calendar** in the app only if you want private event dots, counts, or next-event timing.

Each placed widget keeps its own choices, so you can add multiple sizes or configurations without changing the others.

## Automatic maintenance

Apple says free Personal Team profiles expire after 7 days when Xcode uses one. Xcode 26.6 can legitimately produce a profile-free macOS build for Desktop Widgets because its App Group, sandbox, network, and Calendar permissions are unrestricted macOS entitlements. Automatic maintenance handles either signing form:

- A tiny check runs when you log in and once a day at 11:00 AM, then exits. It does not stay running.
- Most days it only reads the profile expiration or local signing timestamp and does not open Xcode or rebuild anything.
- During the final 48 hours—normally around day 5—it refreshes Desktop Widgets at low priority. Profile-free builds use the same conservative seven-day window rather than assuming they never need maintenance.
- If the Mac is asleep at 11:00 AM, macOS runs the missed check after it wakes.
- Success is quiet. A notification appears only when you need to open Xcode or use the manual refresh.

The automatic refresh normally keeps working without attention while the Mac has internet access, Xcode remains signed in, and the signing certificate is available. Those are usually stable after first setup, but Apple can occasionally require a new sign-in or two-factor confirmation. The helper cannot and will not automate Apple credentials.

Double-click **Enable Automatic Refresh.command** to turn maintenance on later, or **Disable Automatic Refresh.command** to turn it off. Both are safe to run repeatedly.

## Manual fallback

If a notification says Desktop Widgets needs attention, first open Xcode and complete any sign-in or setup message. Then double-click **Refresh Desktop Widgets.command**. It rebuilds the same app with the same local identifiers, installs it in `~/Applications`, and refreshes only Desktop Widgets. Automatic maintenance retries at the next daily check after a failure.

Keep the installer copy saved under **Library → Application Support → Desktop Widgets → Installer**. The app’s Help page can show the refresh command in Finder.

## If setup stops

- **Xcode is missing:** install it from the Mac App Store and open it once.
- **No Personal Team:** add your Apple Account in Xcode Settings → Accounts, then run Install again.
- **Signing or provisioning failed:** open `DesktopWidgets.xcodeproj` once in Xcode and choose your **Personal Team** for both DesktopWidgets targets if Xcode asks. Then quit Xcode and run Refresh.
- **App Group unavailable:** stop. The app and widget need that capability to share appearance settings, so the installer will not remove it or install a reduced build.
- **Command blocked by macOS:** Control-click the command, choose **Open**, then confirm once.

The installation log is at `~/Library/Logs/Desktop Widgets/installation.log`; automatic-maintenance details are at `~/Library/Logs/Desktop Widgets/automatic-refresh.log`. Logs are size-limited, and Apple Account addresses and credential-like values are redacted. The installer never requests, prints, or stores an Apple password or authentication token.
