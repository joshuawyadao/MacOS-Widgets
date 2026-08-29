# Plan

Prepare macOS Widgets as a trustworthy public portfolio repository, preserve its existing history, and publish it with a polished project overview, constrained CI, and protected GitHub settings. Validate the repository locally before exposing it, then use the public repository's free standard GitHub-hosted runner to confirm CI.

## Scope
- In: Portfolio-focused README improvements, authentic app imagery where feasible, public contribution/security guidance, an explicit license decision, pinned and least-privilege CI, local verification, repository metadata/topics, public visibility, secret protection, and a protected `main` branch.
- Out: Sparkle or binary distribution, application behavior changes, widget redesigns, history rewriting, merging unrelated work from the existing installation/Actions branches, and changes to the user's public GitHub profile email.

## Action items
[x] Create a `codex/public-portfolio` branch from the current `main` commit and inventory public-facing assets and metadata without modifying unrelated worktrees or branches.
[x] Restructure `README.md` for recruiter-friendly scanning with an overview, key engineering highlights, architecture, privacy/security posture, local-build instructions, verification, and project status; omit a screenshot because the available running app contains user-specific state that should not be published.
[x] Add focused public-repository guidance (`SECURITY.md` and concise contribution instructions) and the MIT license without duplicating widget-specific documentation.
[x] Pin third-party Actions to an immutable commit, add concurrency protection, retain read-only permissions, and validate the workflow syntax and repository documentation.
[x] Run `git diff --check` and `./Scripts/verify-widgets.sh`; no automated test files are needed because application behavior is unchanged, and the existing full suite plus Release build passed as the relevant regression gate.
[x] Commit and push only the portfolio/publication changes while the repository is private, then make the repository public and configure its description, topics, Actions allowlist with immutable SHA pinning, secret scanning/push protection, dependency security updates, private vulnerability reporting, and a `main` ruleset that blocks deletion/force-push and requires CI through pull requests.
[x] Open publication PR #9, confirm the now-free public `macos-26` CI run succeeds without warnings, merge the verified change, and recheck public visibility, protections, repository presentation, and the absence of exposed repository secrets.

## Open questions
- None. The repository will use the MIT license; official repository updates remain controlled by GitHub write access and protected-branch settings.
