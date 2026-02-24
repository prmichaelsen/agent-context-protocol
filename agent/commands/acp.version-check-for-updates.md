# Command: version-check-for-updates

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-version-check-for-updates` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Scripts**: acp.version-check-for-updates.sh

---

**Purpose**: Check if newer version of ACP is available without applying updates
**Category**: Maintenance
**Frequency**: Per Session

---

## What This Command Does

This command checks if a newer version of ACP is available by running the update check script. It's a non-destructive operation that only reports whether updates exist and what changed, without modifying any files.

Use this command at the start of sessions (it's part of `@acp-init`) or when you want to see if improvements are available. It shows what's new via the CHANGELOG and lets you decide whether to update.

Unlike `@acp-version-update` which applies updates immediately, this command only checks and reports, giving you control over when to update.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/scripts/acp.version-check-for-updates.sh` exists
- [ ] Internet connection available
- [ ] Git installed

---

## Steps

### 1. Run Update Check Script

Execute the check-for-updates script.

**Actions**:
- Check if `./agent/scripts/acp.version-check-for-updates.sh` exists
- If exists, run the script
- If doesn't exist, report that update checking is unavailable
- Capture script output

**Expected Outcome**: Update status determined

### 2. Parse Script Output

Interpret the results from the update check.

**Actions**:
- Check if updates are available
- Extract available version number (if updates exist)
- Note if already up to date
- Handle any errors from script

**Expected Outcome**: Update status understood

### 3. Display Update Status

Show whether updates are available.

**Actions**:
- If up to date: Display success message
- If updates available: Show new version number
- Display current version for comparison
- Show update availability clearly

**Expected Outcome**: User knows if updates exist

### 4. Show What Changed

If updates are available, display changelog.

**Actions**:
- Fetch CHANGELOG from repository
- Show changes between current and new version
- Highlight Added, Changed, Removed, Fixed sections
- Make it easy to understand what's new

**Expected Outcome**: User understands what would change

### 5. Prompt for Action

Ask user if they want to update.

**Actions**:
- If updates available: Suggest running `@acp-version-update`
- If up to date: No action needed
- Provide clear next steps

**Expected Outcome**: User knows what to do next

---

## Verification

- [ ] Update check script executed successfully
- [ ] Update status determined (up to date or updates available)
- [ ] If updates available, changelog displayed
- [ ] Clear next steps provided
- [ ] No files modified

---

## Expected Output

### Files Modified
None - this is a read-only command

### Console Output (Up to Date)
```
🔍 Checking for ACP updates...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Your ACP is up to date!

Current Version: 1.0.3
Latest Version: 1.0.3
Released: 2026-02-13

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  No action needed.
```

### Console Output (Updates Available)
```
🔍 Checking for ACP updates...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🆕 Updates Available!

Current Version: 1.0.3
Latest Version: 1.1.0
Released: 2026-02-20

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 What's New in 1.1.0:

Added:
  • ACP Commands system with 15 core commands
  • Flat directory structure with dot notation
  • Command template for creating custom commands
  • Third-party command installation via @acp-install

Changed:
  • Improved installation scripts
  • Better autocomplete support
  • Enhanced documentation

Fixed:
  • Various bug fixes and improvements

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 To update, run: @acp-version-update

📚 Full changelog:
  https://github.com/prmichaelsen/agent-context-protocol/blob/mainline/CHANGELOG.md
```

### Status Update
No status changes - read-only operation

---

## Examples

### Example 1: Session Start Check

**Context**: Starting work session, want to check for updates

**Invocation**: `@acp-version-check-for-updates`

**Result**: Shows you're on 1.0.3, latest is 1.1.0, displays what's new, suggests updating

### Example 2: Already Up to Date

**Context**: Checking for updates after recent update

**Invocation**: `@acp-version-check-for-updates`

**Result**: Confirms you're on latest version (1.0.3), no action needed

### Example 3: No Internet Connection

**Context**: Offline, trying to check for updates

**Invocation**: `@acp-version-check-for-updates`

**Result**: Reports cannot connect to repository, shows current version, suggests trying again when online

---

## Related Commands

- [`@acp-version-check`](acp.version-check.md) - Show current version without checking for updates
- [`@acp-version-update`](acp.version-update.md) - Apply updates if available
- [`@acp-init`](acp.init.md) - Includes update check as first step

---

## Troubleshooting

### Issue 1: Script not found

**Symptom**: Error "acp.version-check-for-updates.sh not found"

**Cause**: Older ACP installation without update scripts

**Solution**: Update ACP manually by downloading latest AGENT.md, or install update scripts from repository

### Issue 2: Network error

**Symptom**: Error "Cannot connect to repository"

**Cause**: No internet connection or GitHub unavailable

**Solution**: Check internet connection and try again. Use `@acp-version-check` to see current version offline.

### Issue 3: Permission denied

**Symptom**: Error "Permission denied" when running script

**Cause**: Script not executable

**Solution**: Run `chmod +x agent/scripts/acp.version-check-for-updates.sh` to make it executable

---

## Security Considerations

### File Access
- **Reads**: `AGENT.md`, `CHANGELOG.md`
- **Writes**: None (read-only command)
- **Executes**: `./agent/scripts/acp.version-check-for-updates.sh`

### Network Access
- **APIs**: GitHub API (via check-for-updates script)
- **Repositories**: Accesses ACP repository to check latest version

### Sensitive Data
- **Secrets**: Does not access any secrets or credentials
- **Credentials**: Does not access any credentials

---

## Notes

- Non-destructive operation - only checks, doesn't modify files
- Requires internet connection to check for updates
- Part of `@acp-init` workflow
- Safe to run multiple times
- Update check script may cache results briefly
- Shows changelog diff between versions

---

**Namespace**: acp
**Command**: version-check-for-updates
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.0.3+
**Author**: ACP Project
