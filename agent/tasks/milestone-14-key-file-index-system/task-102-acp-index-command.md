# Task 102: @acp.index Command

**Milestone**: [M14 - Key File Index System](../../milestones/milestone-14-key-file-index-system.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: [Task 99](task-99-index-directory-infrastructure.md)  
**Status**: Completed  

---

## Objective

Create the `@acp.index` command for managing key file indices with NLP support and codebase exploration capabilities.

---

## Context

Users and agents need a way to manage the key file index beyond manual YAML editing. The `@acp.index` command provides add, remove, explore, and show subcommands with natural language argument parsing.

---

## Steps

### 1. Create Command Directive

Create `agent/commands/acp.index.md` following the command template with:
- Namespace: acp
- NLP argument parsing (same pattern as @acp.sessions, @acp.proceed)
- Subcommands: list (default), add, remove, explore, show

### 2. Implement `list` Subcommand (Default)

List all indexed key files across all namespaces:

```
📑 Key File Index (7 entries across 2 namespaces)

local (4 entries):
  1.0  requirements  agent/design/requirements.md
  0.8  pattern       agent/patterns/local.e2e-testing.md
  0.7  design        agent/design/local.architecture.md
  0.6  design        src/core/state-machine.ts

core-sdk (3 entries):
  0.5  pattern       agent/patterns/core-sdk.service-base.md
  0.4  pattern       agent/patterns/core-sdk.testing-unit.md
  0.3  design        agent/design/core-sdk.architecture.md
```

### 3. Implement `add` Subcommand

`@acp.index add <path>` — Add a file to `agent/index/local.main.yaml`:
- Validate file exists
- Prompt for weight, kind, description, rationale, applies
- Append to local.main.yaml
- Warn if exceeding recommended limits (5-10 per namespace)

### 4. Implement `remove` Subcommand

`@acp.index remove <path>` — Remove a file from `agent/index/local.main.yaml`:
- Find entry by path
- Confirm removal
- Remove from YAML

### 5. Implement `explore` Subcommand

`@acp.index explore` — Scan codebase and suggest key files:
- List files in `agent/design/` not in any index
- List files in `agent/patterns/` not in any index
- Check for `requirements.md` or `architecture` design docs
- Suggest entries with recommended weights
- Let user pick which to add

### 6. Implement `show` Subcommand

`@acp.index show` — Detailed view of all indices with full metadata:
- Show all fields per entry (path, weight, kind, description, rationale, applies)
- Group by namespace and qualifier

### 7. Update package.yaml

Add `acp.index.md` to package.yaml contents if this project is a package.

---

## Verification

- [ ] `@acp.index` (no args) lists all indexed files
- [ ] `@acp.index add` adds entry to local.main.yaml with all required fields
- [ ] `@acp.index remove` removes entry from local.main.yaml
- [ ] `@acp.index explore` discovers un-indexed files and suggests additions
- [ ] `@acp.index show` displays full metadata for all entries
- [ ] NLP argument parsing works (e.g., "add the testing pattern")
- [ ] Warns when exceeding recommended limits
