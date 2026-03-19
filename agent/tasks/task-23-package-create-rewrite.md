# Task 23: Rewrite @acp.package-create

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 6-8 hours  
**Dependencies**: Task 24 (Pre-Commit Hooks)  
**Status**: Not Started  

---

## Objective

Completely rewrite @acp.package-create to install full ACP in new directory, configure release branch, and install pre-commit hooks.

---

## Context

From clarifications:
- Create directory and run acp.install.sh
- Create package.yaml with metadata
- Configure release branch
- Install pre-commit hook
- Remove example file creation
- Keep all templates from ACP installation

---

## Steps

### 1. Update Command Documentation

Update agent/commands/acp.package-create.md with new workflow.

### 2. Rewrite Script

Rewrite agent/scripts/acp.package-create.sh:

**New Workflow**:
1. Collect package information (existing)
2. Collect target directory (existing)
3. Collect release branch name (new)
4. Create target directory
5. Run acp.install.sh in target directory (new)
6. Create package.yaml
7. Configure release.branch in package.yaml (new)
8. Install pre-commit hook (new)
9. Initialize git and commit
10. Display next steps

### 3. Test Package Creation

Test complete workflow.

---

## Verification

- [ ] acp.package-create.md updated
- [ ] acp.package-create.sh rewritten
- [ ] ACP installation works
- [ ] package.yaml created correctly
- [ ] Release branch configured
- [ ] Pre-commit hook installed
- [ ] All scenarios tested

---

**Next Task**: [Task 24: Pre-Commit Hook System](task-24-precommit-hook-system.md)  
