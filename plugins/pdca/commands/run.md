---
description: "Run the PDCA cycle — auto-chains autonomous phases, pauses for interactive ones"
argument-hint: "<feature-name>"
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

### Handling REVISE from review-claude

When review-claude returns REVISE (not APPROVE), the run loop pauses:

1. **Present the findings** to the user — summarize what needs fixing.
2. **Ask the user how to proceed** with these options:
   - **Fix and re-review** (recommended for implementation gaps or code issues): Make the fixes in the current session, then re-run the review-claude logic. If the re-review returns APPROVE, continue the loop. If it returns REVISE again, pause and ask again.
   - **Iterate back to PLAN**: If the spec itself needs revision (not just code), reset to plan phase and pause for interactive Q&A.
3. **After REVISE is resolved** (review-claude passes), ask the user whether to proceed with review-codex or skip it. Don't silently skip review-codex — let the user decide.

### Handling Decisions in Autonomous Phases

Autonomous phases may surface questions that require user judgment (e.g., "should chat be gated on caller's premium or owner's?"). When this happens:

1. **Pause the autonomous execution** and present the decision to the user.
2. **Wait for the user's answer** before continuing the phase.
3. **Record the decision** in the relevant spec section (Q&A Log, Review Notes, or Technical Design).
4. **Resume the phase** with the decision applied.

This is expected behavior — "autonomous" means no user input is needed for *routine* execution, but design decisions always need user judgment.

### Important Notes
- The whole point of this command is convenience — the user types one command and the cycle runs.
- For autonomous phases, do NOT ask the user for confirmation between them. Just chain and go.
- For interactive phases, you must pause and interact with the user as the phase requires.
- Always re-read the spec from disk before starting each phase (don't rely on cached content).
