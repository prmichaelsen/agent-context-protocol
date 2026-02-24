#!/usr/bin/env bash
# List projects from registry with filtering

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Parse arguments
TYPE_FILTER=""
STATUS_FILTER=""
TAGS_FILTER=""

while [ $# -gt 0 ]; do
    case "$1" in
        --type)
            TYPE_FILTER="$2"
            shift 2
            ;;
        --status)
            STATUS_FILTER="$2"
            shift 2
            ;;
        --tags)
            TAGS_FILTER="$2"
            shift 2
            ;;
        *)
            echo "${RED}Error: Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Get registry path
REGISTRY_PATH=$(get_projects_registry_path)

# Check if registry exists
if ! projects_registry_exists; then
    echo "${YELLOW}No projects registry found${NC}"
    echo ""
    echo "Create projects with: @acp.project-create"
    exit 0
fi

# Get current project
CURRENT_PROJECT=$(get_current_project)

# Source YAML parser
source_yaml_parser

# Parse registry
yaml_parse "$REGISTRY_PATH"

# Get all project names using yaml_query
PROJECT_NAMES=$(yaml_query ".projects" | grep -E "^[a-z0-9-]+:" | sed 's/:$//' || true)

# Count projects
TOTAL_COUNT=0
DISPLAYED_COUNT=0

# Display header
echo ""
echo "${BOLD}📁 Projects in ~/.acp/projects/${NC}"
echo ""

# Check if any projects exist
if [ -z "$PROJECT_NAMES" ]; then
    echo "${YELLOW}No projects registered yet${NC}"
    echo ""
    echo "Create projects with: @acp.project-create"
    exit 0
fi

# Iterate through projects
for project_name in $PROJECT_NAMES; do
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    # Get project metadata
    project_type=$(yaml_query ".projects.${project_name}.type" || echo "unknown")
    project_status=$(yaml_query ".projects.${project_name}.status" || echo "unknown")
    project_desc=$(yaml_query ".projects.${project_name}.description" || echo "No description")
    project_accessed=$(yaml_query ".projects.${project_name}.last_accessed" || echo "Never")
    
    # Apply filters
    if [ -n "$TYPE_FILTER" ] && [ "$project_type" != "$TYPE_FILTER" ]; then
        continue
    fi
    
    if [ -n "$STATUS_FILTER" ] && [ "$project_status" != "$STATUS_FILTER" ]; then
        continue
    fi
    
    # TODO: Tag filtering (requires array parsing)
    
    # Display project
    DISPLAYED_COUNT=$((DISPLAYED_COUNT + 1))
    
    # Mark current project
    if [ "$project_name" = "$CURRENT_PROJECT" ]; then
        echo "${BOLD}${project_name}${NC} (${project_type}) - ${project_status} ${YELLOW}⭐ Current${NC}"
    else
        echo "${BOLD}${project_name}${NC} (${project_type}) - ${project_status}"
    fi
    
    echo "  ${project_desc}"
    echo "  Last accessed: ${project_accessed}"
    echo ""
done

# Summary
if [ $DISPLAYED_COUNT -eq 0 ]; then
    echo "${YELLOW}No projects match filters${NC}"
else
    echo "${GREEN}Showing ${DISPLAYED_COUNT} of ${TOTAL_COUNT} projects${NC}"
fi
echo ""
