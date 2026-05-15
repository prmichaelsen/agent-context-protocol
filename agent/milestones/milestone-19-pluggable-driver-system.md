# Milestone 19: Pluggable Driver System v1

<!-- @scry.entry
id: milestone.pluggable-driver-system~10ffffe3
kind: milestone
summary: >
  Implement v1 contract for pluggable MCP-server drivers — agent/driver.yaml,
  three ext points, workflow override on 3 pilot commands.
status: active
weight: 0.75
tags: ["topic:pluggable-driver", "topic:mcp-tools", "topic:marker-mint", "topic:query-run", "topic:workflow-run", "topic:command-override"]
rationale: >
  Enables external runtimes (e.g., scry-mcp) to override ACP's built-in
  marker stamping, query, and workflow behaviors without forking core.
applies: reviewing M19 scope, implementing driver integrations
seeded_questions:
  - "What ext points does M19 define?"
  - "How does a project bind a driver?"
tasks: task-121..task-129
updated: 2026-05-01
@scry.entry.end -->

**Goal**: Ship the v1 pluggable driver system: a project may bind one MCP-server driver via `agent/driver.yaml` to override marker stamping, query, and workflow execution, with override-with-fallback to `acp.core` defaults.
**Duration**: 2-3 weeks (~22-34 hours of focused implementation work)

---

## Overview

This milestone implements the design captured in `agent/design/local.pluggable-driver-system.md` (D1..D15). The v1 driver system rests on a small contract: a yaml file (`agent/driver.yaml`), three ext-point IDs (`marker.mint`, `query.run`, `workflow.run`), a workflow-as-command-override mechanism for 3 pilot ACP commands, and a validation extension to `@acp.validate`.

The framework-side change is intentionally small: no new user-facing commands, no subprocess management, no IPC layer. Drivers are MCP servers; the LLM is the dispatcher; ACP just owns the contract and the bindings file.

**Out of v1** (per design D11, explicit non-goals): multi-driver projects, driver-to-driver dependencies, additional ext points, migration tooling, full ~37-command override rollout (that's a follow-up milestone, not v1.1-of-this-milestone-but-a-distinct-effort).

---

## Deliverables

### 1. Driver schema + parsing
- `agent/driver.yaml` schema documented and parseable (D1, D15)
- yaml-parser support for the new file format

### 2. Validation
- `@acp.validate` extended (D6, D8) to verify bindings, single-MCP-server constraint, mint/query pairing, server reachability
- Validation surfaces clear errors when MCP catalog can't resolve a bound tool

### 3. Override-with-fallback routing pattern
- Reusable directive snippet (D5, D7) consumer commands embed at the top of their files
- Pattern verified to dispatch correctly when bound, fall through correctly when unbound

### 4. Marker stamping wiring (D2, D9, D12)
- 6 stamping commands invoke `marker.mint` when bound; stamp `@acp.meta.<kind>` when unbound
- Commands updated: task-create, spec, design-create, pattern-create, command-create, clarification-create

### 5. Query wiring (D3, D12)
- 3 query-using commands route through `query.run` when bound; fall back to existing grep/awk paths when unbound
- Commands updated: validate, sync, proceed

### 6. Workflow-as-command-override (D4, D5, D12)
- 3 pilot commands (task-create, plan, init) get the override directive at top of file
- Failure semantics: explicit error surfacing, not silent fallback

### 7. `capabilities.watcher` consultation (D15)
- Consumer commands consult the flag and adjust behavior (no auto-refresh; user-decision-based prompts when stale)

### 8. Testing
- Integration tests with mock MCP server bound (every ext point exercised)
- Backward-compat test suite (zero behavior change when no driver bound)
- Failure-injection: unreachable server, invalid workflow name, bad bindings

### 9. Documentation
- AGENT.md, README.md, CHANGELOG.md updated with driver system documentation
- Examples of binding a driver and what each ext point does

---

## Success Criteria

- [ ] A project with `agent/driver.yaml` absent passes every existing test unchanged (backward compat invariant)
- [ ] A project with `agent/driver.yaml` present and a mock MCP server bound: marker stamping invokes `marker.mint`, queries invoke `query.run`, workflow overrides dispatch via `workflow.run`
- [ ] `@acp.validate` rejects malformed `agent/driver.yaml` with clear errors
- [ ] `@acp.validate` rejects bindings spanning multiple MCP servers (D8)
- [ ] `@acp.validate` rejects `query.run` bound without `marker.mint` (D2 ↔ D3 pairing)
- [ ] All 3 pilot commands (task-create, plan, init) honor the override directive: dispatch when bound, fall back when unbound, surface errors explicitly
- [ ] All 6 marker-stamping commands route through `marker.mint` when bound
- [ ] All 3 query-using commands route through `query.run` when bound
- [ ] `capabilities.watcher` is consulted by relevant consumer commands (no auto-refresh; surfaces guidance only)
- [ ] AGENT.md / README / CHANGELOG document the driver system end-to-end

---

## Key Files to Create

```
agent-context-protocol/
├── agent/
│   ├── milestones/
│   │   └── milestone-19-pluggable-driver-system.md
│   ├── tasks/
│   │   └── milestone-19-pluggable-driver-system/
│   │       ├── task-121-driver-yaml-schema-and-parser.md
│   │       ├── task-122-validate-driver-bindings-extension.md
│   │       ├── task-123-override-fallback-routing-pattern.md
│   │       ├── task-124-marker-mint-wiring.md
│   │       ├── task-125-query-run-wiring.md
│   │       ├── task-126-workflow-override-pilot.md
│   │       ├── task-127-capabilities-watcher-consultation.md
│   │       ├── task-128-integration-and-backward-compat-tests.md
│   │       └── task-129-documentation-updates.md
│   └── schemas/
│       └── driver.schema.yaml         # NEW — schema definition for agent/driver.yaml
└── (modifications to existing commands listed in design D12)
```

---

## Tasks

1. [Task 121: Driver YAML schema and parser](../tasks/milestone-19-pluggable-driver-system/task-121-driver-yaml-schema-and-parser.md) — Define `agent/driver.yaml` schema; extend yaml-parser to load it (D1, D15)
2. [Task 122: `@acp.validate` driver-bindings extension](../tasks/milestone-19-pluggable-driver-system/task-122-validate-driver-bindings-extension.md) — Validate bindings, single-MCP-server, mint/query pairing, reachability (D6, D8)
3. [Task 123: Override-with-fallback routing pattern](../tasks/milestone-19-pluggable-driver-system/task-123-override-fallback-routing-pattern.md) — Reusable directive snippet for consumer commands (D7)
4. [Task 124: `marker.mint` wiring across 6 stamping commands](../tasks/milestone-19-pluggable-driver-system/task-124-marker-mint-wiring.md) — Apply mint dispatch in task-create, spec, design-create, pattern-create, command-create, clarification-create (D2, D9, D12)
5. [Task 125: `query.run` wiring across 3 query-using commands](../tasks/milestone-19-pluggable-driver-system/task-125-query-run-wiring.md) — Apply query dispatch in validate, sync, proceed (D3, D12)
6. [Task 126: Workflow-as-command-override pilot](../tasks/milestone-19-pluggable-driver-system/task-126-workflow-override-pilot.md) — Add override directive to task-create, plan, init (D4, D5, D12)
7. [Task 127: `capabilities.watcher` consultation](../tasks/milestone-19-pluggable-driver-system/task-127-capabilities-watcher-consultation.md) — Consumer commands check the flag; user-decision-based stale-data prompts (D15)
8. [Task 128: Integration tests + backward-compat verification](../tasks/milestone-19-pluggable-driver-system/task-128-integration-and-backward-compat-tests.md) — Full ext-point coverage, zero-driver-bound regression coverage, failure injection
9. [Task 129: Documentation updates](../tasks/milestone-19-pluggable-driver-system/task-129-documentation-updates.md) — AGENT.md, README.md, CHANGELOG.md

---

## Testing Requirements

- [ ] Unit: `agent/driver.yaml` parser handles valid + malformed inputs; clear error messages
- [ ] Unit: `@acp.validate` driver-bindings extension catches every error class in D6
- [ ] Integration: mock MCP server bound; every ext-point dispatched correctly
- [ ] Integration: workflow override dispatches and stops; explicit error surfacing on workflow.run failure
- [ ] Integration: `marker.mint` produces driver-format markers; consumer commands use them verbatim
- [ ] Integration: `query.run` returns driver-defined rows; consumer commands work against them
- [ ] Backward-compat: every existing E2E test passes unchanged with no `agent/driver.yaml`
- [ ] Failure-injection: unreachable MCP server → validate error; bad workflow name → driver error surfaces

---

## Documentation Requirements

- [ ] AGENT.md: new section on the driver system (binding, ext points, override directive)
- [ ] README.md: brief mention + pointer to AGENT.md section
- [ ] CHANGELOG.md: feature entry for v1 driver system
- [ ] `agent/design/local.pluggable-driver-system.md`: already exists, this milestone implements it

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| LLM "STOP" reliability in override directive | High | Medium | Pilot phase (3 commands) collects evidence; structural cues (code-block delimiters, "fallback only" markers) added if reliability is poor |
| Single-MCP-server validation requires runtime-specific introspection | Medium | High | Initial validate impl targets one runtime (Claude Code via slash-command); broader runtime support iterative |
| Mint-wiring across 6 commands hits hidden coupling | Medium | Low | Task 124 pilots one command first, then rolls out; coupling discovered during pilot |
| Backward-compat regression in existing test suite | High | Low | Task 128 explicitly verifies; design D11 invariant: absent driver.yaml ≡ today's behavior |
| Workflow override directive interacts badly with command's own clarification-capture | Medium | Low | Pilot phase reveals; directive is at top-of-file before any command body |

---

**Next Milestone**: TBD (full ~37-command override rollout is a candidate, but explicitly NOT v1.1 of this milestone — distinct effort)
**Blockers**: None — design is locked, dependencies are clear
**Notes**:
- Tasks 124 and 125 each touch multiple commands but apply the same dispatch pattern. Bundle for coherence; split if any one command becomes load-bearing complex during implementation.
- Task 126 (override directive on 3 pilots) is the highest-risk task; most likely to surface "LLM STOP" reliability concerns. Schedule before task 128 so integration tests can validate observed behavior.
- Out-of-v1 items (multi-driver, driver-to-driver, migration tooling, full command rollout) are explicit non-goals per design D11 — no shadow-tasks for them.
