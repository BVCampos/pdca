#!/usr/bin/env bash
set -euo pipefail

# PDCA CLI - Plan, Do, Check, Act development workflow manager
# Usage: pdca <command> [args]

PDCA_DIR="pdca/features"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/spec-template.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo "Usage: pdca <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init                  Initialize pdca/features/ directory"
    echo "  new <feature-name>    Create a new feature spec from template"
    echo "  list                  List all features and their current phase"
    echo "  status <feature-name> Show detailed phase status for a feature"
    echo "  advance <feature-name> Manually advance to the next phase"
    echo "  run <feature-name>    Run the PDCA cycle (auto-chains autonomous phases)"
    echo ""
    echo "PDCA Cycle (use in Claude Code):"
    echo ""
    echo "  [P] PLAN"
    echo "    /pdca:plan <name>           Build spec via structured Q&A"
    echo "    /pdca:review-claude <name>  Claude reviews the spec"
    echo "    /pdca:review-codex <name>   Export spec for Codex review"
    echo "  [D] DO"
    echo "    /pdca:do <name>             Implement + self-verify loop (up to N iterations)"
    echo "  [C] CHECK"
    echo "    /pdca:check <name>          Cold-eye verification (always runs after DO)"
    echo "  [A] ACT"
    echo "    /pdca:act <name>            Act on findings, iterate or close"
}

# Extract a frontmatter field value from a spec file
get_field() {
    local file="$1"
    local field="$2"
    awk -v field="$field" '
        /^---$/ { count++; next }
        count == 1 && $0 ~ "^" field ":" {
            sub("^" field ":[ ]*", "")
            print
            exit
        }
    ' "$file"
}

# Extract phase status from frontmatter
get_phase_status() {
    local file="$1"
    local phase="$2"
    awk -v phase="$phase" '
        /^---$/ { count++; next }
        count == 1 && $0 ~ "^  " phase ":" {
            gsub(/.*status: /, "")
            gsub(/[^a-z]/, "")
            print
            exit
        }
    ' "$file"
}

# Update the top-level status field in frontmatter
set_status() {
    local file="$1"
    local new_status="$2"
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^status: .*/status: ${new_status}/" "$file"
    else
        sed -i "s/^status: .*/status: ${new_status}/" "$file"
    fi
}

# Update a phase's status in frontmatter
set_phase_status() {
    local file="$1"
    local phase="$2"
    local new_status="$3"
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^  ${phase}: { status: [a-z]* }/  ${phase}: { status: ${new_status} }/" "$file"
    else
        sed -i "s/^  ${phase}: { status: [a-z]* }/  ${phase}: { status: ${new_status} }/" "$file"
    fi
}

# Phase order: Plan has 3 sub-steps, then Do, Check, Act
# Keys match frontmatter (underscores), labels match status field (hyphens)
PHASES=("plan" "review_claude" "review_codex" "do" "check" "act")
PHASE_LABELS=("plan" "review-claude" "review-codex" "do" "check" "act")
PDCA_GROUPS=("P" "P" "P" "D" "C" "A")

# Get next phase after current
next_phase() {
    local current="$1"
    for i in "${!PHASE_LABELS[@]}"; do
        if [[ "${PHASE_LABELS[$i]}" == "$current" ]]; then
            local next_idx=$((i + 1))
            if [[ $next_idx -lt ${#PHASES[@]} ]]; then
                echo "${PHASE_LABELS[$next_idx]}"
                return
            else
                echo "done"
                return
            fi
        fi
    done
    echo ""
}

# Map phase label to frontmatter key
phase_to_key() {
    local label="$1"
    echo "$label" | tr '-' '_'
}

# Get the PDCA group for a phase label
pdca_group_for() {
    local label="$1"
    for i in "${!PHASE_LABELS[@]}"; do
        if [[ "${PHASE_LABELS[$i]}" == "$label" ]]; then
            echo "${PDCA_GROUPS[$i]}"
            return
        fi
    done
}

# Get the command name for a phase label
command_for() {
    local label="$1"
    echo "/pdca:${label}"
}

cmd_init() {
    if [[ -d "$PDCA_DIR" ]]; then
        echo -e "${YELLOW}pdca/features/ already exists.${NC}"
    else
        mkdir -p "$PDCA_DIR"
        echo -e "${GREEN}Created pdca/features/ directory.${NC}"
    fi
}

cmd_new() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: pdca new <feature-name>${NC}"
        exit 1
    fi

    if [[ ! -d "$PDCA_DIR" ]]; then
        echo -e "${RED}Run 'pdca init' first to create the features directory.${NC}"
        exit 1
    fi

    local spec_file="$PDCA_DIR/${name}.md"
    if [[ -f "$spec_file" ]]; then
        echo -e "${RED}Feature '${name}' already exists at ${spec_file}${NC}"
        exit 1
    fi

    local today
    today=$(date +%Y-%m-%d)

    sed "s/FEATURE_NAME/${name}/g; s/CREATED_DATE/${today}/g" "$TEMPLATE" > "$spec_file"
    echo -e "${GREEN}Created feature spec: ${spec_file}${NC}"
    echo -e "Next step: run ${CYAN}/pdca:plan ${name}${NC} in Claude Code"
}

cmd_list() {
    if [[ ! -d "$PDCA_DIR" ]]; then
        echo -e "${RED}No pdca/features/ directory. Run 'pdca init' first.${NC}"
        exit 1
    fi

    local count=0
    echo -e "${BOLD}PDCA Features${NC}"
    echo "─────────────────────────────────────────────────"

    for f in "$PDCA_DIR"/*.md; do
        [[ -f "$f" ]] || continue
        count=$((count + 1))
        local name
        name=$(basename "$f" .md)
        local status
        status=$(get_field "$f" "status")
        local complexity
        complexity=$(get_field "$f" "complexity")

        local color="$NC"
        local group=""
        case "$status" in
            plan|review-claude|review-codex) color="$YELLOW"; group="[P]" ;;
            do)    color="$BLUE"; group="[D]" ;;
            check) color="$CYAN"; group="[C]" ;;
            act)   color="$GREEN"; group="[A]" ;;
            done)  color="$GREEN"; group="[*]" ;;
        esac

        printf "  %-28s ${color}%s %-18s${NC} %s\n" "$name" "$group" "$status" "$complexity"
    done

    if [[ $count -eq 0 ]]; then
        echo -e "  ${YELLOW}No features found. Run 'pdca new <name>' to create one.${NC}"
    fi
}

cmd_status() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: pdca status <feature-name>${NC}"
        exit 1
    fi

    local spec_file="$PDCA_DIR/${name}.md"
    if [[ ! -f "$spec_file" ]]; then
        echo -e "${RED}Feature '${name}' not found at ${spec_file}${NC}"
        exit 1
    fi

    local status
    status=$(get_field "$spec_file" "status")
    local complexity
    complexity=$(get_field "$spec_file" "complexity")
    local created
    created=$(get_field "$spec_file" "created")

    echo -e "${BOLD}Feature: ${name}${NC}"
    echo "─────────────────────────────────────────────────"
    local iteration
    iteration=$(get_field "$spec_file" "iteration")
    local max_iter
    max_iter=$(get_field "$spec_file" "max_iterations")

    echo -e "  Created:    ${created}"
    echo -e "  Complexity: ${complexity}"
    echo -e "  Status:     ${status}"
    if [[ "$status" == "do" || "$status" == "check" || "$status" == "act" ]]; then
        echo -e "  Iteration:  ${iteration} / ${max_iter}"
    fi
    echo ""

    local prev_group=""
    for i in "${!PHASES[@]}"; do
        local phase_key="${PHASES[$i]}"
        local phase_label="${PHASE_LABELS[$i]}"
        local group="${PDCA_GROUPS[$i]}"
        local ps
        ps=$(get_phase_status "$spec_file" "$phase_key")

        # Print PDCA group header when it changes
        if [[ "$group" != "$prev_group" ]]; then
            local group_name=""
            case "$group" in
                P) group_name="PLAN" ;;
                D) group_name="DO" ;;
                C) group_name="CHECK" ;;
                A) group_name="ACT" ;;
            esac
            echo -e "  ${BOLD}[${group}] ${group_name}${NC}"
            prev_group="$group"
        fi

        local icon="  "
        local color="$NC"
        case "$ps" in
            done)    icon="[x]"; color="$GREEN" ;;
            active)  icon="[>]"; color="$YELLOW" ;;
            pending) icon="[ ]"; color="$NC" ;;
            skipped) icon="[-]"; color="$RED" ;;
        esac

        printf "      ${color}%s %-20s %s${NC}\n" "$icon" "$phase_label" "$ps"
    done
}

cmd_advance() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: pdca advance <feature-name>${NC}"
        exit 1
    fi

    local spec_file="$PDCA_DIR/${name}.md"
    if [[ ! -f "$spec_file" ]]; then
        echo -e "${RED}Feature '${name}' not found at ${spec_file}${NC}"
        exit 1
    fi

    local current_status
    current_status=$(get_field "$spec_file" "status")

    if [[ "$current_status" == "done" ]]; then
        echo -e "${GREEN}Feature '${name}' is already done.${NC}"
        exit 0
    fi

    local current_key
    current_key=$(phase_to_key "$current_status")
    set_phase_status "$spec_file" "$current_key" "done"

    local next
    next=$(next_phase "$current_status")

    if [[ "$next" == "done" ]]; then
        set_status "$spec_file" "done"
        echo -e "${GREEN}Feature '${name}' is now complete!${NC}"
    else
        set_status "$spec_file" "$next"
        local next_key
        next_key=$(phase_to_key "$next")
        set_phase_status "$spec_file" "$next_key" "active"
        local next_group
        next_group=$(pdca_group_for "$next")
        echo -e "${GREEN}Advanced '${name}' from ${current_status} -> ${next} [${next_group}]${NC}"
        echo -e "Next: run ${CYAN}$(command_for "$next") ${name}${NC} in Claude Code"
    fi
}

# Check if a phase is autonomous (no user input needed)
is_autonomous() {
    local phase="$1"
    case "$phase" in
        review-claude|do|check) return 0 ;;
        *) return 1 ;;
    esac
}

# Build the prompt for an autonomous phase
build_prompt() {
    local phase="$1"
    local name="$2"
    local spec_file="$PDCA_DIR/${name}.md"

    # Read the full spec content
    local spec_content
    spec_content=$(cat "$spec_file")

    case "$phase" in
        review-claude)
            cat <<PROMPT
You are running the PDCA review-claude phase for feature "${name}".

Read the following spec and perform a systematic review across 5 dimensions:
1. Completeness Check
2. Ambiguity Detection
3. Edge Case Review
4. Security & Privacy
5. Consistency Check

Write your findings to the "Review Notes (Claude)" section of the spec file at pdca/features/${name}.md.
Rate each dimension: PASS, NEEDS WORK, or CRITICAL.
Provide a summary recommendation: APPROVE, REVISE, or BLOCK.

If APPROVE: set review_claude phase to done, set status to review-codex, set review_codex to active.
If REVISE or BLOCK: keep status as review-claude and list items to fix.

Here is the current spec:

${spec_content}
PROMPT
            ;;
        do)
            cat <<PROMPT
You are running the PDCA do phase for feature "${name}".

Read the spec at pdca/features/${name}.md and implement the feature in a self-iterating loop:
1. Read and internalize the spec (context, requirements, technical design, edge cases, review notes)
2. Explore the codebase to understand current architecture
3. Create an implementation plan and write it to the Implementation Log
4. Loop up to max_iterations times: implement/fix → self-verify each requirement → if all PASS break, else fix and repeat
5. Update the iteration counter in frontmatter after each iteration
6. When done: set do phase to done. If all PASS, skip check and set status to act. If issues remain, set status to check.

Here is the current spec:

${spec_content}
PROMPT
            ;;
        check)
            cat <<PROMPT
You are running the PDCA check phase for feature "${name}".

This is a cold-eye verification — you have NO context from implementation. Read everything fresh.

1. Read the spec at pdca/features/${name}.md
2. Read the Implementation Log to see what was done
3. Read the Verification Results from DO's self-verification
4. For each requirement: locate the code, verify correctness, check edge cases, rate PASS/PARTIAL/FAIL
5. Spot-check items DO marked PASS (catch self-verification bias)
6. Run tests if possible
7. Append a "Cold-Eye Review" section to Verification Results
8. Set check to done, status to act, act to active

Here is the current spec:

${spec_content}
PROMPT
            ;;
    esac
}

cmd_run() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "${RED}Usage: pdca run <feature-name>${NC}"
        exit 1
    fi

    local spec_file="$PDCA_DIR/${name}.md"
    if [[ ! -f "$spec_file" ]]; then
        echo -e "${RED}Feature '${name}' not found at ${spec_file}${NC}"
        exit 1
    fi

    # Check claude is available
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}claude CLI not found. Install Claude Code first.${NC}"
        exit 1
    fi

    while true; do
        local status
        status=$(get_field "$spec_file" "status")

        if [[ "$status" == "done" ]]; then
            echo ""
            echo -e "${GREEN}${BOLD}Feature '${name}' is complete! Full PDCA cycle done.${NC}"
            break
        fi

        local group
        group=$(pdca_group_for "$status")

        echo ""
        echo -e "${BOLD}─── [${group}] ${status} ───${NC}"

        if is_autonomous "$status"; then
            echo -e "${CYAN}Running autonomously via claude...${NC}"
            echo ""

            local prompt
            prompt=$(build_prompt "$status" "$name")

            # Run claude in non-interactive mode with --print flag
            if claude -p "$prompt" --allowedTools "Edit,Write,Read,Glob,Grep,Bash" 2>&1; then
                # Re-read status — claude should have advanced it
                local new_status
                new_status=$(get_field "$spec_file" "status")
                if [[ "$new_status" == "$status" ]]; then
                    echo -e "${YELLOW}Phase did not advance. Claude may need manual intervention.${NC}"
                    echo -e "Run ${CYAN}/pdca:${status} ${name}${NC} in Claude Code interactively."
                    break
                fi
                echo -e "${GREEN}Phase ${status} complete.${NC}"
                # Continue the loop — will pick up the next phase
            else
                echo -e "${RED}Claude exited with an error.${NC}"
                echo -e "Run ${CYAN}/pdca:${status} ${name}${NC} in Claude Code interactively."
                break
            fi
        else
            # Interactive phase — hand off to user
            echo -e "${YELLOW}This phase needs your input.${NC}"
            echo -e "Opening interactive Claude Code session..."
            echo ""

            # Run claude interactively with the slash command as initial prompt
            claude -p "/pdca:${status} ${name}" --resume 2>&1 || true

            # Re-read status after interactive session
            local new_status
            new_status=$(get_field "$spec_file" "status")
            if [[ "$new_status" == "$status" ]]; then
                echo ""
                echo -e "${YELLOW}Phase did not advance. Run 'pdca run ${name}' again when ready.${NC}"
                break
            fi
            echo -e "${GREEN}Phase ${status} complete.${NC}"
            # Continue the loop
        fi
    done
}

# Main dispatch
case "${1:-}" in
    init)    cmd_init ;;
    new)     cmd_new "${2:-}" ;;
    list)    cmd_list ;;
    status)  cmd_status "${2:-}" ;;
    advance) cmd_advance "${2:-}" ;;
    run)     cmd_run "${2:-}" ;;
    help|-h|--help) usage ;;
    *)       usage; exit 1 ;;
esac
