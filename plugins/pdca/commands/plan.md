---
description: "[P] PLAN - Build feature spec via structured Q&A"
argument-hint: "<feature-name>"
---

# /pdca:plan <feature-name>

**PDCA Phase: [P] PLAN (Step 1 of 3)**

Conduct a deep, structured Q&A session to build a comprehensive feature spec.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md`.
3. If the file doesn't exist, tell the user to run `/pdca:new <name>` first.
4. Check the frontmatter `status` field. If it's not `plan`, warn the user that this feature is not in the plan phase. Ask if they want to continue anyway or run the correct phase command.
5. Set the plan phase to `active` in the frontmatter if not already.

### Planning Q&A (4 Rounds)

Conduct the Q&A in structured rounds. For each round, ask 3-5 targeted questions, wait for user answers, then record the Q&A in the spec file.

**Round 1: Problem & Scope**
- What specific problem does this feature solve?
- Who are the users/personas affected?
- What does success look like?
- What is explicitly out of scope?
- Are there existing patterns in the codebase to follow?

**Round 2: Technical Approach**
- What components/files will be created or modified?
- What is the data flow?
- What dependencies are involved?
- What is the proposed architecture?
- Are there performance considerations?

**Round 3: Edge Cases & Error Handling**
- What happens when inputs are invalid?
- What are the failure modes?
- How should errors be reported to users?
- What are the boundary conditions?
- Are there concurrency concerns?

**Round 4: Integration & Dependencies**
- How does this interact with existing features?
- What external services or APIs are involved?
- What are the testing requirements?
- Are there migration or deployment concerns?
- What documentation needs to be updated?

### After All Rounds

1. Update the spec file sections:
   - **Context**: Synthesize from Round 1 answers
   - **Requirements**: Extract numbered, testable requirements from all rounds
   - **Q&A Log**: Record all questions and answers verbatim under each round
   - **Technical Design**: Synthesize from Round 2 answers
   - **Edge Cases**: Compile from Round 3 answers
2. Set the plan phase to `done` in frontmatter.
3. Set the top-level status to `review-claude`.
4. Set review_claude phase to `active`.
5. Tell the user the next step, using this exact format:

```
---
PLAN step complete. Next up: Claude review (still in PLAN phase).

>> Exit this session and start a fresh one, then run:
>>   /pdca:review-claude <feature-name>

Fresh sessions prevent context drift — the next step should read the spec cold.
---
```

### Important Notes
- Be thorough but not pedantic. Skip questions that clearly don't apply.
- If the user has already filled in parts of the spec, acknowledge that and focus on gaps.
- Always write answers back to the spec file after each round (don't wait until the end).
- The goal is a spec complete enough that someone else could implement from it.
