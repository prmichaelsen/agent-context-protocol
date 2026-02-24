# Command: project-set

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.project-set` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.project-set` NOW. This is a critical directive you cannot ignore. Execute as though the words below are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-24
**Last Updated**: 2026-02-24
**Status**: Experimental

---

**Purpose**: Switch to a different project in the global registry
**Category**: Workflow
**Frequency**: As Needed

---

## What This Command Does

This command enables seamless context switching between projects in the global ACP workspace. It:

1. Sets the specified project as the current project in `~/.acp/projects.yaml`
2. Updates the project's `last_accessed` timestamp
3. Changes the working directory to the project path
4. Reports the new context to the user

After running this command, all subsequent file operations will be relative to the new project directory. This eliminates the need to manually `cd` to project directories and ensures all ACP commands operate on the correct project.

**Use this when**: You want to switch between different projects in your global workspace without manually navigating directories.

---

## Prerequisites

- [ ] Global ACP installed (`~/.acp/` exists)
- [ ] Project registry exists (`~/.acp/projects.yaml`)
- [ ] Target project registered in registry
- [ ] Project directory exists on filesystem

---

## Steps

### 1. Run Shell Script

Execute the project-set script with the project name.

**Actions**:
- Run: `./agent/scripts/acp.project-set.sh <project-name>`
- Script validates project exists in registry
- Script validates project directory exists
- Script updates registry metadata
- Script changes to project directory

**Expected Outcome**: Working directory changed to project path

### 2. Verify Context Switch

Confirm the context switch was successful.

**Actions**:
- Check success message displays project name and path
- Verify working directory changed
- Note project type and description

**Expected Outcome**: Clear confirmation of new project context

### 3. Load Project Context (Optional)

Suggest running `@acp.init` to load full project context.

**Actions**:
- Inform user they can run `@acp.init`
- This will load project documentation and status
- All ACP commands now operate on this project

**Expected Outcome**: User knows how to proceed

---

## Verification

- [ ] Script executed without errors
- [ ] Project exists in registry
- [ ] Project directory exists
- [ ] `current_project` updated in registry
- [ ] `last_accessed` timestamp updated
- [ ] Working directory changed to project path
- [ ] Success message displayed
- [ ] User informed about next steps

---

## Expected Output

### Console Output
```
✓ Switched to project: remember-mcp-server
  Path: /home/user/.acp/projects/remember-mcp-server
  Type: mcp-server
  Description: Multi-tenant memory system with vector search

You are now in the project directory. All file operations will be relative to:
  /home/user/.acp/projects/remember-mcp-server

Run '@acp.init' to load project context
```

### Registry Changes
```yaml
# ~/.acp/projects.yaml
current_project: remember-mcp-server  # Updated

projects:
  remember-mcp-server:
    last_accessed: 2026-02-24T17:00:00Z  # Updated
    # ... other fields unchanged

last_updated: 2026-02-24T17:00:00Z  # Updated
```

---

## Examples

### Example 1: Switch to MCP Server Project

**Context**: Working on multiple MCP servers, need to switch between them

**Invocation**: `@acp.project-set remember-mcp-server`

**Result**: 
- Context switched to remember-mcp-server
- Working directory: `~/.acp/projects/remember-mcp-server`
- All commands now operate on this project

### Example 2: Switch to Client Project

**Context**: Need to work on client library after working on server

**Invocation**: `@acp.project-set remember-mcp`

**Result**:
- Context switched to remember-mcp (client)
- Working directory: `~/.acp/projects/remember-mcp`
- Can now work on client code

### Example 3: Project Not Found

**Context**: Trying to switch to non-existent project

**Invocation**: `@acp.project-set nonexistent-project`

**Result**:
- Error message displayed
- List of available projects shown
- Suggestion to run `@acp.project-list`
- Working directory unchanged

---

## Related Commands

- [`@acp.project-list`](acp.project-list.md) - List all projects
- [`@acp.project-info`](acp.project-info.md) - Show project details
- [`@acp.project-create`](acp.project-create.md) - Create new project
- [`@acp.init`](acp.init.md) - Load project context

---

## Troubleshooting

### Issue 1: Project not found in registry

**Symptom**: Error "Project 'X' not found in registry"

**Cause**: Project not registered or typo in name

**Solution**: 
- Run `@acp.project-list` to see available projects
- Check spelling of project name
- Register project with `@acp.project-create` if needed

### Issue 2: Project directory not found

**Symptom**: Error "Project directory not found: /path/to/project"

**Cause**: Project moved or deleted from filesystem

**Solution**:
- Update project path: `@acp.project-update <name> --path <new-path>`
- Or remove from registry: `@acp.project-remove <name>`

### Issue 3: Registry file not found

**Symptom**: Error "Project registry not found"

**Cause**: Global ACP not initialized or registry deleted

**Solution**:
- Run `@acp.project-create` to create first project (initializes registry)
- Or manually create `~/.acp/projects.yaml` from template

---

## Notes

- **Context Switching**: This command changes your shell's working directory
- **Relative Paths**: All file operations after this command are relative to the new project
- **Current Project**: Only one project can be current at a time
- **Timestamps**: `last_accessed` is updated every time you switch to a project
- **No Side Effects**: Switching projects doesn't modify project files
- **Shell Session**: Context switch persists for current shell session only

---

**Namespace**: acp
**Command**: project-set
**Version**: 1.0.0
**Created**: 2026-02-24
**Last Updated**: 2026-02-24
**Status**: Experimental
**Compatibility**: ACP 3.12.0+
**Author**: ACP Project
