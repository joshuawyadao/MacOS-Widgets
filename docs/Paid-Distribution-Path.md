# Future paid distribution path

This feature does not implement paid distribution. A later release can remove the weekly Personal Team rebuild by enrolling in the Apple Developer Program and producing a Developer ID build that Apple notarizes.

That future work should:

1. create paid-team bundle IDs and an App Group in Apple’s developer portal;
2. sign the host app and widget extension with the appropriate Developer ID identities and provisioning assets while retaining the required entitlements;
3. archive with Xcode, enable the hardened runtime, and submit the archive to Apple’s notary service;
4. staple the notarization ticket and verify Gatekeeper acceptance on a clean Mac;
5. package the notarized app in a signed disk image or installer with a documented update channel; and
6. plan identifier migration carefully, because changing bundle, widget, App Intent, or App Group identities can prevent macOS from preserving placed widgets and settings.

Apple documents the supported release flow in [Distributing your app for beta testing and releases](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) and [Packaging Mac software for distribution](https://developer.apple.com/documentation/xcode/packaging-mac-software-for-distribution). Credentials and notarization secrets must stay in Keychain or a protected CI secret store, never in this repository or its handoff package.
