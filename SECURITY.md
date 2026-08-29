# Security policy

## Supported version

Security fixes are applied to the latest commit on `main`. This project distributes source for local Personal Team builds rather than supported release binaries.

## Reporting a vulnerability

Please use [GitHub private vulnerability reporting](https://github.com/joshuawyadao/MacOS-Widgets/security/advisories/new) so details are not disclosed before a fix is available.

Include:

- The affected component and macOS version.
- Reproduction steps or a minimal proof of concept.
- The likely impact, especially for Calendar privacy, signing, sandbox escape, update integrity, or unintended network access.
- Any suggested remediation.

Do not include real calendar content, personal locations, Apple credentials, certificates, provisioning profiles, or other sensitive data. Use synthetic examples and redact machine-specific paths.

If private vulnerability reporting is unavailable, open a public issue that contains no exploit or sensitive details and ask for a private contact channel.

## Scope

Reports about credential exposure, unsafe scripts, entitlement expansion, privacy regressions, dependency compromise, and unauthorized changes to the official repository are in scope. General support questions and feature requests should use regular GitHub issues.
