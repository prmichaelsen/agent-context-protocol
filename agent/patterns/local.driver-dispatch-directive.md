# Driver Dispatch Directive

<!-- @scry.entry
id: pattern.driver-dispatch-directive~92c038e8
kind: pattern
summary: >
  Reusable directive snippet consumer commands embed to route an ext-point through
  a bound MCP tool with strict binding-first ordering and explicit-error fallthrough.
status: active
weight: 0.7
tags: ["topic:driver-dispatch", "topic:override-fallback", "topic:ext-point-routing", "topic:pluggable-driver"]
rationale: >
  Centralizes the override-with-fallback dispatch pattern so every consumer command
  applies it identically — no per-command divergence in routing order or error semantics.
applies: implementing ext-point dispatch in ACP commands, reviewing driver-binding-routing
seeded_questions:
  - "What is the strict binding-first ordering this directive enforces?"
  - "When should I embed this directive vs. the workflow-override-directive?"
  - "What happens when marker.mint returns an error?"
updated: 2026-05-04
@scry.entry.end -->

**Category**: Architecture

---

## Overview

The Driver Dispatch Directive is a parameterized markdown snippet that consumer commands embed at an ext-point in their step list. It tells the agent: "for this ext-point, check `agent/driver.yaml`; if a binding exists, invoke the bound MCP tool; if not, perform the fallback action; on tool error, surface the error and stop — do not silently fall through."

It implements **D7 (Override-with-fallback routing)** from `agent/design/local.pluggable-driver-system.md`. Without a canonical snippet, every consumer command would re-invent dispatch logic in slightly different ways, drifting in subtle but consequential ways (e.g., one command silently falls through on error, another doesn't). The snippet is the contract.

**Driver-agnostic by design.** The snippet never names a specific driver tool. It resolves through `bindings.<EXT_POINT_ID>` so any driver can plug in by binding its tool name in `agent/driver.yaml`. ACP commands stay portable across drivers.

---

## When to Use This Pattern

✅ **Use this pattern when:**
- A consumer command has a step that maps to one of the v1 ext points: `marker.mint`, `query.run`, `workflow.run`.
- The command needs to support both driver-bound projects (dispatch through binding) and driver-less projects (fallback to existing ACP behavior).
- The fallback path reads or writes ACP-owned state (e.g., `progress.yaml`, scanner output) that a bound driver may have removed or replaced.

❌ **Don't use this pattern when:**
- The step is intrinsic to ACP's own behavior and has no extensibility intent (e.g., reading `agent/driver.yaml` itself, or rendering a console banner).
- The ext-point is an entire command override — for that case, use the **command-override directive** at the top of the command file (D5), not this in-step snippet.
- The work is a one-off bash/markdown thing the agent does inline; introducing a binding contract is over-engineering.

---

## Core Principles

1. **Binding-first, strictly.** When a binding exists, the bound tool is the only path. Do not also read ACP's fallback state "for safety" — a bound driver may have removed or replaced that state (e.g., a driver's init step may delete `progress.yaml` in favor of its own data layer).
2. **Explicit error surfacing.** Tool errors are surfaced to the user, not silently masked by falling through to the fallback. A failed dispatch is NOT permission to use the fallback.
3. **Symmetric missing-state handling.** If the binding is absent AND the fallback's required state (file, command output) is also unavailable, surface a clear, actionable error pointing at both resolutions (bind a driver, or restore the missing state). Empty results are a bug.
4. **Driver-agnostic.** The directive resolves through `bindings.<ext-point-id>`; it never names a specific driver tool. Drivers swap in/out by editing `agent/driver.yaml`.
5. **Short and parameterized.** LLMs handle ~10-20 line directives reliably; longer ones drift. Three substitution points: `<EXT_POINT_ID>`, `<INPUT_SHAPE>`, `<FALLBACK_ACTION>`.
6. **Dispatch may be one-shot OR may start a workflow.** A dispatched tool may return a value the consumer step consumes directly (one-shot — typical for `marker.mint` and `query.run`) OR may return a workflow handle whose `instruction` / `input_shape` ACP must execute step-by-step, feeding results back to the same tool, until the workflow reports completion or termination (typical for `workflow.run`). When a workflow is started, the original consumer-command step is **blocked** — ACP becomes the workflow's executor for the duration. The consumer step resumes (consuming the workflow's final output) only after the workflow signals success or termination. Errors mid-workflow follow the same strict-binding-first rule: surface and STOP, no fallback.

---

## Implementation

### The Canonical Snippet

Embed this block at the dispatch point in a consumer command. Replace the three `<...>` substitution markers with concrete values for the call site.

```markdown
> **🔌 Driver Dispatch — `<EXT_POINT_ID>`**
>
> 1. Read `agent/driver.yaml`. If the file does not exist, OR `bindings.<EXT_POINT_ID>` is unset, jump to step 4 (fallback).
> 2. Invoke the MCP tool named by `bindings.<EXT_POINT_ID>` with input: `<INPUT_SHAPE>`. Inspect the response:
>    - **One-shot result** — the response is the value the consumer step needs (a row set, a marker schema, a computed filename, etc.). Use it as this step's result and continue.
>    - **Workflow start** — the response signals an active workflow (e.g., includes an `execution_id` plus an `instruction` and/or `input_shape`). The original consumer-command step is now BLOCKED. Enter the workflow loop: execute the returned `instruction`, gather any output the workflow asked for via `input_shape`, call the same MCP tool again with the workflow handle and that output, and repeat. Continue this loop until the tool's response signals workflow completion or termination. Only then resume the consumer step, consuming the workflow's final output as this step's result.
> 3. **Error handling (applies in one-shot mode AND at every iteration of the workflow loop):**
>    - If the tool call returns a JSON object with an `"error"` key, surface that message to the user and STOP this step. Do NOT fall through to step 4 — a failed dispatch is NOT permission to use the fallback. If the error occurred mid-workflow, the workflow is considered terminated; the consumer step does not resume into the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule: no fallthrough.
> 4. **Fallback (only when `bindings.<EXT_POINT_ID>` is unset or `agent/driver.yaml` is absent):** `<FALLBACK_ACTION>`.
> 5. **Missing-state guard:** if step 4 cannot proceed because the state it needs is also unavailable (e.g., a required file is missing), surface a clear, actionable error explaining BOTH paths are unavailable. Point the user at: "bind a driver in `agent/driver.yaml`, or restore the missing state." Do NOT return empty results.
```

### Substitution Points

| Token | What goes here | Example |
|---|---|---|
| `<EXT_POINT_ID>` | One of `marker.mint`, `query.run`, `workflow.run` | `query.run` |
| `<INPUT_SHAPE>` | Concrete input the bound tool expects, expressed in the consumer command's step context (variable refs are OK) | `{kind: "task"}` or `{query: "<the SQL or DSL string built earlier in this step>"}` |
| `<FALLBACK_ACTION>` | One-sentence description of the existing ACP behavior, OR a pointer to the existing inline steps below the snippet | `Run \`./agent/scripts/acp.meta-scan.sh agent/\` and parse its output as the marker stream.` |

### Per-Ext-Point Examples

**`marker.mint`** — issue a canonical marker ID + field schema for a new file:

```markdown
> **🔌 Driver Dispatch — `marker.mint`**
>
> 1. Read `agent/driver.yaml`. If the file does not exist, OR `bindings.marker.mint` is unset, jump to step 4 (fallback).
> 2. Invoke the MCP tool named by `bindings.marker.mint` with input: `{kind: "task", context: {milestone_id: "<from earlier in this step>"}}`. Use the tool's response (canonical id + marker_open/close + field schema) as this step's result.
> 3. **Error handling:** if the response contains `"error"` OR an MCP exception is raised, surface and STOP. Do NOT fall through.
> 4. **Fallback:** Compute the next sequential task name (`task-<N>` where N is `highest_existing_task_number + 1`) and stamp the standard `<!-- @acp.meta.task ... @acp.meta.end -->` block as currently defined in this command's existing steps below.
> 5. **Missing-state guard:** if step 4 cannot determine `<N>` because `agent/progress.yaml` and `agent/tasks/` both lack readable state, surface an error pointing at both paths.
```

**`query.run`** — query the driver's data layer instead of grepping files:

```markdown
> **🔌 Driver Dispatch — `query.run`**
>
> 1. Read `agent/driver.yaml`. If the file does not exist, OR `bindings.query.run` is unset, jump to step 4 (fallback).
> 2. Invoke the MCP tool named by `bindings.query.run` with input: the driver-specific query that retrieves the marker inventory (consult the bound tool's MCP description for its input DSL — SQL, JSON-DSL, structured filter, etc.). Use the result rows as this step's marker inventory.
> 3. **Error handling:** if the response contains `"error"` OR an MCP exception is raised, surface and STOP. Do NOT fall through.
> 4. **Fallback:** Run `./agent/scripts/acp.meta-scan.sh agent/` and parse its `file:` / `kind:` / `key:` stream into the in-memory marker inventory structure.
> 5. **Missing-state guard:** if step 4's script is missing or returns a non-zero exit code unrelated to "no markers found", surface a clear error.
```

**`workflow.run`** — dispatch a multi-step workflow to the driver. Note: most full-command workflow overrides use the **top-of-file command-override directive (D5)**, not this in-step snippet. Use this snippet only when a single step within a command should hand off a sub-workflow.

```markdown
> **🔌 Driver Dispatch — `workflow.run`**
>
> 1. Read `agent/driver.yaml`. If the file does not exist, OR `bindings.workflow.run` is unset, jump to step 4 (fallback).
> 2. Invoke the MCP tool named by `bindings.workflow.run` with input: `{action: "start", workflow: "<sub-workflow-name>", ...args}`. The original consumer step is now BLOCKED. Enter the workflow execution loop:
>    a. The response includes a workflow handle (e.g., `execution_id`), an `instruction` describing what to do next, and (often) an `input_shape` describing what output the workflow expects in return.
>    b. Execute the `instruction` faithfully — read files, write code, ask the user, run a command, whatever it specifies. Gather the output the workflow asked for in the shape it described.
>    c. Call `bindings.workflow.run` again with the workflow handle and that output (the driver defines the exact shape, e.g., `{action: "step", execution_id, payload: <output>}`). The response is either the next `instruction` (loop) or a terminal signal (workflow complete or terminated).
>    d. Repeat (a)–(c) until the workflow reports completion or termination. Only then resume the consumer step, consuming the workflow's final output as this step's result.
> 3. **Error handling (one-shot AND every loop iteration):** if any response contains `"error"` OR an MCP exception is raised, surface and STOP. Workflow is terminated; do NOT fall through to step 4 or continue the loop.
> 4. **Fallback (only when `bindings.workflow.run` is unset or `agent/driver.yaml` is absent):** Execute the inline steps for this sub-workflow as written below.
> 5. **Missing-state guard:** standard.
```

**Important**: while inside the workflow loop, ACP is the workflow's executor, not its caller. The driver issues instructions; ACP follows them. ACP-side state (other commands, progress tracking, outer loops) does not advance until the workflow terminates. This is by design — drivers shipping validated workflow runtimes need ACP to faithfully execute their instruction stream, not race ahead with its own logic.

---

## Examples

### Example 1: `@acp.sync` Step 1.3 (marker scan)

**Before**: Step 1.3 unconditionally runs `./agent/scripts/acp.meta-scan.sh agent/`.

**After**: Step 1.3 is wrapped with the `query.run` dispatch snippet — driver-bound projects route through the bound query tool; driver-less projects continue to call the scanner script. The downstream parsing logic doesn't care which path produced the inventory; it consumes the same in-memory structure either way.

This is the v1 pilot deployment for task-123 — proves the snippet works end-to-end on a real consumer command before tasks 124–126 deploy it to the rest.

### Example 2: `@acp.task-create` filename minting

**Before**: command computes `task-<N>` by scanning the highest existing task number and incrementing.

**After**: a `marker.mint` dispatch snippet wraps the filename-and-marker computation. When `bindings.marker.mint` is set, the bound mint tool returns the canonical filename and marker block (UUID-suffixed, milestone-nested, etc.); the command writes the file using that path. When unset, the existing sequential numbering runs as fallback.

This is task-124's deployment site.

---

## Benefits

### 1. One contract, many drivers
The snippet's resolution happens through `bindings.<ext-point-id>`. Each driver chooses its own tool name and binds it in `agent/driver.yaml`; ACP commands consume whatever is bound without modification. Adding a new driver requires zero changes to ACP commands.

### 2. Strict-binding-first prevents silent divergence
The "do not also read fallback state" rule eliminates a real bug class: a command queries the driver AND also reads ACP-owned state files, the two answers diverge silently because the driver's init step has already removed or replaced those files. The snippet's strictness makes this impossible.

### 3. Explicit error surfacing exposes typos in `driver.yaml`
A typo in a workflow name or tool name produces a visible error at invocation time, not a silent fallthrough that quietly degrades behavior. Configuration errors surface as configuration errors, not as mysterious "data missing" symptoms downstream.

### 4. The snippet IS the documentation
A consumer command's dispatch behavior is fully readable from the snippet. No "go look at the dispatch helper script" indirection. LLMs (and humans) can predict behavior from the directive alone.

---

## Trade-offs

### 1. Mechanical proliferation across many command files
**Downside**: Roughly 6 commands need this snippet for `marker.mint`, 3 for `query.run`, and several more eventually for in-step `workflow.run`. Each occurrence is 8–12 lines of nearly identical markdown.
**Mitigation**: The snippet is mechanical to copy and the substitution points are minimal. A future improvement could centralize the snippet body and have command files reference it by name, but for v1 the explicit inline form is more LLM-reliable than indirection.

### 2. LLM faithfulness to "STOP, do not fall through"
**Downside**: LLMs occasionally treat fallback paths as additive — "I dispatched and it failed, let me also try the fallback as belt-and-suspenders." This is the very behavior the strict-binding-first rule forbids.
**Mitigation**: The directive uses bold, repeated, explicit STOP language. Pilot deployment validates reliability. If reliability is poor, structural cues (e.g., wrapping fallback steps in a fenced block labeled "fallback only") may be added in v1.1.

### 3. Substitution points are markdown text, not validated
**Downside**: Nothing prevents a command author from substituting an unsupported `<EXT_POINT_ID>` (e.g., `scanner.run`, which is explicitly out of v1 per D11). The snippet doesn't self-check.
**Mitigation**: `@acp.validate` only validates `agent/driver.yaml`'s binding keys against the v1 ext-point set; command-file substitutions are a code-review concern. v1.1 may add a linter that scans command files for snippet usage and verifies the ext-point IDs.

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Silent fallthrough on tool error

**Description**: After invoking the bound tool and receiving an error, the directive says "fall back to the ACP behavior." This is the single most common temptation when authoring dispatch logic.

**Why it's bad**: Masks real failures. A misconfigured `driver.yaml`, a broken driver, or a transient network issue all silently degrade to ACP behavior — and because ACP's fallback may read state the driver has removed (`progress.yaml`), the command silently produces wrong answers. The user sees no error and trusts the result.

**Instead, do this**: Surface the error and stop. The fallback is for the *unbound* case only. A bound-and-failing driver is a configuration or runtime problem the user must see.

```markdown
> ❌ Bad: "If the bound tool errors, fall through to step 4 as a backup."
>
> ✅ Good: "If the response contains `error` OR raises an MCP exception, surface and STOP. Do NOT fall through to step 4."
```

### ❌ Anti-Pattern 2: Hardcoding a driver tool name in the directive

**Description**: A command file directly names a specific driver's tool (e.g., "invoke `<some-driver>_mint(...)`") instead of resolving through `bindings.<ext-point-id>`.

**Why it's bad**: Couples the ACP command file to one specific driver. Adding a second driver means re-templating every command file. Defeats the purpose of the binding indirection.

**Instead, do this**: Always resolve through the binding. The agent reads `bindings.<EXT_POINT_ID>` at invocation time and calls whatever tool name is bound.

```markdown
> ❌ Bad: "Invoke `<specific-driver>_sql` with the marker query."
>
> ✅ Good: "Invoke the MCP tool named by `bindings.query.run` with the marker query."
```

### ❌ Anti-Pattern 3: Reading fallback state alongside the binding

**Description**: After a successful binding dispatch, the directive *also* reads `progress.yaml` "to be safe" and reconciles the two.

**Why it's bad**: A bound driver is authoritative. ACP's fallback state may not exist (deleted by the driver during init) or may have diverged. Reconciling silently produces incorrect merged state and no obvious failure mode.

**Instead, do this**: Use the bound tool's response and stop. ACP-owned state files are NOT a check on driver-owned state; they are an entirely separate code path used only when no driver is bound.

### ❌ Anti-Pattern 4: Returning empty results when both paths are unavailable

**Description**: Binding is unset, fallback file is missing, directive returns `[]` or `{}` and continues.

**Why it's bad**: Downstream steps treat the empty inventory as "nothing to do" and silently produce wrong/no output. The user has a misconfigured project but sees no error.

**Instead, do this**: Step 5's missing-state guard fires — surface a clear, actionable error pointing at both resolutions. Empty is never a valid recoverable state.

---

## Testing Strategy

### Pattern Validation (this task)
Read the modified pilot consumer command end-to-end. Confirm:
- [ ] An LLM following the directive would correctly invoke the bound tool when `bindings.query.run` is set.
- [ ] An LLM following the directive would correctly run the fallback when `bindings.query.run` is unset.
- [ ] The directive's error-handling clauses are unambiguous (no plausible reading where the LLM falls through silently on tool error).
- [ ] The substitution points in the deployed snippet are concrete and readable.

### Future Snippet Deployments (tasks 124–126)
- [ ] Snippet is copy-pasted with minimal substitution churn (validates the parameterization is right).
- [ ] Each deployment site has a clear `<INPUT_SHAPE>` and `<FALLBACK_ACTION>`.
- [ ] No deployment introduces a new variant of the snippet (no drift).

### Integration Validation (later milestones)
- [ ] With a mock MCP server bound, `@acp.sync` produces the same downstream results whether dispatched through the driver or the fallback.
- [ ] With a deliberately broken binding (typo'd tool name), `@acp.sync` surfaces a clear error and does not silently fall back.
- [ ] With no `driver.yaml`, `@acp.sync` continues to work exactly as today.

---

## Related Patterns

- **Command-Override Directive (D5)** — top-of-file directive that intercepts the entire command for a `workflow.run` dispatch. The in-step snippet documented here is its complement: in-step ext-point routing rather than whole-command routing. Both directives share the workflow-execution-loop semantic from Core Principle 6: when a workflow is started, the dispatching command is blocked until the workflow signals completion or termination.
- **`agent/design/local.pluggable-driver-system.md` D7** — formal specification of the override-with-fallback semantics this snippet encodes.
- **`agent/scripts/acp.driver-yaml.sh`** — the parser commands consult to read `agent/driver.yaml` bindings at dispatch time.

---

## Implications for Downstream Commands

The "dispatch may start a workflow, blocking the caller" semantic (Core Principle 6) ripples into several other ACP commands. Authors of those commands should be aware:

### `@acp.proceed`
When `@acp.proceed` invokes a step that triggers a driver dispatch, and the dispatch enters workflow-execution mode, `@acp.proceed`'s outer loop is blocked for the duration. It does NOT advance to the next task or consider the current task complete until the workflow signals completion or termination. Mid-workflow termination (error path) leaves the current task in whatever state the workflow last left it; `@acp.proceed` should report the termination, not silently mark the task complete or advance.

### `@acp.task-create` (and other create commands)
When create commands dispatch through `marker.mint`, the typical case is one-shot (driver returns id + schema). But create commands MAY also dispatch through a `workflow.run` override (via the command-override directive, D5) — in which case the create flow is the workflow's flow, not the markdown steps. Authors should not assume the create command's own steps run when an override is in effect.

### `@acp.validate` and `@acp.sync` probes
Validate/sync commands that read marker state via `query.run` see one-shot results (rows). They do NOT typically trigger workflow loops, since query is read-only. However, validate's binding-pairing checks should be aware that a workflow IS a possible response shape — defensive code that assumes "result is always rows" may break against drivers that return workflow handles from query tools. For v1 it is fine to assume `query.run` returns rows; if a future driver returns workflow handles, the snippet's general loop-handling logic still applies.

### Dispatching commands generally
Any command that dispatches through a binding inherits the workflow-loop semantic transparently — the snippet's step 2 handles both response shapes. Command authors do not need to write per-command branching logic. The snippet's job is to absorb that complexity uniformly.

---

## Migration Guide

### Step 1: Identify the ext-point in a consumer command
Look for steps that match one of the three v1 ext points:
- A step that creates a marker block or computes a canonical filename → `marker.mint`
- A step that reads marker state by grepping/scanning files → `query.run`
- A step that hands off to a multi-step sub-workflow → `workflow.run` (rare for in-step use; usually D5's command-override directive applies instead)

### Step 2: Substitute the snippet
Copy the canonical snippet. Substitute:
- `<EXT_POINT_ID>` with the appropriate ext-point.
- `<INPUT_SHAPE>` with the concrete input the bound tool expects (consult the per-ext-point examples above).
- `<FALLBACK_ACTION>` with a one-sentence description of the existing inline behavior, OR a pointer at the existing steps if they're long.

### Step 3: Restructure the surrounding step
The original step's body becomes the fallback. Place it inline (or pointed-to) as `<FALLBACK_ACTION>`. Subsequent steps consume the result of either path uniformly — the snippet ensures the downstream interface is the same.

### Step 4: Read end-to-end
Read the modified command from top to bottom. The flow should make sense both as "driver-bound" (steps 1–2 of the snippet do real work) and "driver-less" (snippet skips to step 4, fallback runs as written). Both paths must produce the same downstream interface.

---

## Checklist for Implementation

- [ ] Substitution points are concrete (no leftover `<...>` placeholders)
- [ ] `<INPUT_SHAPE>` references variables that exist in the surrounding step context
- [ ] `<FALLBACK_ACTION>` is unambiguous (a sentence OR a pointer at clearly demarcated existing steps)
- [ ] Error-handling clauses are preserved verbatim — STOP language, no silent fallthrough
- [ ] Missing-state guard is preserved verbatim — empty results are not a valid outcome
- [ ] Downstream steps consume the same interface from both paths
- [ ] Driver tool names do NOT appear in the directive — only `bindings.<ext-point-id>` resolution
- [ ] Read end-to-end as both bound and unbound; both flows make sense

---

**Status**: Active — canonical pattern for in-step ext-point dispatch under M19 (Pluggable Driver System).
**Recommendation**: Use for every consumer command step that maps to one of the three v1 ext points. Pair with the command-override directive (D5) for whole-command workflow overrides.
**Last Updated**: 2026-05-04
