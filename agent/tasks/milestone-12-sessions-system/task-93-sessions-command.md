# Task 93: @acp.sessions Command

**Milestone**: M12 — Sessions System
**Status**: Not Started
**Estimated Hours**: 2-3
**Dependencies**: Task 91
**Design**: [local.sessions-system.md](../../design/local.sessions-system.md)

---

## Objective

Create the dedicated `@acp.sessions` command document with full NLP argument parsing, CLI flag support, and comprehensive documentation.

---

## Context

This is the primary user-facing command for session management. It wraps `acp.sessions.sh` subcommands with a user-friendly interface that supports both explicit flags and natural language.

---

## Steps

### 1. Create acp.sessions.md
- Follow command.template.md structure
- Namespace: `acp`
- Scripts: `acp.sessions.sh`
- Category: Workflow
- Frequency: As Needed

### 2. Define Arguments Section
**CLI-Style Arguments**:
- `list` (default) — list all active sessions
- `clean` — remove stale sessions
- `deregister` — end current session
- `--project <name>` — filter by project
- `--id <session-id>` — target specific session

**Natural Language Arguments**:
- "what's running?" → list
- "show remember-core" → list --project remember-core
- "stop my session" → deregister
- "clean up" → clean
- "how many sessions?" → count

### 3. Define Steps
1. Parse arguments (CLI or NLP)
2. Run `acp.sessions.sh clean` (always, to remove stale first)
3. Execute requested subcommand
4. Display formatted output
5. Suggest next actions if relevant

### 4. Define Output Formats

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

### 5. Add Examples Section
- Example 1: List all sessions
- Example 2: Filter by project
- Example 3: Clean stale sessions
- Example 4: Natural language usage

### 6. Add to package.yaml
- Add `acp.sessions.md` to contents.commands
- Add `acp.sessions.sh` to its scripts array

---

## Verification

- [ ] `acp.sessions.md` created following template structure
- [ ] Arguments section covers CLI and NLP
- [ ] Steps are clear and complete
- [ ] Output formats defined for list, clean, deregister, count
- [ ] Examples cover common use cases
- [ ] Security considerations documented
- [ ] Related commands listed
- [ ] package.yaml updated

---

## Notes

- Mark current session with "(this session)" indicator in list output
- NLP parsing should be forgiving — "sessions", "what's active", "running" all map to list
- Always run `clean` before `list` to show accurate state
