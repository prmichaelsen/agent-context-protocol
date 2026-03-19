# Task 18: @acp.command-create Command

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 5-6 hours  
**Dependencies**: Task 14, 15, 16, 17  
**Status**: Not Started  

---

## Objective

Implement @acp.command-create command that creates command files with namespace enforcement, draft file support, and automatic updates. Similar to @acp.pattern-create but for commands.

---

## Context

From clarifications:
- Works like @acp.pattern-create
- Uses command.template.md
- Collects command-specific fields (category, frequency)
- Supports draft files
- Context-aware behavior

---

## Steps

### 1. Create Command Documentation

Create agent/commands/acp.command-create.md following pattern-create structure.

### 2. Implement Script

Create agent/scripts/acp.command-create.sh:
- Reuse logic from acp.pattern-create.sh
- Add command-specific fields
- Use command.template.md

### 3. Test Command Creation

Test all scenarios similar to pattern-create.

---

## Verification

- [ ] acp.command-create.md created
- [ ] acp.command-create.sh implemented
- [ ] Command-specific fields collected
- [ ] Works in package and project contexts
- [ ] All scenarios tested

---

**Next Task**: [Task 19: @acp.design-create Command](task-19-design-create-command.md)  
