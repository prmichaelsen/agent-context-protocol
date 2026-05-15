# Task 124: `marker.mint` Wiring Across 6 Stamping Commands

<!-- @scry.entry
id: task.marker-mint-wiring~287660a9
kind: task
summary: >
  Wire marker.mint dispatch into the 6 ACP commands that stamp markers;
  agent stamps directly using mint output.
status: completed
weight: 0.6
tags: ["topic:marker-mint", "topic:stamping", "topic:six-commands", "scope:m19"]
rationale: ""
applies: ""
seeded_questions: []
milestone: M19
design: agent/design/local.pluggable-driver-system.md
incorporates: DR2, DR9, DR12
depends_on: [task-121, task-123]
started: 2026-05-04T07:55:00Z
completed: 2026-05-04T08:10:00Z
updated: 2026-05-04
@scry.entry.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — DR2 (mint contract), DR9 (marker authority transfer), DR12 (commands updated)
**Estimated Time**: 3-5 hours

---

## Objective

Embed the driver-dispatch snippet (from task 123) into the 6 ACP commands that stamp markers, so each command consults `agent/driver.yaml` for a `marker.mint` binding and dispatches to it when bound — falling back to the existing hardcoded `@acp.meta.<kind>` stamping when unbound. The agent owns the file write in both paths; mint just produces the canonical ID + field schema.

---

## Context

Per design (DR2), the driver issues canonical IDs and provides field schema with per-field instructions; the agent assembles the marker block and writes the file. Per DR9, when a driver is bound, ACP does not stamp `@acp.meta.*` markers anywhere — the project speaks the driver's marker vocabulary exclusively. The 6 commands listed in DR12 all hardcode `<!-- @acp.meta.<kind> ... -->` blocks today; this task replaces that with dispatch through `marker.mint` when bound.

---

## Steps

### 1. Identify the stamping points

For each of the 6 commands, identify the exact step in the existing markdown directive where the marker block is written into the new file:

- `agent/commands/acp.task-create.md` — stamps `@acp.meta.task`
- `agent/commands/acp.spec.md` — stamps `@acp.meta.spec`
- `agent/commands/acp.design-create.md` — stamps `@acp.meta.design`
- `agent/commands/acp.pattern-create.md` — stamps `@acp.meta.pattern`
- `agent/commands/acp.command-create.md` — stamps `@acp.meta.command` (verify; may be different in current state)
- `agent/commands/acp.clarification-create.md` — stamps `@acp.meta.clarification`

### 2. Embed the dispatch snippet at each stamping point

Insert the canonical snippet from task 123 at the stamping step of each command. Substitutions:
- `<EXT_POINT_ID>` = `marker.mint`
- `<INPUT_SHAPE>` = `{kind: "<kind-for-this-command>", context: { ... }}` where `<kind-for-this-command>` is `task` / `spec` / `design` / `pattern` / `command` / `clarification`
- `<FALLBACK_ACTION>` = the existing instructions for stamping `@acp.meta.<kind>` with the kind's specific fields

After dispatch:
- **Bound path**: agent calls `marker.mint`, receives `{id, marker_open, marker_close, fields[]}`, fills field values per the per-field `instructions`, assembles the block, writes the file.
- **Unbound path**: agent stamps `@acp.meta.<kind>` block with the existing template fields. No behavior change from today.

### 3. Pilot on one command first

Apply the change to `acp.task-create.md` first. Verify the dispatch reads cleanly and an LLM following the directive in a bound-driver context would call mint and assemble correctly. Then proceed to the other 5.

### 4. Tests

Per command, exercise both paths:
- **Unbound (no `agent/driver.yaml`)**: existing behavior preserved — file gets `<!-- @acp.meta.<kind> ... -->` block with current schema. (E2E test against existing test fixtures.)
- **Bound (mock MCP server)**: file gets a marker block matching whatever mint returned. The block does NOT contain `@acp.meta.*`.

### 5. Update `agent/index/local.main.yaml` if needed

If the modified command files are referenced by index entries with weight ≥ 0.7, ensure the entries' `description` and `rationale` still reflect current behavior.

---

## User-Observable Acceptance

- [ ] In a project without `agent/driver.yaml`, running `@acp.task-create` in a fresh session produces a task file with `<!-- @acp.meta.task ... -->` exactly as today.
- [ ] In a project with a mock-bound driver providing `marker.mint`, running `@acp.task-create` produces a task file with the driver-defined marker block (e.g., `<!-- @example.doc ... -->`) — no `@acp.meta.task` stamping occurs.
- [ ] All 6 commands behave the same way for their respective marker kinds.
- [ ] The dispatch snippet is identical across all 6 commands (only the substitutions differ).

---

## Verification

- [ ] All 6 commands have the dispatch snippet embedded at the correct step
- [ ] Substitutions are consistent (same snippet shape, only `<kind>` and field-specific fallback differs)
- [ ] Both paths (bound, unbound) tested per command
- [ ] No `@acp.meta.*` literal text remains in the bound path
- [ ] Existing test fixtures (without driver.yaml) pass unchanged
- [ ] Pilot command (`acp.task-create`) signed off before the other 5 are touched (catches snippet bugs early)

---

## Expected Output

**Files Modified** (6):
- `agent/commands/acp.task-create.md`
- `agent/commands/acp.spec.md`
- `agent/commands/acp.design-create.md`
- `agent/commands/acp.pattern-create.md`
- `agent/commands/acp.command-create.md`
- `agent/commands/acp.clarification-create.md`

**Files Created**:
- E2E tests for each command's bound + unbound paths (under `e2e/` or wherever current tests live)

---

## Notes

- This task touches 6 command files but applies the **same pattern**. If a single command turns out to need bespoke logic (e.g., spec stamping has unique requirements), surface it during pilot and either inline the variation or split off a sub-task.
- The mint response shape is illustrative; the agent should tolerate any `{id, marker_open, marker_close, fields[]}` shape returned by the bound tool. Don't hardcode field names.
- The fallback path's "existing template fields" should be lifted from the current hardcoded marker block in each command — keep that logic intact, just gate it behind the unbound branch.

---

**Next Task**: [Task 125: query.run wiring](task-125-query-run-wiring.md)
