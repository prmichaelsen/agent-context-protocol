# Task 55: @acp.project-info Command

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)
**Estimated Time**: 1-2 hours
**Dependencies**: Task 52 (Registry Infrastructure)
**Status**: Not Started

---

## Objective

Implement the `@acp.project-info` command to display detailed information about a specific project including metadata, related projects, and dependencies.

---

## Context

This command provides comprehensive project details from the registry, helping users understand project relationships and dependencies.

---

## Steps

### 1. Create Shell Script

Create `agent/scripts/acp.project-info.sh`:
- Accept project name as argument
- Validate project exists
- Display all project metadata
- Format output clearly

### 2. Create Command Document

Create `agent/commands/acp.project-info.md`

### 3. Display Metadata

Show:
- Project name and type
- Description
- Status
- Path
- Timestamps (created, modified, accessed)
- Tags
- Related projects
- Dependencies

### 4. Make Executable

```bash
chmod +x agent/scripts/acp.project-info.sh
```

---

## Verification

- [ ] Script created and executable
- [ ] Command document created
- [ ] Displays all metadata fields
- [ ] Handles missing projects
- [ ] Clear formatting
- [ ] No syntax errors

---

**Next Task**: [Task 56: @acp.project-update Command](task-56-project-update.md)
