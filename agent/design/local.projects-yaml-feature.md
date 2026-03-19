# Global ACP Projects Registry

**Concept**: Centralized project metadata tracking for global ACP workspace  
**Created**: 2026-02-23  
**Status**: Proposal  

---

## Overview

This design document describes a centralized project registry system for global ACP workspaces. The `projects.yaml` file in `~/.acp/` will track metadata about all projects in `~/.acp/projects/`, enabling project discovery, relationship mapping, and workspace management. This complements the existing global package system by providing similar management capabilities for projects.

The registry enables agents and users to quickly understand what projects exist, how they relate to each other, and their current status without manually exploring directories.

---

## Problem Statement

Currently, global ACP supports:
- Package installation to `~/.acp/agent/` (via `--global` flag)
- Project creation in `~/.acp/projects/` (via `@acp.project-create`)

However, there's no way to:
- **Discover projects**: List all projects in `~/.acp/projects/` without manual directory exploration
- **Track metadata**: Know project type, status, last activity, or description
- **Understand relationships**: See how projects relate (e.g., server + client pairs)
- **Manage workspace**: Get overview of all projects in global workspace
- **Track dependencies**: Know what external dependencies projects require

**Consequences of not solving**:
- Users must manually explore `~/.acp/projects/` to find projects
- No way to know project status or last activity
- Difficult to understand project relationships
- No centralized workspace management
- Agents cannot discover available projects for context

---

## Solution

Implement a centralized project registry at `~/.acp/projects.yaml` that tracks all projects in the global workspace. The registry will be automatically maintained by ACP commands and provide discovery, metadata tracking, and relationship mapping.

**Key Components**:
1. **Registry File** (`~/.acp/projects.yaml`) - Central metadata store
2. **Auto-Registration** - Projects automatically registered on creation
3. **Management Commands** - List, info, update, remove operations
4. **Relationship Tracking** - Link related projects and dependencies

**Alternative Approaches Considered**:
- **Directory scanning**: Scan `~/.acp/projects/` on demand
  - Rejected: Slow for many projects, no persistent metadata
- **SQLite database**: Use database instead of YAML
  - Rejected: Adds dependency, YAML is human-readable and editable
- **Per-project metadata**: Store metadata in each project
  - Rejected: No centralized view, harder to discover projects

---

## Implementation

### Registry Structure

```yaml
# ~/.acp/projects.yaml
# Tracks ACP projects in global workspace

# Current active project (for context switching)
current_project: remember-mcp-server

projects:
  remember-mcp-server:
    path: ~/.acp/projects/remember-mcp-server
    type: mcp-server
    description: Multi-tenant memory system with vector search
    created: 2026-02-20T10:00:00Z
    last_modified: 2026-02-23T07:00:00Z
    last_accessed: 2026-02-23T07:45:00Z
    status: active
    tags:
      - mcp
      - memory
      - vector-search
    related_projects:
      - remember-mcp
    dependencies:
      npm:
        - weaviate-client
        - firebase-admin
  
  agentbase-mcp-server:
    path: ~/.acp/projects/agentbase-mcp-server
    type: mcp-server
    description: Agent base server implementation
    created: 2026-02-18T14:00:00Z
    last_modified: 2026-02-22T16:00:00Z
    last_accessed: 2026-02-22T16:00:00Z
    status: active
    tags:
      - mcp
      - agents
    related_projects:
      - agentbase-mcp

registry_version: 1.0.0
last_updated: 2026-02-23T07:00:00Z
```

### Command Interfaces

```bash
# List all projects
@acp.project-list [--type TYPE] [--status STATUS] [--tags TAG1,TAG2]

# Show project details
@acp.project-info <project-name>

# Set current/active project (context switching)
@acp.project-set <project-name>

# Update project metadata
@acp.project-update <project-name> [--status STATUS] [--tags TAG1,TAG2]

# Remove project from registry
@acp.project-remove <project-name> [--delete-files]
```

### Integration Points

**@acp.project-create Enhancement**:
```bash
# Automatically register project in registry
register_project() {
  local project_name="$1"
  local project_path="$2"
  local project_type="$3"
  
  # Add to ~/.acp/projects.yaml
  yaml_set "~/.acp/projects.yaml" "projects.${project_name}.path" "$project_path"
  yaml_set "~/.acp/projects.yaml" "projects.${project_name}.type" "$project_type"
  yaml_set "~/.acp/projects.yaml" "projects.${project_name}.created" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  yaml_set "~/.acp/projects.yaml" "projects.${project_name}.last_accessed" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # ... more metadata
  
  # Set as current project if first project or explicitly requested
  if [ "$(yaml_query '~/.acp/projects.yaml' 'current_project')" = "" ]; then
    yaml_set "~/.acp/projects.yaml" "current_project" "$project_name"
  fi
}
```

**@acp.project-set Implementation**:
```bash
# Set current project for context switching
# Usage: @acp.project-set <project-name>
set_current_project() {
  local project_name="$1"
  
  # Validate project exists in registry
  if ! yaml_has_key "~/.acp/projects.yaml" "projects.${project_name}"; then
    echo "Error: Project '${project_name}' not found in registry"
    echo "Run '@acp.project-list' to see available projects"
    return 1
  fi
  
  # Get project path
  local project_path=$(yaml_query "~/.acp/projects.yaml" "projects.${project_name}.path")
  
  # Validate project directory exists
  if [ ! -d "$project_path" ]; then
    echo "Error: Project directory not found: $project_path"
    echo "Project may have been moved or deleted"
    return 1
  fi
  
  # Update current_project in registry
  yaml_set "~/.acp/projects.yaml" "current_project" "$project_name"
  
  # Update last_accessed timestamp
  yaml_set "~/.acp/projects.yaml" "projects.${project_name}.last_accessed" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  
  # Change to project directory
  cd "$project_path" || return 1
  
  # Report success
  echo "✓ Switched to project: ${project_name}"
  echo "  Path: ${project_path}"
  echo "  Type: $(yaml_query "~/.acp/projects.yaml" "projects.${project_name}.type")"
  echo ""
  echo "You are now in the project directory. All file operations will be relative to:"
  echo "  ${project_path}"
  echo ""
  echo "Run '@acp.init' to load project context"
}
```

**Context-Aware File Operations**:
```bash
# Helper function to get current project path
get_current_project_path() {
  local current_project=$(yaml_query "~/.acp/projects.yaml" "current_project")
  if [ -n "$current_project" ]; then
    yaml_query "~/.acp/projects.yaml" "projects.${current_project}.path"
  else
    echo "$(pwd)"  # Fallback to current directory
  fi
}

# All ACP commands can use this to determine working directory
# Example: Reading agent/progress.yaml
local project_path=$(get_current_project_path)
local progress_file="${project_path}/agent/progress.yaml"
```

### Data Schema

```yaml
# Schema for projects.yaml
current_project: string (optional) - Name of currently active project

projects:
  <project-name>:
    path: string (required) - Absolute path to project
    type: string (required) - Project type (mcp-server, web-app, cli-tool, etc.)
    description: string (required) - One-line description
    created: timestamp (required) - ISO 8601 creation time
    last_modified: timestamp (required) - ISO 8601 last modification time
    last_accessed: timestamp (required) - ISO 8601 last access time (updated by @acp.project-set)
    status: enum (required) - active | archived | paused
    tags: array<string> (optional) - Searchable tags
    related_projects: array<string> (optional) - Related project names
    dependencies: object (optional) - External dependencies by package manager

registry_version: string (required) - Schema version
last_updated: timestamp (required) - Last registry update
```

---

## Use Cases

### Use Case 1: List All Projects
```bash
@acp.project-list

# Output:
# 📁 Projects in ~/.acp/projects/ (3)
#
# remember-mcp-server (mcp-server) - Active ⭐ Current
#   Multi-tenant memory system with vector search
#   Last accessed: 2026-02-23
#
# agentbase-mcp-server (mcp-server) - Active
#   Agent base server implementation
#   Last accessed: 2026-02-22
#
# google-calendar-mcp (mcp-server) - Archived
#   Google Calendar integration
#   Last accessed: 2026-02-15
```

### Use Case 2: Switch to Different Project
```bash
@acp.project-set agentbase-mcp-server

# Output:
# ✓ Switched to project: agentbase-mcp-server
#   Path: /home/user/.acp/projects/agentbase-mcp-server
#   Type: mcp-server
#
# You are now in the project directory. All file operations will be relative to:
#   /home/user/.acp/projects/agentbase-mcp-server
#
# Run '@acp.init' to load project context

# Now all commands work in this project context
@acp.init
# Reads /home/user/.acp/projects/agentbase-mcp-server/agent/progress.yaml
```

### Use Case 3: Find Related Projects
```bash
@acp.project-info remember-mcp-server

# Output:
# 📦 remember-mcp-server
# Type: mcp-server
# Status: Active
# Path: ~/.acp/projects/remember-mcp-server
#
# Related Projects:
#   - remember-mcp (client library)
#
# Dependencies:
#   - weaviate-client
#   - firebase-admin
```

---

## Benefits

- **Project Discovery**: Easily find and list all projects in global workspace without manual directory exploration
- **Metadata Tracking**: Know project type, status, last activity at a glance
- **Relationship Mapping**: Understand how projects relate (e.g., server + client pairs)
- **Workspace Management**: Centralized view of all projects in one place
- **Context Switching**: Quickly switch between projects with `@acp.project-set` - all commands automatically use correct project path
- **Agent Awareness**: Agents can discover available projects for context
- **Dependency Tracking**: Know what external dependencies projects require
- **Seamless Navigation**: Change projects without manually `cd`-ing to directories

---

## Trade-offs

- **Additional File to Maintain**: Registry adds another file to manage
  - *Mitigation*: Auto-update registry on all project operations, make it transparent
- **Registry Staleness**: Registry can become stale if projects modified outside ACP
  - *Mitigation*: Provide `@acp.project-sync` command to refresh registry from filesystem
- **Manual Migration**: Existing projects in `~/.acp/projects/` need manual registration
  - *Mitigation*: Provide `@acp.project-scan` command to auto-discover and register existing projects
- **Schema Evolution**: Registry schema may need updates over time
  - *Mitigation*: Include `registry_version` field for schema migrations

---

## Dependencies

**Internal Dependencies**:
- YAML parser (`acp.yaml-parser.sh`) - For reading/writing registry
- Global ACP infrastructure (`~/.acp/`) - Must exist
- `@acp.project-create` command - For auto-registration

**External Dependencies**:
- None (pure bash implementation)

**Related Design Documents**:
- [Global Package Installation](global-package-installation.md) - Similar pattern for packages
- [ACP Package Management System](acp-package-management-system.md) - Manifest pattern inspiration

---

## Testing Strategy

**Unit Tests**:
- Registry initialization (create if missing)
- Project registration (add to registry)
- Project lookup (find by name)
- Project filtering (by type, status, tags)
- Metadata updates (modify existing entries)

**Integration Tests**:
- `@acp.project-create` auto-registers project
- `@acp.project-list` displays all projects correctly
- `@acp.project-info` shows complete metadata
- `@acp.project-update` modifies registry
- `@acp.project-remove` removes from registry

**Edge Cases**:
- Registry file doesn't exist (auto-create)
- Registry file corrupted (validate and repair)
- Project directory deleted but registry entry exists (detect and warn)
- Duplicate project names (prevent or handle)

---

## Migration Path

**For New Users**:
1. Registry auto-created on first `@acp.project-create` in `~/.acp/projects/`
2. All new projects automatically registered
3. No manual steps required

**For Existing Users with Projects**:
1. Run `@acp.project-scan` to discover existing projects in `~/.acp/projects/`
2. Command prompts for metadata for each discovered project
3. Registry populated with all existing projects
4. Future projects auto-registered

**Migration Steps**:
```bash
# 1. Upgrade ACP to version with projects.yaml support
@acp.version-update

# 2. Scan and register existing projects
@acp.project-scan

# 3. Verify registry
@acp.project-list

# 4. Update metadata as needed
@acp.project-update <project-name> --status active --tags mcp,server
```

---

## Future Considerations

**Phase 4: Advanced Features** (future):
- **Workspace visualization**: Graph of project relationships using ASCII art or HTML
- **Project templates**: Create projects from predefined templates
- **Project archiving**: Move inactive projects to archive directory
- **Project search**: Full-text search across project descriptions and tags
- **Project statistics**: Track project activity, size, complexity metrics
- **Multi-workspace support**: Support multiple workspace directories beyond `~/.acp/projects/`
- **Project cloning**: Clone project structure for new projects
- **Project export/import**: Share project configurations between workspaces

**Related Work**:
- Integration with `@acp.init` to show available projects
- Integration with `@acp.resume` to resume work on specific project
- VS Code extension for project browser

---

**Status**: Proposal - Ready for review and feedback  
**Recommendation**: Implement in phases starting with basic registry (Phase 1)  
**Next Steps**:
1. Review and approve design
2. Create milestone for implementation
3. Break into tasks (3 phases, 7-10 hours total)
4. Begin Phase 1 implementation

**Related Documents**:
- [Global Package Installation Design](global-package-installation.md)
- [ACP Package Management System](acp-package-management-system.md)
- Milestone: TBD (create after approval)
