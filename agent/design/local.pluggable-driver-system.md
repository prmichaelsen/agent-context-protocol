# Pluggable Driver System

<!-- @acp.meta.design
topic: pluggable-driver, mcp-tools, marker-mint, query-run, workflow-run, command-override, agent-driver-yaml, override-fallback
description: Lets external MCP-server runtimes override ACP marker stamping, queries, and workflow execution per-project via a small bindings file
depends_on: agent/clarifications/clarification-15-pluggable-driver-system.md
design_requirements: DR1..DR16
status: draft
updated: 2026-05-01
@acp.meta.end -->

**Concept**: A bindings file + three ext-point IDs + a workflow-override mechanism that lets a single MCP-server "driver" replace ACP's built-in marker authoring, querying, and workflow execution per-project, with override-with-fallback routing.
**Created**: 2026-05-01

---

## Overview

ACP today is a pure bash/markdown system with hardcoded behaviors. Marker scanning is a single awk script (`agent/scripts/acp.meta-scan.sh`); marker stamping is hardcoded into consumer commands like `@acp.task-create`; project state lives in flat yaml/markdown files. There is no extension surface — adding new behavior means forking ACP or modifying core directly.

This design introduces a **driver** system: a project may bind exactly one external MCP-server driver, declared in `agent/driver.yaml`, that overrides specific ACP roles (marker authoring, query, workflow execution) and replaces specific ACP commands (workflow-as-command-override). Where the driver doesn't override, ACP's existing behavior continues to apply.

The design preserves bash-ACP for users who don't bind a driver (zero behavior change) while enabling external MCP-server runtimes (e.g., ones with SQL-backed indexing, schema-validated marker stamping, or stateful workflow engines) to take over the project's data and execution model.

---

## Problem Statement

Three concrete frictions in bash-ACP today:

- **Marker authoring is rigid.** `@acp.task-create` and similar commands have `<!-- @acp.meta.<kind> ... -->` blocks hardcoded in their stamping logic. There is no way to introduce custom marker formats, additional fields, or driver-specific schemas without modifying every command file.
- **Query is grep + awk.** Asking "what tasks are in progress?" or "what designs reference this spec?" requires hand-rolled grep across files. Drivers with SQL-backed indexes can answer these queries in milliseconds; ACP commands have no way to use them.
- **Workflow execution is freeform LLM markdown.** Multi-step ACP commands rely on the LLM faithfully executing markdown directives top-to-bottom. There's no mechanism for between-step validation, postcondition enforcement, or stateful resumption. Drivers shipping validated workflow runtimes have no way for ACP commands to dispatch into them.

Forking ACP per-driver creates ecosystem fragmentation and locks driver authors out of the upstream methodology. We need an extension surface that's small enough to maintain, large enough to be useful, and disciplined enough to keep ACP itself coherent.

---

## Solution

A small four-part system. Each part is independently small; together they cover the use case.

1. **`agent/driver.yaml`** — a project-level bindings file (DR1). Absent → today's bash-ACP behavior unchanged. Present → the named driver overrides specific roles and commands.
2. **Three ext-point IDs** — `marker.mint`, `query.run`, `workflow.run` (DR2-DR4). Each binds to one MCP tool name. ACP consumer commands route through these IDs when present, fall back to existing behavior when absent.
3. **Workflow-as-command-override** — a `workflows:` section in `agent/driver.yaml` mapping ACP command names to driver workflow names, paired with a top-of-file directive (DR5) on each ACP command file that checks for a mapping before executing its own steps.
4. **Validation** — `@acp.validate` extended (DR6) to verify bindings reference real MCP tools resolvable in the agent's catalog, all bound tools come from a single MCP server, mint is paired with query, and workflow names resolve via `action="list"` introspection.

The whole system rests on one architectural premise: **ACP commands are agent directives, and the LLM is the dispatcher.** No subprocess management, no JSON-RPC framing, no IPC layer. Drivers expose tools via MCP; the LLM reads `agent/driver.yaml`, picks the right tool, calls it. The framework owns the contract; the agent owns dispatch.

### Alternatives considered (and why rejected)

- **Subprocess-based driver protocol (stdio JSON-RPC, LSP-style framing).** Initial design proposal. Rejected because (a) the LLM is already the dispatcher in the ACP execution model, (b) adding an IPC layer reproduces what MCP already standardizes, (c) subprocess management adds reliability surface for no value.
- **Multi-driver composition / per-ext-point bindings to different drivers.** Rejected because cross-driver state assumptions are subtle and rot silently. Locked to one driver per project; multi-driver is explicitly out of scope and not a planned future direction.
- **Driver-as-ACP-package distribution.** Rejected because drivers are runtimes (often Rust/Python binaries) and forcing them through bash-yaml package machinery is hostile to driver authors. Drivers ship via their native ecosystem.
- **Composition between core markers and custom markers** (e.g., extend acp.core's marker set with a custom driver's `@<custom>.*` markers alongside). Rejected because it introduces hidden coupling and ambiguity about which scanner owns which marker. When a driver is bound, it owns the project's marker vocabulary exclusively.

---

## Implementation

### DR1: `agent/driver.yaml` schema

```yaml
# agent/driver.yaml — present iff a driver is bound
driver: "@<org>/<driver-name>"         # informational; identifies the driver
capabilities:                          # driver-declared guarantees (see DR15)
  watcher: true                        # true = data layer auto-syncs with disk
bindings:                              # ext-point ID → MCP tool name (unprefixed)
  marker.mint: <mint-tool-name>
  query.run: <query-tool-name>
  workflow.run: <workflow-tool-name>
workflows:                             # ACP command name → driver workflow name
  acp.task-create: <workflow-id-1>
  acp.plan: <workflow-id-2>
  acp.init: <workflow-id-3>
```

- All keys optional individually, but invariants apply (DR6).
- Tool names are **unprefixed**; the agent translates to its runtime's naming convention (e.g., Claude Code's `mcp__<server>__<tool>`).
- Absent file or file with empty `bindings:` and `workflows:` ≡ pure `acp.core` behavior.

### DR2: `marker.mint` contract

The driver issues canonical marker IDs and provides field schema with per-field instructions; the **agent assembles the marker block and writes the file**. Driver controls structure + identity (what LLMs are bad at); agent controls semantic content (what LLMs are good at).

**Input**: `{kind: string, context?: object}` — kind identifies what's being stamped (task, design, spec, etc.); context is optional driver-specific input.

**Output** (illustrative example):
```json
{
  "id": "design.auth-flow~c9d8e7f6",
  "marker_open": "@example.doc",
  "marker_close": "@example.doc.end",
  "fields": [
    {"name": "id", "value": "design.auth-flow~c9d8e7f6", "agent_fills": false},
    {"name": "kind", "value": "design", "agent_fills": false},
    {"name": "summary", "type": "block-string", "required": true,
     "instructions": "1-2 sentence summary of what this design covers"},
    {"name": "weight", "type": "float", "range": [0.0, 1.0], "required": true,
     "instructions": "0.9+ critical, 0.5-0.7 normal, 0.3- niche"},
    {"name": "rationale", "type": "block-string", "required": false,
     "instructions": "Why an agent should read this"}
  ]
}
```

**Marker tokens are bare** (no comment syntax). The agent wraps them in the comment style appropriate to the target file's language: `<!-- ... -->` for markdown/HTML, `# ... #` or `# ... ` for Python/shell/YAML, `// ... ` or `/* ... */` for C-family, etc. This keeps the mint contract portable across file types — the same mint output stamps correctly into any file the agent writes. The driver does NOT pre-bake markdown-style wrapping into the tokens.

(`marker_open` / `marker_close` and the field set are entirely driver-defined; the example uses an illustrative `@example.doc` shape.)

**Contract**:
- `id` is canonical and used verbatim by the agent.
- Each field declares either `value` (driver-supplied, agent_fills=false) or `type/required/instructions` (agent-supplied, agent_fills implied true).
- `instructions` is the natural place to teach the agent what to write — richer than a static schema.

### DR3: `query.run` contract

Structured query against the driver's data layer.

**Input**: driver-defined query DSL. The contract does not mandate any specific query language — drivers may accept SQL strings, JSON-DSL query shapes, structured filter objects, or any other input — but the input/output schema must be documented in the tool's MCP description.

**Output**: an array of row objects (or equivalent iterable result). Schema is driver-defined; consumer commands work against whatever the bound driver returns.

**Pairing invariant**: `query.run` requires `marker.mint` (DR6). A driver binding query implicitly claims authority over marker-state queries; without mint, there's no path to produce markers in the canonical format the driver indexes — the round-trip is broken.

### DR4: `workflow.run` contract

Execute a driver-defined workflow step.

**Input**: `{workflow: string, ...driver-defined-args}` — `workflow` names the workflow to execute; remaining args are driver-defined.
**Output**: driver-defined (next instruction, completion status, validation failures, etc.).

**Workflow name resolution is lazy.** Validation does not pre-emptively verify that names in `workflows:` correspond to real workflows the driver knows about. If a name is wrong, the driver returns an error at invocation time. No introspection action is required; ACP makes no assumptions about how (or whether) a driver lists its workflows.

### DR5: Workflow-as-command-override mechanism

Two parts:

1. **`workflows:` section in `agent/driver.yaml`** (DR1) maps ACP command names to driver workflow names.

2. **Top-of-file directive** in each ACP command file (the **command-override directive**):

   ```markdown
   > **🤖 Driver Override Check**: Before executing this command's steps, check
   > `agent/driver.yaml` for a `workflows.<this-command-name>` mapping. If a
   > mapping exists, invoke `workflow.run(action="run", workflow=<mapped-name>)`
   > and STOP — do not execute the steps below. The steps below are the
   > fallback path used when no mapping exists. If the workflow invocation
   > returns an error, surface it to the user — do NOT silently fall through to
   > the steps below.
   ```

**v1 pilot scope**: 2-3 ACP commands receive the override directive (`@acp.task-create`, `@acp.plan`, `@acp.init` are the obvious candidates — they are the highest-leverage commands for any driver wanting to enforce structure between steps).
**v1.1 rollout**: full directive deployment to all ~40 ACP commands once the v1 pilot validates the dispatch-then-stop behavior is reliable.

**Failure semantics**: explicit error surfacing on workflow invocation failure (not silent fallback). This design rejects silent fallback to avoid masking real failures — including the case where a workflow name in `workflows:` doesn't resolve to a real workflow on the driver side. The driver's error surfaces; the ACP markdown steps are not silently used as a substitute.

### DR6: Validation rules in `@acp.validate`

When `agent/driver.yaml` is present, validate enforces:

1. All tool names in `bindings:` resolve in the agent's MCP catalog (the agent runtime can answer "is this tool registered and reachable?" via its tool-listing mechanism).
2. All bound tools come from a **single MCP server** (DR8). Mixing servers fails validation with a clear error.
3. `marker.mint` is bound iff `query.run` is bound (DR2 ↔ DR3 pairing).
4. The MCP server hosting the bound tools is currently registered and reachable.

**Not validated at this stage**: workflow names in `workflows:`. ACP does not require an introspection action on `workflow.run`; workflow names are resolved lazily at invocation time, with the driver returning an error if a name is unknown. The override directive surfaces that error rather than silently falling through to ACP's markdown steps.

When `agent/driver.yaml` is absent, validate continues to use today's behavior unchanged.

### DR7: Override-with-fallback routing

Consumer commands implement the routing pattern:

```
function dispatch(role, args):
  if agent/driver.yaml has bindings[role]:
    return invoke MCP tool bindings[role] with args
  else:
    return invoke acp.core's built-in handler for role with args
```

For the workflow-override case, the dispatch happens at the command-file level (DR5 directive) rather than per-role.

**Strict binding-first ordering**: when a binding exists for the role, consumer commands MUST dispatch through it and MUST NOT also read the corresponding ACP-owned state files "for safety." A bound driver may have removed those files outright (e.g., `progress.yaml` is deleted by `a driver's init step` in favor of project.db); reading them silently risks divergence from the driver's authoritative state.

**No silent failure on missing state**: if a consumer command's primary path (binding) is unavailable AND its fallback path (file read) is also unavailable — e.g., `query.run` unbound AND `agent/progress.yaml` missing — the command MUST surface a clear, actionable error pointing the user to the resolution (bind a driver, or restore the file). Returning empty results or a raw "file not found" stack trace is considered a bug, not a recoverable state.

### DR8: Single-MCP-server enforcement

`@acp.validate` rejects `agent/driver.yaml` configurations where bound tool names span multiple MCP servers. This preserves the "one driver per project" invariant (DR10) and prevents subtle cross-server state-sharing assumptions (e.g., one driver indexes markers, another runs queries against a different index — answers diverge silently).

### DR9: Marker authority transfer

When a driver is bound and binds `marker.mint`, **`@acp.meta.*` markers are never stamped anywhere** in the project. Consumer commands that previously stamped `@acp.meta.task` now invoke `marker.mint(kind=task)` and stamp whatever the driver returns. The project's marker vocabulary is, in effect, the driver's marker vocabulary.

Existing files with `@acp.meta.*` markers are unaffected at write time but invisible to the bound driver's scanner. Migration of existing files (rewriting `@acp.meta.<kind>` markers to whatever format the bound driver uses) is out of v1 scope; users can grep-and-replace or delegate to an LLM as a one-time operation.

### DR10: Zero-or-one driver per project

A project has either no driver (`agent/driver.yaml` absent) or exactly one bound driver. This design does not support multi-driver projects, per-ext-point binding to different drivers, driver inheritance, or driver-to-driver dependencies. None of these are planned future additions; if real demand emerges, a separate design effort will revisit.

### DR11: v1 ext-point scope

The three ext-point IDs (`marker.mint`, `query.run`, `workflow.run`) plus the `workflows:` override section are the entirety of v1. Explicitly **out of v1**:

- `scanner.scan` / `scanner.surface` / `scanner.hydrate` — driver-internal data-layer population is not an ACP concern.
- `scanner.reconcile` — driver-internal consistency.
- `sink`, `scrub` — driver-domain operations the agent invokes directly via MCP, not bound through ACP.
- `mcp.server` — moot, since the driver IS an MCP server.
- `commands` (raw command override beyond workflow dispatch) — out of v1; use `workflows:` instead.
- `scripts` — out of v1.

### DR12: ACP commands updated in v1

Two categories of changes:

**Pilot commands receiving the override directive (DR5)**:
- `agent/commands/acp.task-create.md`
- `agent/commands/acp.plan.md`
- `agent/commands/acp.init.md`

**Commands updated to honor `marker.mint` binding** (stamping logic switches from hardcoded `@acp.meta.*` to `marker.mint` invocation when bound):
- `agent/commands/acp.task-create.md`
- `agent/commands/acp.spec.md`
- `agent/commands/acp.design-create.md`
- `agent/commands/acp.pattern-create.md`
- `agent/commands/acp.command-create.md`
- `agent/commands/acp.clarification-create.md`

**Commands updated to honor `query.run` binding** (existing grep/awk paths become fallback when bound):
- `agent/commands/acp.validate.md`
- `agent/commands/acp.sync.md`
- `agent/commands/acp.proceed.md`

`@acp.validate` itself receives the bindings-validation extension (DR6).

### DR13: New ACP scripts

A small helper script for dispatching to bound MCP tools is **not** needed — dispatch happens at the LLM level by reading `agent/driver.yaml` and invoking the bound tool directly. The framework-side change is purely directive-level updates to existing commands.

### DR14: No new ACP user-facing commands

No `@acp.driver-register`, `@acp.driver-bind`, `@acp.driver-unbind`, `@acp.driver-list`, etc. The entire driver-management UX is:

1. User installs an MCP server in their agent runtime (per the runtime's standard MCP setup).
2. User edits `agent/driver.yaml` to declare bindings.
3. User runs `@acp.validate` to verify.

Three steps, two of which already exist.

### DR15: `capabilities.watcher` — driver-declared data freshness

A bound driver MAY declare `capabilities.watcher: true` in `agent/driver.yaml`. The flag tells consumer commands "the driver's data layer auto-syncs with disk; queries reflect current state without explicit refresh."

**When `watcher: true`** (or absent and assumed true if the driver's docs say so): consumer commands trust that `query.run` results reflect current disk state. No prompt for refresh.

**When `watcher: false`** (or absent and the driver doesn't claim auto-sync): consumer commands MAY surface guidance to the user — e.g., "if results seem stale, ask the driver to refresh via its scan/surface tool." ACP itself never auto-invokes a refresh tool; the user (or LLM) decides when to refresh.

**Default behavior when capability is absent**: treat as `watcher: false` (assume manual refresh may be needed). This is the conservative default — drivers that auto-sync are expected to declare it.

The flag is a hint, not a contract; ACP does not verify it (no MCP probe). The driver's tool descriptions and documentation are the source of truth; the flag is shorthand for consumer commands that want a structured signal.

### DR16: Reserved directory `agent/drivers/`

`agent/drivers/` is reserved for bound drivers' per-project state and locally-installed extension modules. ACP scanners (`acp.meta-scan.sh`, `@acp.validate`, `@acp.sync`, marker discovery, key-file index walks) MUST NOT recurse into this directory. Its contents are entirely driver-managed; ACP makes no assumptions about what's there.

Typical contents (driver-defined, not enforced):

```
agent/drivers/
└── @<org>/<driver-name>/
    ├── data/                # driver-managed state (typically committed)
    ├── runtime/             # runtime artifacts (typically gitignored: logs, locks, caches)
    ├── modules/             # locally-installed driver extension modules
    │   └── @<org>/<module>/
    └── .gitignore           # driver-managed
```

**This is NOT the driver's executable install path.** Driver code is installed via the driver's native ecosystem (uv, cargo, npm, brew, etc.) to system locations like `~/.local/share/uv/tools/<name>/`, `~/.cargo/bin/`, etc., and registered with the agent runtime as an MCP server. `agent/drivers/` exists purely for state + project-scoped module storage owned by the driver.

Implementation requirement: existing scanners must explicitly exclude this directory the same way they currently exclude `node_modules/`, `.git/`, `dist/`, etc. Verified by task-128's backward-compat regression suite.

---

## Benefits

- **Small surface, big lever**. The entire framework-side change fits in: a yaml schema, three ext-point IDs, a directive pattern, and validate-extension. No subprocess code, no IPC, no new commands.
- **Backward compatible by construction**. Absent `agent/driver.yaml` ≡ today's behavior. Existing projects continue to work without any change.
- **Driver authors use their own ecosystem**. ACP doesn't mandate language, distribution, or install path. A driver is an MCP server; how it gets onto the user's machine is the driver author's concern.
- **Reliability via tool catalog**. Drivers expose capabilities as named MCP tools; the LLM reliably picks them up because they're first-class in its tool catalog. No hidden dispatch.
- **Path to validated workflow execution**. The `workflows:` mechanism gives drivers a way to replace freeform LLM markdown execution with stateful, validated, between-step-enforcing workflow runtimes — the headline value-prop for any driver shipping a real workflow engine.

---

## Trade-offs

- **No composition with `acp.core` markers.** A bound driver fully owns the marker vocabulary. Users who want both standard ACP markers AND custom markers don't have a low-friction path; they either re-declare the standard set in their driver's mint tool or accept living without standard markers. This design explicitly says no to composition; not a planned future direction.
- **40+ command files eventually need the override directive.** v1 pilots 3; v1.1 rolls out the rest. The directive is mechanical but pervasive — every command file gets the same top-of-file pattern.
- **LLM "STOP" reliability is a real concern.** The override directive tells the agent to dispatch to `workflow.run` and stop. LLMs sometimes treat fallbacks as additive. Pilot phase will validate; if reliability is poor, structural cues (e.g., wrapping fallback steps in a "fallback only — do not execute if a workflow was dispatched" code-block delimiter) may be needed.
- **Workflow name validation is lazy, not eager.** ACP does not require drivers to support an introspection/list action on `workflow.run`. Typos or stale entries in `workflows:` only surface at invocation time, when the driver returns an error. Trade: simpler driver contract, slightly later failure feedback. The override directive's explicit-error semantic ensures the failure is visible (not silently masked by markdown fallback).
- **Single-MCP-server validation requires runtime-specific introspection.** Verifying every bound tool resolves to the same MCP server depends on the agent runtime's tool-catalog API (Claude Code, Cursor, and Claude Desktop each have their own mechanism). Initial implementation may target one runtime; broader support is iterative.
- **Migration of existing `@acp.meta.*` markers is on the user.** No tooling shipped for rewriting old marker formats to a bound driver's marker format. Likely a one-time scripted operation per project; tooling can come later if demand emerges.

---

## Dependencies

- **MCP (Model Context Protocol)** — drivers MUST be MCP servers. Required.
- **An MCP-aware agent runtime** (Claude Code, Cursor, Claude Desktop, etc.) for the user. Required.
- **`agent/scripts/acp.meta-scan.sh`** — current scanner; remains the fallback when no driver is bound.
- **`@acp.validate`** — extended in this milestone; remains the integration point for binding verification.

No external service dependencies. No SQL/database mandate (drivers may use SQLite, Postgres, in-memory, etc. — driver's choice).

---

## Testing Strategy

- **Unit-level**: validate-extension parses `agent/driver.yaml` correctly, rejects malformed schemas, surfaces clear errors.
- **Integration-level**: with `agent/driver.yaml` present and a mock MCP server bound, verify consumer commands route correctly (mint invocation produces marker, query invocation returns rows, workflow override dispatches and stops on success / surfaces error on failure).
- **Pilot-level**: bind a real driver's MCP server to a test project; run `@acp.task-create`, `@acp.plan`, `@acp.init` end-to-end; verify the driver's workflows execute, markers are stamped in the driver's marker format, and queries return rows from the driver's data layer.
- **Backward-compat**: in a project without `agent/driver.yaml`, every existing test continues to pass unchanged.
- **Failure-injection**: bound MCP server unreachable → validate reports clear error; workflow.run errors mid-execution → directive surfaces, doesn't silently fall through.

---

## Migration Path

For projects upgrading to this design:

1. **No driver bound (default)** — no migration needed. Existing projects work unchanged.
2. **Adopting a driver**:
   - Install the driver's MCP server in the agent runtime.
   - Create `agent/driver.yaml` with the bindings + workflow overrides.
   - Run `@acp.validate` to verify configuration.
   - Optionally rewrite existing `@acp.meta.*` markers to the driver's format (one-time, scripted or LLM-assisted).

For ACP itself:

1. **v1 milestone (M19)** — implement validate-extension, write `agent/driver.yaml` schema, update 3 pilot commands with override directive, update 6 marker-stamping commands to honor `marker.mint`, update 3 query-using commands to honor `query.run`.
2. **v1.1 milestone** — roll out override directive to remaining ~37 ACP commands; iterate on directive wording based on pilot reliability data.

---

## Key Design Requirements

### Architecture

| Decision | Choice | Rationale |
|---|---|---|
| Build driver system in bash-ACP now vs. wait for acp-code (clar-14) | Build now | Real users today; cheaper to design contribution surface against real implementation while still small |
| Driver runtime contract | MCP servers (hard requirement) | LLM reliability proportional to tool-catalog membership; hidden dispatch is fragile |
| IPC between framework and driver | None — LLM dispatches via tool calls | ACP commands are agent directives; LLM is already the dispatcher |
| Distribution mechanism | Driver's native ecosystem (cargo/npm/uv/brew/etc.) | ACP isn't a package manager for arbitrary runtimes |
| Driver as ACP package? | No, parallel concept | Drivers are runtimes; packages are content |

### Bindings & cardinality

| Decision | Choice | Rationale |
|---|---|---|
| Drivers per project | Zero or one | Simpler model; matches kernel/printer-driver metaphor |
| Composition between drivers | No (v1) | Cross-driver state assumptions rot silently |
| Composition between driver and core for markers | No | Hidden coupling; ambiguity over scanner ownership |
| Bindings cardinality (one-of vs. many-of per ext point) | One-of (single tool per ext point) | Matches one-driver-per-project |
| Single-MCP-server enforcement | Yes, via `@acp.validate` | Preserves "one driver" coherence |

### Ext points

| Decision | Choice | Rationale |
|---|---|---|
| v1 ext-point set | `marker.mint`, `query.run`, `workflow.run` | Minimal sufficient set for the targeted use cases (marker authoring, structured query, workflow execution) |
| `marker.mint` ↔ `query.run` pairing | Required (mint iff query bound) | Round-trip invariant — index-able markers must be produce-able |
| `scanner.*` as ext point | No (driver-internal) | Consumer commands need data, not scan-orchestration |
| `mcp.server` as ext point | No (driver IS the MCP server) | Trivially true |
| `workflow.run` introspection | Hard requirement: `action="list"` returns workflow IDs | Validate must verify `workflows:` mappings |

### Marker authoring

| Decision | Choice | Rationale |
|---|---|---|
| Stamping mechanism | Agent stamps file; `marker.mint` issues ID + schema | Driver controls structure (LLMs bad at); agent controls semantics (LLMs good at) |
| Marker authority when driver bound | Driver fully owns vocabulary | No `@acp.meta.*` stamped anywhere |
| Migration of existing `@acp.meta.*` files | Out of v1 (user's concern) | One-time scripted operation; not framework's job |
| Schema documentation surface | Rich tool descriptions on each MCP tool | Floor quality bar; no separate `about` tool needed |

### Workflow override

| Decision | Choice | Rationale |
|---|---|---|
| Mechanism | `workflows:` section + top-of-file directive | Simple routing; mechanical to deploy |
| v1 scope | 2-3 piloted commands | Validate dispatch-then-stop reliability before full rollout |
| v1.1 scope | All ~40 ACP commands | Following pilot validation |
| Failure semantics | Explicit error surfacing, NOT silent fallback | Avoid masking real failures |
| YAML key naming | `workflows:` (not `commands:`) | Values are workflow names, not command implementations |

### Tool naming & registration

| Decision | Choice | Rationale |
|---|---|---|
| Tool names in bindings | Unprefixed (e.g., `my_query_tool`, not `mcp__server__my_query_tool`) | Agent translates to runtime naming; portable |
| Driver registration | None — MCP runtime owns it | User registers MCP server with their agent runtime |
| New ACP user-facing commands | None | `agent/driver.yaml` is user-edited; `@acp.validate` extended |
| `~/.acp/drivers.yaml` global registry | No | MCP runtime is the registry |

---

## Future Considerations

### Planned followup work

- **Full command-override rollout (v1.1)**. After the v1 pilot (3 ACP commands receive the override directive), deploy the directive to remaining ~37 ACP commands once pilot data shows the dispatch-then-stop behavior is reliable.
- **Convergence with acp-code (clar-14)**. The Python plugin system in clar-14 has different mechanics (in-process FFI plugins) but similar spirit (one-of binding, override-with-fallback, isolation). The two extension surfaces may eventually be unified under a shared vocabulary; for now they are deliberately parallel.

### Explicit non-goals (not planned)

These are decisions, not deferrals. None of the following are roadmapped; if real demand emerges, a separate design effort will revisit each on its own merits:

- **Multi-driver projects / per-ext-point binding to different drivers.** Composition across drivers is rejected; one driver per project is a load-bearing invariant.
- **Driver-to-driver dependencies / driver inheritance / driver composition.** Drivers are independent worlds; ACP does not provide a dependency or inheritance mechanism between them.
- **Migration tooling for `@acp.meta.*` → driver-format markers.** Out of scope. One-time migration is on the user (grep-and-replace, LLM-assisted rewrite, custom script).
- **Additional ext points beyond `marker.mint`, `query.run`, `workflow.run`.** The ext-point set is intentionally small and final for this design. New roles (formatters, validators, rendering, etc.) would require a separate clar/design.
- **Auto-invocation of driver refresh tools by ACP.** The `capabilities.watcher` flag (DR15) is a hint surfaced to consumer commands; ACP itself never auto-calls a driver's scan/surface/refresh tool. That decision stays with the user / LLM.

---

**Status**: Draft — design captured; ready for task breakdown via `@acp.task-create` under M19 (Pluggable Driver System).
**Recommendation**: Proceed to `@acp.task-create` to break this design into v1 tasks. Drill is ready on their side; ACP-side work is the gating path.
**Related Documents**:
- `agent/clarifications/clarification-15-pluggable-driver-system.md` (source clarification, captured)
- `agent/clarifications/clarification-14-acp-code-design.md` (parallel Python plugin design)
- `agent/scripts/acp.meta-scan.sh` (current scanner; fallback when no driver bound)
- `agent/commands/acp.validate.md` (extended in this milestone)
