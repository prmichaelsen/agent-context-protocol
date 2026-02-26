#!/usr/bin/env bash
# acp.project-remove.sh - Remove project from registry
# Part of Agent Context Protocol (ACP)

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "$SCRIPT_DIR/acp.common.sh"

# Initialize YAML parser
source_yaml_parser

# Usage information
usage() {
    cat << EOF
Usage: acp.project-remove.sh <project-name> [OPTIONS]

Remove a project from the ACP project registry.

Arguments:
  <project-name>        Name of the project to remove

Options:
  --delete-files        Delete the project directory from filesystem
  -y, --yes            Auto-confirm (skip confirmation prompts)
  -h, --help           Show this help message

Examples:
  # Remove from registry only (keep files)
  ./agent/scripts/acp.project-remove.sh my-project

  # Remove from registry and delete files
  ./agent/scripts/acp.project-remove.sh my-project --delete-files

  # Auto-confirm deletion
  ./agent/scripts/acp.project-remove.sh my-project --delete-files -y

Notes:
  - By default, only removes from registry (files are kept)
  - Use --delete-files to also delete the project directory
  - Confirmation required unless -y flag is used
  - If removing current project, current_project is cleared

EOF
    exit 0
}

# Parse arguments
PROJECT_NAME=""
DELETE_FILES=false
AUTO_CONFIRM=false

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        --delete-files)
            DELETE_FILES=true
            shift
            ;;
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            echo "Run with --help for usage information" >&2
            exit 1
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                echo "Error: Multiple project names provided" >&2
                echo "Usage: acp.project-remove.sh <project-name> [OPTIONS]" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate project name provided
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name is required" >&2
    echo "Usage: acp.project-remove.sh <project-name> [OPTIONS]" >&2
    echo "" >&2
    echo "Run '@acp.project-list' to see available projects" >&2
    exit 1
fi

# Get registry path
REGISTRY_FILE=$(get_projects_registry_path)

# Check if registry exists
if ! projects_registry_exists; then
    echo "Error: Project registry not found at: $REGISTRY_FILE" >&2
    echo "" >&2
    echo "No projects are registered. Nothing to remove." >&2
    exit 1
fi

# Parse registry
yaml_parse "$REGISTRY_FILE"

# Check if project exists
if ! project_exists "$PROJECT_NAME"; then
    echo "Error: Project '$PROJECT_NAME' not found in registry" >&2
    echo "" >&2
    echo "Available projects:" >&2
    
    # List available projects
    local projects
    projects=$(yaml_query ".projects" 2>/dev/null || echo "")
    
    if [ -z "$projects" ]; then
        echo "  (none)" >&2
    else
        echo "$projects" | grep -o '^[^:]*' | while read -r name; do
            [ -n "$name" ] && echo "  - $name" >&2
        done
    fi
    
    exit 1
fi

# Get project details
PROJECT_PATH=$(yaml_query ".projects.$PROJECT_NAME.path" 2>/dev/null || echo "")
PROJECT_TYPE=$(yaml_query ".projects.$PROJECT_NAME.type" 2>/dev/null || echo "unknown")
PROJECT_DESC=$(yaml_query ".projects.$PROJECT_NAME.description" 2>/dev/null || echo "")

# Expand tilde in path
if [ -n "$PROJECT_PATH" ]; then
    PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"
fi

# Check if this is the current project
CURRENT_PROJECT=$(get_current_project)
IS_CURRENT=false
if [ "$CURRENT_PROJECT" = "$PROJECT_NAME" ]; then
    IS_CURRENT=true
fi

# Display project information
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Project to Remove: $PROJECT_NAME"
echo ""
echo "  Type: $PROJECT_TYPE"
[ -n "$PROJECT_DESC" ] && echo "  Description: $PROJECT_DESC"
echo "  Path: $PROJECT_PATH"
echo ""

if [ "$IS_CURRENT" = true ]; then
    echo "  ⚠️  WARNING: This is the current project"
    echo ""
fi

if [ "$DELETE_FILES" = true ]; then
    echo "  🗑️  Files will be DELETED from filesystem"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirmation prompt
if [ "$AUTO_CONFIRM" = false ]; then
    if [ "$DELETE_FILES" = true ]; then
        echo "⚠️  WARNING: This will remove the project from the registry AND delete all files!"
        echo ""
        read -p "Are you sure you want to remove '$PROJECT_NAME' and DELETE its files? (yes/no): " confirm
    else
        echo "This will remove the project from the registry (files will be kept)."
        echo ""
        read -p "Remove '$PROJECT_NAME' from registry? (yes/no): " confirm
    fi
    
    if [ "$confirm" != "yes" ] && [ "$confirm" != "y" ]; then
        echo ""
        echo "❌ Removal cancelled"
        exit 0
    fi
fi

echo ""
echo "Removing project from registry..."

# Remove project from registry using yaml_delete
yaml_delete ".projects.$PROJECT_NAME"

# If this was the current project, clear current_project
if [ "$IS_CURRENT" = true ]; then
    echo "  ✓ Clearing current_project (was: $PROJECT_NAME)"
    yaml_set ".current_project" ""
fi

# Update registry timestamp
yaml_set ".last_updated" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Write changes
yaml_write "$REGISTRY_FILE"

echo "  ✓ Removed from registry"

# Delete files if requested
if [ "$DELETE_FILES" = true ]; then
    if [ -d "$PROJECT_PATH" ]; then
        echo ""
        echo "Deleting project directory..."
        rm -rf "$PROJECT_PATH"
        echo "  ✓ Deleted: $PROJECT_PATH"
    else
        echo ""
        echo "  ⚠️  Project directory not found: $PROJECT_PATH"
        echo "  (Already deleted or moved)"
    fi
fi

# Success message
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Project removed: $PROJECT_NAME"
echo ""

if [ "$DELETE_FILES" = true ]; then
    echo "  Registry: Removed"
    echo "  Files: Deleted"
else
    echo "  Registry: Removed"
    echo "  Files: Kept at $PROJECT_PATH"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show remaining projects
REMAINING_COUNT=$(yaml_query ".projects" 2>/dev/null | grep -c '^[^:]*:' || echo "0")

if [ "$REMAINING_COUNT" -gt 0 ]; then
    echo "Remaining projects: $REMAINING_COUNT"
    echo ""
    echo "Run '@acp.project-list' to see all projects"
else
    echo "No projects remaining in registry"
fi

echo ""
