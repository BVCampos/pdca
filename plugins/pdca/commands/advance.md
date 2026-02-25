---
description: "Manually advance a feature to the next phase"
argument-hint: "<feature-name>"
---

# /pdca:advance <feature-name>

Manually advance a feature to the next phase in the PDCA workflow.

## Instructions

1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md`.
3. If the file doesn't exist, tell the user and stop.
4. Read the current `status` from frontmatter.
5. If status is `done`, tell the user the feature is already complete.
6. The phase order is: `plan` -> `review-claude` -> `review-codex` -> `implement` -> `verify` -> `done`.
7. Mark the current phase as `done` in the frontmatter phases section.
8. Set the next phase to `active` and update the top-level `status` field.
9. If the current phase is `verify`, set status to `done`.
10. Write the updated frontmatter back to the spec file.
11. Confirm the transition and tell the user which command to run next.

## Warning

Tell the user this skips the current phase's work. Ask for confirmation before proceeding. This is useful for skipping optional phases (e.g., review-codex) or recovering from errors.
