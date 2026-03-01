#!/usr/bin/env bash
# acp.projects-restore.sh - Restore/clone projects from registry git origins
# Part of Agent Context Protocol (ACP)
# Usage: ./acp.projects-restore.sh [--dry-run] [--install-acp]

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/acp.common.sh"

init_colors

# Parse arguments
DRY_RUN=false
INSTALL_ACP=false

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --install-acp)
            INSTALL_ACP=true
            shift
            ;;
        *)
            echo "${RED}Error: Unknown option: $1${NC}"
            echo ""
            echo "Usage: $0 [--dry-run] [--install-acp]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Preview what would be cloned without cloning"
            echo "  --install-acp   Run ACP install after cloning each project"
            exit 1
            ;;
    esac
done

# Get registry path
REGISTRY_PATH=$(get_projects_registry_path)

# Check if registry exists
if ! projects_registry_exists; then
    echo "${RED}Error: No projects registry found at $REGISTRY_PATH${NC}"
    exit 1
fi

# Source YAML parser
source_yaml_parser

# Parse registry
yaml_parse "$REGISTRY_PATH"

# Get all project names
PROJECT_NAMES=$(yaml_query ".projects" 2>/dev/null | grep -E "^[a-z0-9-]+:" | sed 's/:$//' || true)

if [ -z "$PROJECT_NAMES" ]; then
    echo "${YELLOW}No projects in registry${NC}"
    exit 0
fi

echo ""
if $DRY_RUN; then
    echo "${BOLD}Restore Preview (dry run)${NC}"
else
    echo "${BOLD}Restoring projects from registry...${NC}"
fi
echo ""

CLONE_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

for project_name in $PROJECT_NAMES; do
    project_status=$(yaml_query ".projects.${project_name}.status" 2>/dev/null || echo "active")
    project_path=$(yaml_query ".projects.${project_name}.path" 2>/dev/null || echo "")
    git_origin=$(yaml_query ".projects.${project_name}.git_origin" 2>/dev/null || echo "")
    git_branch=$(yaml_query ".projects.${project_name}.git_branch" 2>/dev/null || echo "")

    # Expand tilde
    expanded_path="${project_path/#\~/$HOME}"

    # Skip archived projects
    if [ "$project_status" = "archived" ]; then
        echo "${YELLOW}⊘${NC} ${project_name} (archived, skipping)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    # Skip projects with no git origin
    if [ -z "$git_origin" ] || [ "$git_origin" = "null" ]; then
        echo "${YELLOW}⊘${NC} ${project_name} (no git_origin, skipping)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    # Skip existing directories
    if [ -d "$expanded_path" ]; then
        echo "${GREEN}✓${NC} ${project_name} (already exists)"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    # This project needs cloning
    if $DRY_RUN; then
        echo "${BLUE}○${NC} ${project_name}"
        echo "  Would clone: ${git_origin}"
        if [ -n "$git_branch" ] && [ "$git_branch" != "null" ]; then
            echo "  Branch: ${git_branch}"
        fi
        echo "  Into: ${expanded_path}"
        echo ""
        CLONE_COUNT=$((CLONE_COUNT + 1))
        continue
    fi

    echo "${BLUE}○${NC} ${project_name} - cloning..."

    # Ensure parent directory exists
    mkdir -p "$(dirname "$expanded_path")"

    # Build clone command
    clone_args=()
    if [ -n "$git_branch" ] && [ "$git_branch" != "null" ]; then
        # Check if branch exists on remote before using it
        if git ls-remote --heads "$git_origin" "$git_branch" 2>/dev/null | grep -q "$git_branch"; then
            clone_args+=(--branch "$git_branch")
        else
            echo "  ${YELLOW}Warning: Branch '$git_branch' not found on remote, using default${NC}"
        fi
    fi

    if git clone "${clone_args[@]}" "$git_origin" "$expanded_path" 2>/dev/null; then
        echo "  ${GREEN}✓ Cloned${NC}"
        CLONE_COUNT=$((CLONE_COUNT + 1))

        # Run ACP install if requested
        if $INSTALL_ACP; then
            install_script="${SCRIPT_DIR}/acp.install.sh"
            if [ -f "$install_script" ]; then
                echo "  Installing ACP..."
                if (cd "$expanded_path" && bash "$install_script") 2>/dev/null; then
                    echo "  ${GREEN}✓ ACP installed${NC}"
                else
                    echo "  ${YELLOW}Warning: ACP install failed${NC}"
                fi
            fi
        fi
    else
        echo "  ${RED}✗ Clone failed${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
    echo ""
done

# Summary
echo ""
echo "${BOLD}Restore Complete${NC}"
if $DRY_RUN; then
    echo "  Would clone: $CLONE_COUNT projects"
else
    echo "  Cloned: $CLONE_COUNT projects"
fi
echo "  Skipped: $SKIP_COUNT projects"
if [ $ERROR_COUNT -gt 0 ]; then
    echo "  ${RED}Errors: $ERROR_COUNT${NC}"
fi
echo ""
