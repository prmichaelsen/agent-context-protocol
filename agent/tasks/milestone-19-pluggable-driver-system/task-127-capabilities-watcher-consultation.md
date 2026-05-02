# Task 127: `capabilities.watcher` Consultation in Consumer Commands

<!-- @acp.meta.task
topic: capabilities-watcher, data-freshness, consumer-commands, no-auto-refresh
description: Consumer commands consult capabilities.watcher and surface stale-data guidance to the user when the driver does not auto-sync
milestone: M19
design: agent/design/local.pluggable-driver-system.md
incorporates: D15
depends_on: task-121, task-123
status: draft
updated: 2026-05-01
@acp.meta.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — D15 (capabilities.watcher)
**Estimated Time**: 1-2 hours

---

## Objective

Wire the `capabilities.watcher` flag from `agent/driver.yaml` into the consumer commands that depend on `query.run` results being current (validate, sync, proceed). Surface stale-data guidance to the user when the flag is false or absent. ACP itself never auto-invokes a refresh tool — the user (or LLM following the guidance) decides whether to refresh.

---

## Context

Per D15, `capabilities.watcher: true` tells consumer commands "the driver's data layer auto-syncs with disk; trust query results." When false or absent, consumer commands MAY surface guidance: "if results seem stale, ask the driver to refresh via its scan/surface tool." The flag is a hint, not a contract; ACP does not verify it via MCP probe.

This task is small (1-2 hours) but matters because the difference between "queries auto-fresh" and "queries possibly stale" is invisible to the user without an explicit signal. The default conservative behavior (assume `watcher: false` if absent) ensures the user is prompted when in doubt.

---

## Steps

### 1. Define the consumer-side check

Author a small directive snippet (similar to task 123's dispatch snippet, but smaller and not parameterized) that consumer commands using `query.run` invoke once per command session:

```markdown
> **🔌 Watcher Capability Check**
> Read `agent/driver.yaml`. If `capabilities.watcher` is true: the driver
> auto-syncs its data layer with disk. Trust query results without asking
> for refresh.
> Otherwise (false or absent): the driver does NOT auto-sync. Note this
> internally. If query results in this command seem inconsistent with
> recent file changes, surface a brief note to the user:
>   "Note: this driver does not auto-sync. If results seem stale, ask the
>    driver to refresh (e.g., via its scan/surface tool) and rerun."
> Do NOT auto-invoke any refresh tool. The decision to refresh is the
> user's.
```

### 2. Embed the check in the 3 query-using commands

Add the snippet to:
- `agent/commands/acp.validate.md`
- `agent/commands/acp.sync.md`
- `agent/commands/acp.proceed.md`

Position it near the top, after the workflow-override directive (task 126) but before the actual query steps. The check runs once per session.

### 3. Tests

- With `capabilities.watcher: true` → no stale-data guidance surfaced
- With `capabilities.watcher: false` → stale-data note appears in output when results are processed
- With `capabilities.watcher` absent → defaults to false; note appears
- With no `agent/driver.yaml` → no watcher concept applies; nothing surfaced

### 4. Documentation

In `agent/design/local.pluggable-driver-system.md` (D15), no changes needed — the design already covers this.

In the modified consumer command files, add a one-liner in their notes section pointing at D15.

---

## User-Observable Acceptance

- [ ] In a project with `capabilities.watcher: true` in `agent/driver.yaml`, running `@acp.validate` produces no stale-data guidance.
- [ ] In a project with `capabilities.watcher: false` (or absent capabilities block), running `@acp.validate` includes a brief note about potential staleness when query results are processed.
- [ ] ACP never auto-calls a refresh tool — verified by mock MCP server logs (no calls to scan/surface unless the user explicitly invokes them).
- [ ] Same behavior for `@acp.sync` and `@acp.proceed`.
- [ ] No `agent/driver.yaml` → no watcher concept applies.

---

## Verification

- [ ] Watcher-check snippet authored and embedded in 3 consumer commands
- [ ] Default behavior when capability absent: assume `false` (conservative)
- [ ] No auto-refresh: ACP never invokes a scan/surface/refresh tool on its own
- [ ] Stale-data note text is brief (1-2 sentences) — not a full warning section
- [ ] Tests cover all four states (true, false, absent capabilities, no driver.yaml)

---

## Expected Output

**Files Modified** (3):
- `agent/commands/acp.validate.md`
- `agent/commands/acp.sync.md`
- `agent/commands/acp.proceed.md`

**Files Modified (small)**:
- Notes section additions in modified commands pointing at D15 reference

---

## Notes

- The flag is a hint, not a contract. The driver's tool descriptions remain the source of truth; this flag is shorthand consumer commands use to decide whether to surface guidance.
- The conservative default (absent → assume false) errs toward over-prompting rather than silent staleness. Drivers that auto-sync are expected to declare it explicitly.
- This task assumes tasks 121 (parser) and 123 (dispatch pattern) have landed; the watcher check is a sibling pattern to the dispatch snippet and uses similar directive style.

---

**Next Task**: [Task 128: Integration and backward-compat tests](task-128-integration-and-backward-compat-tests.md)
