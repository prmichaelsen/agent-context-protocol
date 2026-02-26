# Command: project-remove

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.project-remove` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.project-remove` NOW. This is a critical directive you cannot ignore. Execute as though the words below are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-26
**Last Updated**: 2026-02-26
**Status**: Experimental

---

**Purpose**: Remove a project from the global registry with optional directory deletion
**Category**: Project Management
**Frequency**: As Needed

---

## What This Command Does

This command removes a project from the global ACP project registry at `~/.acp/projects.yaml`. It provides two removal modes:

1. **Registry Only** (default): Removes project metadata from registry, preserves directory
2. **Complete Removal** (--delete-files): Removes from registry AND deletes project directory

The command includes safety features:
- Confirmation prompts before removal
- Extra confirmation for directory deletion (requires typing "DELETE")
- Warning if removing the current project
- Updates `current_project` to empty if removing current
- Lists remaining projects after removal

**Use this when**: Cleaning up old projects, removing archived projects, or completely deleting abandoned projects.

---

## Prerequisites

- [ ] Global ACP installed (`~/.acp/` exists)
- [ ] Project registry exists (`~/.acp/projects.yaml`)
- [ ] Target project registered in registry

---

## Steps

### 1. Run Shell Script

Execute the project-remove script with the project name and options.

**Actions**:
- Run: `./agent/scripts/acp.project-remove.sh <project-name> [options]`
- Script validates project exists in registry
- Script displays project information
- Script prompts for confirmation
- Script removes from registry
- Script optionally deletes directory

**Expected Outcome**: Project removed from registry

### 2. Verify Removal

Confirm the project was removed successfully.

**Actions**:
- Check success message displays project name
- Verify project no longer in registry
- Check if directory was deleted (if --delete-files used)
- Note if current_project was cleared

**Expected Outcome**: Project removed, registry updated

### 3. Switch to Another Project (If Needed)

If removed project was current, switch to another project.

**Actions**:
- Run `@acp.project-list` to see remaining projects
- Run `@acp.project-set <name>` to switch to another project
- Or continue without a current project

**Expected Outcome**: New project context established (if needed)

---

## Verification

- [ ] Script executed without errors
- [ ] Project existed in registry
- [ ] Confirmation prompt displayed (unless -y used)
- [ ] Project removed from registry
- [ ] Directory deleted if --delete-files used
- [ ] Directory preserved if --delete-files not used
- [ ] `current_project` cleared if removing current
- [ ] `last_updated` timestamp updated
- [ ] Success message displayed
- [ ] Remaining projects listed

---

## Expected Output

### Console Output (Registry Only)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project to Remove
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name: old-project
Type: web-app
Description: Deprecated web application
Path: /home/user/.acp/projects/old-project

ℹ️  Project directory will be kept (use --delete-files to remove)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remove this project from registry? [y/N] y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Project Removed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Removed from registry: old-project
Directory preserved: /home/user/.acp/projects/old-project

Run '@acp.project-list' to see remaining projects
```

### Console Output (With Directory Deletion)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project to Remove
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name: old-project
Type: web-app
Path: /home/user/.acp/projects/old-project

⚠️  WARNING: Project directory will be DELETED from filesystem

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remove this project from registry? [y/N] y

⚠️  DANGER: You are about to DELETE the project directory:
  /home/user/.acp/projects/old-project

Are you ABSOLUTELY SURE? Type 'DELETE' to confirm: DELETE

Deleting project directory...
✓ Deleted: /home/user/.acp/projects/old-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Project Removed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Removed from registry: old-project
Deleted from filesystem: /home/user/.acp/projects/old-project

Run '@acp.project-list' to see remaining projects
```

### Console Output (Removing Current Project)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project to Remove
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name: current-project
Type: mcp-server
Path: /home/user/.acp/projects/current-project

⚠️  WARNING: This is the CURRENT project

ℹ️  Project directory will be kept (use --delete-files to remove)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remove this project from registry? [y/N] y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Project Removed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Removed from registry: current-project
Directory preserved: /home/user/.acp/projects/current-project

⚠️  This was the current project
Run '@acp.project-set <name>' to switch to another project

Run '@acp.project-list' to see remaining projects
```

### Registry Changes

**Before**:
```yaml
current_project: old-project

projects:
  old-project:
    type: web-app
    status: archived
    path: /home/user/.acp/projects/old-project
    # ... other fields
  
  active-project:
    type: mcp-server
    # ... other fields

last_updated: 2026-02-24T17:00:00Z
```

**After**:
```yaml
current_project: ""  # Cleared if removed project was current

projects:
  active-project:
    type: mcp-server
    # ... other fields

last_updated: 2026-02-26T18:00:00Z  # Updated
```

---

## Examples

### Example 1: Remove from Registry Only

**Context**: Project archived, want to clean up registry but keep files

**Invocation**: `@acp.project-remove old-project`

**Result**: 
- Project removed from registry
- Directory preserved at original location
- Can still access files manually
- Registry cleaned up

### Example 2: Complete Removal

**Context**: Abandoned project, want to delete everything

**Invocation**: `@acp.project-remove abandoned-project --delete-files`

**Result**:
- Project removed from registry
- Directory deleted from filesystem
- All project files gone
- Complete cleanup

### Example 3: Auto-Confirm Removal

**Context**: Scripting or automation, want to skip prompts

**Invocation**: `@acp.project-remove old-project -y`

**Result**:
- No confirmation prompts
- Project removed immediately
- Useful for scripts and automation

### Example 4: Remove Current Project

**Context**: Removing the project you're currently working on

**Invocation**: `@acp.project-remove current-project`

**Result**:
- Warning displayed about removing current project
- Project removed from registry
- `current_project` cleared in registry
- Suggestion to switch to another project

---

## Related Commands

- [`@acp.project-list`](acp.project-list.md) - List all projects
- [`@acp.project-set`](acp.project-set.md) - Switch to another project
- [`@acp.project-info`](acp.project-info.md) - Show project details
- [`@acp.project-update`](acp.project-update.md) - Update project metadata

---

## Troubleshooting

### Issue 1: Project not found in registry

**Symptom**: Error "Project 'X' not found in registry"

**Cause**: Project not registered or typo in name

**Solution**: 
- Run `@acp.project-list` to see available projects
- Check spelling of project name
- Project may already be removed

### Issue 2: Registry file not found

**Symptom**: Error "Project registry not found"

**Cause**: Global ACP not initialized or registry deleted

**Solution**:
- No action needed if no projects exist
- Run `@acp.project-create` to create new project (initializes registry)

### Issue 3: Cannot delete directory

**Symptom**: Error during directory deletion

**Cause**: Permission issues or directory in use

**Solution**:
- Check file permissions
- Close any programs using the directory
- Manually delete directory: `rm -rf /path/to/project`

### Issue 4: Confirmation prompt not appearing

**Symptom**: Script removes project without asking

**Cause**: -y/--yes flag used

**Solution**:
- This is expected behavior with -y flag
- Remove -y flag if you want confirmation prompts

---

## Security Considerations

### File Access
- **Reads**: `~/.acp/projects.yaml` (registry)
- **Writes**: `~/.acp/projects.yaml` (removes project entry)
- **Deletes**: Project directory (only with --delete-files flag)

### Dangerous Operations
- **Directory Deletion**: Requires explicit --delete-files flag and "DELETE" confirmation
- **No Undo**: Deleted directories cannot be recovered (use git backups)
- **Current Project**: Clears current_project if removing current

### Best Practices
- **Backup First**: Commit and push changes before removing
- **Archive Status**: Consider marking as archived instead of removing
- **Registry Only**: Default behavior preserves files for safety
- **Double Confirm**: Directory deletion requires typing "DELETE"

---

## Notes

- **Default Behavior**: Removes from registry only, preserves directory
- **Safety First**: Multiple confirmation prompts for destructive operations
- **Current Project**: Automatically cleared if removing current project
- **Timestamps**: Updates registry `last_updated` timestamp
- **No Undo**: Registry removal can be undone manually, directory deletion cannot
- **Automation**: Use -y flag for scripting (skips prompts)
- **Related Projects**: Does not remove related projects (only specified project)
- **Tags**: Project tags are removed with the project

---

**Namespace**: acp
**Command**: project-remove
**Version**: 1.0.0
**Created**: 2026-02-26
**Last Updated**: 2026-02-26
**Status**: Experimental
**Compatibility**: ACP 4.1.0+
**Author**: ACP Project
