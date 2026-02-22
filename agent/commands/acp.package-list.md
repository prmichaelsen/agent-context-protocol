# Command: package-list

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-list` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-18
**Status**: Active

---

**Purpose**: List installed ACP packages with versions, file counts, and optional details
**Category**: Information
**Frequency**: As Needed

---

## What This Command Does

This command displays all installed ACP packages by reading `agent/manifest.yaml` (local) or `~/.acp/manifest.yaml` (global) and showing package names, versions, and file counts. It provides optional verbose mode for detailed information and filters for outdated or modified packages.

Use this command when you want to see what packages are installed locally or globally, check package versions, identify packages with updates available, or find packages with local modifications.

---

## Auto-Initialization

When using the `--global` flag for the first time, the system automatically initializes `~/.acp/` infrastructure:
- Creates `~/.acp/` directory
- Installs full ACP (templates, scripts, schemas)
- Creates `~/.acp/projects/` directory
- Creates `~/.acp/agent/manifest.yaml` for package tracking

This happens automatically - no manual setup required.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/manifest.yaml` exists (packages have been installed)
- [ ] `agent/scripts/acp.package-list.sh` exists

---

## Steps

### 1. Run Package List Script

Execute the list script with desired options.

**Actions**:
- Run `./agent/scripts/acp.package-list.sh` with optional flags:
  ```bash
  # Basic list (local packages)
  ./agent/scripts/acp.package-list.sh
  
  # List global packages
  ./agent/scripts/acp.package-list.sh --global
  
  # Verbose mode (detailed information)
  ./agent/scripts/acp.package-list.sh --verbose
  
  # Show only outdated packages
  ./agent/scripts/acp.package-list.sh --outdated
  
  # Show only packages with local modifications
  ./agent/scripts/acp.package-list.sh --modified
  
  # Combine flags
  ./agent/scripts/acp.package-list.sh --global --verbose
  ```

**Expected Outcome**: Package list displayed

### 2. Review Package Information

Analyze the displayed information.

**Actions**:
- Note which packages are installed
- Check versions
- Identify packages with many files
- Note any outdated packages (if using --outdated)
- Note any modified packages (if using --modified)

**Expected Outcome**: Understanding of installed packages

---

## Verification

- [ ] Script executed successfully
- [ ] All installed packages displayed
- [ ] Package versions shown correctly
- [ ] File counts accurate
- [ ] Verbose mode shows detailed information (if used)
- [ ] Outdated filter works (if used)
- [ ] Modified filter works (if used)
- [ ] Handles empty manifest gracefully
- [ ] No errors during execution

---

## Expected Output

### Files Modified
None - this is a read-only command

### Console Output

**Basic Mode**:
```
📦 Installed ACP Packages

firebase (1.2.0) - 6 file(s)
mcp-integration (2.0.1) - 4 file(s)
oauth (1.0.0) - 2 file(s)

Total: 3 of 3 package(s)
```

**Verbose Mode** (`--verbose`):
```
📦 Installed ACP Packages

firebase (1.2.0) - 6 file(s)
  Source: https://github.com/prmichaelsen/acp-firebase.git
  Installed: 2026-02-18T10:30:00Z
  Updated: 2026-02-18T15:45:00Z
  Files:
    - 3 pattern(s)
    - 2 command(s)
    - 1 design(s)
  Modified files:
    - patterns/firebase-security-rules.md

mcp-integration (2.0.1) - 4 file(s)
  Source: https://github.com/prmichaelsen/acp-mcp-integration.git
  Installed: 2026-02-15T14:20:00Z
  Files:
    - 2 pattern(s)
    - 2 command(s)

oauth (1.0.0) - 2 file(s)
  Source: https://github.com/prmichaelsen/acp-oauth.git
  Installed: 2026-02-16T09:15:00Z
  Files:
    - 2 pattern(s)

Total: 3 of 3 package(s)
```

**Outdated Filter** (`--outdated`):
```
📦 Installed ACP Packages

firebase (1.2.0) - 6 file(s)
  Update available

Total: 1 of 3 package(s)

To update: ./agent/scripts/acp.package-update.sh firebase
```

**Modified Filter** (`--modified`):
```
📦 Installed ACP Packages

firebase (1.2.0) - 6 file(s)
  Modified files:
    - patterns/firebase-security-rules.md

Total: 1 of 3 package(s)
```

**Empty Manifest**:
```
No packages installed

To install a package:
  ./agent/scripts/acp.package-install.sh <repository-url>
```

---

## Examples

### Example 1: Basic List

**Context**: Want to see what packages are installed

**Invocation**: `@acp.package-list`

**Result**: Shows 3 packages with versions and file counts

### Example 2: Detailed Information

**Context**: Need detailed info about installed packages

**Invocation**: `@acp.package-list --verbose`

**Result**: Shows all packages with source URLs, timestamps, file breakdowns, and modified files

### Example 3: Check for Outdated Packages

**Context**: Want to see which packages have updates available

**Invocation**: `@acp.package-list --outdated`

**Result**: Shows only firebase (1.2.0) has update available, suggests update command

### Example 4: Find Modified Packages

**Context**: Want to see which packages have local modifications

**Invocation**: `@acp.package-list --modified`

**Result**: Shows only firebase has 1 modified file (firebase-security-rules.md)

---

## Related Commands

- [`@acp.package-install`](acp.package-install.md) - Install packages
- [`@acp.package-update`](acp.package-update.md) - Update packages
- [`@acp.package-info`](acp.package-info.md) - Show detailed package info
- [`@acp.package-remove`](acp.package-remove.md) - Remove packages

---

## Troubleshooting

### Issue 1: No packages shown

**Symptom**: "No packages installed" message

**Cause**: No packages installed or manifest doesn't exist

**Solution**: Install packages using `@acp.package-install`

### Issue 2: File counts seem wrong

**Symptom**: File count doesn't match actual files

**Cause**: Manifest out of sync with actual files

**Solution**: Reinstall package or manually fix manifest

### Issue 3: Outdated check is slow

**Symptom**: `--outdated` flag takes a long time

**Cause**: Cloning repositories to check versions

**Solution**: This is normal for multiple packages, be patient or check specific package with `@acp.package-update <name> --check`

---

## Notes

- Read-only operation (doesn't modify anything)
- `--outdated` requires network access (clones repos)
- `--modified` uses local checksums (no network)
- Verbose mode shows all available information
- Filters can be combined: `--verbose --outdated`
- Fast operation for basic list (no network)

---

**Namespace**: acp
**Command**: package-list
**Version**: 1.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-18
**Status**: Active
**Compatibility**: ACP 2.0.0+
**Author**: ACP Project
