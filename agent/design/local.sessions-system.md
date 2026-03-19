# ACP Sessions System

**Concept**: Global session tracking for concurrent multi-project agent work from a single IDE instance  
**Created**: 2026-03-01  
**Status**: Implemented  

---

## Overview

The ACP Sessions System provides lightweight, advisory tracking of active agent sessions across projects. When a user opens `~/.acp` in VS Code and runs multiple `claude` terminals — each working on a different project (or different areas of the same project) — sessions.yaml gives each agent awareness of what other agents are doing.

This is not a coordination or locking mechanism. It is a visibility layer: agents can see sibling sessions, users can list active work from any terminal, and stale sessions are automatically cleaned up.

**Primary pain point**: Running many remote sessions consumes excessive memory and causes connection interruptions. Working from a single IDE instance with multiple local terminals is more stable, but agents lose cross-project awareness. Sessions.yaml restores that awareness.  

---

## Problem Statement

- Multiple `claude` sessions running concurrently have no awareness of each other
- Users can't easily see "what's running where" without checking each terminal
- No way to track remote session URLs for easy re-access
- Stale sessions (crashed terminals) leave no trace and can't be discovered
- Agents working on related projects can't see what sibling agents are doing

---

## Solution

A single global file at `~/.acp/sessions.yaml` that tracks active sessions. Sessions are registered at `@acp.init` and deregistered at `@acp.report` or via timeout. A dedicated `@acp.sessions` command provides full session management.

**Key design constraint**: The sessions system is self-contained in `acp.sessions.sh`. Existing stable commands (`@acp.init`, `@acp.proceed`, `@acp.status`, `@acp.report`) do NOT depend on sessions.yaml or the sessions script. Integration with those commands happens at the command-directive level (markdown instructions), not at the shell-script level.  

### Alternatives Considered

| Approach | Rejected Because |
|---|---|
| Per-project `agent/sessions.yaml` | Doesn't support cross-project awareness |
| Shared daemon process | Over-engineered, no daemon infrastructure in ACP |
| File locking / coordination | User explicitly wants advisory-only, no locking |
| Session history log | User doesn't need history, just active sessions |

---

## Implementation

### Schema: `~/.acp/sessions.yaml`

```yaml
# ~/.acp/sessions.yaml
# Managed by acp.sessions.sh — do not edit manually

sessions:
  - id: sess_a1b2c3
    project: remember-core
    description: "Task 12: Implement Auth Middleware"
    started: 2026-03-01T14:30:00Z
    last_activity: 2026-03-01T15:10:00Z
    status: active            # active | idle
    current_milestone: M3
    current_task: task-12
    pid: 48291
    terminal: /dev/pts/2
    remote_url: ""

  - id: sess_d4e5f6
    project: agent-context-protocol
    description: "Task 37: Preference Loading Infrastructure"
    started: 2026-03-01T14:32:00Z
    last_activity: 2026-03-01T15:08:00Z
    status: active
    current_milestone: M6
    current_task: task-37
    pid: 48305
    terminal: /dev/pts/3
    remote_url: ""

last_updated: 2026-03-01T15:10:00Z
```

### Session Entry Fields

| Field | Type | Source | Notes |
|---|---|---|---|
| `id` | string | Auto-generated | Short unique ID (e.g., `sess_` + 6 hex chars) |
| `project` | string | `projects.yaml` or cwd | Project name |
| `description` | string | Auto-inferred | From current task name, with manual override |
| `started` | ISO 8601 | Auto | Session registration time |
| `last_activity` | ISO 8601 | Auto | Updated on heartbeat/activity |
| `status` | enum | Auto | `active` or `idle` |
| `current_milestone` | string | `progress.yaml` | Current milestone ID |
| `current_task` | string | `progress.yaml` | Current task ID |
| `pid` | integer | `$$` | Claude process ID for stale detection |
| `terminal` | string | `tty` | TTY identifier |
| `remote_url` | string | User-provided | Optional, for remote session tracking |

### Script: `agent/scripts/acp.sessions.sh`

Self-contained script with these subcommands:

```bash
# Register a new session
acp.sessions.sh register --project <name> [--description <desc>] [--remote-url <url>]

# Deregister current session
acp.sessions.sh deregister --id <session-id>

# List active sessions
acp.sessions.sh list [--project <name>]

# Clean stale sessions
acp.sessions.sh clean

# Update session activity (heartbeat)
acp.sessions.sh heartbeat --id <session-id> [--task <task-id>] [--description <desc>]

# Show session count (for embedding in other command output)
acp.sessions.sh count
```

### Stale Detection

Two mechanisms (both used):

1. **PID check**: `kill -0 $pid 2>/dev/null` — if process doesn't exist, session is stale
2. **Timeout**: If `last_activity` is older than 30 minutes, mark as idle; older than 2 hours, remove

Stale cleanup runs automatically on `list`, `register`, and `clean` subcommands.

### Command Integration (Directive-Level Only)

Integration happens in the markdown command files, NOT in shell scripts. Existing commands call `acp.sessions.sh` as an optional step — if the script is missing or fails, the command continues normally.

| Command | Integration |
|---|---|
| `@acp.init` | Step N: "Run `acp.sessions.sh register` to register session. Run `acp.sessions.sh list` and display active siblings." |
| `@acp.status` | Step N: "Run `acp.sessions.sh count` and display: 'Sessions: N active'" |
| `@acp.report` | Step N: "Run `acp.sessions.sh deregister` to end session." |
| `@acp.sessions` (NEW) | Primary command. Full session management with NLP argument parsing. |

### `@acp.sessions` Command

Dedicated command supporting CLI flags and natural language:

```
@acp.sessions                          # List all active sessions
@acp.sessions --project remember-core  # Filter by project
@acp.sessions clean                    # Remove stale sessions
@acp.sessions deregister               # End current session
@acp.sessions what's running?          # NLP: list
@acp.sessions stop my session          # NLP: deregister
@acp.sessions show remember-core       # NLP: filter by project
```

### Init Display Format

Compact, one line per sibling session:

```
Active Sessions: 2 others
  remember-core — task-12 (Implement Auth) — 20m ago
  agentbase.me — task-5 (Fix API Routes) — 8m ago
```

---

## Benefits

- **Visibility**: See all active work from any terminal
- **Stale cleanup**: Crashed sessions don't linger forever
- **Low coupling**: Self-contained script, existing commands don't break if sessions feature is absent
- **Multi-session per project**: Supports multiple agents working on different areas of the same project
- **Remote URL tracking**: Store remote session URLs for easy re-access
- **Memory reduction**: Encourages local terminals over many remote sessions

---

## Trade-offs

- **Race conditions**: Two sessions registering simultaneously could cause YAML corruption. Mitigated by: writes are append-only and infrequent; worst case is a duplicate entry that gets cleaned up.
- **Platform dependency**: PID-based stale detection uses `kill -0` which is POSIX but behavior varies. Mitigated by: timeout is the backup mechanism.
- **No real-time updates**: Sessions see stale data until the next `acp.sessions.sh` call. Mitigated by: this is advisory-only, staleness is acceptable.

---

## Dependencies

- `acp.yaml-parser.sh` — for reading/writing sessions.yaml
- `acp.common.sh` — for shared utilities (timestamps, colors)
- `~/.acp/` directory — must exist (created by global ACP init)

No external dependencies. No new runtime requirements.

---

## Testing Strategy

- **Unit tests**: Register, deregister, list, clean, heartbeat, count subcommands
- **Stale detection tests**: Mock expired PIDs and old timestamps
- **Concurrent access**: Two scripts registering simultaneously (basic race condition test)
- **Missing file**: Graceful handling when sessions.yaml doesn't exist
- **Integration**: `@acp.init` shows siblings, `@acp.report` deregisters

---

## Migration Path

No migration needed. This is a new feature with a new file (`~/.acp/sessions.yaml`). If the file doesn't exist, it gets created on first `register`. If `acp.sessions.sh` is missing, command directives skip the session step silently.

---

## Future Considerations

- **Configurable toggle**: Once M6 (Preferences) lands, add `sessions.tracking` configurable (default: enabled)
- **Related project warnings**: When `projects.yaml` relationships exist, warn about conflicting work on related projects
- **Session labels**: Let users manually label sessions for easier identification
- **Dashboard view**: `@acp.sessions --dashboard` showing a live-updating terminal view
- **Pruning**: Auto-prune sessions.yaml if it exceeds N entries (shouldn't happen with stale cleanup, but safety valve)

---

**Status**: Implemented  
**Recommendation**: M12 milestone complete — sessions system implemented  
**Related Documents**:
- [Clarification 3: Sessions YAML](../clarifications/clarification-3-sessions-yaml.md)
- [Clarification 4: Sessions YAML Open Questions](../clarifications/clarification-4-sessions-yaml-open-qs.md)
- [Draft: sessions.draft.md](../drafts/sessions.draft.md)
