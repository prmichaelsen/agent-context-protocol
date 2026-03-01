#!/usr/bin/env bash
# Sync registry with filesystem - discover unregistered projects

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/acp.common.sh"

init_colors

# Get registry path
REGISTRY_PATH=$(get_projects_registry_path)

# Initialize registry if needed
if ! projects_registry_exists; then
    init_projects_registry
    echo "${GREEN}✓${NC} Initialized projects registry"
fi

# Scan ~/.acp/projects/ directory
PROJECTS_DIR="$HOME/.acp/projects"

if [ ! -d "$PROJECTS_DIR" ]; then
    echo "${YELLOW}No projects directory found: $PROJECTS_DIR${NC}"
    exit 0
fi

# Find all directories with agent/progress.yaml (ACP projects)
echo ""
echo "${BOLD}Scanning for ACP projects in $PROJECTS_DIR...${NC}"
echo ""

FOUND_COUNT=0
REGISTERED_COUNT=0

for project_dir in "$PROJECTS_DIR"/*; do
    if [ ! -d "$project_dir" ]; then
        continue
    fi
    
    # Check if it's an ACP project
    if [ ! -f "$project_dir/agent/progress.yaml" ]; then
        continue
    fi
    
    project_name=$(basename "$project_dir")
    FOUND_COUNT=$((FOUND_COUNT + 1))
    
    # Check if already registered
    if project_exists "$project_name"; then
        echo "${GREEN}✓${NC} ${project_name} (already registered)"
        continue
    fi
    
    # Found unregistered project
    echo "${YELLOW}○${NC} ${project_name} (not registered)"
    
    # Read project metadata from progress.yaml
    project_type="unknown"
    project_desc="No description"
    
    if [ -f "$project_dir/agent/progress.yaml" ]; then
        # Source YAML parser
        source_yaml_parser
        
        # Parse the progress.yaml file
        yaml_parse "$project_dir/agent/progress.yaml"
        
        # Query metadata
        project_type=$(yaml_query ".project.type" 2>/dev/null || echo "unknown")
        project_desc=$(yaml_query ".project.description" 2>/dev/null || echo "No description")
        
        # Clean up multiline descriptions
        project_desc=$(echo "$project_desc" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-80)
    fi
    
    # Detect git info
    local git_origin git_branch
    git_origin=$(get_git_origin "$project_dir")
    git_branch=$(get_git_branch "$project_dir")

    # Prompt to register
    echo "  Type: $project_type"
    echo "  Description: $project_desc"
    if [ -n "$git_origin" ]; then
        echo "  Git Origin: $git_origin"
    fi
    echo ""
    read -p "  Register this project? (Y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
        register_project "$project_name" "$project_dir" "$project_type" "$project_desc" "$git_origin" "$git_branch"
        echo "${GREEN}  ✓ Registered${NC}"
        REGISTERED_COUNT=$((REGISTERED_COUNT + 1))
    else
        echo "${YELLOW}  ⊘ Skipped${NC}"
    fi
    echo ""
done

# Backfill git_origin/git_branch for already-registered projects missing them
BACKFILL_COUNT=0

source_yaml_parser
yaml_parse "$REGISTRY_PATH"

PROJECT_NAMES=$(yaml_query ".projects" 2>/dev/null | grep -E "^[a-z0-9-]+:" | sed 's/:$//' || true)

for project_name in $PROJECT_NAMES; do
    existing_origin=$(yaml_query ".projects.${project_name}.git_origin" 2>/dev/null || echo "")
    if [ -n "$existing_origin" ] && [ "$existing_origin" != "null" ]; then
        continue
    fi

    # Resolve project path
    project_path=$(yaml_query ".projects.${project_name}.path" 2>/dev/null || echo "")
    expanded_path="${project_path/#\~/$HOME}"

    if [ ! -d "$expanded_path" ]; then
        continue
    fi

    git_origin=$(get_git_origin "$expanded_path")
    git_branch=$(get_git_branch "$expanded_path")

    if [ -n "$git_origin" ]; then
        yaml_set "projects.${project_name}.git_origin" "$git_origin"
        if [ -n "$git_branch" ]; then
            yaml_set "projects.${project_name}.git_branch" "$git_branch"
        fi
        BACKFILL_COUNT=$((BACKFILL_COUNT + 1))
        echo "${GREEN}✓${NC} ${project_name} (backfilled git_origin)"
    fi
done

if [ $BACKFILL_COUNT -gt 0 ]; then
    yaml_set "last_updated" "$(get_timestamp)"
    yaml_write "$REGISTRY_PATH"
    echo ""
    echo "${GREEN}✓${NC} Backfilled git info for $BACKFILL_COUNT existing projects"
fi

# Summary
echo ""
echo "${BOLD}Sync Complete${NC}"
echo "  Found: $FOUND_COUNT projects"
echo "  Registered: $REGISTERED_COUNT new projects"
echo "  Backfilled: $BACKFILL_COUNT git origins"
echo ""

if [ $REGISTERED_COUNT -gt 0 ] || [ $BACKFILL_COUNT -gt 0 ]; then
    echo "Run ${BOLD}@acp.project-list${NC} to see all registered projects"
fi
