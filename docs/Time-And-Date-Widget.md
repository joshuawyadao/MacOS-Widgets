# Time and Date Widget

The Time and Date widget is inspired by the supplied desktop reference: white uppercase date text, a large handwritten clock, a separated AM/PM marker, and no card background so the desktop wallpaper remains visible.

## Customize the widget

1. Run the `DesktopWidgets` app once from Xcode.
2. Remove any Time and Date widget installed from build 3 or earlier. Build 4 intentionally uses a fresh widget and intent identity so macOS does not reuse the old AppEnum configuration cache.
3. Add **Time and Date (Custom)** from the macOS widget gallery.
4. Control-click the widget on the desktop.
5. Choose **Edit Time and Date**.
6. Change any of the following options:

| Setting | Choices |
| --- | --- |
| Layout | Reference, Date Above Time, Time Above Date, Centered, Side by Side |
| Date format | Sunday 09 Aug, Sun Aug 09, MM/dd/yyyy, dd/MM/yyyy, yyyy-MM-dd |
| Time format | 12-hour, 24-hour |
| Date font | System Bold, System Rounded, System Serif, System Monospaced, Avenir Next, Noteworthy, Chalkboard SE, Bradley Hand, Marker Felt, Snell Roundhand |
| Time font | The same independent font list as the date |

The 24-hour format automatically hides AM/PM. Each layout adapts to the small, medium, and large widget families; the compact family stacks content when a side-by-side presentation would be too narrow.

Each editor row is backed by a stable string identifier supplied by a native App Intents dynamic options provider. The widget validates each identifier and safely falls back to its documented default if macOS supplies an unknown value. This transport preserves independent per-widget choices while avoiding a macOS 26.5 issue where AppEnum selections were stored correctly but rendered as their defaults.

Each font choice includes a square `Aa` specimen rendered with that macOS font. The specimen is attached to its dynamic option as a template image, allowing macOS to tint it appropriately in light and dark menus. Apple controls the Edit Widget interface, including whether and at what size it displays those images; option titles themselves remain in the system interface font.

## Appearance notes

- The wallpaper texture belongs to the desktop; the widget declares a clear, removable container background rather than copying it.
- WidgetKit controls the final desktop presentation. On current macOS versions, clear or accented appearances can replace the removed app background with system glass or tint, so a native widget cannot guarantee literal wallpaper-pixel transparency in every appearance mode.
- Noteworthy is the default time font and the closest built-in approximation to the reference. An exact match would require the original font file and permission to redistribute it.
- In **System Settings → Desktop & Dock → Widgets**, choose **Full-color** for Widget style and set desktop dimming to **Never** when you want the white-on-wallpaper appearance to remain closest to the reference.
- The widget uses fonts already included with macOS and does not download or bundle third-party assets.
