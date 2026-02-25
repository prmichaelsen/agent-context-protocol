# Command: project-info

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.project-info` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
**Status**: Experimental

---

**Purpose**: Display detailed information about a specific project from the global registry
**Category**: Project Management
**Frequency**: As Needed

---

## What This Command Does

This command displays comprehensive information about a project registered in `~/.acp/projects.yaml`, including metadata, timestamps, tags, related projects, dependencies, and directory status. It provides a complete view of a project's configuration and current state.

Use this command to understand project details, check project status, view relationships with other projects, and verify project directory existence. It's particularly useful when working with multiple projects in the global workspace to quickly understand project context.

Unlike [`@acp.project-list`](acp.project-list.md:1) which shows all projects in a summary view, `@acp.project-info` focuses on a single project and displays all available metadata in detail.

---

## Prerequisites

- [ ] Global ACP infrastructure initialized (`~/.acp/` exists)
- [ ] Project registry exists (`~/.acp/projects.yaml`)
- [ ] Project is registered in the registry

---

## Steps

### 1. Validate Arguments

Check that project name is provided.

**Actions**:
- Verify project name argument is present
- Show usage if missing

**Expected Outcome**: Project name identified

### 2. Load Registry

Read the project registry file.

**Actions**:
- Get registry path via `get_projects_registry_path()`
- Check if registry file exists
- Parse registry with `yaml_parse()`

**Expected Outcome**: Registry loaded successfully

### 3. Validate Project Exists

Check that the project is in the registry.

**Actions**:
- Use `yaml_has_key()` to check for project
- If not found, list available projects
- Show helpful error message

**Expected Outcome**: Project found in registry

### 4. Extract Project Metadata

Read all project fields from registry.

**Actions**:
- Extract required fields: path, type, description, status, timestamps
- Extract optional fields: tags, related_projects, dependencies
- Check if project is current project (marked with ⭐)

**Expected Outcome**: All metadata extracted

### 5. Display Project Information

Format and display comprehensive project details.

**Actions**:
- Display project name with current indicator
- Show type, status, path, description
- Display timestamps (created, modified, accessed)
- Show tags (if present)
- Show related projects (if present)
- Show dependencies by package manager (npm, pip, cargo, go)

**Expected Outcome**: Complete project information displayed

### 6. Check Directory Status

Verify project directory exists and check ACP status.

**Actions**:
- Expand tilde in path
- Check if directory exists
- Check if AGENT.md exists (ACP project indicator)
- Try to read project version from progress.yaml
- Display status with appropriate indicators (✅/❌/⚠️)

**Expected Outcome**: Directory status reported

---

## Verification

- [ ] Script created and executable
- [ ] Command document created
- [ ] Validates project name argument
- [ ] Loads registry successfully
- [ ] Checks project exists in registry
- [ ] Displays all metadata fields
- [ ] Shows tags, related projects, dependencies (if present)
- [ ] Checks directory existence
- [ ] Detects ACP projects
- [ ] Handles missing projects gracefully
- [ ] Clear formatting with separators
- [ ] No syntax errors

---

## Expected Output

### Files Created
- `agent/scripts/acp.project-info.sh` - Shell script for displaying project info
- `agent/commands/acp.project-info.md` - This command documentation

### Console Output
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 remember-mcp-server ⭐ Current

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: mcp-server
Status: active
Path: ~/.acp/projects/remember-mcp-server

Description:
  Multi-tenant memory system with vector search

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Timestamps:
  Created: 2026-02-20T10:00:00Z
  Last Modified: 2026-02-23T07:00:00Z
  Last Accessed: 2026-02-25T17:00:00Z

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tags:
  - mcp
  - memory
  - vector-search

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Related Projects:
  - remember-mcp

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Dependencies:
  npm:
    - weaviate-client
    - firebase-admin

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Project directory exists
✅ ACP project (AGENT.md found)
   Version: 1.0.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Status Update
- Project information displayed
- Directory status verified

---

## Examples

### Example 1: Show Current Project Info

**Context**: Want to see details about the current project

**Invocation**: `@acp.project-info remember-mcp-server`

**Result**: Displays complete project metadata including type, status, path, description, timestamps, tags, related projects, dependencies, and directory status

### Example 2: Check Project Before Switching

**Context**: Want to verify project exists before switching to it

**Invocation**: `@acp.project-info agentbase-mcp-server`

**Result**: Shows project details, confirms directory exists, shows it's an ACP project with version

### Example 3: Project Not Found

**Context**: Trying to view info for non-existent project

**Invocation**: `@acp.project-info nonexistent-project`

**Result**: Error message with list of available projects

### Example 4: Project Directory Missing

**Context**: Project in registry but directory deleted

**Invocation**: `@acp.project-info old-project`

**Result**: Shows metadata but warns that directory doesn't exist

---

## Related Commands

- [`@acp.project-list`](acp.project-list.md) - List all projects in registry
- [`@acp.project-set`](acp.project-set.md) - Switch to a project
- [`@acp.project-update`](acp.project-update.md) - Update project metadata
- [`@acp.projects-sync`](acp.projects-sync.md) - Sync registry with filesystem

---

## Troubleshooting

### Issue 1: Registry not found

**Symptom**: Error "Project registry not found"

**Cause**: `~/.acp/projects.yaml` doesn't exist

**Solution**: Create a project with `@acp.project-create` to initialize the registry

### Issue 2: Project not found

**Symptom**: Error "Project 'name' not found in registry"

**Cause**: Project not registered or wrong name

**Solution**: Run `@acp.project-list` to see available projects, or use `@acp.projects-sync` to discover unregistered projects

### Issue 3: Directory not found

**Symptom**: Warning "Project directory not found"

**Cause**: Project directory was moved or deleted

**Solution**: Either restore the directory, update the path with `@acp.project-update`, or remove the project with `@acp.project-remove`

### Issue 4: No metadata displayed

**Symptom**: Some fields show as empty or "null"

**Cause**: Optional fields not set in registry

**Solution**: This is normal for optional fields (tags, related_projects, dependencies). Use `@acp.project-update` to add metadata.

---

## Security Considerations

### File Access
- **Reads**: `~/.acp/projects.yaml` (project registry), project directory for AGENT.md and progress.yaml
- **Writes**: None (read-only command)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access any secrets or credentials
- **Credentials**: Does not access credentials

---

## Notes

- This is a read-only command - it doesn't modify the registry
- Expands tilde (~) in project paths automatically
- Checks if project directory exists on filesystem
- Detects ACP projects by presence of AGENT.md
- Tries to read project version from progress.yaml
- Shows current project indicator (⭐) if applicable
- Handles missing optional fields gracefully
- Part of Milestone 7 (Global ACP Project Registry)
- Marked as Experimental until M7 is complete

---

**Namespace**: acp
**Command**: project-info
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
**Status**: Experimental
**Compatibility**: ACP 4.1.1+
**Author**: ACP Project
