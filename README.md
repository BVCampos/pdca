# PDCA - Plan, Do, Check, Act

A Claude Code plugin that enforces the PDCA quality cycle for spec-driven feature development.

```
  ┌─────────┐
  │  PLAN   │  Build spec, review with Claude & Codex
  └────┬────┘
       ▼
  ┌─────────┐    ┌──────────────────────────────┐
  │   DO    │───>│ implement → verify → fix     │ x max_iterations
  └────┬────┘    │ (self-iterating inner loop)  │
       │         └──────────────────────────────┘
       ▼
  ┌─────────┐
  │  CHECK  │  Cold-eye review (skipped if DO self-verified all PASS)
  └────┬────┘
       ▼
  ┌─────────┐
  │   ACT   │──── iterate back to DO or PLAN
  └────┬────┘     if issues found
       ▼
     done
```

Each phase runs in a fresh session. The spec file is the shared memory between sessions.

## Installation

```bash
# Install the plugin
claude plugin add /path/to/pdca

# Optional: symlink the CLI for terminal use
ln -s /path/to/pdca/scripts/pdca-cli.sh /usr/local/bin/pdca
```

## Quick Start

```bash
# Initialize in your project
pdca init                        # or /pdca:init in Claude Code

# Create a feature spec
pdca new user-authentication     # or /pdca:new user-authentication

# Run each step in a fresh Claude Code session:

# [P] PLAN
/pdca:plan user-authentication
/pdca:review-claude user-authentication
/pdca:review-codex user-authentication

# [D] DO — implements + self-verifies in a loop (up to 3 iterations)
/pdca:do user-authentication

# [C] CHECK — only if DO had remaining issues
/pdca:check user-authentication

# [A] ACT
/pdca:act user-authentication
```

## Commands

### Management (CLI + Claude Code)

| Command | CLI | Claude Code | Purpose |
|---------|-----|-------------|---------|
| Init | `pdca init` | `/pdca:init` | Create `pdca/features/` directory |
| New | `pdca new <name>` | `/pdca:new <name>` | Create feature spec from template |
| List | `pdca list` | `/pdca:list` | List all features + current phase |
| Status | `pdca status <name>` | `/pdca:status <name>` | Detailed phase status |
| Advance | `pdca advance <name>` | `/pdca:advance <name>` | Skip to next phase |

### PDCA Phase Commands (Claude Code only)

| Phase | Command | What it does |
|-------|---------|-------------|
| **[P] PLAN** | `/pdca:plan <name>` | Structured Q&A in 4 rounds to build the spec |
| | `/pdca:review-claude <name>` | Claude reviews spec for gaps and risks |
| | `/pdca:review-codex <name>` | Export spec to Codex for second opinion |
| **[D] DO** | `/pdca:do <name>` | Implement + self-verify loop (up to max_iterations) |
| **[C] CHECK** | `/pdca:check <name>` | Cold-eye verification (optional if DO self-verified) |
| **[A] ACT** | `/pdca:act <name>` | Close, iterate to DO, or iterate to PLAN |

## The PDCA Cycle

### [P] PLAN

Three steps to build a bulletproof spec:

1. **Spec Q&A** (`/pdca:plan`) - 4 rounds: Problem & Scope, Technical Approach, Edge Cases, Integration
2. **Claude Review** (`/pdca:review-claude`) - Fresh-eyes review across 5 dimensions (completeness, ambiguity, edge cases, security, consistency)
3. **Codex Review** (`/pdca:review-codex`) - Export for external second opinion, record feedback

### [D] DO

The engine of the workflow. Within a single session, DO runs a self-iterating loop:

```
Iteration 1:  Implement full plan → verify all requirements → found 2 FAIL
Iteration 2:  Fix the 2 failures → re-verify → found 1 PARTIAL
Iteration 3:  Fix the partial → re-verify → all PASS ✓
```

- `max_iterations` (default: 3) controls how many attempts
- If all PASS: skips CHECK, goes straight to ACT
- If issues remain after max iterations: sends to CHECK for cold-eye review

### [C] CHECK

Optional cold-eye verification in a fresh session. Only runs when DO couldn't resolve everything. Reviews with no implementation bias — acts as the skeptic to catch self-verification blind spots.

### [A] ACT

The phase that makes PDCA a cycle:

- **All PASS** → Close the feature, mark done
- **PARTIAL/FAIL items** → Iterate back to DO with a focused fix list (resets iteration counter)
- **Spec issues** → Iterate back to PLAN to revise requirements

Each iteration is logged in the Act Log for traceability.

## Spec File Format

Feature specs live at `pdca/features/<feature-name>.md` with YAML frontmatter:

```yaml
---
feature: user-authentication
status: do
created: 2026-02-25
complexity: medium
max_iterations: 3
iteration: 1
phases:
  plan: { status: done }
  review_claude: { status: done }
  review_codex: { status: done }
  do: { status: active }
  check: { status: pending }
  act: { status: pending }
---
```

## Design Principles

- **Spec is memory** - Each phase reads the spec fresh; no accumulated context
- **Phase gating** - Commands check frontmatter status before proceeding
- **DO self-iterates** - The inner loop runs autonomously; the outer PDCA loop requires user judgment
- **PDCA is a cycle** - The ACT phase enables continuous improvement through iteration
- **Fresh sessions** - Each phase should run in a new Claude Code session
- **Zero dependencies** - CLI is pure bash; plugin is pure markdown
