# Time and Date Widget

The Time and Date widget is inspired by the supplied desktop reference: white uppercase date text, a large handwritten clock, a separated AM/PM marker, and no card background so the desktop wallpaper remains visible.

## Customize the widget

1. Run the `DesktopWidgets` app once from Xcode and add **Time and Date** from the macOS widget gallery.
2. Control-click the widget on the desktop.
3. Choose **Edit Time and Date**.
4. Change any of the following options:

| Setting | Choices |
| --- | --- |
| Layout | Reference, Date Above Time, Time Above Date, Centered, Side by Side |
| Date format | Sunday 09 Aug, Sun Aug 09, MM/dd/yyyy, dd/MM/yyyy, yyyy-MM-dd |
| Time format | 12-hour, 24-hour |
| Date font | System Bold, System Rounded, System Serif, System Monospaced, Avenir Next, Noteworthy, Chalkboard SE, Bradley Hand, Marker Felt, Snell Roundhand |
| Time font | The same independent font list as the date |

The 24-hour format automatically hides AM/PM. Each layout adapts to the small, medium, and large widget families; the compact family stacks content when a side-by-side presentation would be too narrow.

## Appearance notes

- The wallpaper texture belongs to the desktop; the widget intentionally uses a clear background rather than copying it.
- Noteworthy is the default time font and the closest built-in approximation to the reference. An exact match would require the original font file and permission to redistribute it.
- macOS may tint widgets according to **System Settings → Desktop & Dock → Widgets → Widget style**. Choose **Full-color** when you want the white-on-wallpaper appearance to remain closest to the reference.
- The widget uses fonts already included with macOS and does not download or bundle third-party assets.
