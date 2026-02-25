---
description: "List all PDCA features and their current phase"
---

# /pdca:list

List all features being tracked by PDCA with their current phase.

## Instructions

1. Check that `pdca/features/` exists. If not, tell the user to run `/pdca:init` first.
2. Find all `.md` files in `pdca/features/`.
3. For each file, read the YAML frontmatter and extract:
   - `feature` name
   - `status` (current phase)
   - `complexity`
   - `created` date
4. Display a formatted table:

```
PDCA Features
─────────────────────────────────────
  feature-name          [phase]       complexity
```

5. If no features exist, tell the user to create one with `/pdca:new <name>`.
