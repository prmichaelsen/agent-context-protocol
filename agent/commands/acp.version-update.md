# Command: version-update

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-version-update` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Scripts**: acp.version-update.sh, acp.common.sh

---

**Purpose**: Update ACP files (AGENT.md, templates, scripts) to the latest version
**Category**: Maintenance
**Frequency**: When Updates Available

---

## What This Command Does

This command updates your ACP installation to the latest version by running the update script. It downloads the latest AGENT.md, template files, and utility scripts from the ACP repository, replacing your current versions while preserving your project-specific files.

Use this command when `@acp-version-check-for-updates` reports that updates are available, or when you want to get the latest ACP improvements. The update process is git-friendly and reversible.

Unlike `@acp-version-check-for-updates` which only checks, this command actually applies the updates. It's recommended to commit your changes before updating so you can revert if needed.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/scripts/acp.version-update.sh` exists
- [ ] Internet connection available
- [ ] Git repository initialized (recommended for easy rollback)
- [ ] Changes committed (recommended)

---

## Steps

### 1. Verify Prerequisites

Check that update can proceed safely.

**Actions**:
- Verify `./agent/scripts/acp.version-update.sh` exists
- Check internet connection
- Recommend committing changes if git repo exists
- Warn user that files will be updated

**Expected Outcome**: Prerequisites confirmed or user warned

### 2. Run Update Script

Execute the update script.

**Actions**:
- Run `./agent/scripts/acp.version-update.sh`
- Script will:
  - Clone latest ACP repository
  - Update AGENT.md
  - Update all template files
  - Update utility scripts
  - Preserve your project files (non-templates)

**Expected Outcome**: Update script completes successfully

### 3. Review Changes

Show what was updated.

**Actions**:
- List files that were updated
- Show version change (old → new)
- Highlight major changes from CHANGELOG
- Note any breaking changes

**Expected Outcome**: User understands what changed

### 4. Verify Update Success

Confirm update completed correctly.

**Actions**:
- Check AGENT.md version number updated
- Verify template files updated
- Confirm scripts updated
- Test that ACP still works

**Expected Outcome**: Update verified successful

### 5. Suggest Next Actions

Provide recommendations after update.

**Actions**:
- Suggest reviewing changes: `git diff`
- Recommend reading CHANGELOG for details
- Suggest running `@acp-init` to reload context
- Note any action items from update

**Expected Outcome**: User knows what to do next

---

## Verification

- [ ] Update script executed successfully
- [ ] AGENT.md updated to new version
- [ ] Template files updated
- [ ] Scripts updated
- [ ] Project-specific files preserved (not overwritten)
- [ ] No errors encountered
- [ ] Git shows clean diff of changes

---

## Expected Output

### Files Modified
- `AGENT.md` - Updated to latest version
- `agent/design/*.template.md` - Updated templates
- `agent/milestones/*.template.md` - Updated templates
- `agent/patterns/*.template.md` - Updated templates
- `agent/tasks/*.template.md` - Updated templates
- `agent/commands/command.template.md` - Updated template
- `agent/commands/acp.*.md` - Updated core commands (if any)
- `agent/progress.template.yaml` - Updated template
- `agent/scripts/*.sh` - Updated utility scripts

### Console Output
```
🔄 Updating ACP to latest version...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📥 Fetching latest files...
✓ Latest files fetched

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Updating files...
✓ Updated AGENT.md (1.0.3 → 1.1.0)
✓ Updated design templates
✓ Updated milestone templates
✓ Updated pattern templates
✓ Updated task templates
✓ Updated command template
✓ Updated core commands (3 files)
✓ Updated progress template
✓ Updated utility scripts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Update complete!

Version: 1.0.3 → 1.1.0
Files updated: 15

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Next steps:
  1. Review changes: git diff
  2. See what changed: git status
  3. Revert if needed: git checkout <file>
  4. Read changelog: @acp-version-check

📚 Full changelog:
  https://github.com/prmichaelsen/agent-context-protocol/blob/mainline/CHANGELOG.md
```

### Status Update
- ACP version: 1.0.3 → 1.1.0
- Template files updated
- Scripts updated

---

## Examples

### Example 1: Applying Available Update

**Context**: `@acp-version-check-for-updates` reported version 1.1.0 available

**Invocation**: `@acp-version-update`

**Result**: Updates from 1.0.3 to 1.1.0, shows 15 files updated, suggests reviewing changes with git diff

### Example 2: Already Up to Date

**Context**: Running update when already on latest version

**Invocation**: `@acp-version-update`

**Result**: Script reports already up to date, no files modified

### Example 3: Update with Git Review

**Context**: Want to see exactly what changed

**Invocation**: `@acp-version-update` then `git diff`

**Result**: Updates applied, git diff shows line-by-line changes, can revert specific files if needed

---

## Related Commands

- [`@acp-version-check-for-updates`](acp.version-check-for-updates.md) - Check before updating
- [`@acp-version-check`](acp.version-check.md) - Verify version after updating
- [`@acp-init`](acp.init.md) - Reload context after updating

---

## Troubleshooting

### Issue 1: Script not found

**Symptom**: Error "acp.version-update.sh not found"

**Cause**: Older ACP installation without update scripts

**Solution**: Manually download latest AGENT.md from repository, or install update scripts

### Issue 2: Network error

**Symptom**: Error "Cannot fetch repository"

**Cause**: No internet connection or GitHub unavailable

**Solution**: Check internet connection and try again later

### Issue 3: Permission denied

**Symptom**: Error "Permission denied" when running script

**Cause**: Script not executable

**Solution**: Run `chmod +x agent/scripts/acp.version-update.sh` to make it executable

### Issue 4: Merge conflicts

**Symptom**: Git reports conflicts after update

**Cause**: Local modifications to template files

**Solution**: Review conflicts, keep your changes or accept updates, resolve conflicts manually

---

## Security Considerations

### File Access
- **Reads**: Current ACP files to determine what to update
- **Writes**: AGENT.md, all template files, utility scripts
- **Executes**: `./agent/scripts/acp.version-update.sh`

### Network Access
- **APIs**: GitHub API (via update script)
- **Repositories**: Clones ACP repository to temporary directory

### Sensitive Data
- **Secrets**: Does not access any secrets or credentials
- **Credentials**: Does not access any credentials
- **Project Files**: Does not modify your project-specific files (non-templates)

---

## Notes

- **Backup recommended**: Commit changes before updating
- **Reversible**: Use `git checkout <file>` to revert specific files
- **Template-only**: Only updates `.template.md` files and core ACP files
- **Preserves your work**: Your project-specific files are not touched
- **Safe operation**: Can be reverted via git
- **Git-friendly**: Creates clean diffs for review
- **Run after update**: Consider running `@acp-init` to reload context

---

**Namespace**: acp
**Command**: version-update
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.0.3+
**Author**: ACP Project
