# Workflow Override Directive

<!-- @scry.entry
id: pattern.workflow-override-directive~57f42742
kind: pattern
summary: >
  Top-of-file directive consumer commands embed to dispatch the entire command to a bound
  workflow.run tool, with strict STOP semantics that prevent the markdown fallback from
  running alongside dispatch.
status: active
weight: 0.7
tags: ["topic:workflow-override", "topic:command-override-directive", "topic:top-of-file-dispatch", "topic:llm-stop-reliability", "topic:pluggable-driver"]
rationale: >
  Provides a single canonical pattern for command-level workflow override that enforces
  strict STOP semantics — critical for preventing half-driver, half-markdown execution
  when a workflow is dispatched.
applies: implementing command-level workflow override in ACP commands, pluggable-driver integration
seeded_questions:
  - "What are the strict STOP semantics this directive enforces?"
  - "How does this differ from the driver-dispatch-directive?"
  - "Which commands use the workflow-override-directive in v1?"
updated: 2026-05-04
@scry.entry.end -->

**Category**: Architecture

---

## Overview

The Workflow Override Directive is the **top-of-file** counterpart to the in-step Driver Dispatch Directive (`agent/patterns/local.driver-dispatch-directive.md`). It intercepts the entire command at the moment of invocation and dispatches it to a bound workflow when `agent/driver.yaml` maps the command name. If no mapping exists, the markdown fallback below runs as today.

This is the headline value-prop of the Pluggable Driver System (M19, design DR5): drivers shipping validated workflow runtimes can replace freeform LLM markdown execution with stateful, between-step-enforcing workflows. Without this directive, ACP commands always run their markdown steps regardless of what the driver could do.

**Driver-agnostic by design.** The directive resolves through `bindings.workflow.run` — never names a specific driver tool. Each driver chooses its own workflow-dispatch tool name and binds it in `agent/driver.yaml`.

---

## When to Use This Pattern

✅ **Use this directive when:**
- The command is one of the v1 pilot commands (`acp.task-create`, `acp.plan`, `acp.init`) — D5 explicitly piloted these first.
- A driver-bound version of the command should *replace* the markdown flow entirely (not augment a single step).
- The command's value to driver authors is in its workflow shape, not its individual step content (e.g., a creation flow with mandatory validation between steps).

❌ **Don't use this directive when:**
- The dispatch is for a single step within a command — use the in-step **Driver Dispatch Directive** instead.
- The command has no extensibility intent (e.g., reading `agent/driver.yaml` itself, rendering a banner). Adding the override there is over-engineering.
- The command is small enough that a driver could replace it more cleanly with a different ACP command rather than overriding this one.

---

## Core Principles

1. **Top-of-file placement is load-bearing.** The directive must execute BEFORE any markdown step is read for execution. It is placed immediately after the existing `🤖 Agent Directive` block so the LLM encounters it as part of the directive's preamble.
2. **STOP is non-negotiable when dispatched.** When `workflow.run` is invoked, the markdown steps below MUST NOT also run. LLMs sometimes treat fallbacks as additive — the directive's language is intentionally repetitive on this point to combat that drift.
3. **Strict-binding-first.** When a `workflows.<command>` mapping exists, dispatch is the only path. The markdown is fallback ONLY when the mapping is absent. A failed dispatch is NOT permission to use the markdown.
4. **Driver-agnostic indirection.** The directive resolves `bindings.workflow.run` to find the actual MCP tool name. Consumer commands never name a specific driver tool.
5. **Configuration-error surfacing.** If `workflows.<command>` is mapped but `bindings.workflow.run` is unbound, that's a configuration error in `agent/driver.yaml`. Surface it explicitly — do NOT silently fall back, since the user clearly intended the override.
6. **Workflow-execution loop.** A `workflow.run` dispatch typically returns a workflow handle, not a one-shot result. ACP becomes the workflow's executor for the duration: follow each returned `instruction`, return requested output to the same MCP tool, repeat until completion or termination. See the canonical Driver Dispatch Directive's Core Principle 6 for the full loop semantic.

---

## Implementation

### The Canonical Directive

This is the exact text consumer commands embed at the top of their file, immediately after the existing agent directive blockquote:

```markdown
> **🔌 Driver Override Check** (TOP-OF-FILE — runs BEFORE any other step in this file)
>
> 1. Read `agent/driver.yaml`. If the file does not exist OR there is no `workflows.<this-command-name>` mapping, jump to step 5 (fallback to the markdown steps below).
> 2. Look up `bindings.workflow.run` — the MCP tool name this driver uses for workflow dispatch. If the mapping exists but `workflow.run` is unbound, surface a clear configuration error (`"workflows.<this-command-name> is mapped but bindings.workflow.run is unset in agent/driver.yaml"`) and STOP.
> 3. Invoke that MCP tool with input `{action: "start", workflow: <mapped-value>, args: <user-arguments-from-this-invocation>}`. The command is now BLOCKED — execute the workflow loop per the canonical pattern (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): follow each returned `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion or termination. The workflow's final output IS this command's output. **STOP. Do NOT execute any of the markdown steps below.**
> 4. **Error handling** (one-shot AND every loop iteration):
>    - If any tool response contains an `"error"` key, surface that message to the user and STOP. Do NOT fall through to the markdown steps below — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule.
> 5. **Fallback (only when `workflows.<this-command-name>` is unmapped or `agent/driver.yaml` is absent):** Proceed to the markdown steps below as written — they describe ACP's default behavior for this command.
>
> ⚠️  **The rest of this file is the unbound-case fallback.** If the override block above dispatched a workflow (whether it completed successfully or errored), do NOT also execute the steps below. They are "execute only if step 5 above is the path you took."
```

### Substitution Point

| Token | What goes here | Example |
|---|---|---|
| `<this-command-name>` | The full command name including the namespace prefix, matching the file header | `acp.task-create`, `acp.plan`, `acp.init` |

This is the only substitution point. The directive body is otherwise identical across all consumer commands — that uniformity is intentional, both to make the pattern recognizable to LLMs and to make audit/lint mechanical.

### Placement in the Command File

Insert the directive as a new blockquote block:
- **After** the existing `🤖 Agent Directive` blockquote (which sets the "execute as a script" preamble)
- **Before** the `**Namespace**:` metadata header
- Separated from neighboring content by blank lines (markdown blockquote convention)

Example resulting file structure:
```markdown
# Command: <name>

> **🤖 Agent Directive**: ...    ← existing preamble
> ...
> Follow the steps below.

> **🔌 Driver Override Check**   ← NEW: workflow-override directive
> ...

**Namespace**: acp                ← existing metadata header
**Version**: ...
```

### v1 Pilot Deployment

Per design DR12, the v1 pilot is exactly 3 commands:

- `agent/commands/acp.task-create.md` — substitute `<this-command-name>` = `acp.task-create`
- `agent/commands/acp.plan.md` — substitute `<this-command-name>` = `acp.plan`
- `agent/commands/acp.init.md` — substitute `<this-command-name>` = `acp.init`

These three are the highest-leverage commands for any driver wanting to enforce structure between steps (creation flows + planning flows + session init).

### v1.1 Rollout (Post-M19)

Following pilot validation, the directive deploys to all remaining ~37 ACP commands. The deployment is mechanical — same directive, only the `<this-command-name>` substitution differs per file.

---

## Reliability Pilot Notes

The "STOP, do not execute below" semantic is the single biggest reliability concern for this directive (design Trade-offs section, DR5). LLMs sometimes treat fallbacks as additive — interpreting "step 5 is the fallback" as "I'll dispatch AND ALSO run the markdown steps just in case." That is the bug the strict-STOP language is designed to prevent.

### Defensive structures already in the directive

The current draft uses three layered defenses:

1. **Explicit STOP language at step 3** — bold, repeated, in the imperative.
2. **Step 4's error-handling clauses** also say STOP — even error paths do not fall through.
3. **The closing ⚠️ note** explicitly reframes "the rest of this file is the unbound-case fallback. Do NOT also execute the steps below."

If reliability is poor in observed pilots, escalation order:

1. **Structural cues**: wrap the markdown fallback steps in a fenced/labeled block (e.g., `<!-- BEGIN FALLBACK ONLY -->` ... `<!-- END FALLBACK -->`). Visual separation may help.
2. **Section heading rename**: change "Steps" to "Steps (fallback only — execute only if no workflow override dispatched)".
3. **Stronger linguistic cues**: more emphatic STOP, capitalized, possibly with a fake-error-message style ("EXECUTING THE STEPS BELOW IS A BUG").
4. **Last resort**: revisit the override-with-fallback model itself — if the directive can't be made reliable in markdown, the design's premise is at risk.

### Pilot data collection (deferred)

Validating reliability requires:
- A bound mock MCP server exposing `workflow.run` (not yet built; deferred per task-128's regression suite scope).
- Multiple LLM sessions invoking each pilot command to test variance.
- Tracking: (a) bound case dispatches without executing markdown? (b) unbound case executes markdown unchanged? (c) error case surfaces error and STOPs?

This pattern doc will be updated with empirical findings once the mock server and integration tests land.

---

## Examples

### Example 1: A `acp.task-create` invocation under a driver-bound project

**Setup**: `agent/driver.yaml` exists with:
```yaml
bindings:
  workflow.run: <some-driver>_workflow
workflows:
  acp.task-create: task_create
```

**Invocation**: User types `@acp.task-create create a task for adding webhook support`

**Flow under directive**:
1. LLM reads `acp.task-create.md`, encounters the override directive.
2. Reads `agent/driver.yaml`, finds `workflows.acp.task-create: task_create`.
3. Reads `bindings.workflow.run: <some-driver>_workflow`.
4. Invokes `<some-driver>_workflow(action="start", workflow="task_create", args="create a task for adding webhook support")`.
5. Receives `{execution_id: "abc", instruction: "Read agent/progress.yaml to find the active milestone", input_shape: {milestone_id: "string"}}`.
6. Reads progress.yaml, extracts `milestone_id: "M22"`, calls `<some-driver>_workflow(action="step", execution_id: "abc", payload: {milestone_id: "M22"})`.
7. Continues the loop until the workflow returns `{status: "complete", output: {...}}`.
8. The workflow's final output is this command's output. ACP does NOT also run the markdown create-flow.

### Example 2: A `acp.task-create` invocation under a driver-less project

**Setup**: No `agent/driver.yaml`.

**Invocation**: User types `@acp.task-create create a task for adding webhook support`

**Flow under directive**:
1. LLM reads `acp.task-create.md`, encounters the override directive.
2. Tries to read `agent/driver.yaml`, finds it absent. Jumps to step 5.
3. Step 5 says "proceed to the markdown steps below as written."
4. LLM executes the existing task-create markdown flow exactly as today. Behavior unchanged.

### Example 3: Misconfigured `agent/driver.yaml`

**Setup**: `agent/driver.yaml` has `workflows.acp.plan: plan_workflow` but no `bindings.workflow.run`.

**Invocation**: User types `@acp.plan plan the next milestone`

**Flow under directive**:
1. LLM reads `acp.plan.md`, encounters the override directive.
2. Reads `agent/driver.yaml`, finds `workflows.acp.plan: plan_workflow`.
3. Looks up `bindings.workflow.run` — unset.
4. Step 2 fires: surfaces `"workflows.acp.plan is mapped but bindings.workflow.run is unset in agent/driver.yaml"` and STOPS.
5. The markdown plan-flow does NOT run as silent fallback. The user must fix the configuration.

---

## Benefits

### 1. Drivers can ship real workflow runtimes
Without this directive, ACP commands are always freeform LLM markdown — no between-step validation, no postcondition enforcement, no stateful resumption. The directive is the single mechanism that lets a driver replace that with a validated execution model. This is what most drivers will care about.

### 2. Backward-compatible by construction
A project without `agent/driver.yaml` sees zero behavior change. The directive's first check fails, jumping to step 5, which is the existing markdown. No regression risk for any project that doesn't opt into the driver system.

### 3. Mechanical to deploy
Same directive in every file, one substitution point. Audit and lint can verify all consumer commands have the directive with correct substitution. No per-command branching logic to maintain.

### 4. Errors are visible, not silent
Misconfigured `driver.yaml` (e.g., mapping a workflow but forgetting to bind `workflow.run`) surfaces as a clear error. Compared to silent fallthrough, this is a much better failure mode for drivers and users.

---

## Trade-offs

### 1. LLM "STOP" reliability is a real risk
**Downside**: LLMs occasionally treat fallbacks as additive. If the LLM dispatches AND also runs the markdown, the user gets duplicate work and silent divergence between driver state and ACP state.
**Mitigation**: Strict, repetitive STOP language. Pilot phase explicitly designed to gather evidence on reliability. Escalation path documented (structural cues → linguistic emphasis → revisit design).

### 2. Mechanical fan-out across ~40 command files
**Downside**: v1 pilots 3 commands; v1.1 rolls out the rest. Every command file gains the same top-of-file block.
**Mitigation**: The substitution is one token. A linter could verify presence and substitution correctness across the command corpus. The deploy is straightforward grunt work, not creative work.

### 3. The "args" payload shape is driver-defined
**Downside**: The directive passes `args: <user-arguments-from-this-invocation>` to `workflow.run`. The exact shape of those arguments — string? object? structured? — is driver-defined. Different drivers may expect different shapes.
**Mitigation**: The driver's `workflow.run` MCP tool description should specify the args shape. The LLM reads that description and shapes the call accordingly. ACP's directive doesn't lock down the shape; it defers to the driver.

### 4. Workflow-name validation is lazy
**Downside**: A typo in `workflows.<command>` mapping (e.g., `task_creat` instead of `task_create`) surfaces only at invocation time, when the driver returns an error for the unknown workflow name.
**Mitigation**: This is a conscious choice (design D6, lazy validation). Error surfacing in step 4 ensures the typo is visible — not silent. `@acp.validate` MAY add a soft-check using a driver-side workflow-listing call, but that's optional and driver-specific.

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Silent fallthrough on dispatch error

**Description**: After invoking `workflow.run` and receiving an error, the directive falls through to the markdown steps as a "backup."

**Why it's bad**: Masks misconfiguration. A misnamed workflow, a broken driver, a transient network blip — all silently degrade to ACP's markdown behavior. The user sees no error and trusts the result. Same anti-pattern as the in-step Driver Dispatch directive's Anti-Pattern 1.

**Instead, do this**: Surface the error and STOP. The markdown is fallback for the *unbound* case only. A bound-and-failing dispatch is a problem the user must see.

### ❌ Anti-Pattern 2: Hardcoding a driver tool name

**Description**: Top-of-file directive directly says "invoke `<some-driver>_workflow(...)`" instead of resolving through `bindings.workflow.run`.

**Why it's bad**: Couples the ACP command file to one specific driver. Each new driver requires re-templating every command file. Defeats the indirection's purpose.

**Instead, do this**: Always resolve through `bindings.workflow.run`. The agent reads the binding at invocation time and calls whatever is bound.

### ❌ Anti-Pattern 3: Running markdown steps "for safety" alongside dispatch

**Description**: Directive says "dispatch via workflow.run, then ALSO run the markdown steps to make sure the work gets done."

**Why it's bad**: A bound driver is authoritative. Running both produces duplicate side effects (e.g., two task files created), state divergence between driver and ACP, and silent inconsistency.

**Instead, do this**: STOP after dispatch. The driver's flow is THE flow. The markdown is unbound-only.

### ❌ Anti-Pattern 4: Letting workflow-name typos fail silently

**Description**: When `workflow.run` returns `{"error": "workflow 'task_creat' not found"}`, the directive says "ah, the workflow doesn't exist — must mean we should run the markdown."

**Why it's bad**: A typo in `agent/driver.yaml` should NOT be papered over by silent fallback. The user clearly intended the override; the typo needs to surface.

**Instead, do this**: Surface the error, STOP. The user fixes `agent/driver.yaml`. The markdown is for projects that don't bind a workflow at all — not a backup for misconfigured ones.

---

## Testing Strategy

### Static validation (this task's deliverable)
- [ ] Directive applied to all 3 pilot commands at the very top of the file (after the existing agent directive blockquote, before the `**Namespace**:` metadata).
- [ ] `<this-command-name>` substitution correct in each file.
- [ ] Directive language is identical across all 3 (only the implicit substitution differs).
- [ ] Read each modified command end-to-end; confirm the bound, unbound, and error paths all read coherently.

### Runtime validation (deferred to task-128 integration tests)
- [ ] Bound case: with mock MCP server bound, `@acp.task-create` invokes `workflow.run` and does NOT execute markdown steps.
- [ ] Unbound case: without `driver.yaml`, `@acp.task-create` executes markdown steps unchanged.
- [ ] Configuration-error case: with `workflows.acp.task-create` mapped but `bindings.workflow.run` unbound, the configuration error surfaces and the markdown does NOT run.
- [ ] Workflow-error case: with workflow returning `{"error": "..."}`, the error surfaces and the markdown does NOT run.
- [ ] Repeat each case across multiple LLM sessions — gather variance data on STOP reliability.

### Reliability metrics to collect
- Bound-case dispatch-without-markdown rate (target: 100%, observed: TBD).
- Unbound-case markdown-execution rate (target: 100%, observed: TBD — should match pre-directive baseline).
- Error-case STOP rate (target: 100%, observed: TBD).
- LLM-to-LLM variance (e.g., does Claude Sonnet handle STOP differently from Opus or Haiku?).

---

## Related Patterns

- **`agent/patterns/local.driver-dispatch-directive.md`** — the in-step counterpart. Use it for ext-point dispatch within a single step (`marker.mint`, `query.run`, in-step `workflow.run`). The two patterns share the strict-binding-first, explicit-error principles and the workflow-execution-loop semantic; the difference is granularity (top-of-file vs. in-step).
- **`agent/design/local.pluggable-driver-system.md` DR5** — formal specification of the workflow-as-command-override mechanism this directive encodes.
- **`agent/scripts/acp.driver-yaml.sh`** — parser commands consult to read `agent/driver.yaml` at dispatch time.

---

## Migration Guide

### Step 1: Identify the consumer command
Confirm the command should be in the override scope:
- Is it a creation/planning/init flow with multi-step shape that drivers might want to validate or replace? → Yes, candidate.
- Is it a small read-only utility? → No, skip; an in-step dispatch (or no override) is more appropriate.

### Step 2: Insert the directive
Copy the canonical directive. Insert as a new blockquote immediately after the existing `🤖 Agent Directive` block, before `**Namespace**:`.

### Step 3: Substitute `<this-command-name>`
Replace the four occurrences of `<this-command-name>` with the actual command name (including namespace prefix, e.g., `acp.task-create`).

### Step 4: Read end-to-end
Read the resulting file from top to bottom. Confirm:
- The override block is positioned correctly (after agent directive, before metadata header).
- The bound path (steps 1–4) is unambiguous about STOP.
- The unbound path (step 5 → markdown steps) reads as the existing command behavior.
- An LLM following the file would correctly choose the path based on `agent/driver.yaml` state.

---

## Checklist for Implementation

- [ ] Directive copy-pasted verbatim from this pattern doc — no language drift between commands
- [ ] `<this-command-name>` substituted at all four placement sites in the directive body
- [ ] Directive positioned after the existing `🤖 Agent Directive` block, before `**Namespace**:`
- [ ] Surrounding blank lines preserve markdown blockquote separation
- [ ] STOP language preserved verbatim — no "softening" the imperative
- [ ] Error-handling clause preserved verbatim — both `error`-key and MCP-exception cases
- [ ] Closing ⚠️ note preserved — reframes the markdown below as fallback-only
- [ ] No driver tool names appear in the directive — only `bindings.workflow.run` resolution

---

**Status**: Active — canonical pattern for top-of-file workflow override under M19 (Pluggable Driver System).
**Recommendation**: Use for v1 pilot commands (`acp.task-create`, `acp.plan`, `acp.init`). Extend in v1.1 to remaining ~37 ACP commands once pilot reliability data is collected.
**Last Updated**: 2026-05-04
