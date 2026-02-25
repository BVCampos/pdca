---
name: pdca:status
description: Show detailed phase status for a feature
args: <feature-name>
user-invocable: true
---

# /pdca:status <feature-name>

Show the detailed status of all phases for a specific feature.

## Instructions

1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md`.
3. If the file doesn't exist, tell the user and list available features.
4. Parse the YAML frontmatter and display:
   - Feature name, created date, complexity
   - Current overall status
   - Each phase with its status, using visual indicators:
     - `[x]` done (green)
     - `[>]` active (yellow)
     - `[ ]` pending
     - `[-]` skipped
5. Show the next action the user should take (e.g., "Run `/pdca:plan <name>` to start planning").
