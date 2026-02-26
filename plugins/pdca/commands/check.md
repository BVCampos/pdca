---
description: "[C] CHECK - Cold-eye verification of remaining issues (optional)"
argument-hint: "<feature-name>"
---

# /pdca:check <feature-name>

**PDCA Phase: [C] CHECK**

Fresh-session verification of the implementation. This phase always runs after DO — even when DO reports all requirements as PASS.

DO has inherent self-verification bias (it just wrote the code). CHECK provides an independent perspective that consistently catches issues DO misses.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md` completely.
3. Check the frontmatter `status` field. If it's not `check`, warn the user.
4. Set the check phase to `active` in the frontmatter.

### Review DO's Work

1. Read the **Implementation Log** to understand what was done and how many iterations were used.
2. Read the **Verification Results** from DO's self-verification to see what's PARTIAL/FAIL.
3. Focus your review on the items DO couldn't resolve, plus a spot-check of items DO marked PASS (to catch self-verification bias).

### Cold-Eye Verification

For each numbered requirement in the Requirements section:

1. **Locate the implementation** — Find the code. Read the actual files.
2. **Check correctness** — Does the code satisfy the requirement as written?
3. **Check edge cases** — Are the edge cases from the spec handled?
4. **Check review items** — Were Claude and Codex review findings addressed?
5. **Rate it**:
   - **PASS** — Fully implemented and correct
   - **PARTIAL** — Implemented but with gaps
   - **FAIL** — Not implemented or incorrect

### Test Verification

6. Run tests if possible (ask the user for the test command if needed).
7. Record results.

### Output

8. Write the cold-eye verification report to the **Verification Results** section (append, don't overwrite DO's results):

```markdown
### Cold-Eye Review — YYYY-MM-DD

**Overall result:** PASS / PARTIAL / FAIL

| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 1 | [text] | PASS | [details] |
| 2 | [text] | PARTIAL | [what's still missing] |

### Test Results
- Tests passing: X/Y

### Items Changed from DO's Assessment
- Req #3: DO said PASS, CHECK says PARTIAL — [reason]

### Outstanding Issues
- [list any remaining problems]
```

### Completion

9. Set check phase to `done`.
10. Set top-level status to `act`.
11. Set act phase to `active`.
12. Tell the user:

```
---
CHECK phase complete. Moving to ACT.

>> Exit this session and start a fresh one, then run:
>>   /pdca:act <feature-name>

Fresh sessions prevent context drift — ACT should evaluate the findings objectively.
---
```

### Important Notes
- Your job is to be the skeptic. DO was biased toward passing its own work.
- If you disagree with DO's assessment on a requirement, say so and explain why.
- Read actual code — don't trust the implementation log.
- If you can't find the implementation for a requirement, it's a FAIL.
