# Plan

Preserve the full Xcode verification gate while sharply reducing costly macOS-hosted executions. Run the gate only for merge-ready pull requests or manual requests, cancel superseded work, and remove the duplicate post-merge `main` run.

## Scope
- In: `.github/workflows/ci.yml` trigger, concurrency, draft policy, manual dispatch, and README CI guidance.
- Out: Xcode tests, coverage behavior, release-build behavior, signing, widget runtime code, branch-protection settings, and self-hosted runners.

## Action items
[x] Restrict macOS CI to merge-ready pull requests plus manual dispatch, removing the duplicate `main` push trigger.
[x] Add per-workflow/per-ref concurrency cancellation while preserving the existing 20-minute timeout and read-only permissions.
[x] Document when hosted macOS verification runs and how to request it manually.
[x] Validate YAML parsing, workflow-policy invariants, `git diff --check`, and the scoped diff; no Swift test files are needed because executable widget behavior is unchanged.
[x] Commit and push the isolated `codex/optimize-github-actions` branch while leaving the unrelated `v6` file in the original checkout untouched.

## Open questions
- None.
