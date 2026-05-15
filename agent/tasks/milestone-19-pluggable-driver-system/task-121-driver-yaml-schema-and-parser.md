# Task 121: Driver YAML Schema and Parser Support

<!-- @scry.entry
id: task.driver-yaml-schema-parser~791b7456
kind: task
summary: >
  Define agent/driver.yaml schema and extend yaml-parser to load it;
  cover bindings, workflows, and capabilities.watcher.
status: completed
weight: 0.6
tags: ["topic:driver-yaml", "topic:schema", "topic:yaml-parser", "topic:capabilities-watcher", "scope:m19"]
rationale: ""
applies: ""
seeded_questions: []
milestone: M19
design: agent/design/local.pluggable-driver-system.md
incorporates: DR1, DR15
started: 2026-05-04T07:00:00Z
completed: 2026-05-04T07:20:00Z
updated: 2026-05-04
@scry.entry.end -->

**Milestone**: [M19 - Pluggable Driver System](../../milestones/milestone-19-pluggable-driver-system.md)
**Design Reference**: [Pluggable Driver System](../../design/local.pluggable-driver-system.md) — DR1 (driver.yaml schema), DR15 (capabilities.watcher)
**Estimated Time**: 3-4 hours

---

## Objective

Define the `agent/driver.yaml` schema as a versioned schema document, and extend ACP's yaml-parser (`agent/scripts/acp.yaml-parser.sh`) so commands can load and inspect the file via standard parser functions.

---

## Context

`agent/driver.yaml` is the single project-level file that names the bound driver and declares its bindings, workflow overrides, and capabilities. It's the load-bearing artifact every other task in M19 builds on. Without a schema and parser support, downstream tasks (validate extension, mint wiring, query wiring, override directive) have nothing to read.

---

## Steps

### 1. Define the schema

Create `agent/schemas/driver.schema.yaml` mirroring the existing `agent/schemas/projects.schema.yaml` style (used in M7). Schema documents shape:

```yaml
# agent/driver.yaml
driver: string                # informational, format: "@<org>/<name>" or "<name>"
capabilities:                 # optional
  watcher: bool               # default false
bindings:                     # optional, but invariants apply (DR6)
  marker.mint: string         # MCP tool name, unprefixed
  query.run: string
  workflow.run: string
workflows:                    # optional, ACP command name → driver workflow name
  acp.task-create: string
  acp.plan: string
  acp.init: string
  # ...any acp.<command>: string
```

All keys are optional individually; pairing invariants (e.g., `marker.mint` required if `query.run` bound) are enforced by `@acp.validate`, not by the schema.

### 2. Add parser helpers

In `agent/scripts/acp.yaml-parser.sh` (or a small new helper `agent/scripts/acp.driver-yaml.sh` that uses it), add:

- `driver_yaml_path()` — returns `agent/driver.yaml` if exists, empty string otherwise.
- `driver_yaml_get_driver_name()` — reads `driver:` field; empty if absent.
- `driver_yaml_get_binding(ext_point)` — reads `bindings.<ext_point>`; empty if not bound.
- `driver_yaml_get_workflow(command_name)` — reads `workflows.<command_name>`; empty if not mapped.
- `driver_yaml_get_capability(name)` — reads `capabilities.<name>`; empty if absent (callers default to false).
- `driver_yaml_present()` — boolean: file exists with non-empty content.

### 3. Create a template

Create `agent/driver.template.yaml` showing the canonical shape with placeholders, comparable to `agent/manifest.template.yaml`. Used for documentation and future scaffolding.

### 4. Update package.yaml

Add the schema + template to `package.yaml` under appropriate sections so they're shipped with `acp-core`.

### 5. Test

Add unit tests in `tests/` (or `e2e/`) covering:
- File absent → all helpers return empty/false.
- File present with full content → every getter returns correct value.
- Malformed yaml → parser returns clear error (delegates to existing yaml-parser error semantics).
- Empty `bindings:` and empty `workflows:` → behave as absent.

---

## User-Observable Acceptance

- [ ] In a fresh shell, `agent/scripts/acp.driver-yaml.sh present` (or equivalent) returns false in a project without `agent/driver.yaml`, true when the file exists.
- [ ] `agent/scripts/acp.driver-yaml.sh get-binding marker.mint` returns the bound tool name when set, empty string when not.
- [ ] `agent/scripts/acp.driver-yaml.sh get-workflow acp.task-create` returns the mapped workflow name when set.
- [ ] `agent/schemas/driver.schema.yaml` exists and documents the schema shape.
- [ ] `agent/driver.template.yaml` exists with placeholder content.

---

## Verification

- [ ] Schema document follows the pattern of existing `agent/schemas/*.schema.yaml`
- [ ] Parser helpers are pure shell, no new external dependencies
- [ ] All 6+ helper functions implemented and exported from `acp.driver-yaml.sh`
- [ ] Unit tests cover: absent, present, malformed, partially-populated
- [ ] `bash -n` passes on new scripts
- [ ] Template file exists with all schema sections illustrated
- [ ] `package.yaml` updated to ship schema + template

---

## Expected Output

**File Structure** (new files):
```
agent-context-protocol/
├── agent/
│   ├── schemas/
│   │   └── driver.schema.yaml          # NEW
│   ├── driver.template.yaml            # NEW
│   └── scripts/
│       └── acp.driver-yaml.sh          # NEW (or additions to acp.yaml-parser.sh)
└── tests/
    └── driver-yaml-parser.test.sh      # NEW
```

**Key Files Created**:
- `agent/schemas/driver.schema.yaml`: schema definition
- `agent/driver.template.yaml`: template for new projects
- `agent/scripts/acp.driver-yaml.sh`: parser helper script (or equivalent additions to existing yaml-parser)
- `tests/driver-yaml-parser.test.sh`: unit tests

---

## Notes

- Pairing invariants (`marker.mint` required if `query.run` bound, etc.) belong in task 122 (`@acp.validate` extension), NOT in the schema or parser. Keep this task purely about parsing.
- Schema does NOT include any driver-specific tool names — `<mint-tool-name>`, `<query-tool-name>`, etc. as placeholders.
- `capabilities:` is documented but only `watcher` is defined for v1. Other capabilities can be added without schema breaks since the section is open-ended.

---

**Next Task**: [Task 122: `@acp.validate` driver-bindings extension](task-122-validate-driver-bindings-extension.md)
