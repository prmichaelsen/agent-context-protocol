# Task 57: @acp.project-remove Command

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)
**Estimated Time**: 1-2 hours
**Dependencies**: Task 52 (Registry Infrastructure)
**Status**: Not Started

---

## Objective

Implement the `@acp.project-remove` command to remove projects from the registry with optional directory deletion.

---

## Steps

### 1. Create Shell Script

Create `agent/scripts/acp.project-remove.sh`:
- Accept project name
- Support --delete-files flag (deletes project directory)
- Support -y/--yes flag (auto-confirm)
- Remove from registry
- Update current_project if removing current

### 2. Create Command Document

Create `agent/commands/acp.project-remove.md`

### 3. Safety Checks

- Confirm before deletion
- Warn if deleting current project
- Validate project exists
- Handle errors gracefully

### 4. Make Executable

```bash
chmod +x agent/scripts/acp.project-remove.sh
```

---

## Verification

- [ ] Script created and executable
- [ ] Command document created
- [ ] Removes from registry
- [ ] Optional directory deletion works
- [ ] Confirmation prompts work
- [ ] Updates current_project if needed

---

**Next Task**: [Task 58: @acp.projects-sync Command](task-58-projects-sync.md)
