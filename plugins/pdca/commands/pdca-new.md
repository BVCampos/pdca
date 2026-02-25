---
name: pdca:new
description: Create a new feature spec from template
args: <feature-name>
user-invocable: true
---

# /pdca:new <feature-name>

Create a new feature spec file from the PDCA template.

## Instructions

1. Parse the feature name from the argument. If no argument given, ask the user for a feature name.
2. Check that `pdca/features/` exists. If not, create it (run init automatically).
3. Check if `pdca/features/<feature-name>.md` already exists. If so, tell the user and stop.
4. Read the spec template from the plugin directory at `scripts/spec-template.md`.
5. Create `pdca/features/<feature-name>.md` by copying the template and replacing:
   - `FEATURE_NAME` with the feature name
   - `CREATED_DATE` with today's date (YYYY-MM-DD format)
6. Set the plan phase status to `active` in the frontmatter.
7. Confirm creation and tell the user to run `/pdca:plan <feature-name>` to start planning.
