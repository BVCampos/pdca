---
description: "Generate a PR-ready summary from a completed (or in-progress) feature spec"
argument-hint: "<feature-name>"
---

# /pdca:summary <feature-name>

Generate a concise summary of a PDCA feature suitable for PR descriptions, changelogs, or team updates.

## Instructions

### Setup
1. Parse the feature name from the argument. If missing, ask the user.
2. Read `pdca/features/<feature-name>.md` completely.
3. The feature does not need to be `done` — summaries can be generated at any phase.

### Extract and Format

Read the spec and produce a summary with these sections:

**1. Title line** — one sentence describing the feature.

**2. Changes** — bullet list of what was implemented, derived from the Requirements and Implementation Log sections. Group by area if there are many items.

**3. Issues Found & Fixed** — count of issues found during review and check phases, with highlights of the most significant ones (race conditions, security fixes, etc.). Skip this section if no issues were found.

**4. Files Changed** — list from the Implementation Log. If not available, note that.

**5. Test Results** — pass/fail counts from Verification Results. If not available, note that.

### Output Format

Output the summary in two formats:

**Short format** (for PR titles and one-liners):
```
<one-line summary of what this feature does>
```

**Full format** (for PR body / changelog):
```markdown
## Summary
<2-3 bullet points of key changes>

## Details
<grouped list of specific changes>

## Review Findings
- Issues found: N (N fixed, N deferred)
- Key fixes: <list significant fixes>

## Test Results
- X/Y tests passing

## Files Changed
- <file list>
```

### Important Notes
- Be concise — this is a summary, not the full spec.
- Focus on what changed and why, not on the PDCA process itself.
- If the feature is still in progress, note the current phase and what's remaining.
- Don't include internal PDCA details (iteration counts, phase transitions) — those are process artifacts, not user-facing changes.
