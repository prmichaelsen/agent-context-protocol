# Task 122: `@acp.validate` Driver-Bindings Extension

<!-- @acp.meta.task
topic: acp-validate, driver-bindings, single-mcp-server, mint-query-pairing, mcp-catalog
description: Extend @acp.validate to verify agent/driver.yaml bindings, single-MCP-server constraint, mint/query pairing, and tool reachability
milestone: M19
design: agent/design/local.pluggable-driver-system.md
incorporates: DR6, DR8
depends_on: task-121
status: completed
started: 2026-05-04T07:20:00Z
completed: 2026-05-04T07:40:00Z
updated: 2026-05-04
@acp.meta.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — DR6 (validation rules), DR8 (single-MCP-server enforcement)
**Estimated Time**: 4-6 hours

---

## Objective

Extend `@acp.validate` (`agent/commands/acp.validate.md`) to detect and validate `agent/driver.yaml` when present. Validation must enforce all four rules from DR6: tool resolution, single-MCP-server, mint/query pairing, and reachability.

---

## Context

`agent/driver.yaml` is user-edited; mistakes are inevitable (typo in tool name, bound tools from two different MCP servers, query bound without mint, MCP server not running). Catching them at validate time turns silent runtime failures into clear errors.

Workflow names in `workflows:` are NOT validated here — per design (DR4 lazy resolution), workflow name correctness is checked at invocation time by the driver itself.

---

## Steps

### 1. Add a "Driver Bindings" validation section to `@acp.validate`

Update `agent/commands/acp.validate.md` to include a new validation section that runs when `agent/driver.yaml` is present (use `driver_yaml_present()` from task 121).

If absent, skip silently — backward-compat invariant.

### 2. Implement validation rules (DR6)

For each rule, surface a clear error with file path + line context:

**Rule 1 — Tool resolution**: every tool name in `bindings:` must resolve in the agent's MCP catalog. Mechanism is runtime-specific (see step 3); validate uses whatever introspection the runtime provides.

**Rule 2 — Single MCP server (DR8)**: all bound tool names must come from the same MCP server. Cross-server bindings fail with: `"Bindings span multiple MCP servers: <tool-A> from <server-1>, <tool-B> from <server-2>. One driver per project — pick one server."`

**Rule 3 — Mint/query pairing (DR2 ↔ DR3)**: if `query.run` is bound, `marker.mint` must also be bound. Failure: `"query.run is bound but marker.mint is not. A driver indexing markers must be able to produce them in canonical format."`

**Rule 4 — Server reachability**: the MCP server hosting bound tools must be currently registered and reachable. Failure: `"MCP server '<server-name>' is unreachable. Ensure it's registered with your agent runtime and the process is running."`

### 3. Runtime-specific MCP catalog introspection

ACP can't introspect every agent runtime's MCP catalog directly. Strategy:
- **For v1**: target one runtime (Claude Code, since this is the primary dev environment). Use whatever introspection mechanism Claude Code exposes for listing registered MCP servers + their tools.
- **Add a runtime adapter layer**: a single function (`mcp_catalog_lookup(tool_name)` or similar) that returns `(server_name, exists)`. Other runtimes can implement the same function later.
- **If introspection is unavailable** (offline, sandboxed): degrade gracefully — surface a warning ("could not verify tools resolve in MCP catalog; assuming bindings are valid") rather than failing validation outright.

### 4. Update validate's report format

Validate's existing output format gets a new section when driver.yaml is present:

```
🔌 Driver Bindings...
  ✓ marker.mint: drill_mint (resolved in mcp.driver)
  ✓ query.run: drill_sql (resolved in mcp.driver)
  ✓ workflow.run: drill_workflow (resolved in mcp.driver)
  ✓ All bound tools from a single MCP server (mcp.driver)
  ✓ marker.mint paired with query.run
  ✓ MCP server reachable
```

On error:
```
🔌 Driver Bindings...
  ✗ query.run: foo_tool — NOT FOUND in MCP catalog
    Fix: ensure foo_tool is exposed by a registered MCP server, or update agent/driver.yaml
```

### 5. Tests

- Unit: each rule fails with the expected error message given malformed input
- Integration: with mock MCP server present, all rules pass
- Integration: with mock MCP server absent, server-reachability rule fails clearly
- Backward-compat: when `agent/driver.yaml` is absent, validate runs as before with no driver section in output

---

## User-Observable Acceptance

- [ ] In a fresh project with no `agent/driver.yaml`, `@acp.validate` runs unchanged from current behavior; output has no driver section.
- [ ] In a project with valid `agent/driver.yaml` and all bound tools resolvable, `@acp.validate` displays a "Driver Bindings" section with green checkmarks for each rule.
- [ ] In a project with `query.run` bound but `marker.mint` unbound, `@acp.validate` reports the pairing failure with the exact message specified above.
- [ ] In a project with bindings spanning two MCP servers, `@acp.validate` reports the cross-server failure.
- [ ] In a project with an unbound tool name (typo or unregistered server), `@acp.validate` reports the resolution failure with the offending tool name.

---

## Verification

- [ ] All 4 DR6 rules implemented and tested
- [ ] Single-MCP-server constraint (DR8) enforced
- [ ] Workflow name validation explicitly NOT done here (lazy resolution per DR4)
- [ ] Runtime-adapter pattern in place (target Claude Code initially; degrade gracefully for unknown runtimes)
- [ ] Validate's output format extended cleanly without breaking existing sections
- [ ] Backward-compat: `agent/driver.yaml` absent → no behavior change
- [ ] Error messages are actionable (include the offending tool/server name + suggested fix)

---

## Expected Output

**Files Modified**:
- `agent/commands/acp.validate.md` — new "Driver Bindings" validation section
- `agent/scripts/acp.validate.sh` (if exists) — implementation of the rules
- Possibly new helper: `agent/scripts/acp.mcp-catalog.sh` — runtime adapter for MCP catalog introspection

**Files Created**:
- Tests in `e2e/` or `tests/` covering each rule + backward compat

---

## Notes

- This task does NOT validate workflow names in `workflows:` — that's lazy per DR4. Adding such validation would require a contract with the driver (action="list") that we explicitly chose not to require.
- Server reachability is a soft check — if introspection fails for environmental reasons (sandboxed shell, etc.), warn rather than fail. Don't block the user when validate can't talk to the runtime.
- The runtime adapter for MCP catalog introspection is the load-bearing complexity here. Picking Claude Code as the v1 target is pragmatic; document the adapter contract so future runtimes can plug in.

---

**Next Task**: [Task 123: Override-with-fallback routing pattern](task-123-override-fallback-routing-pattern.md)
