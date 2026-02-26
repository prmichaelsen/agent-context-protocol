# Command: project-remove

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.project-remove` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
**Status**: Experimental
**Scripts**: acp.project-remove.sh

---

**Purpose**: Remove a project from the global ACP project registry with optional directory deletion
**Category**: Project Management
**Frequency**: As Needed

---

## What This Command Does

This command removes a project from the global ACP project registry at `~/.acp/projects.yaml`. By default, it only removes the registry entry and keeps the project files intact. With the `--delete-files` flag, it will also delete the project directory from the filesystem.

**Key Features**:
- Remove project from registry
- Optional directory deletion with `--delete-files`
- Safety confirmation prompts (unless `-y` flag used)
- Clears `current_project` if removing active project
- Updates registry timestamp
- Shows remaining project count

**Use this when**: You want to unregister a project or completely remove it from your workspace.

---

## Prerequisites

- [ ] Global ACP installed (`~/.acp/` exists)
- [ ] Project registry exists (`~/.acp/projects.yaml`)
- [ ] Project is registered in registry

---

## Steps

### 1. Validate Project Exists

Check if the project is registered.

**Actions**:
- Read `~/.acp/projects.yaml`
- Check if project exists in registry
- Display error if not found
- List available projects

**Expected Outcome**: Project validated or error shown

### 2. Display Project Information

Show what will be removed.

**Actions**:
- Display project name, type, description
- Show project path
- Warn if this is the current project
- Warn if `--delete-files` is used

**Expected Outcome**: User understands what will be removed

### 3. Confirm Removal

Get user confirmation (unless `-y` flag).

**Actions**:
- Prompt for confirmation
- Different message for registry-only vs file deletion
- Cancel if user says no
- Skip prompt if `-y` flag used

**Expected Outcome**: User confirms or cancels

### 4. Remove from Registry

Remove project entry from registry.

**Actions**:
- Use `yaml_delete()` to remove `.projects.<project-name>`
- Clear `current_project` if removing active project
- Update `last_updated` timestamp
- Write changes to registry file

**Expected Outcome**: Project removed from registry

### 5. Delete Files (Optional)

Delete project directory if `--delete-files` flag used.

**Actions**:
- Check if directory exists
- Delete directory with `rm -rf`
- Handle missing directory gracefully
- Report deletion status

**Expected Outcome**: Files deleted or kept based on flag

### 6. Report Success

Show removal summary and remaining projects.

**Actions**:
- Display success message
- Show what was removed (registry, files, or both)
- Count remaining projects
- Suggest `@acp.project-list` to see remaining

**Expected Outcome**: User informed of results

---

## Verification

- [ ] Project removed from registry
- [ ] Registry file updated successfully
- [ ] `current_project` cleared if was current
- [ ] Files deleted if `--delete-files` used
- [ ] Files kept if `--delete-files` not used
- [ ] Confirmation prompt shown (unless `-y`)
- [ ] Clear error messages for invalid input
- [ ] No syntax errors in script

---

## Expected Output

### Console Output (Registry Only)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Project to Remove: old-project

  Type: web-app
  Description: Deprecated web application
  Path: /home/user/.acp/projects/old-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This will remove the project from the registry (files will be kept).

Remove 'old-project' from registry? (yes/no): yes

Removing project from registry...
  ✓ Removed from registry

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Project removed: old-project

  Registry: Removed
  Files: Kept at /home/user/.acp/projects/old-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining projects: 2

Run '@acp.project-list' to see all projects
```

### Console Output (With File Deletion)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Project to Remove: old-project

  Type: web-app
  Description: Deprecated web application
  Path: /home/user/.acp/projects/old-project

  ⚠️  WARNING: This is the current project

  🗑️  Files will be DELETED from filesystem

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  WARNING: This will remove the project from the registry AND delete all files!

Are you sure you want to remove 'old-project' and DELETE its files? (yes/no): yes

Removing project from registry...
  ✓ Clearing current_project (was: old-project)
  ✓ Removed from registry

Deleting project directory...
  ✓ Deleted: /home/user/.acp/projects/old-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Project removed: old-project

  Registry: Removed
  Files: Deleted

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remaining projects: 2

Run '@acp.project-list' to see all projects
```

### Console Output (Auto-Confirm)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Project to Remove: old-project

  Type: web-app
  Path: /home/user/.acp/projects/old-project

  🗑️  Files will be DELETED from filesystem

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Removing project from registry...
  ✓ Removed from registry

Deleting project directory...
  ✓ Deleted: /home/user/.acp/projects/old-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Project removed: old-project

  Registry: Removed
  Files: Deleted

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No projects remaining in registry
```

---

## Examples

### Example 1: Remove from Registry (Keep Files)

**Context**: Want to unregister a project but keep the files

**Invocation**: `@acp.project-remove old-project`

**Result**: 
- Project removed from registry
- Files kept at original location
- Can re-register later if needed

### Example 2: Complete Removal

**Context**: Want to completely remove a project

**Invocation**: `@acp.project-remove old-project --delete-files`

**Result**:
- Project removed from registry
- Directory deleted from filesystem
- Confirmation prompt shown
- Cannot be recovered (unless backed up)

### Example 3: Auto-Confirm Deletion

**Context**: Scripted removal without prompts

**Invocation**: `@acp.project-remove old-project --delete-files -y`

**Result**:
- No confirmation prompt
- Project and files deleted immediately
- Useful for automation scripts

### Example 4: Remove Current Project

**Context**: Removing the currently active project

**Invocation**: `@acp.project-remove my-current-project`

**Result**:
- Warning shown that it's current project
- `current_project` field cleared in registry
- User must set new current project with `@acp.project-set`

---

## Related Commands

- [`@acp.project-list`](acp.project-list.md) - List all projects
- [`@acp.project-info`](acp.project-info.md) - Show project details before removing
- [`@acp.project-set`](acp.project-set.md) - Set different current project after removal
- [`@acp.projects-sync`](acp.projects-sync.md) - Re-register projects after accidental removal

---

## Troubleshooting

### Issue 1: Project not found

**Symptom**: Error "Project 'xyz' not found in registry"

**Cause**: Project name doesn't exist in registry

**Solution**: Run `@acp.project-list` to see available projects, check spelling

### Issue 2: Registry not found

**Symptom**: Error "Project registry not found"

**Cause**: `~/.acp/projects.yaml` doesn't exist

**Solution**: No projects are registered. Nothing to remove. Create projects with `@acp.project-create` first.

### Issue 3: Directory already deleted

**Symptom**: Warning "Project directory not found"

**Cause**: Directory was manually deleted before running command

**Solution**: This is fine - command removes from registry anyway. Use `@acp.projects-sync` to clean up stale entries.

### Issue 4: Permission denied

**Symptom**: Error when deleting files

**Cause**: Insufficient permissions to delete directory

**Solution**: Check directory permissions, may need sudo or ownership change

---

## Security Considerations

### File Access
- **Reads**: `~/.acp/projects.yaml` (project registry)
- **Writes**: `~/.acp/projects.yaml` (removes project entry)
- **Deletes**: Project directory (only with `--delete-files` flag)

### Destructive Operations
- **Registry Removal**: Reversible (can re-register with `@acp.projects-sync`)
- **File Deletion**: IRREVERSIBLE (unless backed up)
- **Confirmation**: Required unless `-y` flag used

### Safety Features
- Confirmation prompts by default
- Clear warnings for file deletion
- Special warning when removing current project
- Lists available projects on error

---

## Notes

- **Default behavior**: Registry-only removal (files kept)
- **File deletion**: Requires explicit `--delete-files` flag
- **Confirmation**: Always prompted unless `-y` flag
- **Current project**: Automatically cleared if removing active project
- **Recovery**: Registry removal is reversible via `@acp.projects-sync`
- **File recovery**: File deletion is NOT reversible (backup first!)
- **Idempotent**: Safe to run multiple times (will error if already removed)
- **Related projects**: Does not remove related projects (only specified project)

**Best Practices**:
1. Run `@acp.project-info` first to verify project details
2. Backup important projects before using `--delete-files`
3. Set new current project after removing current one
4. Use `@acp.projects-sync` to clean up stale entries
5. Consider archiving instead of removing (use `@acp.project-update --status archived`)

---

**Namespace**: acp
**Command**: project-remove
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
**Status**: Experimental
**Compatibility**: ACP 3.13.0+
**Author**: ACP Project
