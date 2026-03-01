# Task 91: Sessions Infrastructure

**Milestone**: M12 — Sessions System
**Status**: Not Started
**Estimated Hours**: 4-6
**Dependencies**: None
**Design**: [local.sessions-system.md](../../design/local.sessions-system.md)

---

## Objective

Create the self-contained `acp.sessions.sh` script with all 6 subcommands, the `sessions.template.yaml` template, and session ID generation. This is the core infrastructure that all other tasks build on.

---

## Context

The sessions system must be fully self-contained in a single script (`acp.sessions.sh`) that does not modify or depend on `acp.common.sh` at the shell level. It sources `acp.yaml-parser.sh` for YAML operations and `acp.common.sh` for utilities (timestamps, colors), but no other ACP script sources or calls `acp.sessions.sh`.

---

## Steps

### 1. Create sessions.template.yaml
- Create `agent/sessions.template.yaml` with empty sessions array
- Include header comment: "Managed by acp.sessions.sh — do not edit manually"
- Fields: `sessions: []`, `last_updated: null`

### 2. Create acp.sessions.sh
- Self-contained bash script with subcommand dispatch
- Source `acp.yaml-parser.sh` and `acp.common.sh`
- Implement argument parsing for subcommands

### 3. Implement `register` subcommand
- Generate session ID: `sess_$(head -c 3 /dev/urandom | xxd -p)`
- Accept: `--project <name>`, `--description <desc>`, `--remote-url <url>`
- Auto-detect: PID (`$$`), terminal (`tty`), timestamps
- Auto-infer description from project's `progress.yaml` current task (if not provided)
- Read current milestone/task from project's `progress.yaml`
- Create `~/.acp/sessions.yaml` if missing (from template)
- Append session entry to sessions array
- Run stale cleanup before registering
- Output: session ID and confirmation

### 4. Implement `deregister` subcommand
- Accept: `--id <session-id>` or auto-detect by PID
- Remove matching session entry from sessions.yaml
- Update last_updated timestamp
- Output: confirmation or "session not found"

### 5. Implement `list` subcommand
- Accept: `--project <name>` for filtering
- Display active sessions: project, description, task, age (relative time)
- Run stale cleanup before listing
- Output: formatted table or "No active sessions"

### 6. Implement `clean` subcommand
- Check each session's PID: `kill -0 $pid 2>/dev/null`
- Check each session's last_activity against thresholds:
  - > 30 min: mark as idle
  - > 2 hours: remove
- Remove dead-PID sessions
- Output: count of cleaned sessions

### 7. Implement `heartbeat` subcommand
- Accept: `--id <session-id>`, `--task <task-id>`, `--description <desc>`
- Update `last_activity` timestamp
- Optionally update `current_task` and `description`
- Auto-detect session by PID if `--id` not provided

### 8. Implement `count` subcommand
- Run stale cleanup
- Output: integer count of active sessions (no formatting, for embedding)

### 9. Make script executable
- `chmod +x agent/scripts/acp.sessions.sh`
- Validate syntax: `bash -n agent/scripts/acp.sessions.sh`

---

## Verification

- [ ] `sessions.template.yaml` created
- [ ] `acp.sessions.sh` created and executable
- [ ] `register` creates session entry with all 11 fields
- [ ] `deregister` removes session by ID or PID
- [ ] `list` displays sessions with formatting
- [ ] `list --project` filters correctly
- [ ] `clean` removes dead-PID and timed-out sessions
- [ ] `heartbeat` updates timestamps and fields
- [ ] `count` outputs integer
- [ ] Missing `~/.acp/sessions.yaml` created automatically
- [ ] Script sources yaml-parser and common correctly
- [ ] `bash -n` passes (no syntax errors)

---

## Notes

- Use `source_yaml_parser()` pattern from other scripts
- ID generation: if `xxd` not available, fall back to `$RANDOM`
- Relative time display: "2m ago", "1h ago", "3h ago"
- Stale cleanup is idempotent and runs on list/register/clean
