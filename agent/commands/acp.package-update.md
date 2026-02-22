# Command: package-update

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-update` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 2.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-22
**Status**: Active

---

**Purpose**: Update installed ACP packages to their latest versions with smart conflict detection
**Category**: Maintenance
**Frequency**: As Needed

---

## What This Command Does

This command updates installed ACP packages to their latest versions by comparing the current version in `agent/manifest.yaml` with the latest version in the package repository. It intelligently detects locally modified files via checksum comparison and provides conflict resolution options.

Use this command when you want to get the latest bug fixes, features, and improvements from installed packages. The command can update all packages at once or specific packages individually, and it respects local modifications to prevent accidental overwrites.

Unlike `@acp.version-update` which updates ACP itself, this command updates third-party packages installed via `@acp.package-install`.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/manifest.yaml` exists with installed packages
- [ ] Git installed and available
- [ ] Internet connection available
- [ ] `agent/scripts/acp.package-update.sh` exists

---

## Steps

### 1. Choose Update Mode

Decide what to update.

**Update Modes**:

**A. Check for Updates** (preview only):
```bash
./agent/scripts/acp.package-update.sh --check
```
Shows available updates without installing them.

**B. Update All Packages**:
```bash
./agent/scripts/acp.package-update.sh
```
Updates all installed packages to latest versions.

**C. Update Specific Package**:
```bash
./agent/scripts/acp.package-update.sh <package-name>
```
Updates only the specified package.

**D. Update with Options**:
```bash
# Skip modified files automatically
./agent/scripts/acp.package-update.sh --skip-modified

# Force overwrite modified files
./agent/scripts/acp.package-update.sh --force

# Auto-confirm (no prompts)
./agent/scripts/acp.package-update.sh -y
```

### 2. Run Package Update Script

Execute the update script with chosen options.

**Actions**:
- Run `./agent/scripts/acp.package-update.sh` with desired flags
- The script will:
  - Read installed packages from `agent/manifest.yaml`
  - Clone each package repository to check for updates
  - Compare current version with remote version
  - Detect locally modified files via checksum comparison
  - Prompt for conflict resolution (unless --skip-modified or --force)
  - Update unmodified files to latest versions
  - Update manifest with new versions and checksums
  - Report what was updated and what was skipped

**Expected Outcome**: Packages updated to latest versions

### 3. Review Update Results

Verify the updates were applied correctly.

**Actions**:
- Check which files were updated
- Review any skipped files (locally modified)
- Verify `agent/manifest.yaml` has new versions
- Test updated commands/patterns if critical
- Review changes in updated files

**Expected Outcome**: Updates verified and working

### 4. Document Update

Update progress tracking with update notes.

**Actions**:
- Add note to `agent/progress.yaml` about package updates
- Document which packages were updated
- Note any conflicts or skipped files
- Record update date

**Expected Outcome**: Update tracked in progress

---

## Verification

- [ ] Script executed successfully
- [ ] Version comparison detected updates correctly
- [ ] Locally modified files detected via checksum
- [ ] User prompted for conflict resolution (if applicable)
- [ ] Unmodified files updated to latest versions
- [ ] Modified files handled according to flags (skip/force)
- [ ] Manifest updated with new versions and checksums
- [ ] Update summary shows what changed
- [ ] No errors during update

---

## Expected Output

### Files Modified
- `agent/manifest.yaml` - Updated with new versions, checksums, and timestamps
- `agent/patterns/*.md` - Updated pattern files (unmodified ones)
- `agent/commands/*.md` - Updated command files (unmodified ones)
- `agent/design/*.md` - Updated design files (unmodified ones)

### Console Output
```
📦 ACP Package Updater
========================================

Checking all packages for updates...

ℹ Checking firebase (1.2.0)...
  ✓ Update available: 1.2.0 → 1.3.0

ℹ Checking mcp-integration (2.0.1)...
  ✓ Up to date: 2.0.1

Update all packages? (y/N) y

Updating firebase...

⚠️  Modified files detected:
  - patterns/firebase-security-rules.md

Overwrite modified files? (y/N) n
Skipping modified files

  ✓ Updated patterns/user-scoped-collections.md (v1.2.0)
  ✓ Updated patterns/firestore-queries.md (v1.0.1)
  ⊘ Skipped patterns/firebase-security-rules.md (modified locally)
  ✓ Updated commands/firebase.init.md (v1.0.1)

✓ Updated firebase: 3 file(s)
  Skipped: 1 file(s)

✅ Update complete!
```

### Status Update
- Package versions updated in manifest
- File versions and checksums updated
- Modified files preserved or overwritten based on user choice

---

## Examples

### Example 1: Check for Updates

**Context**: Want to see if updates are available without installing

**Invocation**: `@acp.package-update --check`

**Result**: Shows firebase has update (1.2.0 → 1.3.0), mcp-integration is up to date, provides update commands

### Example 2: Update All Packages

**Context**: Want to update all installed packages

**Invocation**: `@acp.package-update`

**Result**: Checks all packages, finds 2 with updates, prompts for confirmation, updates both packages, skips 1 modified file

### Example 3: Update Specific Package

**Context**: Only want to update firebase package

**Invocation**: `@acp.package-update firebase`

**Result**: Checks only firebase, finds update, prompts for modified files, updates 3 files, skips 1 modified file

### Example 4: Update with Skip Modified

**Context**: Want to update but preserve all local changes

**Invocation**: `@acp.package-update --skip-modified`

**Result**: Updates all packages, automatically skips any locally modified files without prompting

### Example 5: Force Update

**Context**: Want to overwrite all local changes

**Invocation**: `@acp.package-update --force`

**Result**: Updates all files including locally modified ones, no prompts, all changes overwritten

---

## Related Commands

- [`@acp.package-install`](acp.package-install.md) - Install packages
- [`@acp.package-list`](acp.package-list.md) - List installed packages
- [`@acp.package-info`](acp.package-info.md) - Show package details
- [`@acp.version-update`](acp.version-update.md) - Update ACP itself (not packages)

---

## Troubleshooting

### Issue 1: No updates available

**Symptom**: All packages report "up to date"

**Cause**: Packages are already at latest versions

**Solution**: This is normal, no action needed

### Issue 2: Failed to clone repository

**Symptom**: Error cloning package repository

**Cause**: Network issue, repository moved, or deleted

**Solution**: Check internet connection, verify repository still exists, update source URL in manifest if moved

### Issue 3: Checksum mismatch on unmodified file

**Symptom**: File flagged as modified but you didn't change it

**Cause**: Line ending differences (CRLF vs LF) or encoding changes

**Solution**: Use --force to overwrite, or manually verify file content

### Issue 4: Update breaks functionality

**Symptom**: After update, commands or patterns don't work

**Cause**: Breaking changes in package update

**Solution**: Check package CHANGELOG, revert using git, or reinstall previous version

---

## Security Considerations

### File Access
- **Reads**: `agent/manifest.yaml`, installed package files
- **Writes**: Updated package files, `agent/manifest.yaml`
- **Executes**: None (only file operations)

### Network Access
- **Repositories**: Clones package repositories from GitHub
- **APIs**: None

### Conflict Resolution
- **Modified files**: Detected via checksum comparison
- **User control**: Prompts before overwriting (unless --force)
- **Preservation**: --skip-modified preserves all local changes

---

## Notes

- Updates only affect installed files (partial installations stay partial)
- Checksums recalculated after each update
- Package metadata (version, commit, timestamp) updated in manifest
- Modified files can be overwritten with --force flag
- Use --check to preview updates before applying
- Safe to run multiple times (idempotent)

---

**Namespace**: acp
**Command**: package-update
**Version**: 1.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-18
**Status**: Active
**Compatibility**: ACP 2.0.0+
**Author**: ACP Project
