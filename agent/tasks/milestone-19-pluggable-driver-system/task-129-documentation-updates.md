# Task 129: Documentation Updates

<!-- @acp.meta.task
topic: documentation, agent-md, readme, changelog, driver-system-docs
description: Update AGENT.md, README.md, CHANGELOG.md to document the v1 pluggable driver system
milestone: M19
design: agent/design/local.pluggable-driver-system.md
depends_on: task-121, task-122, task-123, task-124, task-125, task-126, task-127, task-128
status: draft
updated: 2026-05-01
@acp.meta.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Estimated Time**: 2-3 hours

---

## Objective

Update ACP's user-facing documentation (AGENT.md, README.md, CHANGELOG.md) to describe the v1 pluggable driver system: what it is, how to bind a driver, what each ext point does, the workflow-override mechanism, and how to validate a driver configuration.

---

## Context

M19 ships a meaningful new capability — pluggable MCP-server drivers — that ACP users will want to discover and adopt. Without documentation, the feature exists but isn't usable; the design doc and task notes are internal artifacts not aimed at end users. This task closes that gap.

---

## Steps

### 1. Update AGENT.md

Add a new top-level section to AGENT.md (the comprehensive ACP methodology document) titled "Pluggable Drivers" or similar. Include:

- **What a driver is**: an external MCP server that overrides specific ACP roles per-project
- **When to bind one**: when you want SQL-backed indexing, validated workflow execution, custom marker formats, or anything beyond bash-ACP's defaults
- **How to bind one**: the three-step flow (install MCP server in agent runtime, edit `agent/driver.yaml`, run `@acp.validate`)
- **The `agent/driver.yaml` schema**: a clear example with `driver:`, `bindings:`, `workflows:`, `capabilities:` blocks. Use placeholder driver/tool names (`@<org>/<driver-name>`, `<mint-tool-name>`, etc.) — no specific driver names.
- **The three ext points**: brief description of what each one does and when it dispatches
- **Workflow override**: how the `workflows:` mapping replaces ACP commands with driver workflows
- **`capabilities.watcher`**: what the flag means and when to set it
- **Backward compat invariant**: with no `agent/driver.yaml`, ACP behaves exactly as today
- **What's not in v1** (link to design D11 and Future Considerations): multi-driver, driver-to-driver deps, migration tooling, additional ext points
- **Pointer to the design doc**: `agent/design/local.pluggable-driver-system.md`

Keep this section focused. Aim for 1-2 pages of AGENT.md, not 10. Most of the depth belongs in the design doc; AGENT.md is the user-facing summary.

### 2. Update README.md

Add a short subsection in README.md (probably under an existing "Features" or "Architecture" section) introducing the driver system in 1-2 paragraphs. Include:

- A one-line description of what drivers do
- A pointer to AGENT.md's new section for details
- A pointer to the design doc

Keep README brief — it's the front door, not the manual.

### 3. Update CHANGELOG.md

Add an entry under the next release version describing M19. Follow existing CHANGELOG conventions (look at recent entries for the format). Include:

- Feature summary (1-2 sentences)
- Breaking changes: NONE (backward-compat invariant)
- New artifacts: `agent/driver.yaml`, `agent/schemas/driver.schema.yaml`, `agent/driver.template.yaml`, M19 milestone + 9 tasks
- Modified commands: list the 6 mint-wired + 3 query-wired + 3 override-pilot commands

### 4. Verify cross-references

Once all three docs are updated, read through them to ensure:
- Cross-references between docs are correct (AGENT.md → design doc; README → AGENT.md)
- Terminology is consistent (e.g., "driver" vs "plugin" — design uses "driver" consistently; documentation should too)
- No specific-driver project references slip in (per project convention; see also the rename done earlier)

### 5. Optional: examples directory

If demand is clear, add an `examples/driver-system/` directory with:
- A sample `agent/driver.yaml`
- A README explaining the example
- Mock or reference scripts

Skip this if it would add scope; the AGENT.md section + design doc cover the canonical example.

---

## User-Observable Acceptance

- [ ] AGENT.md contains a new "Pluggable Drivers" section that a user reading it cold can use to bind a driver to a project.
- [ ] README.md mentions the driver system briefly with a pointer to AGENT.md.
- [ ] CHANGELOG.md has a clear entry for M19 documenting what shipped.
- [ ] No specific-driver project names appear anywhere in the updated docs.
- [ ] Cross-references between docs are correct.

---

## Verification

- [ ] AGENT.md section covers all four sub-areas (what/when/how/schema)
- [ ] AGENT.md section is concise (1-2 pages, not 10)
- [ ] README.md addition is brief (1-2 paragraphs)
- [ ] CHANGELOG entry follows existing format conventions
- [ ] No specific-driver names (any specific-driver project) in any doc
- [ ] Cross-references resolve correctly
- [ ] Backward-compat invariant called out explicitly

---

## Expected Output

**Files Modified**:
- `AGENT.md` — new "Pluggable Drivers" section
- `README.md` — brief mention with pointers
- `CHANGELOG.md` — M19 release entry

**Optional**:
- `examples/driver-system/` — sample configuration

---

## Notes

- This task depends on all earlier M19 tasks completing. The docs describe what shipped; if any task gets descoped during implementation, update the docs to match.
- The design doc (`agent/design/local.pluggable-driver-system.md`) remains the authoritative reference. AGENT.md and README are summaries pointing at it.
- Do not include any specific-driver project's tool names anywhere in the public docs (per project convention). All examples use placeholder names like `@<org>/<driver-name>` and `<mint-tool-name>`.

---

**Next Milestone**: TBD — likely a follow-up effort for full ~37-command override rollout once pilot reliability data lands (post-M19, distinct effort)
