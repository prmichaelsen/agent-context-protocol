# Task 128: Integration Tests + Backward-Compat Verification

<!-- @scry.entry
id: task.integration-backward-compat-tests~b4193794
kind: task
summary: >
  End-to-end tests covering every ext point with a mock MCP server bound;
  backward-compat verification with no driver.yaml present.
status: completed
weight: 0.6
tags: ["topic:integration-tests", "topic:backward-compat", "topic:mock-mcp-server", "scope:m19"]
rationale: ""
applies: ""
seeded_questions: []
milestone: M19
design: agent/design/local.pluggable-driver-system.md
depends_on: [task-121, task-122, task-123, task-124, task-125, task-126, task-127]
started: 2026-05-04T08:15:00Z
completed: 2026-05-04T09:00:00Z
updated: 2026-05-04
@scry.entry.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — Testing Strategy section
**Estimated Time**: 4-6 hours

---

## Objective

Build the integration test suite that validates the pluggable driver system end-to-end with a mock MCP server bound to all ext points. Verify backward compatibility (zero behavior change when no `agent/driver.yaml`). Verify failure-injection paths surface errors clearly and don't silently fall through.

---

## Context

Per design Testing Strategy, four test layers cover the system:

1. **Unit-level**: covered by tasks 121 (parser) and 122 (validate extension)
2. **Integration-level**: this task — mock driver, every ext point exercised
3. **Backward-compat**: this task — zero behavior change when unbound
4. **Failure-injection**: this task — unreachable server, bad bindings, workflow.run errors

Without this task, M19 ships untested as a system. Individual tasks have their own unit/component tests, but the integration story is owned here.

---

## Steps

### 1. Build a mock MCP server

Create a minimal mock MCP server (Python or TypeScript — pick whichever fits the existing test infrastructure) that exposes:

- `mock_mint(kind, context?)` — returns a fixed `{id, marker_open, marker_close, fields[]}` shape; the marker shape is recognizably non-`@acp.meta.*` (e.g., `@mock.doc`)
- `mock_query(query)` — returns a fixed mock row array; varies based on the query input so tests can verify routing
- `mock_workflow(action, workflow?, args?)` — supports `action="run"` returning a configurable result; can be configured to return errors for failure-injection tests
- Configurable failure modes: per-tool-call error, server unreachable, malformed response

Mock should be runnable as a real MCP server (registered with the agent runtime during tests) so dispatch tests exercise the actual catalog-resolution path, not a mocked-out shim.

### 2. Test fixtures

Create test fixtures under `e2e/fixtures/driver-system/`:

- **No driver fixture**: a project with no `agent/driver.yaml` — validates backward compat
- **Bound driver fixture**: a project with `agent/driver.yaml` mapping all 3 ext points to the mock + 3 workflows mapped to mock workflow names
- **Partially bound fixture**: only `workflow.run` bound (no mint, no query) — exercises override-with-fallback for unbound ext points
- **Misconfigured fixtures**: query bound without mint (should fail validate), bindings spanning two mock servers (should fail validate), bindings to nonexistent tool (should fail validate)

### 3. Integration test suite

For each fixture, run a series of ACP commands and verify:

**No driver fixture**:
- `@acp.validate` runs without driver section
- `@acp.task-create`, `@acp.spec`, `@acp.design-create`, `@acp.pattern-create`, `@acp.command-create`, `@acp.clarification-create` all stamp `@acp.meta.*` markers
- `@acp.sync`, `@acp.proceed` use grep/awk paths
- `@acp.task-create`, `@acp.plan`, `@acp.init` execute their existing markdown steps (no override dispatch)

**Bound driver fixture**:
- `@acp.validate` reports driver bindings section with all green
- All 6 marker-stamping commands invoke `mock_mint` and produce `@mock.doc` markers (no `@acp.meta.*`)
- All 3 query-using commands invoke `mock_query` for their query points
- All 3 workflow-override pilot commands invoke `mock_workflow(action="run")` and STOP without executing markdown steps
- Mock-tool call logs show every dispatch happened

**Partially bound fixture**:
- `workflow.run` invocations route to `mock_workflow`
- `marker.mint` and `query.run` use fallback (since unbound)
- Validate passes (no pairing violation since neither query nor mint is bound)

**Misconfigured fixtures**:
- Validate rejects each with the correct error message

### 4. Backward-compat regression suite

Run the **entire existing E2E test suite** with no `agent/driver.yaml` present. Every existing test must pass unchanged. This is the load-bearing invariant from D7.

Add a CI check (or manual sign-off) that confirms zero existing tests modified or skipped.

### 5. Failure-injection tests

With the bound driver fixture and the mock configured to fail in various ways:

- **Mock returns error from `workflow.run`**: pilot command surfaces error; markdown steps NOT executed
- **Mock returns error from `marker.mint`**: stamping command surfaces error; falls back to existing template? OR surfaces and stops? (Per design, mint is the format authority — if it errors, the stamp can't proceed. Surface and stop, no fallback.)
- **Mock returns error from `query.run`**: query-using command surfaces error; does NOT fall through to grep/awk (per task 125 notes)
- **Mock server unreachable mid-run**: the in-progress command surfaces a clear "MCP server lost connection" error; does not silently fall through

Each failure-injection scenario produces a clear, actionable error in the user-visible output.

### 6. Reliability evidence for workflow override

Tied to task 126's reliability concern. Run the workflow-override pilot tests across multiple LLM sessions (5+) to gather evidence that the dispatch-then-stop semantic is reliable. Document findings.

---

## User-Observable Acceptance

- [ ] Running the M19 integration test suite produces a clear pass/fail summary covering all fixtures and scenarios.
- [ ] The full existing E2E test suite passes unchanged when no `agent/driver.yaml` is present.
- [ ] Each failure-injection scenario produces an explicit error in the user-visible output (not silent fallback, not opaque crash).
- [ ] Workflow-override reliability across 5+ sessions documented in test results.

---

## Verification

- [ ] Mock MCP server implemented and registers correctly with the test agent runtime
- [ ] All 4 fixture categories created (no driver, bound, partially bound, misconfigured)
- [ ] Bound-driver tests verify each ext-point dispatch via mock-tool call logs
- [ ] Backward-compat suite passes 100% with no driver.yaml
- [ ] Failure-injection scenarios all surface explicit errors
- [ ] Workflow-override reliability evidence captured (number of sessions, success rate, any structural cues that improved reliability)
- [ ] Tests are idempotent (running twice produces same result)
- [ ] Tests are CI-runnable (no manual MCP server setup required during CI)

---

## Expected Output

**Files Created**:
- `e2e/fixtures/driver-system/` — 4 fixture directories
- `e2e/mock-mcp-server/` — mock server implementation
- `e2e/driver-system.integration.test.sh` — integration suite (or equivalent)
- `e2e/driver-system.failure-injection.test.sh` — failure-injection suite
- Documentation in test files describing what each test asserts

**CI Updates**:
- New test job (or extension of existing) that runs the M19 suite alongside existing tests

---

## Notes

- The mock MCP server is the highest-cost item in this task. If existing test infrastructure doesn't have a clean way to register MCP servers during tests, that's the load-bearing complexity to design first.
- Backward-compat is the single most important assertion in M19. If any existing test breaks, halt M19 rollout and fix root cause — don't paper over with test edits.
- Failure-injection is where the design's "explicit error surfacing, not silent fallback" gets its teeth. Don't skip these scenarios; they're the only place silent-fallback bugs would surface.
- Reliability evidence for workflow override (step 6) feeds the post-M19 decision on whether to roll out the override directive to all ~37 ACP commands. Capture data conservatively — if reliability is shaky, recommend pilot extension before broader rollout.

---

**Next Task**: [Task 129: Documentation updates](task-129-documentation-updates.md)
