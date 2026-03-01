# Task 94: Testing and Documentation

**Milestone**: M12 — Sessions System
**Status**: Not Started
**Estimated Hours**: 2-3
**Dependencies**: Tasks 91, 92, 93
**Design**: [local.sessions-system.md](../../design/local.sessions-system.md)

---

## Objective

Create comprehensive E2E test suite for sessions system and update project documentation (AGENT.md, README.md, CHANGELOG.md).

---

## Steps

### 1. Create E2E Test Suite
- Create `e2e/acp.sessions.test.sh`
- Use existing test framework (`tests/common.sh`)

**Test scenarios**:
1. **Register session** — creates entry with all fields, auto-generates ID
2. **Register with description** — custom description stored correctly
3. **Register with remote URL** — remote_url field populated
4. **List sessions** — shows registered session(s)
5. **List with project filter** — only shows matching project
6. **List empty** — graceful output when no sessions
7. **Deregister by ID** — removes specific session
8. **Deregister by PID** — auto-detects current session
9. **Clean stale (dead PID)** — removes session with non-existent PID
10. **Clean stale (timeout)** — removes session with old last_activity
11. **Heartbeat** — updates last_activity and optional fields
12. **Count** — outputs correct integer
13. **Multiple sessions same project** — both registered and listed
14. **Auto-create sessions.yaml** — file created on first register
15. **Missing script graceful** — commands skip session steps without error

**Target**: 15+ test scenarios, 40+ assertions

### 2. Update AGENT.md
- Add "Sessions System" section after "Project Registry System"
- Document:
  - What sessions.yaml tracks
  - `@acp.sessions` command usage
  - How sessions integrate with @acp.init, @acp.status, @acp.report
  - Session lifecycle (register → heartbeat → deregister/timeout)

### 3. Update README.md
- Add `@acp.sessions` to "Available Commands" under Workflow Commands
- Add brief "Sessions" section explaining multi-project session tracking

### 4. Update CHANGELOG.md
- Add version entry for M12
- Document: sessions.yaml, acp.sessions.sh, @acp.sessions command, init/status/report integration

### 5. Update Design Doc Status
- Change `local.sessions-system.md` status from "Design Specification" to "Implemented"

### 6. Version Bump
- Determine version bump (minor — new feature, backward compatible)
- Update version in AGENT.md, package.yaml, progress.yaml

---

## Verification

- [ ] E2E tests created with 15+ scenarios
- [ ] All tests passing (target: 100%)
- [ ] AGENT.md updated with Sessions System section
- [ ] README.md updated with @acp.sessions command
- [ ] CHANGELOG.md entry added
- [ ] Design doc status updated to Implemented
- [ ] Version bumped across all files
- [ ] No existing tests broken

---

## Notes

- Follow existing E2E test patterns (see `e2e/acp.project-set.test.sh` for reference)
- Tests should create temp `~/.acp/sessions.yaml` and clean up after
- Test stale detection by writing entries with old timestamps and fake PIDs
- Version bump is minor (new feature, no breaking changes)
