---
name: pdca:init
description: Initialize PDCA features directory in the current project
user-invocable: true
---

# /pdca:init

Initialize the PDCA workflow in the current project.

## Instructions

1. Check if `pdca/features/` directory already exists in the current working directory.
2. If it exists, tell the user it's already initialized.
3. If not, create the `pdca/features/` directory.
4. Confirm creation and explain the next step: use `/pdca:new <feature-name>` to create a feature spec.
