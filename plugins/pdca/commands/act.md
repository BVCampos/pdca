---
description: "[A] ACT - Act on findings, iterate or close the feature"
argument-hint: "<feature-name>"
---

# /pdca:act <feature-name>

**PDCA Phase: [A] ACT**

Review the DO/CHECK findings and decide: close the feature, iterate back to DO, or iterate back to PLAN.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md` completely.
3. Check the frontmatter `status` field. If it's not `act`, warn the user.
4. Set the act phase to `active` in the frontmatter.

### Review Findings

1. Read the **Verification Results** section — both DO's self-verification and CHECK's cold-eye review (if it ran).
2. Read the **Implementation Log** — how many iterations were used, what's the DO Summary.
3. Summarize for the user:
   - How many requirements PASS / PARTIAL / FAIL
   - Iterations used vs max_iterations
   - Test results summary
   - Outstanding issues list
   - Whether CHECK disagreed with any of DO's self-assessments
4. Read the **Review Notes (Claude)** and **Review Notes (Codex)** sections to check if any review findings were not addressed.

### Decision Point

Present the user with clear options based on the findings:

**If ALL requirements PASS and no outstanding issues:**
- Recommend: **Close the feature**
- "All requirements verified. This feature is ready to ship."

**If there are PARTIAL or FAIL items:**
- Recommend: **Iterate back to DO**
- List each issue and what needs to change
- Propose a focused action plan for the next iteration
- Note: this resets the iteration counter so DO gets fresh attempts

**If there are only Low-severity residual issues (all requirements PASS but with minor gaps):**
- Recommend: **Quick fix and close**
- List the minor issues and confirm the user wants them fixed in-place
- This avoids a full DO cycle for trivial fixes

**If there are spec issues (requirements that need updating):**
- Recommend: **Iterate back to PLAN**
- Explain which requirements need revision and why

### Taking Action

**Option A: Close (mark done)**
1. Write a summary to the **Act Log** section:
   - Final disposition: COMPLETE
   - Date closed
   - Total iterations across all DO runs
   - Any notes about known limitations or follow-up work
2. Set act phase to `done`
3. Set top-level status to `done`
4. Tell user: "Feature '<feature-name>' is complete! The full PDCA cycle is done."

**Option B: Iterate back to DO (fix implementation)**
1. Write to the **Act Log** section:
   - Iteration reason: [what needs fixing]
   - Items to address: [list from verification]
   - Date of iteration
2. Set act phase to `done`
3. Reset do phase to `pending`, check phase to `pending`, act phase to `pending`
4. Reset `iteration` to `0` in frontmatter (fresh iteration counter for the new DO run)
5. Set top-level status to `do`
6. Set do phase to `active`
7. Tell the user:

```
---
Iterating back to DO to address [N] issues. Iteration counter reset.

>> Exit this session and start a fresh one, then run:
>>   /pdca:do <feature-name>

Fresh sessions prevent context drift — DO should read the spec and act log fresh.
---
```

**Option D: Quick fix and close (minor residuals only)**

Use this when all requirements PASS but CHECK found Low-severity residual issues (theoretical race conditions, test coverage gaps, minor code quality items).

1. Fix the residual issues in-place (code changes + tests).
2. Run tests to verify.
3. Write to the **Act Log** section:
   - Disposition: CLOSED (with quick fixes)
   - Residual issues fixed: [list]
   - Test results after fixes
4. Set act phase to `done`
5. Set top-level status to `done`
6. Tell user: "Feature '<feature-name>' is complete! Quick fixes applied for [N] residual issues."

**Important**: Only use this for genuinely minor issues. If any fix requires significant code changes, architectural decisions, or could introduce regressions, use Option B (iterate to DO) instead.

**Option C: Iterate back to PLAN (fix spec)**
1. Write to the **Act Log** section:
   - Iteration reason: [what needs revising in the spec]
   - Items to address: [list]
   - Date of iteration
2. Set act phase to `done`
3. Reset all phases from plan onward to `pending`
4. Reset `iteration` to `0` in frontmatter
5. Set top-level status to `plan`
6. Set plan phase to `active`
7. Tell the user:

```
---
Iterating back to PLAN to revise the spec.

>> Exit this session and start a fresh one, then run:
>>   /pdca:plan <feature-name>

Fresh sessions prevent context drift — PLAN should approach the spec fresh.
---
```

### Important Notes
- The ACT phase is what makes PDCA a cycle, not just a linear process.
- Iterating is not failure — it's the methodology working as intended.
- Each iteration should be focused: fix specific issues, don't re-do everything.
- The Act Log preserves the history of iterations for future reference.
