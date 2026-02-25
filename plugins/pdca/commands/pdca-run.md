---
name: pdca:run
description: "Run the PDCA cycle — auto-chains autonomous phases, pauses for interactive ones"
args: <feature-name>
user-invocable: true
---

# /pdca:run <feature-name>

Run the PDCA cycle automatically. Reads the current status from the spec and executes phases in sequence, chaining autonomous phases together and pausing only when user input is needed.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md`.
3. If the file doesn't exist, tell the user to run `/pdca:new <name>` first.

### Phase Loop

Read the `status` field from the frontmatter and enter a loop. For each iteration:

1. **Read the current status** from the spec frontmatter.
2. **If status is `done`**: announce the feature is complete and stop.
3. **Determine if the current phase is autonomous or interactive:**

**Autonomous phases** (run without stopping):
- `review-claude` — Read spec, perform systematic review, write findings, advance status
- `do` — Implement + self-verify loop (up to max_iterations), advance status
- `check` — Cold-eye verification, advance status

**Interactive phases** (need user input — stop and hand off):
- `plan` — Needs Q&A with user. Run the plan phase instructions (same as /pdca:plan).
- `review-codex` — Needs user to copy-paste to Codex. Run the review-codex instructions (same as /pdca:review-codex).
- `act` — Needs user decision. Run the act phase instructions (same as /pdca:act).

4. **For autonomous phases**: Execute the phase fully (following the same instructions as the individual phase command), then **loop back to step 1** to continue with the next phase. Do NOT stop between autonomous phases — chain them together.

5. **For interactive phases**: Execute the phase (it will involve back-and-forth with the user). After the phase completes and status advances, **loop back to step 1** to continue.

### Execution Details

When executing each phase, follow the exact same instructions as the standalone command:

- **review-claude**: Follow `/pdca:review-claude` instructions — systematic review across 5 dimensions, write to Review Notes (Claude), rate APPROVE/REVISE/BLOCK, advance status if APPROVE.
- **do**: Follow `/pdca:do` instructions — spec analysis, implementation plan, implement→verify→fix loop up to max_iterations, advance status.
- **check**: Follow `/pdca:check` instructions — cold-eye verification, write report, advance status.
- **plan**: Follow `/pdca:plan` instructions — 4 rounds of Q&A, write to spec, advance status.
- **review-codex**: Follow `/pdca:review-codex` instructions — format spec for export, wait for user paste, record feedback, advance status.
- **act**: Follow `/pdca:act` instructions — review findings, present options, take user's chosen action, advance status.

### Phase Transitions

Between phases, announce the transition clearly:

```
───────────────────────────────────
[P] review-claude complete → moving to [P] review-codex
───────────────────────────────────
```

### Important Notes
- The whole point of this command is convenience — the user types one command and the cycle runs.
- For autonomous phases, do NOT ask the user for confirmation between them. Just chain and go.
- For interactive phases, you must pause and interact with the user as the phase requires.
- If an autonomous phase fails to advance (e.g., review-claude returns REVISE), stop the loop and tell the user what needs fixing.
- Always re-read the spec from disk before starting each phase (don't rely on cached content).
