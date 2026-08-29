# Plan

Polish the public repository with an authentic privacy-safe widget showcase, lightweight contribution templates, and removal of internal-only review history. Generate the visual from the real SwiftUI widget views using deterministic synthetic data, then publish the changes through the protected pull-request workflow.

## Scope
- In: A generated portfolio preview, README presentation updates, issue and pull-request templates, internal artifact cleanup, documentation of the preview workflow, validation, and protected publication.
- Out: Real calendar or location screenshots, application behavior changes, signed binary distribution, Git history rewriting, GitHub profile pinning, LinkedIn edits, commit-email changes, and a Code of Conduct that would require choosing a private maintainer contact channel.

## Action items
[x] Remove `.brooks-lint-history.json` from the tracked project and ignore future local Brooks review history without altering other project metadata.
[x] Add focused GitHub issue forms and a pull-request template that reinforce the repository's privacy, security, compatibility, and verification expectations.
[x] Extend `DesktopWidgetsTests/WidgetRenderingSmokeTests.swift` with a synthetic-data showcase that pins locale, time zone, and color scheme while rendering the real widget views into temporary storage; add an explicit generator that respects configured or system-selected Xcode paths as the only way to refresh the tracked preview.
[x] Generate and visually inspect `docs/images/widgets-preview.png`, then add it near the top of `README.md` with an accurate synthetic-data caption and regeneration instructions.
[x] Run targeted rendering tests, YAML/Markdown/link checks, `git diff --check`, and the complete `./Scripts/verify-widgets.sh` gate; confirm no personal data or credentials appear in the changed files or image.
[ ] Commit and push the scoped changes on `codex/public-polish`, open a pull request, address review feedback, require public CI to pass, and merge without bypassing the `main` ruleset.

## Open questions
- None. Account-level profile, LinkedIn, and email choices will be reported as manual follow-up steps.
