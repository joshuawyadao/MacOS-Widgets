# Plan

Replace teamless ad-hoc development signing with automatic signing that reads a Personal Team identifier from an ignored local configuration file, allowing macOS to register the Weather city AppEntity without publishing account-specific values.

## Scope
- In: App and widget-extension Debug/Release signing configuration, a local Personal Team setup helper, signing verification, and developer setup documentation.
- Out: Paid Developer Program enrollment, App Store/Developer ID distribution, changing the Weather configuration model, or storing an Apple Account or Team ID in Git.

## Action items
[x] Add a committed signing configuration that optionally imports ignored machine-local values and enables automatic Apple Development signing.
[x] Attach the signing configuration to the host app and widget extension without embedding a Team ID in the project.
[x] Add a helper that validates a Personal Team ID, writes only the ignored `Local.xcconfig`, and explains the Xcode account prerequisite.
[x] Extend repository verification to reject accidental committed Team IDs and confirm the app and extension share the automatic-signing configuration.
[x] Update the main and Weather documentation with the free Personal Team setup, local-file behavior, and runtime signature check.
[x] Run script syntax checks, the repository verification gate, and a signing build if a local Apple Development identity is available. No signing build was possible before Xcode account setup because the keychain contains no Apple Development identity.
[x] Commit and push the verified repository setup on the current Weather feature branch.

## Open questions
- None.
