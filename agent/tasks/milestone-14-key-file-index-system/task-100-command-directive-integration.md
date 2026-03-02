# Task 100: Command Directive Integration

**Milestone**: [M14 - Key File Index System](../../milestones/milestone-14-key-file-index-system.md)
**Estimated Time**: 3-4 hours
**Dependencies**: [Task 99](task-99-index-directory-infrastructure.md)
**Status**: Completed

---

## Objective

Update core workflow command directives (`@acp.init`, `@acp.resume`, `@acp.proceed`, `@acp.plan`) to read key files from `agent/index/` before executing their main logic.

---

## Context

These commands make intelligent decisions that benefit from having critical project context loaded. The design specifies that `@acp.init` and `@acp.resume` read high-weight files (>= 0.8) automatically, while `@acp.proceed` and `@acp.plan` filter by their `applies` field.

---

## Steps

### 1. Define Key File Reading Step

Create a reusable "Read Key Files" step template that can be inserted into command directives:

1. Scan `agent/index/` for all `*.yaml` files
2. Parse entries, merge across namespaces (`local.*` takes precedence)
3. Filter by `applies` field matching the current command name
4. Sort by `weight` descending
5. Read files in weight order
6. Produce visible output

### 2. Update @acp.init

Add a new step (between current steps 2.5 and 3) to read key files:
- Read ALL index files
- Load files with weight >= 0.8 automatically
- Display what was read/skipped
- This runs on every initialization

### 3. Update @acp.resume

Add key file reading step (same behavior as @acp.init since resume invokes init).

### 4. Update @acp.proceed

Add key file reading step before task execution:
- Filter entries where `applies` includes `acp.proceed`
- Read matching files sorted by weight
- Display output

### 5. Update @acp.plan

Add key file reading step before planning:
- Filter entries where `applies` includes `acp.plan`
- Read matching files sorted by weight
- Display output

### 6. Add Context Compaction Instructions

Add instructions to CLAUDE.md or command directives for context compaction behavior:
- Re-read `agent/index/` on compaction
- Propose which files to re-read based on current work
- Offer user options (keep, reduce, add, broader search)

---

## Verification

- [ ] `@acp.init` reads key files and produces visible output
- [ ] `@acp.resume` reads key files
- [ ] `@acp.proceed` reads contextually relevant key files
- [ ] `@acp.plan` reads contextually relevant key files
- [ ] `local.*` entries take precedence over package entries
- [ ] Context compaction re-read proposal is documented
- [ ] Files with weight below threshold are skipped with visible indicator
