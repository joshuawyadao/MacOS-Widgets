# Plan

Separate public contact from commit attribution without rewriting published history, and add a recognized conduct policy with a genuinely private reporting route. Future commits will use the GitHub-provided noreply identity, while the already-public account email will be reserved for intentional conduct correspondence.

## Scope
- In: Future Git commit email configuration, existing-history decision, Contributor Covenant policy, contributor guidance, documentation consistency, local validation, and branch publication.
- Out: Rewriting or force-pushing existing commits, changing the GitHub profile's public email setting, changing application behavior, and creating a new external mailbox or form.

## Action items
[x] Configure Git to use `38051882+joshuawyadao@users.noreply.github.com` for future commits and verify the effective identity without rewriting history.
[x] Add GitHub's recognized Contributor Covenant template as `CODE_OF_CONDUCT.md`, using the account's public Gmail address as a private-by-email conduct reporting channel.
[x] Update `CONTRIBUTING.md` and `README.md` so contributors can find the conduct standards and distinguish conduct reports from security vulnerabilities.
[x] Verify the policy contact, Markdown links, repository diff, commit metadata, and absence of application/test impact. Automated tests do not apply because no executable, test, build, or project-configuration files changed.
[x] Commit and push the scoped documentation and plan on `codex/community-privacy` using the noreply identity.
[x] Check the pushed branch and report the expected community-profile improvement, noting that GitHub recalculates the default-branch score after merge.

## Open questions
- None. The existing Gmail address remains in published history and is already exposed on the GitHub profile; it will be used only as an intentional private reporting route, while new commit metadata uses noreply.
