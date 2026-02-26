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
    
    # Prompt to register
    echo "  Type: $project_type"
    echo "  Description: $project_desc"
    echo ""
    read -p "  Register this project? (Y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]] || [ -z "$REPLY" ]; then
        register_project "$project_name" "$project_dir" "$project_type" "$project_desc"
        echo "${GREEN}  ✓ Registered${NC}"
        REGISTERED_COUNT=$((REGISTERED_COUNT + 1))
    else
        echo "${YELLOW}  ⊘ Skipped${NC}"
    fi
    echo ""
done

# Summary
echo ""
echo "${BOLD}Sync Complete${NC}"
echo "  Found: $FOUND_COUNT projects"
echo "  Registered: $REGISTERED_COUNT new projects"
echo ""

if [ $REGISTERED_COUNT -gt 0 ]; then
    echo "Run ${BOLD}@acp.project-list${NC} to see all registered projects"
fi
