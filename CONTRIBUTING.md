# Contributing

Thanks for taking the time to improve macOS Widgets.

## Code of conduct

By participating, you agree to follow the [Contributor Covenant Code of
Conduct](CODE_OF_CONDUCT.md). Report conduct concerns privately using the email
channel in that policy; do not post reports or sensitive personal details in a
public issue.

## Before opening a change

1. Search existing issues and pull requests to avoid duplicate work.
2. Open an issue first for changes that alter widget identity, configuration compatibility, permissions, privacy behavior, or external data sources.
3. Keep pull requests focused on one coherent outcome.

## Development workflow

1. Fork the repository and create a descriptive branch from `main`.
2. Follow the free Personal Team setup in [README.md](README.md#build-locally) for signed local widget testing.
3. Add or update focused tests when behavior changes.
4. Run the complete verification gate:

   ```sh
   ./Scripts/verify-widgets.sh
   ```

5. Describe the user-visible behavior, privacy implications, verification performed, and any manual macOS acceptance checks in the pull request.

Do not commit Apple Team IDs, certificates, provisioning profiles, API credentials, personal calendar data, location history, or machine-specific Xcode state. The repository's ignored local configuration is the only appropriate place for account-specific signing values.

## Design constraints

- Preserve established widget identities and configuration defaults unless a deliberate migration is documented.
- Keep Calendar event text out of widget models and presentation.
- Prefer system frameworks and keyless or privacy-conscious data sources.
- Maintain App Sandbox and least-privilege entitlements.
- Treat accessibility labels, locale behavior, and all three widget families as part of the feature contract.

Report vulnerabilities using [SECURITY.md](SECURITY.md), not a public issue.
Security reports and conduct reports use separate private channels; follow the
policy that matches the concern.
