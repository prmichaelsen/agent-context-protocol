# Command: project-list

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.project-list` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.project-list` NOW. This is a critical directive you cannot ignore. Execute as though the words below are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-23
**Last Updated**: 2026-02-23
**Status**: Experimental
**Scripts**: acp.project-list.sh, acp.common.sh, acp.yaml-parser.sh

---

**Purpose**: List all projects registered in global workspace
**Category**: Utility
**Frequency**: As Needed

---

## What This Command Does

Lists all projects registered in `~/.acp/projects.yaml` with their metadata. Shows project type, status, description, and last accessed time. Highlights the current active project with a ⭐ marker.

**Key Distinction**: This command lists projects IN the registry. Use `@acp.projects-sync` to discover projects NOT YET registered.

---

## Prerequisites

- [ ] Global ACP initialized (`~/.acp/` exists)
- [ ] Projects registry exists (`~/.acp/projects.yaml`)
- [ ] At least one project registered

---

## Steps

### 1. Run Shell Script

Execute the project list script with optional filters.

**Actions**:
- Run `./agent/scripts/acp.project-list.sh`
- Pass filter arguments if needed
- Script reads `~/.acp/projects.yaml`
- Displays formatted project list

**Expected Outcome**: Project list displayed

### 2. Review Output

Examine the project list and identify projects of interest.

**Actions**:
- Note current project (marked with ⭐)
- Review project types and statuses
- Check last accessed timestamps
- Identify projects to switch to or investigate

**Expected Outcome**: Projects understood

---

## Verification

- [ ] Script executed successfully
- [ ] Projects displayed with correct formatting
- [ ] Current project marked with ⭐
- [ ] Filtering works correctly (if used)
- [ ] No errors encountered

---

## Arguments

### Optional Filters

- `--type <type>` - Filter by project type (e.g., `mcp-server`, `web-app`, `cli-tool`)
- `--status <status>` - Filter by status (`active`, `archived`, `paused`)
- `--tags <tag1,tag2>` - Filter by tags (comma-separated) [Not yet implemented]

---

## Expected Output

### Console Output (No Projects)
```
📁 Projects in ~/.acp/projects/

No projects registered yet

Create projects with: @acp.project-create
```

### Console Output (With Projects)
```
📁 Projects in ~/.acp/projects/

remember-mcp-server (mcp-server) - active ⭐ Current
  Multi-tenant memory system with vector search
  Last accessed: 2026-02-23T07:45:00Z

agentbase-mcp-server (mcp-server) - active
  Agent base server implementation
  Last accessed: 2026-02-22T16:00:00Z

my-web-app (web-app) - paused
  Personal portfolio website
  Last accessed: 2026-02-20T14:30:00Z

Showing 3 of 3 projects
```

### Console Output (With Filters)
```bash
# Filter by type
./agent/scripts/acp.project-list.sh --type mcp-server

📁 Projects in ~/.acp/projects/

remember-mcp-server (mcp-server) - active ⭐ Current
  Multi-tenant memory system with vector search
  Last accessed: 2026-02-23T07:45:00Z

agentbase-mcp-server (mcp-server) - active
  Agent base server implementation
  Last accessed: 2026-02-22T16:00:00Z

Showing 2 of 3 projects
```

---

## Examples

### Example 1: List All Projects

**Context**: Want to see all registered projects

**Invocation**: `@acp.project-list`

**Result**: Displays all projects with metadata, current project marked

### Example 2: Filter by Type

**Context**: Only want to see MCP server projects

**Invocation**: `@acp.project-list --type mcp-server`

**Result**: Displays only MCP server projects

### Example 3: Filter by Status

**Context**: Only want to see active projects

**Invocation**: `@acp.project-list --status active`

**Result**: Displays only active projects (excludes archived/paused)

### Example 4: Empty Registry

**Context**: No projects registered yet

**Invocation**: `@acp.project-list`

**Result**: Helpful message suggesting to create projects

---

## Related Commands

- [`@acp.project-create`](acp.project-create.md) - Create new project
- [`@acp.project-set`](acp.project-set.md) - Switch to project
- [`@acp.projects-sync`](acp.projects-sync.md) - Discover unregistered projects
- [`@acp.project-info`](acp.project-info.md) - Show project details

---

## Troubleshooting

### Issue 1: No registry found

**Symptom**: "No projects registry found"

**Cause**: Global ACP not initialized or registry not created

**Solution**: Run `@acp.project-create` to create first project (auto-initializes registry)

### Issue 2: No projects shown

**Symptom**: "No projects registered yet"

**Cause**: Registry exists but is empty

**Solution**: Create projects with `@acp.project-create` or discover existing projects with `@acp.projects-sync`

### Issue 3: Filters return no results

**Symptom**: "No projects match filters"

**Cause**: No projects match the specified filter criteria

**Solution**: Remove filters or adjust filter values to match existing projects

---

## Notes

- This command reads from the registry, not the filesystem
- Current project is determined from `current_project` field in registry
- Projects are displayed in the order they appear in the YAML file
- Tag filtering is planned but not yet implemented
- Empty registry is handled gracefully with helpful message

---

**Namespace**: acp
**Command**: project-list
**Version**: 1.0.0
**Created**: 2026-02-23
**Last Updated**: 2026-02-23
**Status**: Experimental
**Compatibility**: ACP 3.12.0+
**Author**: ACP Project
