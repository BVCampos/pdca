---
name: pdca:do
description: "[D] DO - Implement and self-verify in a loop (up to max_iterations)"
args: <feature-name>
user-invocable: true
---

# /pdca:do <feature-name>

**PDCA Phase: [D] DO**

Implement the feature, verify against the spec, fix failures, and repeat — all in one session, up to `max_iterations` times.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md` completely.
3. Check the frontmatter `status` field. If it's not `do`, warn the user.
4. Set the do phase to `active` in the frontmatter.
5. Read `max_iterations` from frontmatter (default: 3).
6. Read `iteration` from frontmatter (current count, starts at 0).

### Spec Analysis (once, before the loop)

1. Read and internalize the entire spec: context, requirements, technical design, edge cases, and both review notes.
2. Identify all the review findings that need to be addressed during implementation.
3. Explore the existing codebase to understand current architecture, patterns, and conventions.
4. Create a concrete implementation plan listing:
   - Files to create or modify (with paths)
   - Order of implementation (dependencies first)
   - Which requirements each file change addresses
   - Test files to create
5. Write the implementation plan to the **Implementation Log** section of the spec.

### DO Loop (repeat up to max_iterations)

For each iteration:

**Step 1: Implement (or Fix)**
- On iteration 1: Implement the full plan
- On iteration 2+: Fix only the PARTIAL/FAIL items from the previous verification
- After making changes, log what was done in the Implementation Log with the iteration number

**Step 2: Self-Verify**
Re-read the spec requirements and verify each one against the current code:

For each numbered requirement:
1. Locate the code that implements it
2. Check correctness against the requirement as written
3. Check that edge cases from the spec are handled
4. Rate it: **PASS**, **PARTIAL**, or **FAIL**

Also run tests if a test command is known or discoverable.

Write/update the **Verification Results** section with the current results:

```markdown
### Iteration [N] — YYYY-MM-DD

| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 1 | [text] | PASS | [details] |
| 2 | [text] | PARTIAL | [what's missing] |

Tests: X/Y passing
```

**Step 3: Evaluate**
- If ALL requirements PASS and tests pass: **break the loop** — move to completion
- If there are PARTIAL/FAIL items AND iterations remaining: **continue the loop** — go back to Step 1 with a focused fix list
- If there are PARTIAL/FAIL items AND no iterations remaining: **break the loop** — move to completion with issues noted

Update the `iteration` field in frontmatter after each iteration.

### After the Loop

1. Write a summary at the end of the Implementation Log:
   ```
   ### DO Summary
   - Iterations used: N / max_iterations
   - Final result: ALL PASS / X of Y passing
   - Remaining issues: [list or "none"]
   ```

2. Set do phase to `done`.
3. If ALL requirements PASS:
   - Set check phase to `skipped` (self-verification was sufficient)
   - Set top-level status to `act`
   - Set act phase to `active`
   - Tell the user:

   ```
   ---
   DO phase complete — all requirements verified in [N] iterations.
   CHECK is skipped (self-verified). Moving straight to ACT.

   >> Exit this session and start a fresh one, then run:
   >>   /pdca:act <feature-name>

   Fresh sessions prevent context drift — ACT should evaluate objectively.
   ---
   ```

4. If there are remaining PARTIAL/FAIL items:
   - Set top-level status to `check`
   - Set check phase to `active`
   - Tell the user:

   ```
   ---
   DO phase complete — [X] of [Y] requirements passing after [N] iterations.
   Moving to CHECK for a cold-eye review of remaining issues.

   >> Exit this session and start a fresh one, then run:
   >>   /pdca:check <feature-name>

   Fresh sessions prevent context drift — CHECK should review with no prior assumptions.
   ---
   ```

### Important Notes
- Each iteration should be focused: don't re-implement everything, only fix what failed.
- Log every change with its iteration number for traceability.
- Be honest in self-verification. Passing yourself on broken code just wastes a loop.
- If you hit a blocker that can't be fixed by code changes alone (e.g., missing dependency, unclear requirement), stop the loop and tell the user what's blocking.
