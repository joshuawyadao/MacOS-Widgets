# Install Desktop Widgets on Your Mac

You do not need to know how to code. The setup command handles the build, installation, and widget refresh for you.

## First time

1. Install **Xcode** from the Mac App Store. It is large, but the Apple tools inside it are required for the free personal build.
2. Open Xcode once and let its setup finish.
3. In Xcode, choose **Xcode → Settings → Accounts**, press **+**, and sign in with your Apple Account. Xcode handles the sign-in; Desktop Widgets never asks for or sees your password.
4. Quit Xcode. In this folder, double-click **Install Desktop Widgets.command**.
5. When the app opens, Control-click the desktop, choose **Edit Widgets**, search for **Desktop Widgets**, and drag the widgets you want into place.
6. Open **Appearance** in the Desktop Widgets app to choose a style.

Apple requires you to place widgets yourself. Desktop Widgets cannot automatically arrange your desktop.

## The one regular refresh

Apple says free Personal Team profiles expire after 7 days. If the widgets disappear or need attention, double-click **Refresh Desktop Widgets.command**. It rebuilds the same app with the same local identifiers, installs it in `~/Applications`, and refreshes only Desktop Widgets.

Keep the installer copy saved under **Library → Application Support → Desktop Widgets → Installer**. The app’s Help page can show the refresh command in Finder.

## If setup stops

- **Xcode is missing:** install it from the Mac App Store and open it once.
- **No Personal Team:** add your Apple Account in Xcode Settings → Accounts, then run Install again.
- **Signing or provisioning failed:** open `DesktopWidgets.xcodeproj` once in Xcode and choose your **Personal Team** for both DesktopWidgets targets if Xcode asks. Then quit Xcode and run Refresh.
- **App Group unavailable:** stop. The app and widget need that capability to share appearance settings, so the installer will not remove it or install a reduced build.
- **Command blocked by macOS:** Control-click the command, choose **Open**, then confirm once.

The diagnostic log is at `~/Library/Logs/Desktop Widgets/installation.log`. Apple Account addresses and credential-like values are redacted. The installer never requests, prints, or stores an Apple password or authentication token.
