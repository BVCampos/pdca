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
    echo "    /pdca:check <name>          Cold-eye verification (optional if DO self-verified)"
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

# Main dispatch
case "${1:-}" in
    init)    cmd_init ;;
    new)     cmd_new "${2:-}" ;;
    list)    cmd_list ;;
    status)  cmd_status "${2:-}" ;;
    advance) cmd_advance "${2:-}" ;;
    help|-h|--help) usage ;;
    *)       usage; exit 1 ;;
esac
