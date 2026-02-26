---
description: "[P] PLAN - Claude reviews the spec for gaps and risks"
argument-hint: "<feature-name>"
---

# /pdca:review-claude <feature-name>

**PDCA Phase: [P] PLAN (Step 2 of 3)**

Read the spec with fresh eyes and conduct a systematic review.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md` completely.
3. Check the frontmatter `status` field. If it's not `review-claude`, warn the user. Ask if they want to continue anyway.
4. Set the review_claude phase to `active` in the frontmatter.

### Implementation-Aware Review

Before starting the review, check if implementation already exists:

1. Check git log and the codebase for existing code related to this feature.
2. **If no implementation exists**: Review the spec only (standard flow below).
3. **If implementation exists**: Review BOTH the spec quality AND the implementation correctness. For each requirement:
   - Is it implemented? Where? (file + function)
   - Is the implementation correct against the requirement?
   - Are there bugs, race conditions, or missing edge cases in the actual code?
   - Build a completeness table: `| # | Requirement | Implemented? | Gap |`

This hybrid review catches real issues that a spec-only review would miss. Write findings from both the spec review and the implementation audit into the Review Notes section.

### Systematic Review

Read the entire spec and evaluate it across these dimensions. For each, provide specific findings (not generic advice):

**1. Completeness Check**
- Are all requirements testable and specific?
- Are acceptance criteria clear for each requirement?
- Are there requirements implied by the context but not listed?
- Is the technical design sufficient to implement from?

**2. Ambiguity Detection**
- Flag any requirement that could be interpreted multiple ways
- Identify vague terms ("fast", "secure", "user-friendly") that need quantification
- Check for contradictions between requirements

**3. Edge Case Review**
- Are all error paths defined?
- What happens at scale? With empty data? With malicious input?
- Are there race conditions or timing issues?

**4. Security & Privacy**
- Authentication/authorization concerns
- Data validation and sanitization
- Sensitive data handling
- OWASP top 10 relevance

**5. Consistency Check**
- Do the requirements align with the technical design?
- Are there conflicts between edge case handling and requirements?
- Does the scope match what's described in context?

### Output

1. Write all findings to the **Review Notes (Claude)** section of the spec, organized by the 5 dimensions above.
2. Rate each dimension: PASS, NEEDS WORK, or CRITICAL.
3. Provide a summary recommendation: APPROVE (move forward), REVISE (address specific items), or BLOCK (fundamental issues).
4. If APPROVE:
   - Set review_claude phase to `done`
   - Set top-level status to `review-codex`
   - Set review_codex phase to `active`
   - Tell the user the next step, using this exact format:

```
---
Claude review complete. Next up: Codex review (final PLAN step).

>> Exit this session and start a fresh one, then run:
>>   /pdca:review-codex <feature-name>

Fresh sessions prevent context drift — the next step should read the spec cold.
---
```

5. If REVISE or BLOCK:
   - Keep status as `review-claude`
   - List specific items to address
   - Tell user to fix the issues and re-run `/pdca:review-claude <feature-name>` in this same session

### Issues List

When the review finds issues, write a prioritized **Issues to Fix** list at the end of Review Notes (Claude):

```markdown
### Issues to Fix (Priority Order)

1. **[MUST]** [description] — [why it blocks shipping]
2. **[SHOULD]** [description] — [impact if not fixed]
```

Use **[MUST]** for blocking issues and **[SHOULD]** for important but non-blocking ones. This list becomes the fix checklist when REVISE is the outcome.

### Important Notes
- Be genuinely critical. The point is to find problems before implementation.
- Reference specific requirement numbers when noting issues.
- Don't suggest scope additions - only flag issues with what's already planned.
