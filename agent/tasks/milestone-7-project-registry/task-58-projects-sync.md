# Task 58: @acp.projects-sync Command

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)
**Estimated Time**: 2-3 hours
**Dependencies**: Task 52 (Registry Infrastructure), Task 53 (Project List)
**Status**: Not Started

---

## Objective

Implement the `@acp.projects-sync` command to discover unregistered projects in `~/.acp/projects/` and add them to the registry. This is the migration tool for existing projects.

---

## Context

**Key Distinction**:
- `@acp.project-list` - Lists projects IN the registry (reads YAML)
- `@acp.projects-sync` - Discovers projects NOT in registry (scans filesystem)

This command is essential for users who already have projects in `~/.acp/projects/` before the registry system was implemented.

---

## Steps

### 1. Create Shell Script

Create `agent/scripts/acp.projects-sync.sh`:

```bash
#!/usr/bin/env bash
# Sync registry with filesystem - discover unregistered projects

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/acp.common.sh"
source "${SCRIPT_DIR}/acp.yaml-parser.sh"

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
        project_type=$(yaml_query "$project_dir/agent/progress.yaml" "project.type" || echo "unknown")
        project_desc=$(yaml_query "$project_dir/agent/progress.yaml" "project.description" || echo "No description")
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
```

### 2. Create Command Document

Create `agent/commands/acp.projects-sync.md`

### 3. Make Executable

```bash
chmod +x agent/scripts/acp.projects-sync.sh
```

---

## Verification

- [ ] Script created and executable
- [ ] Command document created
- [ ] Scans `~/.acp/projects/` directory
- [ ] Detects ACP projects (has agent/progress.yaml)
- [ ] Skips already registered projects
- [ ] Prompts for each unregistered project
- [ ] Registers projects with metadata
- [ ] Summary displayed

---

## Expected Output

```
Scanning for ACP projects in /home/user/.acp/projects...

✓ remember-mcp-server (already registered)
○ agentbase-mcp-server (not registered)
  Type: mcp-server
  Description: Agent base server implementation
  
  Register this project? (Y/n) y
  ✓ Registered

Sync Complete
  Found: 2 projects
  Registered: 1 new projects

Run @acp.project-list to see all registered projects
```

---

**Next Task**: [Task 59: Integration & Testing](task-59-integration-testing.md)
