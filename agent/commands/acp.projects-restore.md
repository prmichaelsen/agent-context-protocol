# Command: projects-restore

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.projects-restore` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-03-01  
**Last Updated**: 2026-03-01  
**Status**: Experimental  

---

**Purpose**: Restore/clone missing projects from their registered git origins  
**Category**: Project Management  
**Frequency**: As Needed  
**Script**: [`agent/scripts/acp.projects-restore.sh`](../scripts/acp.projects-restore.sh)  

---

## What This Command Does

This command reads `~/.acp/projects.yaml` and clones any missing project directories from their stored `git_origin` URLs. It's designed for restoring projects on a new machine after pushing your `~/.acp` configuration.

**Use this when**:
- You've set up `~/.acp` on a new machine and need to clone all your projects
- Project directories were deleted and need to be restored
- You want to preview what projects are missing with `--dry-run`

**Key Distinction**:
- `@acp.projects-sync` - Discovers projects on disk and registers them in the registry
- `@acp.projects-restore` - Reads the registry and clones projects that are missing from disk

---

## Prerequisites

- [ ] `~/.acp/projects.yaml` exists with project entries
- [ ] Projects have `git_origin` field set (run `@acp.projects-sync` to backfill)
- [ ] Git installed and network access available for cloning

---

## Steps

### 1. Execute Restore Script

Run the shell script to restore missing projects.

**Actions**:
- Execute `./agent/scripts/acp.projects-restore.sh [--dry-run] [--install-acp]`
- Script reads `~/.acp/projects.yaml` registry
- Checks each project's directory existence
- Clones missing projects from `git_origin`

**Expected Outcome**: Missing projects cloned to their registered paths  

### 2. Review Results

Check the restore summary.

**Actions**:
- Review clone count (projects restored)
- Review skip count (already exist, archived, no origin)
- Review errors (failed clones)

**Expected Outcome**: All restorable projects cloned successfully  

---

## Arguments

### Optional Flags

- `--dry-run` - Preview what would be cloned without actually cloning
- `--install-acp` - Run ACP install in each cloned project after cloning

---

## Verification

- [ ] Script executed successfully
- [ ] Missing projects were cloned
- [ ] Existing directories were skipped
- [ ] Archived projects were skipped
- [ ] Projects without git_origin were skipped
- [ ] Summary displayed correctly
- [ ] No errors encountered

---

## Expected Output

### Console Output (Dry Run)

```
Restore Preview (dry run)

✓ agent-context-protocol (already exists)
○ old-project
  Would clone: git@github.com:user/old-project.git
  Branch: main
  Into: /home/user/.acp/projects/old-project

⊘ archived-project (archived, skipping)
⊘ local-only (no git_origin, skipping)

Restore Complete
  Would clone: 1 projects
  Skipped: 3 projects
```

### Console Output (Actual Restore)

```
Restoring projects from registry...

✓ agent-context-protocol (already exists)
○ old-project - cloning...
  ✓ Cloned

Restore Complete
  Cloned: 1 projects
  Skipped: 1 projects
```

---

## Examples

### Example 1: Preview Restore

**Context**: Check what would be restored on a new machine  

**Invocation**: `@acp.projects-restore --dry-run`  

**Result**: Lists projects that would be cloned, skipped projects, and reasons  

### Example 2: Full Restore

**Context**: Restore all projects on a new machine  

**Invocation**: `@acp.projects-restore`  

**Result**: Clones all missing projects from their git origins  

### Example 3: Restore with ACP Install

**Context**: Restore and set up ACP in each project  

**Invocation**: `@acp.projects-restore --install-acp`  

**Result**: Clones missing projects and installs ACP in each one  

---

## Related Commands

- [`@acp.projects-sync`](acp.projects-sync.md) - Discover and register unregistered projects (opposite direction)
- [`@acp.project-list`](acp.project-list.md) - List all registered projects
- [`@acp.project-info`](acp.project-info.md) - View project details including git info
- [`@acp.project-update`](acp.project-update.md) - Manually set git_origin/git_branch

---

## Troubleshooting

### Issue 1: No projects to restore

**Symptom**: All projects show "already exists" or "no git_origin"  

**Cause**: Either all projects exist on disk, or git origins haven't been recorded  

**Solution**: Run `@acp.projects-sync` first to backfill git_origin for existing projects  

### Issue 2: Clone failed

**Symptom**: "Clone failed" for a project  

**Cause**: Network error, authentication required, or repository no longer exists  

**Solution**: Check the git_origin URL, verify network access, and ensure you have repository permissions  

### Issue 3: Branch not found

**Symptom**: "Branch 'xyz' not found on remote, using default"  

**Cause**: The stored branch no longer exists on the remote  

**Solution**: This is handled automatically by falling back to the default branch. Update with `@acp.project-update <name> --git-branch <new-branch>`  

---

## Security Considerations

### File Access
- **Reads**: `~/.acp/projects.yaml` (project registry)
- **Writes**: Creates project directories via git clone
- **Executes**: `git clone`, optionally `acp.install.sh`

### Network Access
- **APIs**: None
- **Repositories**: Clones from git_origin URLs (SSH or HTTPS)

### Sensitive Data
- **Secrets**: Does not read `.env` files or credentials
- **Credentials**: Uses system git credentials for cloning

---

## Notes

- This command is the counterpart to `@acp.projects-sync` (sync discovers on disk, restore clones from registry)
- Archived projects are always skipped
- Projects without `git_origin` are skipped (use `@acp.projects-sync` to backfill)
- Falls back to default branch if the stored branch doesn't exist on the remote
- Safe to run multiple times (existing directories are skipped)
- Does not modify the registry, only creates directories

---

**Namespace**: acp  
**Command**: projects-restore  
**Version**: 1.0.0  
**Created**: 2026-03-01  
**Last Updated**: 2026-03-01  
**Status**: Experimental  
**Compatibility**: ACP 5.7.3+  
**Author**: ACP Project  
