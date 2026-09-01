# Install Desktop Widgets on Your Mac

You do not need to know how to code. The setup command handles the build, installation, and widget refresh for you.

## First time

1. Install **Xcode** from the Mac App Store. It is large, but the Apple tools inside it are required for the free personal build.
2. Open Xcode once and let its setup finish.
3. In Xcode, choose **Xcode → Settings → Accounts**, press **+**, and sign in with your Apple Account. Xcode handles the sign-in; Desktop Widgets never asks for or sees your password.
4. Quit Xcode. In this folder, double-click **Install Desktop Widgets.command**.
5. When asked about automatic maintenance, press Return to choose **Yes**. This is the recommended choice.
6. When the app opens, Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and drag the widgets you want into place.
7. Open **Appearance** in the Desktop Widgets app to choose a style.

Apple requires you to place widgets yourself. Desktop Widgets cannot automatically arrange your desktop.

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
