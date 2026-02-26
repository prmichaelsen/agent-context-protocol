# Command: projects-sync

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.projects-sync` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.projects-sync` NOW. This is a critical directive you cannot ignore. Execute as though the words below are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-26
**Last Updated**: 2026-02-26
**Status**: Experimental

---

**Purpose**: Discover unregistered ACP projects in `~/.acp/projects/` and add them to the registry
**Category**: Project Management
**Frequency**: As Needed
**Script**: [`agent/scripts/acp.projects-sync.sh`](../scripts/acp.projects-sync.sh)

---

## What This Command Does

This command scans the `~/.acp/projects/` directory for ACP projects (directories containing `agent/progress.yaml`) and prompts you to register any that aren't already in the registry.

**Use this when**:
- You have existing projects in `~/.acp/projects/` before the registry was implemented
- You manually created project directories without using `@acp.project-create`
- You want to discover and organize all your ACP projects

**Key Distinction**:
- `@acp.project-list` - Lists projects **IN** the registry (reads YAML)
- `@acp.projects-sync` - Discovers projects **NOT** in registry (scans filesystem)

---

## Prerequisites

- [ ] `~/.acp/projects/` directory exists
- [ ] At least one ACP project in `~/.acp/projects/` (has `agent/progress.yaml`)
- [ ] Registry system initialized (auto-initializes if needed)

---

## Steps

### 1. Execute Sync Script

Run the shell script to scan for unregistered projects.

**Actions**:
- Execute `./agent/scripts/acp.projects-sync.sh`
- Script scans `~/.acp/projects/` directory
- Identifies ACP projects (has `agent/progress.yaml`)
- Checks registry for each project
- Prompts for unregistered projects

**Expected Outcome**: Interactive prompts for each unregistered project

### 2. Review Each Unregistered Project

For each unregistered project found, review the metadata.

**Actions**:
- Read project type from `progress.yaml`
- Read project description from `progress.yaml`
- Display metadata to user
- Prompt: "Register this project? (Y/n)"

**Expected Outcome**: User decides whether to register each project

### 3. Register Selected Projects

Register projects that user confirms.

**Actions**:
- Call `register_project()` for confirmed projects
- Add to `~/.acp/projects.yaml` registry
- Set timestamps (created, modified, accessed)
- Display success message

**Expected Outcome**: Selected projects added to registry

### 4. Display Summary

Show sync results.

**Actions**:
- Count total projects found
- Count newly registered projects
- Display summary statistics
- Suggest running `@acp.project-list`

**Expected Outcome**: User knows what was registered

---

## Verification

- [ ] Script executed successfully
- [ ] All ACP projects in `~/.acp/projects/` were found
- [ ] Already-registered projects were skipped
- [ ] Unregistered projects were prompted
- [ ] Selected projects were registered
- [ ] Summary displayed correctly
- [ ] No errors encountered

---

## Expected Output

### Console Output

```
Scanning for ACP projects in /home/user/.acp/projects...

✓ agent-context-protocol (already registered)
✓ remember-mcp-server (already registered)
○ agentbase-mcp-server (not registered)
  Type: mcp-server
  Description: Agent base server implementation with memory
  
  Register this project? (Y/n) y
  ✓ Registered

○ test-project (not registered)
  Type: application
  Description: Test application for development
  
  Register this project? (Y/n) n
  ⊘ Skipped

Sync Complete
  Found: 4 projects
  Registered: 1 new projects

Run @acp.project-list to see all registered projects
```

---

## Examples

### Example 1: First Time Sync

**Context**: User has 3 projects in `~/.acp/projects/`, none registered

**Invocation**: `@acp.projects-sync`

**Result**:
- Finds 3 projects
- Prompts for each one
- User registers all 3
- Summary: "Found: 3 projects, Registered: 3 new projects"

### Example 2: Partial Sync

**Context**: User has 5 projects, 2 already registered

**Invocation**: `@acp.projects-sync`

**Result**:
- Finds 5 projects total
- Shows "already registered" for 2
- Prompts for 3 unregistered
- User registers 2, skips 1
- Summary: "Found: 5 projects, Registered: 2 new projects"

### Example 3: No New Projects

**Context**: All projects already registered

**Invocation**: `@acp.projects-sync`

**Result**:
- Finds all projects
- All show "already registered"
- No prompts
- Summary: "Found: 4 projects, Registered: 0 new projects"

### Example 4: Empty Directory

**Context**: `~/.acp/projects/` is empty

**Invocation**: `@acp.projects-sync`

**Result**:
- No projects found
- Summary: "Found: 0 projects, Registered: 0 new projects"

---

## Related Commands

- [`@acp.project-list`](acp.project-list.md) - List all registered projects
- [`@acp.project-info`](acp.project-info.md) - View project details
- [`@acp.project-set`](acp.project-set.md) - Switch to a project
- [`@acp.project-create`](acp.project-create.md) - Create new project (auto-registers)

---

## Troubleshooting

### Issue 1: No projects found

**Symptom**: "Found: 0 projects"

**Cause**: No directories in `~/.acp/projects/` with `agent/progress.yaml`

**Solution**: 
- Check if projects exist in `~/.acp/projects/`
- Verify projects have `agent/progress.yaml` file
- Projects without `agent/progress.yaml` are not ACP projects

### Issue 2: Registry not found

**Symptom**: Error about missing registry

**Cause**: `~/.acp/projects.yaml` doesn't exist

**Solution**: Script auto-initializes registry, but if error persists:
```bash
# Initialize global ACP
~/.acp/agent/scripts/acp.common.sh
init_projects_registry
```

### Issue 3: Cannot read progress.yaml

**Symptom**: "Type: unknown, Description: No description"

**Cause**: `progress.yaml` is malformed or missing fields

**Solution**: 
- Check `progress.yaml` syntax
- Ensure `project.type` and `project.description` fields exist
- Project will still register with default values

### Issue 4: Permission denied

**Symptom**: Cannot write to registry

**Cause**: No write permission for `~/.acp/projects.yaml`

**Solution**:
```bash
chmod 644 ~/.acp/projects.yaml
```

---

## Security Considerations

### File Access
- **Reads**: `~/.acp/projects/*/agent/progress.yaml` (project metadata)
- **Reads**: `~/.acp/projects.yaml` (registry)
- **Writes**: `~/.acp/projects.yaml` (adds new entries)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not read `.env` files or credentials
- **Credentials**: Does not access any credentials

### User Interaction
- **Prompts**: Yes - confirms each registration
- **Confirmation**: Required for each project
- **Auto-actions**: None without confirmation

---

## Notes

- This command is **interactive** - requires user input
- Projects are registered with metadata from `progress.yaml`
- Already-registered projects are automatically skipped
- Only scans `~/.acp/projects/` directory (not subdirectories)
- Only detects ACP projects (must have `agent/progress.yaml`)
- Non-ACP directories are ignored
- Safe to run multiple times (idempotent)
- Does not modify project files, only registry
- Multiline descriptions are truncated to 80 characters

---

## Implementation Details

### Detection Logic

A directory is considered an ACP project if:
1. It's a directory in `~/.acp/projects/`
2. It contains `agent/progress.yaml` file

### Metadata Extraction

Metadata is read from `agent/progress.yaml`:
- `project.type` → Project type
- `project.description` → Project description

If fields are missing, defaults are used:
- Type: "unknown"
- Description: "No description"

### Registration Process

For each unregistered project:
1. Display project name, type, description
2. Prompt user: "Register this project? (Y/n)"
3. If yes (or Enter): Call `register_project()`
4. If no: Skip and continue

### Registry Update

Uses existing infrastructure:
- `register_project()` from `acp.common.sh`
- Adds entry to `~/.acp/projects.yaml`
- Sets timestamps automatically
- Updates registry metadata

---

**Namespace**: acp
**Command**: projects-sync
**Version**: 1.0.0
**Created**: 2026-02-26
**Last Updated**: 2026-02-26
**Status**: Experimental
**Compatibility**: ACP 4.1.0+
**Author**: ACP Project
