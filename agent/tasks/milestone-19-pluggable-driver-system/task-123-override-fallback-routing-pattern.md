# Task 123: Override-with-Fallback Routing Pattern

<!-- @acp.meta.task
topic: override-fallback, routing-pattern, directive-snippet, ext-point-dispatch
description: Establish the reusable directive snippet consumer commands embed at the top of their files to dispatch to the bound driver tool or fall back to ACP defaults
milestone: M19
design: agent/design/local.pluggable-driver-system.md
incorporates: DR7
depends_on: task-121
status: completed
started: 2026-05-04T05:00:00Z
completed: 2026-05-04T06:00:00Z
updated: 2026-05-04
@acp.meta.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — DR7 (override-with-fallback routing)
**Estimated Time**: 2-3 hours

---

## Objective

Author the canonical reusable directive snippet that consumer commands embed (in their markdown directive bodies) to invoke a bound MCP tool when present and fall back to existing behavior when absent. Validate the pattern works on a single sample command before tasks 124, 125, 126 deploy it broadly.

---

## Context

ACP commands are markdown directives interpreted by an LLM. The override-with-fallback model (DR7) requires a small, repeatable snippet the LLM can embed in any consumer command directive: "for ext-point X, check `agent/driver.yaml` for a binding; if bound, invoke that MCP tool; if unbound, do the existing thing."

Without a clean snippet, every consumer command would re-invent the dispatch logic. This task establishes the canonical pattern, names it, and validates it against one real command before tasks 124–126 deploy it across many.

---

## Steps

### 1. Author the directive snippet

Write a short markdown block (~10–20 lines) consumer commands paste at the appropriate point in their step list. The snippet should:

- Direct the agent to consult `agent/driver.yaml` for a binding on a named ext-point
- If bound, invoke the named MCP tool with the appropriate input shape
- If unbound, perform the fallback action (the command's existing behavior, described inline)
- Be parameterizable via simple substitutions: `<EXT_POINT_ID>`, `<INPUT_SHAPE>`, `<FALLBACK_ACTION>`

Draft pattern (for reference; refine in execution):

```markdown
> **🔌 Driver Dispatch — `<EXT_POINT_ID>`**
> Read `agent/driver.yaml`. If `bindings.<EXT_POINT_ID>` is set:
>   - Invoke the named MCP tool with input: <INPUT_SHAPE>
>   - Use the tool's output as the result of this step.
>   - **Do NOT also perform the fallback path "for safety"** — a bound
>     driver may have removed the file/state the fallback reads.
> If `bindings.<EXT_POINT_ID>` is unset (or `agent/driver.yaml` absent):
>   - Perform the fallback: <FALLBACK_ACTION>
> If the bound tool errors AND the binding is set:
>   - Surface the error to the user. Do NOT silently fall through to
>     the fallback — a failed dispatch is NOT permission to use the
>     fallback path.
> If `<EXT_POINT_ID>` is unbound AND the fallback's required state is
> unavailable (e.g., the file the fallback would read does not exist):
>   - Surface a clear, actionable error explaining BOTH paths are
>     unavailable and pointing at resolution (bind a driver, or
>     restore the missing state).
```

The clauses about NOT silently falling through and NOT silently producing empty results are baked into every instance of the snippet, not parameterized. Task-125's notes section 6 codifies the same rule for the specific case of `query.run` + missing `progress.yaml`; the snippet template encodes the rule generically.

### 2. Document the snippet

Create `agent/patterns/local.driver-dispatch-directive.md` (or similar pattern doc) explaining:
- What the snippet does
- The three substitution points
- Examples for each ext point (`marker.mint`, `query.run`, `workflow.run`)
- What "fallback" means for each consumer command (point at the command's existing logic)

### 3. Pilot on one consumer command

Pick one of the simpler consumer commands (suggested: `@acp.sync` since it has clear "before / after" steps) and embed the snippet for one ext point (`query.run`). Verify by reading the resulting directive flow that:
- The dispatch reads naturally
- An LLM following the directive would correctly invoke the tool when bound
- The fallback path is unambiguous

### 4. Tests / validation

This is a directive pattern, not code, so there's no unit test. Validation is:
- Read the resulting modified `acp.sync.md` end-to-end and confirm both paths (bound, unbound) are clear
- (Optional) ask a fresh LLM session to read the pilot command and describe its dispatch behavior; verify it matches intent

### 5. Hand off to tasks 124–126

Tasks 124, 125, 126 will deploy this snippet across their target commands. This task's deliverable is the snippet + pattern doc + one pilot deployment as proof.

---

## User-Observable Acceptance

- [ ] `agent/patterns/local.driver-dispatch-directive.md` exists and contains the canonical snippet with documented substitution points and per-ext-point examples.
- [ ] One existing consumer command file (e.g., `agent/commands/acp.sync.md`) has the snippet embedded and produces correct dispatch behavior on read-through.
- [ ] An agent reading the modified consumer command can describe the bound-vs-unbound paths correctly when prompted.

---

## Verification

- [ ] Snippet is parameterized cleanly (3 named substitution points)
- [ ] Pattern doc covers all three v1 ext points with concrete examples
- [ ] Pilot command's directive flow reads coherently both paths (bound, unbound)
- [ ] Tasks 124, 125, 126 can copy the snippet and deploy it without re-authoring

---

## Expected Output

**Files Created**:
- `agent/patterns/local.driver-dispatch-directive.md` — pattern doc with snippet + examples

**Files Modified**:
- One pilot consumer command (e.g., `agent/commands/acp.sync.md`) — proves the pattern works

---

## Notes

- This task is intentionally NOT about touching all consumer commands — that's tasks 124, 125, 126. This task establishes and validates the snippet.
- The snippet is markdown directives, not bash scripts. The LLM is the dispatcher. No `acp.driver-call` script.
- Keep the snippet short. LLMs handle 10-line directives reliably; 30-line directives less so. If the snippet grows, refactor.

---

**Next Tasks**: [Task 124: marker.mint wiring](task-124-marker-mint-wiring.md), [Task 125: query.run wiring](task-125-query-run-wiring.md), [Task 126: workflow override pilot](task-126-workflow-override-pilot.md) — all three apply this task's snippet
