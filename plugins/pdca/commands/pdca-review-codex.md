---
name: pdca:review-codex
description: "[P] PLAN - Export spec for Codex review and record feedback"
args: <feature-name>
user-invocable: true
---

# /pdca:review-codex <feature-name>

**PDCA Phase: [P] PLAN (Step 3 of 3)**

Prepare the spec for Codex review via copy-paste and record the feedback.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md` completely.
3. Check the frontmatter `status` field. If it's not `review-codex`, warn the user.
4. Set the review_codex phase to `active` in the frontmatter.

### Export for Codex

1. Format the spec content (everything below the frontmatter) for Codex review.
2. Output the following to the user in a clearly marked code block they can copy:

```
Review the following feature specification for a software project. Analyze it for:

1. Missing requirements or gaps in coverage
2. Ambiguous or contradictory requirements
3. Edge cases not considered
4. Security or performance concerns
5. Implementation risks

Provide specific, actionable feedback organized by category. Reference requirement numbers where applicable.

---

[FULL SPEC CONTENT HERE - everything below the YAML frontmatter]
```

3. Tell the user:
   - "Copy the above and paste it into Codex (or another AI tool) for a second opinion."
   - "When you get the response, paste it back here and I'll record it in the spec."

### Recording Codex Feedback

4. When the user pastes Codex's response back:
   - Write it to the **Review Notes (Codex)** section of the spec file.
   - Briefly summarize the key findings.
   - Note any findings that overlap with Claude's review (from Review Notes (Claude) section).
   - Note any new findings not caught by Claude's review.

5. After recording:
   - Set review_codex phase to `done`
   - Set top-level status to `do`
   - Set do phase to `active`
   - Tell the user the next step, using this exact format:

```
---
PLAN phase complete! All reviews recorded. Moving to DO.

>> Exit this session and start a fresh one, then run:
>>   /pdca:do <feature-name>

Fresh sessions prevent context drift — the next step should read the spec cold.
---
```

### Skip Option

If the user wants to skip the Codex review:
- Confirm they want to skip
- Set review_codex phase to `skipped`
- Set top-level status to `do`
- Set do phase to `active`
- Show the same fresh session reminder above, pointing to `/pdca:do <feature-name>`
