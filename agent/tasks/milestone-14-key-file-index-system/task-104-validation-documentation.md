# Task 104: Validation & Documentation

**Milestone**: [M14 - Key File Index System](../../milestones/milestone-14-key-file-index-system.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: [Task 100](task-100-command-directive-integration.md), [Task 101](task-101-creation-command-integration.md)  
**Status**: Completed  

---

## Objective

Add index validation rules to `@acp.validate` and update AGENT.md to reference the key file index system for agent discoverability.

---

## Context

Validation ensures index files stay healthy (no broken paths, valid schemas). AGENT.md integration ensures agents discover the index system on first read, which is critical since the whole point is preventing agents from missing important files.

---

## Steps

### 1. Update @acp.validate Command

Add a new validation section for index files:

**Checks**:
- All paths in index files actually exist (warn on missing)
- Required fields present: path, weight, kind, description, rationale, applies
- Weight values in range 0.0-1.0
- Kind values are valid enum: pattern, command, design, requirements
- Applies values use fully qualified command names (contain a dot)
- Warn if `agent/index/` directory doesn't exist
- Warn if total indexed files exceed recommended limit (15-20)
- Warn if per-namespace entries exceed limit (5-10)

**Output format**:
```
📑 Index Validation:
  ✓ agent/index/local.main.yaml (4 entries, all valid)
  ⚠️ agent/index/core-sdk.main.yaml: path not found: agent/patterns/core-sdk.deleted.md
  ✓ Total: 7 entries across 2 namespaces (within limits)
```

### 2. Update AGENT.md

Add a "Key File Index" section to AGENT.md:

```markdown
## Key File Index

This project uses the ACP Key File Index system. Critical project files
are declared in `agent/index/` with weights and descriptions. Before
making decisions, commands read relevant key files from the index.

- Index files: `agent/index/{namespace}.{qualifier}.yaml`
- Local index: `agent/index/local.main.yaml` (highest precedence)
- Design: `agent/design/local.key-file-index-system.md`
```

### 3. Update README.md

Add brief mention of the key file index in the project README under the ACP features section.

### 4. Add Context Compaction Instructions

Add to CLAUDE.md or session recovery instructions:
- After context compaction, re-read `agent/index/` directory
- Propose key files to re-read based on current work context
- Offer user options for scope control

---

## Verification

- [ ] `@acp.validate` checks all index file paths exist
- [ ] `@acp.validate` validates required fields and value ranges
- [ ] `@acp.validate` warns on missing `agent/index/` directory
- [ ] `@acp.validate` warns on exceeding recommended limits
- [ ] AGENT.md includes Key File Index section
- [ ] README.md mentions key file index
- [ ] Context compaction instructions documented
