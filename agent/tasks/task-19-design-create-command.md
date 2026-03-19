# Task 19: @acp.design-create Command

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 4-5 hours  
**Dependencies**: Task 14, 15, 16, 17, 18  
**Status**: Not Started  

---

## Objective

Implement @acp.design-create command that creates design documents with namespace enforcement. Similar to @acp.pattern-create and @acp.command-create.

---

## Context

From clarifications:
- Works like pattern-create and command-create
- Uses design.template.md
- Supports draft files
- Context-aware behavior

---

## Steps

### 1. Create Command Documentation

Create agent/commands/acp.design-create.md following pattern-create structure.

### 2. Implement Script

Create agent/scripts/acp.design-create.sh:
- Reuse logic from pattern-create and command-create
- Use design.template.md

### 3. Test Design Creation

Test all scenarios.

---

## Verification

- [ ] acp.design-create.md created
- [ ] acp.design-create.sh implemented
- [ ] Works in package and project contexts
- [ ] All scenarios tested

---

**Next Task**: [Task 20: @acp.package-validate Command](task-20-package-validate-command.md)  
