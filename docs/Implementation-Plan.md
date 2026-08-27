# Plan

Reduce the companion app's change surface before merging by separating navigation, appearance editing, widget guidance, help/privacy content, and reusable UI components into focused Swift files. Preserve the existing user experience and keep the shared typography draft and Calendar permission state owned by the root view so navigation behavior does not change.

## Scope
- In: Companion-app SwiftUI file organization, typography-controller placement, Xcode project references, existing navigation/accessibility behavior, review-history recording, and full repository verification.
- Out: New user-facing features, widget rendering or configuration changes, installation-flow work, signing changes, and changes to the existing navigation information architecture.

## Action items
[x] Extract `WidgetTypographyController` from `ContentView.swift` into a focused app model without changing its draft/apply semantics.
[x] Split Home, Appearance, widget guidance, and Help & Privacy page content into focused companion-app view files while keeping root navigation state in `ContentView`.
[x] Move reusable companion-app cards and permission controls into a shared components file with the same accessibility labels and actions.
[x] Add the extracted Swift files to the Desktop Widgets app target and verify no widget-extension or test-target membership changes are introduced.
[x] Confirm the refactor preserves destination ordering, pending appearance state, Calendar permission ownership, and all existing user-facing copy.
[x] Record the Brooks review result and run `git diff --check`, the complete `Scripts/verify-widgets.sh` gate, and GitHub CI before saving the review fix.
[x] Commit and push the scoped maintainability fix to the current PR branch, then re-check Codex feedback, CI, and mergeability.

## Open questions
- None.
