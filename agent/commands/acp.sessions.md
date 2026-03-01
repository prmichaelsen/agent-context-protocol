# Command: sessions

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.sessions` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-sessions` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."
>
> **STEP 0: CHECK FOR ARGUMENTS FIRST.**
> If arguments or natural language follow `@acp.sessions`, detect the subcommand before doing anything else.
> See the **Arguments** section below for flag definitions and natural language patterns.
> If no arguments, default to `list`.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-03-01
**Last Updated**: 2026-03-01
**Status**: Active
**Scripts**: acp.sessions.sh, acp.common.sh, acp.yaml-parser.sh

---

**Purpose**: Manage and view active agent sessions across projects
**Category**: Workflow
**Frequency**: As Needed

---

## Arguments

This command supports both CLI-style flags and natural language arguments.

**CLI-Style Arguments**:
- `list` (default) — list all active sessions
- `clean` — remove stale sessions (dead PIDs, timed out)
- `deregister` — end current session
- `count` — output number of active sessions
- `--project <name>` — filter by project name (used with `list`)
- `--id <session-id>` — target specific session (used with `deregister`)

**Natural Language Arguments**:
- "what's running?" → list
- "show remember-core" → list --project remember-core
- "stop my session" → deregister
- "clean up" → clean
- "how many sessions?" → count
- "what's active?" → list
- "end session" → deregister

**Argument Mapping**:
The agent infers intent from context:
1. Parse explicit CLI-style subcommands/flags if present
2. Extract intent from natural language keywords: `running`, `active`, `stop`, `end`, `clean`, `how many`, `count`
3. Project names after `show` or `for` map to `--project` filter
4. Default to `list` if no subcommand is detected

---

## What This Command Does

This command provides a user-friendly interface for managing agent sessions tracked in `~/.acp/sessions.yaml`. It wraps the `acp.sessions.sh` script subcommands with NLP argument parsing and formatted output.

Sessions are registered when `@acp.init` runs and deregistered when `@acp.report` runs. Between those, this command lets you see what's active, clean stale sessions, or manually end a session.

Use this command when you want to see what other agents are working on, check if stale sessions need cleanup, or manage your current session. The default behavior (`list`) always runs stale cleanup first to show accurate state.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `./agent/scripts/acp.sessions.sh` exists and is executable

---

## Steps

### 1. Parse Arguments

Determine the requested action from CLI flags or natural language.

**Actions**:
- Check for explicit subcommand: `list`, `clean`, `deregister`, `count`
- Check for `--project` and `--id` flags
- Apply natural language mapping if no explicit subcommand
- Default to `list` if no subcommand detected

**Expected Outcome**: Subcommand and options determined

### 2. Run Stale Cleanup

Always clean stale sessions before displaying results.

**Actions**:
- Run `./agent/scripts/acp.sessions.sh clean` (silently, unless `clean` is the explicit subcommand)
- This removes sessions with dead PIDs or inactive for 2+ hours

**Expected Outcome**: Stale sessions removed

### 3. Execute Requested Subcommand

Run the appropriate `acp.sessions.sh` subcommand.

**Actions**:
- **list** (default): Run `./agent/scripts/acp.sessions.sh list [--project <name>]`
- **clean**: Run `./agent/scripts/acp.sessions.sh clean` (verbose output)
- **deregister**: Run `./agent/scripts/acp.sessions.sh deregister [--id <session-id>]`
- **count**: Run `./agent/scripts/acp.sessions.sh count`

**Expected Outcome**: Subcommand executed successfully

### 4. Display Formatted Output

Present results in a clear format.

**List output**:
```
Active Sessions (3):

  sess_a1b2c3  remember-core
               Task 12: Implement Auth Middleware
               Started 45m ago, last active 2m ago

  sess_d4e5f6  agent-context-protocol  (this session)
               Task 91: Sessions Infrastructure
               Started 10m ago, last active now

  sess_g7h8i9  agentbase.me
               Task 5: Fix API Routes
               Started 1h ago, last active 20m ago
```

**Clean output**:
```
Cleaned 2 stale sessions:
  sess_x1y2z3  old-project (PID 12345 not running)
  sess_m4n5o6  test-project (inactive for 3h)

Active sessions remaining: 3
```

**Deregister output**:
```
Session sess_a1b2c3 deregistered.
Active sessions remaining: 2
```

**Count output**:
```
3
```

**Expected Outcome**: User sees formatted session information

### 5. Suggest Next Actions

If relevant, suggest follow-up actions.

**Actions**:
- If sessions are stale: "Run `@acp.sessions clean` to remove stale sessions"
- If no sessions: "Run `@acp.init` to register a new session"
- If showing list: No suggestions needed (informational)

**Expected Outcome**: User knows what to do next (if applicable)

---

## Verification

- [ ] Arguments parsed correctly (CLI or NLP)
- [ ] Stale cleanup ran before list/count
- [ ] Subcommand executed with correct flags
- [ ] Output formatted clearly
- [ ] Edge cases handled (no sessions, missing script)

---

## Expected Output

### Files Modified
- `~/.acp/sessions.yaml` — updated by clean/deregister subcommands

### Console Output
See output formats in Step 4 above.

---

## Examples

### Example 1: List All Sessions (Default)

**Context**: You want to see what's currently running

**Invocation**: `@acp.sessions`

**Result**: Shows all active sessions with project, description, and timing info

### Example 2: Filter by Project

**Context**: You want to see sessions for a specific project

**Invocation**: `@acp.sessions --project remember-core`

**Result**: Shows only sessions for remember-core

### Example 3: Clean Stale Sessions

**Context**: You suspect some sessions are stale

**Invocation**: `@acp.sessions clean`

**Result**: Removes dead-PID and timed-out sessions, shows what was cleaned

### Example 4: Natural Language Usage

**Context**: You want to check what's running using natural language

**Invocation**: `@acp.sessions what's running?`

**Result**: Same as `@acp.sessions list` — shows all active sessions

### Example 5: End Current Session

**Context**: You're done working and want to deregister

**Invocation**: `@acp.sessions stop my session`

**Result**: Deregisters the current session, shows remaining count

---

## Related Commands

- [`@acp.init`](acp.init.md) — Registers session automatically at start
- [`@acp.status`](acp.status.md) — Shows session count in status output
- [`@acp.report`](acp.report.md) — Deregisters session automatically at end

---

## Troubleshooting

### Issue 1: "acp.sessions.sh not found"

**Symptom**: Command reports script not found

**Cause**: Sessions script not installed or path incorrect

**Solution**: Verify `./agent/scripts/acp.sessions.sh` exists and is executable. Run `chmod +x agent/scripts/acp.sessions.sh` if needed.

### Issue 2: Sessions disappear immediately

**Symptom**: Registered sessions are gone on next list

**Cause**: Stale cleanup removing sessions because the registering process PID is dead

**Solution**: Use `--pid <pid>` when registering to track the long-lived parent process (terminal/agent) instead of the script's own PID.

### Issue 3: "No active sessions" when sessions should exist

**Symptom**: List shows no sessions despite recent registration

**Cause**: Sessions were registered under a different process tree and stale cleanup removed them

**Solution**: Re-register with `@acp.init` or manually via `./agent/scripts/acp.sessions.sh register --project <name> --pid <pid>`

---

## Security Considerations

### File Access
- **Reads**: `~/.acp/sessions.yaml`
- **Writes**: `~/.acp/sessions.yaml` (clean, deregister modify the file)
- **Executes**: `./agent/scripts/acp.sessions.sh`

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access secrets or credentials
- **Credentials**: Does not access credentials files
- **PIDs**: Stores process IDs for stale detection (not sensitive)

---

## Notes

- Mark current session with "(this session)" indicator in list output
- NLP parsing should be forgiving — "sessions", "what's active", "running" all map to list
- Always run `clean` before `list` to show accurate state
- Sessions are advisory only — no locking or coordination
- `~/.acp/sessions.yaml` is auto-created on first register

---

**Namespace**: acp
**Command**: sessions
**Version**: 1.0.0
**Created**: 2026-03-01
**Last Updated**: 2026-03-01
**Status**: Active
**Compatibility**: ACP 5.9.1+
**Author**: ACP Project
