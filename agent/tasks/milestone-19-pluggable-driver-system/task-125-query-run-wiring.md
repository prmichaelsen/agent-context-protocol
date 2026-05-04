# Task 125: `query.run` Wiring Across 3 Query-Using Commands

<!-- @acp.meta.task
topic: query-run, dispatch, validate, sync, proceed
description: Wire query.run dispatch into validate, sync, and proceed commands; route through driver when bound, fall back to grep/awk when unbound
milestone: M19
design: agent/design/local.pluggable-driver-system.md
incorporates: DR3, DR12
depends_on: task-121, task-123
status: draft
updated: 2026-05-01
@acp.meta.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — DR3 (query.run contract), DR12 (commands updated)
**Estimated Time**: 3-5 hours

---

## Objective

Embed the driver-dispatch snippet (from task 123) into the 3 ACP commands that query project state, so each consults `agent/driver.yaml` for a `query.run` binding and dispatches to it when bound — falling back to existing grep/awk-based query paths when unbound.

---

## Context

Per DR3, `query.run` is the structured-query ext point. Driver-defined input shape (SQL string, JSON-DSL, structured filter — driver's choice); array-of-rows output. The 3 consumer commands that need queries today (validate, sync, proceed) currently use `acp.meta-scan.sh` + grep + awk to find marker hits and project state. Under the driver model, when bound, those queries route to the driver's tool instead.

Important: this task does NOT replace the marker-scanning step entirely. It adds dispatch around the existing scan-based queries. When unbound, scan + grep continues to work as today.

---

## Steps

### 1. Identify the query points

For each of the 3 commands, identify the steps that issue queries against project state:

- `agent/commands/acp.validate.md` — queries marker hits during validation; may also query for cross-references between markers (task-spec coverage, design-task incorporation)
- `agent/commands/acp.sync.md` — queries existing markers to detect drift between source-of-truth and rendered state
- `agent/commands/acp.proceed.md` — queries current task state to determine what's next

Each command may have multiple query points. Inventory them carefully before applying the snippet.

### 2. Embed the dispatch snippet at each query point

Insert the canonical snippet (task 123) at each query step. Substitutions:
- `<EXT_POINT_ID>` = `query.run`
- `<INPUT_SHAPE>` = the query specification — driver-defined; the snippet should pass the agent's intent (e.g., `"all in_progress tasks"`) as semantic input, with the bound tool's description making clear what input shape it accepts
- `<FALLBACK_ACTION>` = the existing scan + grep + awk pipeline for that specific query

After dispatch:
- **Bound path**: agent calls `query.run` with the appropriate input, receives row array, processes results
- **Unbound path**: agent runs the existing grep/awk pipeline, processes the text output

### 3. Handle input-shape variability

Different drivers will accept different query shapes — some drivers take SQL, others may take JSON DSL or structured filters. The dispatch snippet should not hardcode a query shape. Two valid approaches:

**Approach A (preferred)**: pass natural-language intent in the input. The driver's tool description tells the LLM what shape the tool expects; the LLM translates intent → shape. Example: `query.run({intent: "all tasks where status=in_progress", milestone: "M6"})`.

**Approach B**: the consumer command specifies the query shape in the snippet, parameterized by what's needed. Less flexible across driver implementations; only adopt if Approach A proves unreliable in pilot.

### 4. Pilot on one command first

Apply the change to `acp.validate.md` first (it has the most clearly defined queries). Verify dispatch reads cleanly and the LLM correctly invokes the bound tool with appropriate input. Then proceed to sync and proceed.

### 5. Tests

Per command, exercise both paths:
- **Unbound**: existing behavior preserved — grep/awk pipeline runs, command produces same output as today
- **Bound (mock MCP server)**: dispatch invokes the mock; mock returns mock rows; command processes them and produces equivalent output

### 6. Failure semantics for progress-state reads (added per prior cross-project handoff)

A driver may remove ACP-owned state files when bound — notably `progress.yaml`,
which `a driver's init step` deletes outright in favor of project.db. Consumer commands
that today read `progress.yaml` directly must follow strict binding-first
order:

1. **Check `query.run` binding first.** If bound, use it. Period. Do NOT also
   read `progress.yaml` "for safety" — the file may not exist, and reading it
   silently risks divergence from the driver's authoritative state.
2. **Fall back to `progress.yaml` only when `query.run` is unbound.** This is
   the today-behavior path.
3. **Surface a clear error if neither path is viable** — i.e., `query.run`
   unbound AND `progress.yaml` missing. Do NOT silently produce empty results
   or fail with an opaque "file not found" trace. The error message should
   point the user at the resolution: bind a driver via `agent/driver.yaml`,
   or restore `agent/progress.yaml` from `agent/progress.template.yaml`.

The directive language embedded by the dispatch snippet (task 123) should
make this ordering and failure path explicit, not leave it to LLM judgment.

### 6. Index updates

If `acp.validate.md`, `acp.sync.md`, or `acp.proceed.md` are referenced in `agent/index/local.main.yaml` or `agent/index/acp.core.yaml`, ensure descriptions/rationales are current.

---

## User-Observable Acceptance

- [ ] In a project without `agent/driver.yaml`, `@acp.validate`, `@acp.sync`, and `@acp.proceed` produce identical output to current behavior.
- [ ] In a project with a mock-bound driver providing `query.run`, all three commands invoke the mock at appropriate steps and process its results.
- [ ] At least one query per command actually exercises the dispatch (verified by mock-tool call logs).
- [ ] Failure in `query.run` invocation surfaces as an error, not a silent fallback to grep/awk.

---

## Verification

- [ ] All query points in each of the 3 commands inventoried before snippet deployment
- [ ] Same dispatch snippet shape used across all 3 commands (only substitutions differ)
- [ ] Approach A (natural-language intent) used unless pilot shows it unreliable
- [ ] Both paths (bound, unbound) tested per command
- [ ] Existing test fixtures (without driver.yaml) pass unchanged
- [ ] Mint pairing invariant (DR6) held: if `query.run` is bound, the test fixtures also have `marker.mint` bound
- [ ] Pilot command (`acp.validate`) signed off before sync and proceed are touched

---

## Expected Output

**Files Modified** (3):
- `agent/commands/acp.validate.md`
- `agent/commands/acp.sync.md`
- `agent/commands/acp.proceed.md`

**Files Created**:
- E2E tests covering bound + unbound paths per command (extending or alongside existing tests)

---

## Notes

- `query.run` failures must surface clearly — do NOT silently fall back to grep/awk on driver error. Falling back masks the broken integration; surfacing the error tells the user what to fix.
- The existing grep/awk paths are the fallback. They should remain intact as the unbound branch — don't refactor them away "since the driver will handle it."
- If pilot reveals that natural-language intent (Approach A) is unreliable, fall back to Approach B. Document the choice in the modified command file's notes.

---

**Next Task**: [Task 126: Workflow override pilot](task-126-workflow-override-pilot.md)
