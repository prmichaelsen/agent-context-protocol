# Task 56: @acp.project-update Command

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)  
**Estimated Time**: 1-2 hours  
**Dependencies**: Task 52 (Registry Infrastructure)  
**Status**: Not Started  

---

## Objective

Implement the `@acp.project-update` command to modify project metadata in the registry including status, tags, description, and related projects.

---

## Steps

### 1. Create Shell Script

Create `agent/scripts/acp.project-update.sh`:
- Accept project name and update flags
- Support: --status, --tags, --description, --add-related, --remove-related
- Update registry fields
- Update `last_updated` timestamp

### 2. Create Command Document

Create `agent/commands/acp.project-update.md`

### 3. Make Executable

```bash
chmod +x agent/scripts/acp.project-update.sh
```

---

## Verification

- [ ] Script created and executable
- [ ] Command document created
- [ ] Can update status
- [ ] Can update tags
- [ ] Can update description
- [ ] Can manage related projects
- [ ] Timestamps updated correctly

---

**Next Task**: [Task 57: @acp.project-remove Command](task-57-project-remove.md)  
