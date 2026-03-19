# Task 99: Index Directory Infrastructure

**Milestone**: [M14 - Key File Index System](../../milestones/milestone-14-key-file-index-system.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: None  
**Status**: Completed  

---

## Objective

Create the `agent/index/` directory structure, define the index schema, and create the `local.main.yaml` template. This establishes the foundation all other M14 tasks build on.

---

## Context

The Key File Index System needs a well-defined directory and schema before any command integration can happen. The `agent/index/` directory follows the `{namespace}.{qualifier}.yaml` naming convention, enabling multiple index files per namespace for future extensibility.

---

## Steps

### 1. Create Directory Structure

- Create `agent/index/` directory
- Add `.gitkeep` for empty directory tracking

### 2. Create Index Template

Create `agent/index/local.main.template.yaml` with the full schema:

```yaml
# agent/index/local.main.yaml
# Key file index for project-local files
# See: agent/design/local.key-file-index-system.md

local:
  index:
    - path: agent/design/requirements.md
      weight: 1.0
      kind: requirements
      description: |
        Core project requirements.
      rationale: |
        Must be read before any design or task creation.
      applies: acp.init, acp.design-create, acp.task-create, acp.plan, acp.proceed
```

### 3. Define Schema Validation Rules

Document the required fields and valid values for index entries:
- `path` (string, required) — explicit file path, no globs
- `weight` (float, required) — 0.0 to 1.0
- `kind` (enum, required) — pattern, command, design, requirements
- `description` (string, required) — what the file contains
- `rationale` (string, required) — why it's in the index
- `applies` (string, required) — comma-separated fully qualified command names

### 4. Create local.main.yaml for ACP Project

Create the actual `agent/index/local.main.yaml` for the agent-context-protocol project itself, indexing its own key patterns and designs.

### 5. Add to ACP Install Process

Update `acp.install.sh` to create `agent/index/` directory during ACP installation.

---

## Verification

- [ ] `agent/index/` directory exists
- [ ] `local.main.template.yaml` follows documented schema
- [ ] `local.main.yaml` created for ACP project with sensible entries
- [ ] `acp.install.sh` creates `agent/index/` on install
- [ ] Schema fields match design document specification
