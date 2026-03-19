# Task 53: @acp.project-list Command

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 52 (Registry Infrastructure)  
**Status**: Not Started  

---

## Objective

Implement the `@acp.project-list` command to display all registered projects from `~/.acp/projects.yaml` with filtering capabilities by type, status, and tags.

---

## Context

This command provides the primary interface for discovering what projects exist in the global workspace. It reads the registry (not the filesystem) and displays projects that have been registered via `@acp.project-create` or `@acp.project-scan`.

**Key Distinction**: This command lists projects IN the registry, while `@acp.project-scan` (Task 58) discovers projects NOT YET in the registry.  

---

## Steps

### 1. Create Shell Script

Create `agent/scripts/acp.project-list.sh`:

```bash
#!/usr/bin/env bash
# List projects from registry with filtering

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/acp.common.sh"
source "${SCRIPT_DIR}/acp.yaml-parser.sh"

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

# Parse registry
yaml_parse "$REGISTRY_PATH"

# Get all project names
PROJECT_NAMES=$(yaml_query "$REGISTRY_PATH" "projects" | grep -E "^[a-z0-9-]+:" | sed 's/:$//')

# Count projects
TOTAL_COUNT=0
DISPLAYED_COUNT=0

# Display header
echo ""
echo "${BOLD}📁 Projects in ~/.acp/projects/${NC}"
echo ""

# Iterate through projects
for project_name in $PROJECT_NAMES; do
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    # Get project metadata
    project_type=$(yaml_query "$REGISTRY_PATH" "projects.${project_name}.type")
    project_status=$(yaml_query "$REGISTRY_PATH" "projects.${project_name}.status")
    project_desc=$(yaml_query "$REGISTRY_PATH" "projects.${project_name}.description")
    project_accessed=$(yaml_query "$REGISTRY_PATH" "projects.${project_name}.last_accessed")
    
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
```

### 2. Create Command Document

Create `agent/commands/acp.project-list.md`:

```markdown
# Command: project-list

> **🤖 Agent Directive**: Run `./agent/scripts/acp.project-list.sh` to list all registered projects.

**Namespace**: acp  
**Version**: 1.0.0  
**Purpose**: List all projects registered in global workspace  
**Category**: Utility  
**Frequency**: As Needed  

---

## What This Command Does

Lists all projects registered in `~/.acp/projects.yaml` with their metadata. Shows project type, status, description, and last accessed time. Highlights the current active project.

**Note**: This lists projects IN the registry. Use `@acp.project-scan` to discover projects NOT YET registered.  

---

## Arguments

- `--type <type>` - Filter by project type (mcp-server, web-app, etc.)
- `--status <status>` - Filter by status (active, archived, paused)
- `--tags <tag1,tag2>` - Filter by tags (comma-separated)

---

## Steps

1. Run shell script with optional filters
2. Display formatted project list
3. Show current project with ⭐ marker

---

## Examples

### Example 1: List All Projects
\`\`\`bash
@acp.project-list
\`\`\`

### Example 2: Filter by Type
\`\`\`bash
@acp.project-list --type mcp-server
\`\`\`

### Example 3: Filter by Status
\`\`\`bash
@acp.project-list --status active
\`\`\`

---

## Related Commands

- [`@acp.project-set`](acp.project-set.md) - Switch to project
- [`@acp.project-scan`](acp.project-scan.md) - Discover unregistered projects
- [`@acp.project-info`](acp.project-info.md) - Show project details
```

### 3. Make Script Executable

```bash
chmod +x agent/scripts/acp.project-list.sh
```

### 4. Test Command

```bash
# Test with empty registry
./agent/scripts/acp.project-list.sh

# Test with projects (after Task 52 functions are available)
```

---

## Verification

- [ ] `acp.project-list.sh` created
- [ ] Script is executable
- [ ] `acp.project-list.md` command document created
- [ ] Script handles empty registry gracefully
- [ ] Script displays projects with correct formatting
- [ ] Current project marked with ⭐
- [ ] Filtering works (--type, --status)
- [ ] No syntax errors (`bash -n acp.project-list.sh`)

---

## Expected Output

### Example Output
```
📁 Projects in ~/.acp/projects/

remember-mcp-server (mcp-server) - active ⭐ Current
  Multi-tenant memory system with vector search
  Last accessed: 2026-02-23T07:45:00Z

agentbase-mcp-server (mcp-server) - active
  Agent base server implementation
  Last accessed: 2026-02-22T16:00:00Z

Showing 2 of 2 projects
```

---

**Next Task**: [Task 54: @acp.project-set Command](task-54-project-set.md)  
