# Task 126: Workflow-as-Command-Override Pilot (3 Commands)

<!-- @acp.meta.task
topic: workflow-override, command-override-directive, pilot, llm-stop-reliability
description: Add the top-of-file workflow-override directive to acp.task-create, acp.plan, acp.init; pilot dispatch-then-stop reliability before broader rollout
milestone: M19
design: agent/design/local.pluggable-driver-system.md
incorporates: DR4, DR5, DR12
depends_on: task-123
status: draft
updated: 2026-05-01
@acp.meta.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — DR4 (workflow.run contract), DR5 (workflow-as-command-override mechanism), DR12 (commands updated)
**Estimated Time**: 2-3 hours

---

## Objective

Add the top-of-file workflow-override directive to 3 pilot ACP commands (task-create, plan, init), so each consults `agent/driver.yaml` for a `workflows.<command-name>` mapping and dispatches to `workflow.run` with the mapped workflow name when present — falling back to its existing markdown steps when not. Validate the dispatch-then-stop behavior is reliable before broader rollout.

---

## Context

Per design (DR5), workflow override is the headline value-prop for any driver shipping a workflow runtime — replacing freeform LLM markdown execution with stateful, validated, between-step-enforcing workflows. The mechanism is a **top-of-file directive** in each ACP command file that:

1. Checks `agent/driver.yaml` for a `workflows.<this-command-name>` mapping
2. If present, invokes `workflow.run(action="run", workflow=<mapped-name>)` and **STOPS**
3. If absent, executes the command's existing markdown steps as fallback
4. On `workflow.run` failure: surfaces the error to the user; does NOT silently fall through to markdown steps

The "STOP" semantic is the load-bearing reliability concern (DR5, Trade-offs). LLMs sometimes treat fallback paths as additive. This pilot collects evidence on reliability before deploying the directive to all ~37 ACP commands (which is a separate, post-M19 effort).

---

## Steps

### 1. Author the canonical override directive

Write the exact directive text consumer commands embed at the top of their files. Working draft (refine in execution):

```markdown
> **🤖 Driver Override Check** (TOP-OF-FILE — runs before any other step)
>
> Read `agent/driver.yaml`. Look up `workflows.<this-command-name>` (where
> `<this-command-name>` is the command name in the file header above, e.g.
> `acp.task-create`).
>
> **If a mapping exists**:
>   1. Invoke the bound `workflow.run` tool with input:
>      `{action: "run", workflow: <mapped-workflow-name>, args: <user-arguments-from-this-invocation>}`
>   2. **STOP. Do not execute any of the steps below.** The steps below are
>      ONLY the fallback path used when no mapping exists.
>   3. If the workflow invocation returns an error, surface it to the user
>      with the exact error text. Do NOT silently fall through to the steps
>      below — a failed workflow is NOT permission to use the markdown path.
>
> **If no mapping exists** (or `agent/driver.yaml` is absent):
>   - Proceed to the steps below normally.
>
> ⚠️  This is the only place this directive appears in this file. The rest
> of the file is the fallback markdown for the unbound case. Treat it as
> "execute only if the override block above did NOT dispatch."
```

This wording is intentionally repetitive on the "STOP" point — LLM reliability concern.

### 2. Apply the directive to 3 pilot commands

Insert the directive at the very top of each file, immediately after the existing agent-directive block (the "Pretend this command was entered with this additional context" lines). The new override block goes before any "Steps" section.

- `agent/commands/acp.task-create.md`
- `agent/commands/acp.plan.md`
- `agent/commands/acp.init.md`

For each, also add a note near the top of the existing Steps section (or rename the section) clarifying: "These steps are the fallback for the unbound case. If a workflow override applies, the directive at the top of this file dispatches before reaching here."

### 3. Test reliability — bound case

With a mock MCP server bound that exposes `workflow.run`:
- Invoke `@acp.task-create` (pilot) and verify the agent calls `workflow.run` with the correct workflow name and stops without executing the markdown steps
- Repeat 5+ times across different LLM sessions to test "STOP" reliability
- If reliability is poor (steps executed in addition to dispatch), explore structural cues: code-block delimiters around fallback ("```fallback-only" markers), more emphatic STOP wording, or a separator line in the file

### 4. Test reliability — unbound case

Without `agent/driver.yaml`:
- Invoke each pilot command and verify it executes the markdown steps as today
- No regression in current behavior

### 5. Test failure semantics

With a mock MCP server bound that returns an error from `workflow.run`:
- Verify the error surfaces to the user
- Verify the markdown steps are NOT executed as silent fallback
- Verify the error message is clear (includes the workflow name and the driver-side error text)

### 6. Document findings

In a short note at the bottom of `agent/design/local.pluggable-driver-system.md` (or a sibling pattern doc), record:
- Whether the dispatch-then-stop directive worked reliably as written
- Any structural cues that improved reliability (if needed)
- Recommendations for the broader rollout (post-M19)

---

## User-Observable Acceptance

- [ ] In a project with `agent/driver.yaml` mapping `workflows.acp.task-create: <workflow-name>` and a mock MCP server bound, running `@acp.task-create` results in a `workflow.run` invocation and NO execution of the existing task-create markdown steps.
- [ ] In a project without `agent/driver.yaml`, running `@acp.task-create` executes the existing markdown steps and produces a task file as today.
- [ ] In a project with the workflow mapping but the bound `workflow.run` tool returning an error, the error surfaces to the user; the existing markdown steps do NOT silently execute.
- [ ] Same behavior for `@acp.plan` and `@acp.init`.
- [ ] Reliability findings (STOP semantic) documented in design or sibling notes.

---

## Verification

- [ ] Override directive applied to all 3 pilot commands at the very top of the file
- [ ] Directive language is identical across all 3 (only the implicit `<this-command-name>` differs by file)
- [ ] Bound + unbound + failure paths all tested
- [ ] Reliability evidence collected across multiple sessions (not just one)
- [ ] Failure semantics: explicit error surfacing, NOT silent fallback, verified in a real test
- [ ] Findings documented for post-M19 rollout decisions

---

## Expected Output

**Files Modified** (3):
- `agent/commands/acp.task-create.md` — override directive at top
- `agent/commands/acp.plan.md` — override directive at top
- `agent/commands/acp.init.md` — override directive at top

**Files Modified or Created**:
- `agent/design/local.pluggable-driver-system.md` — append a short "Pilot findings" section, OR
- `agent/patterns/local.workflow-override-directive.md` — sibling pattern doc with the canonical directive + reliability findings

**Tests**:
- E2E tests covering bound, unbound, and failure paths for each pilot command

---

## Notes

- This is the highest-risk task in M19 because of the LLM "STOP" reliability concern. Schedule it before task 128 (integration tests) so the integration tests can validate observed pilot behavior.
- If reliability is poor with the directive as written, **don't** add complexity to the directive itself. Try structural cues first (code-block-fenced fallback, separator marks). If those fail, escalate — may indicate the override-with-fallback model itself needs revisiting.
- Pilot scope is intentionally small (3 commands). Resist scope creep — adding 4th and 5th commands here pushes integration tests later. Save broader rollout for the post-M19 follow-up effort.
- The `<user-arguments-from-this-invocation>` placeholder in the directive needs careful thought during execution — depending on how ACP commands receive arguments today, this may need a defined shape. Pick the shape during pilot.

---

**Next Task**: [Task 127: capabilities.watcher consultation](task-127-capabilities-watcher-consultation.md)
