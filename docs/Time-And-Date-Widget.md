# Time and Date Widget

The Time and Date widget is inspired by the supplied desktop reference: white uppercase date text, a large handwritten clock, a separated AM/PM marker, and no card background so the desktop wallpaper remains visible.

## Customize the widget

1. Run the `DesktopWidgets` app once from Xcode.
2. Choose an **Appearance theme** in the app. Leave Time & Date on **Follow Global Theme**, choose a different curated theme for every Time & Date widget, or select **Use Each Widget's Fonts** to activate the per-copy font rows described below. Font Coverage does not visibly change Time & Date because its date, clock, and AM/PM are all display roles already.
3. Remove any Time and Date widget installed from build 3 or earlier. Build 4 intentionally uses a fresh widget and intent identity so macOS does not reuse the old AppEnum configuration cache.
4. Add **Time & Date** from the macOS widget gallery.
5. Control-click the widget on the desktop.
6. Choose **Edit Time and Date**.
7. Change any of the following options:

| Setting | Choices |
| --- | --- |
| Arrangement | Classic — Date above time; Compact — Date above time; Time first; Centered; Side by side |
| Date style | Words — Sunday 09 Aug; Short words — Sun Aug 09; Month first — 08/09/2026; Day first — 09/08/2026; ISO — 2026-08-09 |
| Clock style | 12-hour — 09:09 AM; 24-hour — 09:09 |
| Date font | Clean & Classic: System Bold, System Rounded, System Serif, System Monospaced, Avenir Next. Handwritten: Noteworthy, Chalkboard SE, Bradley Hand, Marker Felt, Snell Roundhand. |
| Time font | The same grouped font choices as the date |

The 24-hour format automatically hides AM/PM. Each layout adapts to the small, medium, and large widget families; the compact family stacks content when a side-by-side presentation would be too narrow.

Each editor row is backed by a stable string identifier supplied by a native App Intents dynamic options provider. The widget validates each identifier and safely falls back to its documented default if macOS supplies an unknown value. This transport preserves independent per-widget choices while avoiding a macOS 26.5 issue where AppEnum selections were stored correctly but rendered as their defaults.

Each font choice includes a square `Aa` specimen rendered with that macOS font. The specimen is attached to its dynamic option as a template image, allowing macOS to tint it appropriately in light and dark menus. Font choices are separated into **Clean & Classic** and **Handwritten** sections. Apple controls the Edit Widget interface, including whether and at what size it displays those images; option titles themselves remain in the system interface font. These rows remain stored independently for every placed copy and take visual effect whenever the app's Time & Date override is **Use Each Widget's Fonts**.

## Appearance notes

- Time & Date uses the same shared widget surface and selected display theme as Weather, Battery, and Calendar: white content with a consistent contrast shadow in Full Color, and system-primary content in accented or vibrant modes. Its configurable date and clock fonts remain a unique opt-in override.
- The wallpaper texture belongs to the desktop; the widget declares a clear, removable container background rather than copying it.
- WidgetKit controls the final desktop presentation. On current macOS versions, clear or accented appearances can replace the removed app background with system glass or tint, so a native widget cannot guarantee literal wallpaper-pixel transparency in every appearance mode.
- The app's global default is System for maximum readability. Under **Use Each Widget's Fonts**, Noteworthy remains the default time font and the closest built-in approximation to the reference. An exact match would require the original font file and permission to redistribute it.
- In **System Settings → Appearance**, choose **Clear → Light** for the softest Liquid Glass appearance. macOS still supplies the glass surface; native WidgetKit apps cannot remove that system-owned layer.
- The widget uses fonts already included with macOS and does not download or bundle third-party assets.

## Desktop acceptance checklist

`./Scripts/verify-widgets.sh` verifies every formatter and dynamic option provider, every size/arrangement combination, every size/date/clock combination, the exact formatted strings and combined accessibility label used by the SwiftUI view, every independent date/time font pair, fallback behavior, minute scheduling, representative Small/Medium/Large 12/24-hour render smoke tests, the Release extension bundle, and its App Intent metadata. Only WidgetKit's system-owned editor, final visual quality, and restart persistence still require a short check:

- [ ] Add small, medium, and large Time & Date widgets and visually confirm no date, time, or AM/PM text is clipped with the chosen fonts.
- [ ] Switch through every app theme and confirm Small, Medium, and Large remain readable; then choose **Use Each Widget's Fonts**.
- [ ] Configure one instance with the default Classic/12-hour choices and a second instance with Side by side/ISO/24-hour choices and different fonts; confirm the two instances remain visually different.
- [ ] Reopen **Edit Time & Date** for both instances and confirm each editor shows its own saved selections.
- [ ] Restart the Mac (or log out and back in), then confirm both configurations persist and the clocks continue updating.
- [ ] Use VoiceOver once to confirm macOS announces the combined date and complete time as one element.

## Lock-screen privacy behavior

The extension intentionally does not include Apple's Data Protection entitlement. Adding `NSFileProtectionCompleteUntilFirstUserAuthentication` made Xcode require a provisioning profile for the widget extension, which would break this project's free, teamless **Sign to Run Locally** workflow. As a result, macOS may show its opaque privacy placeholder while the Mac is locked. Revisit this tradeoff only if the project later adopts an Apple Developer Program signing profile.
