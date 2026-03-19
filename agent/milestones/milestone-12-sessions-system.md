# Milestone 12: Sessions System

**Goal**: Implement global session tracking for concurrent multi-project agent work, enabling cross-session awareness from a single IDE instance  
**Duration**: 1-2 weeks  
**Dependencies**: None (self-contained feature)  
**Status**: Not Started  

---

## Overview

This milestone implements the ACP Sessions System as specified in the design document (`agent/design/local.sessions-system.md`). It adds a global `~/.acp/sessions.yaml` file that tracks active agent sessions across projects, a self-contained `acp.sessions.sh` script, a dedicated `@acp.sessions` command, and lightweight integration into existing commands via directive-level updates.

**Key design constraint**: The sessions system is fully self-contained. Existing stable commands do NOT depend on sessions.yaml or the sessions script at the shell level. Integration happens in command markdown directives as optional steps that gracefully skip if the script is missing.  

**Existing infrastructure**:
- `~/.acp/` directory and global manifest (M5)
- `~/.acp/projects.yaml` project registry (M7)
- `acp.yaml-parser.sh` for YAML read/write
- `acp.common.sh` for shared utilities

**What this milestone adds**:
- `~/.acp/sessions.yaml` schema and template
- `agent/scripts/acp.sessions.sh` (self-contained, 6 subcommands)
- `agent/commands/acp.sessions.md` (dedicated command with NLP support)
- Directive-level integration in `@acp.init`, `@acp.status`, `@acp.report`
- E2E test suite

---

## Deliverables

### 1. Schema and Infrastructure
- `~/.acp/sessions.yaml` file format (11 fields per session entry)
- `sessions.template.yaml` for initialization
- Session ID generation (sess_ + 6 hex chars)
- Stale detection (PID check + 30min idle / 2hr timeout)

### 2. Self-Contained Script
- `agent/scripts/acp.sessions.sh` with 6 subcommands:
  - `register` — add session entry
  - `deregister` — remove session entry
  - `list` — show active sessions (with --project filter)
  - `clean` — remove stale sessions
  - `heartbeat` — update last_activity and current_task
  - `count` — output session count for embedding

### 3. Dedicated Command
- `agent/commands/acp.sessions.md` with NLP argument parsing
- CLI flags: `--project`, `clean`, `deregister`
- Natural language: "what's running?", "stop my session", "show remember-core"

### 4. Command Integration
- `@acp.init` — optional step: register session + show siblings
- `@acp.status` — optional step: show session count
- `@acp.report` — optional step: deregister session
- All integrations gracefully skip if acp.sessions.sh is absent

---

## Success Criteria

- [ ] `acp.sessions.sh register` creates session entry in `~/.acp/sessions.yaml`
- [ ] `acp.sessions.sh list` displays active sessions with project, task, age
- [ ] `acp.sessions.sh deregister` removes session by ID
- [ ] `acp.sessions.sh clean` removes stale sessions (dead PID or timeout)
- [ ] `acp.sessions.sh heartbeat` updates last_activity timestamp
- [ ] `acp.sessions.sh count` outputs integer count
- [ ] `@acp.sessions` command works with CLI flags and natural language
- [ ] `@acp.init` shows active sibling sessions (compact format)
- [ ] `@acp.report` deregisters session on completion
- [ ] Multiple sessions per project supported
- [ ] Missing sessions.yaml created automatically on first register
- [ ] E2E tests passing for all subcommands
- [ ] No existing command breaks if sessions feature is absent

---

## Key Files to Create/Modify

```
agent/
├── scripts/
│   └── acp.sessions.sh                (NEW — self-contained, 6 subcommands)
├── commands/
│   └── acp.sessions.md                (NEW — dedicated command with NLP)
├── milestones/
│   └── milestone-12-sessions-system.md (this file)
├── tasks/
│   └── milestone-12-sessions-system/
│       ├── task-91-sessions-infrastructure.md
│       ├── task-92-sessions-init-integration.md
│       ├── task-93-sessions-command.md
│       └── task-94-sessions-testing-documentation.md
├── design/
│   └── local.sessions-system.md       (EXISTS — design spec)
└── sessions.template.yaml             (NEW — template for ~/.acp/sessions.yaml)

~/.acp/
└── sessions.yaml                      (CREATED at runtime)
```

---

## Tasks

1. [Task 91: Sessions Infrastructure](../tasks/milestone-12-sessions-system/task-91-sessions-infrastructure.md) — Schema, template, acp.sessions.sh with all 6 subcommands (4-6h)
2. [Task 92: Init and Report Integration](../tasks/milestone-12-sessions-system/task-92-sessions-init-integration.md) — Directive-level integration in @acp.init, @acp.status, @acp.report (1-2h)
3. [Task 93: @acp.sessions Command](../tasks/milestone-12-sessions-system/task-93-sessions-command.md) — Dedicated command with NLP argument parsing (2-3h)
4. [Task 94: Testing and Documentation](../tasks/milestone-12-sessions-system/task-94-sessions-testing-documentation.md) — E2E tests, AGENT.md, README.md, CHANGELOG.md updates (2-3h)

**Total Estimated**: 9-14 hours  

---

## Testing Requirements

- [ ] All 6 subcommands pass E2E tests
- [ ] Stale detection works (dead PID, timeout)
- [ ] Multiple sessions per project register correctly
- [ ] Missing sessions.yaml handled gracefully
- [ ] Concurrent register doesn't corrupt file (basic test)
- [ ] @acp.init displays siblings correctly
- [ ] @acp.report deregisters correctly
- [ ] NLP argument parsing works for common phrases

---

## Documentation Requirements

- [ ] AGENT.md updated with Sessions System section
- [ ] README.md updated with sessions commands
- [ ] CHANGELOG.md entry for M12
- [ ] Design doc status updated to Implemented

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|---|---|---|---|
| YAML corruption from concurrent writes | Medium | Low | Append-only writes, stale cleanup fixes duplicates |
| PID detection platform differences | Low | Medium | Timeout is backup mechanism, PID check is best-effort |
| Session accumulation if cleanup fails | Low | Low | Max entries limit, manual `clean` subcommand |
| Integration breaks existing commands | High | Low | Directive-level only, graceful skip if script missing |

---

**Next Milestone**: TBD  
**Blockers**: None  
**Notes**:
- Self-contained design means this can be implemented independently of all other milestones
- No shell-level dependencies added to existing scripts
- Always-on for MVP; configurable toggle deferred to M6 (Preferences)
- Design doc: agent/design/local.sessions-system.md
