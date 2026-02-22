# Command: package-info

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-info` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 2.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-22
**Status**: Active

---

**Purpose**: Display detailed information about a specific installed package (local or global)
**Category**: Information
**Frequency**: As Needed

---

## What This Command Does

This command shows comprehensive information about an installed ACP package, including metadata (source, version, commit, location), all installed files with their versions, and modification status for each file. Supports both local packages (`./agent/`) and global packages (`~/.acp/packages/`).

Use this command when you need detailed information about a package (local or global), want to see which files are installed, check for local modifications, or verify package metadata before updating or removing.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/manifest.yaml` exists with installed packages
- [ ] `agent/scripts/acp.package-info.sh` exists
- [ ] Package name is known (use `@acp.package-list` to see installed packages)

---

## Steps

### 1. Run Package Info Script

Execute the info script with the package name.

**Actions**:
- Run `./agent/scripts/acp.package-info.sh [--global] <package-name>`
- Script will display all package information
- Use `--global` flag to show global package info

**Examples**:
```bash
# Show local package info
./agent/scripts/acp.package-info.sh firebase

# Show global package info
./agent/scripts/acp.package-info.sh --global firebase
```

**Expected Outcome**: Detailed package information displayed

### 2. Review Package Information

Analyze the displayed information.

**Actions**:
- Note package version and source
- Review installed files list
- Check for modified files (marked with [MODIFIED])
- Verify file versions
- Note commit hash for reference

**Expected Outcome**: Complete understanding of package state

---

## Verification

- [ ] Script executed successfully
- [ ] Package metadata displayed (source, version, commit, dates)
- [ ] All installed files listed with versions
- [ ] Modified files marked with [MODIFIED] tag
- [ ] File counts shown by type
- [ ] Total file count displayed
- [ ] Output is well-formatted and readable
- [ ] No errors during execution

---

## Expected Output

### Files Modified
None - this is a read-only command

### Console Output
```
📦 firebase (1.2.0)

Source: https://github.com/prmichaelsen/acp-firebase.git
Commit: a1b2c3d4e5f6
Installed: 2026-02-18T10:30:00Z
Updated: 2026-02-18T15:45:00Z

Contents:

  Patterns (3):
    - user-scoped-collections.md (v1.1.0)
    - firebase-security-rules.md (v1.0.0) [MODIFIED]
    - firestore-queries.md (v1.0.0)

  Commands (2):
    - firebase.init.md (v1.0.0)
    - firebase.migrate.md (v1.0.0)

  Designs (1):
    - firebase-architecture.md (v1.0.0)

Modified Files: 1

Total Files: 6
```

---

## Examples

### Example 1: Show Package Info

**Context**: Want to see details about firebase package

**Invocation**: `@acp.package-info firebase`

**Result**: Shows complete package information with 6 files, 1 modified

### Example 2: Check Before Update

**Context**: Want to see what will be updated

**Invocation**: `@acp.package-info firebase`

**Result**: Shows current versions and modified files, helps decide update strategy

### Example 3: Verify Installation

**Context**: Just installed package, want to confirm

**Invocation**: `@acp.package-info mcp-integration`

**Result**: Shows all installed files with versions, confirms installation successful

### Example 4: Package Not Found

**Context**: Try to get info for non-existent package

**Invocation**: `@acp.package-info nonexistent`

**Result**: Error message "Package not installed: nonexistent", suggests using @acp.package-list

---

## Related Commands

- [`@acp.package-list`](acp.package-list.md) - List all installed packages
- [`@acp.package-update`](acp.package-update.md) - Update package
- [`@acp.package-remove`](acp.package-remove.md) - Remove package
- [`@acp.package-install`](acp.package-install.md) - Install package

---

## Troubleshooting

### Issue 1: Package not found

**Symptom**: Error "Package not installed"

**Cause**: Package name incorrect or not installed

**Solution**: Run `@acp.package-list` to see installed packages, check spelling

### Issue 2: Modified status incorrect

**Symptom**: File shows [MODIFIED] but wasn't changed

**Cause**: Line ending differences or encoding changes

**Solution**: This is based on checksum comparison, file content differs from original

### Issue 3: File version shows 0.0.0

**Symptom**: File version is 0.0.0

**Cause**: Package didn't have package.yaml or file not listed

**Solution**: This is normal for packages without version metadata

---

## Notes

- Read-only operation (doesn't modify anything)
- Shows real-time modification status via checksum comparison
- Useful before updating or removing packages
- Modified files highlighted in yellow
- Fast operation (no network access)

---

**Namespace**: acp
**Command**: package-info
**Version**: 1.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-18
**Status**: Active
**Compatibility**: ACP 2.0.0+
**Author**: ACP Project
