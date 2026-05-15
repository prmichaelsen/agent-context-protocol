# Command: version-check

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-version-check` has been invoked. Follow the steps below to execute this command.

> **🔌 Driver Override Check** (TOP-OF-FILE — runs BEFORE any other step in this file)
>
> 1. Read `agent/driver.yaml`. If the file does not exist OR there is no `workflows.acp.version-check` mapping, jump to step 5 (fallback to the markdown steps below).
> 2. Look up `bindings.workflow.run` — the MCP tool name this driver uses for workflow dispatch. If the mapping exists but `workflow.run` is unbound, surface a clear configuration error (`"workflows.acp.version-check is mapped but bindings.workflow.run is unset in agent/driver.yaml"`) and STOP.
> 3. Invoke that MCP tool with input `{action: "start", workflow: <mapped-value>, args: <user-arguments-from-this-invocation>}`. The command is now BLOCKED — execute the workflow loop per the canonical pattern (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): follow each returned `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion or termination. The workflow's final output IS this command's output. **STOP. Do NOT execute any of the markdown steps below.**
> 4. **Error handling** (one-shot AND every loop iteration):
>    - If any tool response contains an `"error"` key, surface that message to the user and STOP. Do NOT fall through to the markdown steps below — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule.
> 5. **Fallback (only when `workflows.acp.version-check` is unmapped or `agent/driver.yaml` is absent):** Proceed to the markdown steps below as written — they describe ACP's default behavior for this command.
>
> ⚠️  **The rest of this file is the unbound-case fallback.** If the override block above dispatched a workflow (whether it completed successfully or errored), do NOT also execute the steps below. They are "execute only if step 5 above is the path you took."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-02-16  
**Last Updated**: 2026-02-16  
**Status**: Active  
**Scripts**: acp.version-check.sh  

---

**Purpose**: Display current ACP version and compatibility information  
**Category**: Maintenance  
**Frequency**: As Needed  

---

## What This Command Does

This command displays the current version of ACP installed in the project by running a simple script that extracts version information from AGENT.md. It provides a quick way to check which version you're using without needing to manually open files.

Use this command when you need to verify your ACP version, check compatibility with other tools, or before reporting issues. It's a simple, read-only operation that provides version information at a glance.

Unlike `@acp-version-check-for-updates` which checks for newer versions, this command only shows your current version without making any network requests.

---

## Prerequisites

- [ ] ACP installed in project (AGENT.md exists)
- [ ] `agent/scripts/acp.version-check.sh` exists (or can extract from AGENT.md directly)

---

## Steps

### 0. Display Command Header

Display the following informational header, then continue immediately:

```
⚡ @acp.version-check
  Display current ACP version and compatibility information

  Related:
    @acp.version-check-for-updates   Check if newer version available
    @acp.version-update              Update to latest version
```

### 1. Run Version Script

Execute the version check script.

**Actions**:
- Run `./agent/scripts/acp.version-check.sh`
- Script extracts version from AGENT.md using grep
- Displays version, created date, and status

**Expected Outcome**: Version information displayed  

**Alternative** (if script doesn't exist):
```bash
# Extract version directly from AGENT.md
grep -m 1 "^\*\*Version\*\*:" AGENT.md | sed 's/.*: //'
```

---

## Verification

- [ ] Version script executed successfully (or AGENT.md read directly)
- [ ] Version number displayed
- [ ] Output is clear and well-formatted
- [ ] No errors encountered

---

## Expected Output

### Files Modified
None - this is a read-only command

### Console Output
```
📦 ACP Version Information

Version: 1.0.3
Created: 2026-02-11
Status: Production Pattern

✓ ACP is installed

To check for updates: ./agent/scripts/acp.version-check-for-updates.sh
To update ACP: ./agent/scripts/acp.version-update.sh
```

### Status Update
No status changes - read-only operation

---

## Examples

### Example 1: Quick Version Check

**Context**: Want to know which ACP version you're using  

**Invocation**: `@acp-version-check`  

**Result**: Shows version 1.0.3, created 2026-02-11, status: Production Pattern  

### Example 2: Before Reporting Issue

**Context**: Need to report a bug and want to include version info  

**Invocation**: `@acp-version-check`  

**Result**: Displays version 1.0.3, helps you provide accurate bug report  

### Example 3: Verifying Installation

**Context**: Just installed ACP, want to confirm it worked  

**Invocation**: `@acp-version-check`  

**Result**: Shows version installed, confirms ACP is working  

---

## Related Commands

- [`@acp-version-check-for-updates`](acp.version-check-for-updates.md) - Check if newer version available
- [`@acp-version-update`](acp.version-update.md) - Update to latest version
- [`@acp-init`](acp.init.md) - Includes version check as part of initialization

---

## Troubleshooting

### Issue 1: AGENT.md not found

**Symptom**: Error message "AGENT.md not found"  

**Cause**: ACP not installed or AGENT.md deleted  

**Solution**: Reinstall ACP using the installation script  

### Issue 2: Script not found

**Symptom**: Error "acp.version-check.sh not found"  

**Cause**: Older ACP installation without version script  

**Solution**: Extract version directly from AGENT.md using grep command shown in Steps section  

### Issue 3: Version not found in AGENT.md

**Symptom**: Grep returns no results  

**Cause**: AGENT.md format changed or corrupted  

**Solution**: Manually open AGENT.md and check header, or update ACP to latest version  

---

## Security Considerations

### File Access
- **Reads**: `AGENT.md`
- **Writes**: None (read-only command)
- **Executes**: `./agent/scripts/acp.version-check.sh` (simple grep script)

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access any secrets or credentials
- **Credentials**: Does not access any credentials

---

## Notes

- This is a read-only command with no side effects
- No network access required
- Fast operation (runs simple grep command)
- Safe to run anytime
- Useful for troubleshooting and bug reports
- Can be run offline
- Script is simple and safe (just reads AGENT.md)

---

**Namespace**: acp  
**Command**: version-check  
**Version**: 1.0.0  
**Created**: 2026-02-16  
**Last Updated**: 2026-02-16  
**Status**: Active  
**Compatibility**: ACP 1.0.3+  
**Author**: ACP Project  
