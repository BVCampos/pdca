# PDCA Workflow - Background Knowledge

This skill provides ambient knowledge about the PDCA (Plan-Do-Check-Act) spec-driven development workflow used in this project.

## The PDCA Cycle

The plugin maps directly to the PDCA quality cycle:

### [P] PLAN - Define what to build (3 steps)
1. **Spec Q&A** (`/pdca:plan`) - Build a comprehensive spec through structured Q&A rounds
2. **Claude Review** (`/pdca:review-claude`) - Claude reviews the spec for gaps, ambiguities, and risks
3. **Codex Review** (`/pdca:review-codex`) - External second opinion from Codex via copy-paste bridge

### [D] DO - Build it (self-iterating loop)
4. **Implement + Verify Loop** (`/pdca:do`) - Implements the spec, then self-verifies against every requirement, then fixes failures — repeating up to `max_iterations` times (default: 3). Always advances to CHECK afterward.

### [C] CHECK - Cold-eye review (always runs)
5. **Independent Verification** (`/pdca:check`) - Always runs after DO. A fresh session reviews the code with no implementation bias. DO has inherent self-verification bias, so CHECK provides a necessary independent perspective.

### [A] ACT - Decide what's next
6. **Act** (`/pdca:act`) - Review findings and decide: close the feature, iterate back to DO (fix implementation), or iterate back to PLAN (fix spec)

## The DO Loop

The DO phase is the engine of the workflow. Within a single session it runs:

```
┌─> Implement (or fix) ─> Self-verify against spec ─> All PASS? ─── yes ──> Done
│                                                          │
│                                                          no
│                                                          │
│                                                   iterations left?
│                                                     │         │
│                                                    yes        no
└────────────────────────────────────────────────────┘          │
                                                             Done (with issues)
```

- Iteration 1: Full implementation
- Iteration 2+: Focused fixes on PARTIAL/FAIL items only
- The `iteration` field in frontmatter tracks the count
- The `max_iterations` field sets the ceiling (default: 3)

## Key Principles

- **Each phase runs in a fresh session** - No accumulated context drift
- **The spec file IS the memory** - Located at `pdca/features/<feature-name>.md` in the user's project
- **YAML frontmatter tracks state** - The `status` field determines which step is current
- **Phase gating** - Each command checks the frontmatter status before proceeding
- **Explicit user control** - Phase transitions require user invocation, not auto-advancement
- **PDCA is a cycle** - The ACT phase can loop back to DO or PLAN, making continuous improvement possible
- **DO self-iterates** - The inner loop (implement→verify→fix) runs autonomously; the outer loop (PDCA) requires user judgment
- **Implementation-aware** - When code already exists, plan and review phases adapt by auditing what's built before spec'ing what's missing
- **Decisions surface to the user** - Autonomous phases pause when they discover design decisions that need human judgment

## Spec File Location

Feature specs live at: `pdca/features/<feature-name>.md`

The directory is initialized with `/pdca:init` or `pdca init` from the CLI.

## CLI Integration

The `pdca` CLI (bash script) handles file operations: `init`, `new`, `list`, `status`, `advance`.

Slash commands handle the intelligent work: planning Q&A, reviews, implementation loops, verification, and acting on findings.

## Ralph Loop Integration

The DO phase can optionally use Ralph Loop for the implementation step. The user explicitly runs the Ralph Loop command — the PDCA plugin does not auto-invoke it. If Ralph Loop is not available, DO handles implementation directly within its own loop.

## Codex Integration

The review-codex step (part of PLAN) formats the spec for clipboard export and provides a suggested Codex prompt. When the user pastes Codex's response back, it gets recorded in the spec's Review Notes (Codex) section.
