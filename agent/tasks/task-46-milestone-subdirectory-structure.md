# Task 46: Milestone Subdirectory Structure

**Milestone**: Future Enhancement
**Estimated Time**: 4-6 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Update task directory structure to use milestone subdirectories (`agent/tasks/milestone-{N}-{title}/`) instead of flat structure, making it easier to correlate tasks to milestones and improving organization.

---

## Context

Currently, tasks are stored in a flat directory structure:
```
agent/tasks/
├── task-1-commands-infrastructure.md
├── task-2-workflow-commands.md
├── task-37-preference-loading-infrastructure.md
└── ...
```

**Problem**: Hard to correlate tasks to milestones, difficult to parse and organize.

**Solution**: Use milestone subdirectories (already implemented for Milestone 6):
```
agent/tasks/
├── task-1-commands-infrastructure.md (legacy)
├── milestone-6-preferences-system/
│   ├── task-37-preference-loading-infrastructure.md
│   ├── task-38-configurables-system-enhancement.md
│   └── ...
└── unassigned/
    └── task-{N}-{title}.md (orphaned tasks)
```

**Motivation**: 
- Easier to find tasks for a specific milestone
- Better organization as project grows
- Clearer task-milestone relationships
- Already proven with Milestone 6 tasks

---

## Steps

### 1. Update @acp.task-create Command

Update [`agent/commands/acp.task-create.md`](../commands/acp.task-create.md) to create tasks in milestone subdirectories:

**Changes**:
- Step 6: Update file path logic
  - If milestone assigned: `agent/tasks/milestone-{N}-{title}/task-{M}-{name}.md`
  - If no milestone: `agent/tasks/unassigned/task-{M}-{name}.md`
- Create milestone subdirectory if it doesn't exist
- Update progress.yaml with new path format

**Verification**:
- Command documentation updated
- New path logic documented
- Examples show new structure

### 2. Update @acp.plan Command

Update [`agent/commands/acp.plan.md`](../commands/acp.plan.md) to use milestone subdirectories:

**Changes**:
- Task creation section: Use milestone subdirectory paths
- Update examples to show new structure
- Document migration from flat structure

**Verification**:
- Command updated
- Examples updated
- Migration notes added

### 3. Update AGENT.md Documentation

Update [`AGENT.md`](../../AGENT.md) directory structure diagram:

**Changes**:
- Update "Directory Structure" section (line ~78)
- Show milestone subdirectory pattern
- Add note about legacy flat structure
- Update "Tasks" component section

**Example**:
```
agent/tasks/                      # Granular tasks
├── .gitkeep
├── task-1-{title}.template.md
├── milestone-1-{title}/          # Tasks for milestone 1
│   ├── task-1-{name}.md
│   ├── task-2-{name}.md
│   └── ...
├── milestone-2-{title}/          # Tasks for milestone 2
│   └── ...
└── unassigned/                   # Orphaned tasks
    └── task-{N}-{name}.md
```

**Verification**:
- Directory structure updated
- Examples updated
- Migration notes added

### 4. Update Task Template

Update [`agent/tasks/task-1-{title}.template.md`](task-1-{title}.template.md):

**Changes**:
- Update milestone link to account for parent directory
- Change from `../milestones/` to `../../milestones/`
- Update "Next Task" link format

**Verification**:
- Template updated
- Links work correctly
- Relative paths correct

### 5. Create Migration Guide

Create [`agent/design/task-directory-migration.md`](../design/task-directory-migration.md):

**Content**:
- Explain old vs new structure
- Provide migration script or manual steps
- Document when to use unassigned/ directory
- Explain backward compatibility

**Verification**:
- Migration guide created
- Clear instructions provided
- Script or manual steps documented

### 6. Optional: Migrate Existing Tasks

Optionally migrate existing tasks to new structure:

**Actions**:
- Create milestone subdirectories for M1-M5
- Move tasks to appropriate subdirectories
- Update progress.yaml file paths
- Test that all links still work

**Note**: This step is optional - old flat structure can coexist with new structure.

**Verification**:
- Tasks moved (if migration performed)
- progress.yaml updated
- All links work
- No broken references

---

## Verification

- [ ] @acp.task-create updated to use milestone subdirectories
- [ ] @acp.plan updated to use milestone subdirectories
- [ ] AGENT.md directory structure updated
- [ ] Task template updated with correct relative paths
- [ ] Migration guide created
- [ ] (Optional) Existing tasks migrated
- [ ] All documentation references updated
- [ ] All links work correctly
- [ ] No broken references

---

## Expected Output

### Files Modified
- `agent/commands/acp.task-create.md` - Updated path logic
- `agent/commands/acp.plan.md` - Updated task creation
- `AGENT.md` - Updated directory structure
- `agent/tasks/task-1-{title}.template.md` - Updated relative paths

### Files Created
- `agent/design/task-directory-migration.md` - Migration guide

### Directory Structure
```
agent/tasks/
├── .gitkeep
├── task-1-{title}.template.md
├── milestone-1-acp-commands/
│   ├── task-1-commands-infrastructure.md
│   ├── task-2-workflow-commands.md
│   ├── task-3-version-commands.md
│   └── task-4-update-documentation.md
├── milestone-6-preferences-system/
│   ├── task-37-preference-loading-infrastructure.md
│   └── ...
└── unassigned/
    └── (orphaned tasks)
```

---

## Common Issues and Solutions

### Issue 1: Broken links after migration

**Symptom**: Links to milestones or other tasks don't work

**Solution**: Update relative paths in migrated tasks. From milestone subdirectory, use `../../milestones/` instead of `../milestones/`

### Issue 2: progress.yaml paths incorrect

**Symptom**: Tasks not found when running @acp.proceed

**Solution**: Update file paths in progress.yaml to include milestone subdirectory

### Issue 3: Mixing old and new structure

**Symptom**: Some tasks in subdirectories, some in root

**Solution**: This is acceptable during transition. New tasks use subdirectories, old tasks can stay in root.

---

## Resources

- [Milestone 6 Tasks](milestone-6-preferences-system/): Example of new structure
- [@acp.plan Command](../commands/acp.plan.md): Uses new structure
- [AGENT.md](../../AGENT.md): Main documentation

---

## Notes

- Milestone 6 tasks already use this structure (proof of concept)
- Old flat structure can coexist with new structure
- Migration is optional - both patterns work
- New structure is recommended for new tasks
- Unassigned/ directory for tasks without milestone
- Subdirectory name format: `milestone-{N}-{title}/`
- This improves organization as project scales
- Backward compatible - old paths still work

---

**Next Task**: None (future enhancement)
**Related Design Docs**: task-directory-migration.md (to be created)
**Estimated Completion Date**: TBD
