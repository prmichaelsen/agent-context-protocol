# Task 20: @acp.package-validate Command

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 7-9 hours  
**Dependencies**: Task 14 (YAML Schema), Task 15 (Namespace Utilities)  
**Status**: Not Started  

---

## Objective

Implement comprehensive package validation with shell-based and LLM-based checks, auto-fix capabilities, test installation, and remote availability verification.

---

## Context

From clarifications:
- Shell validation (structure, files, git)
- LLM validation (content quality)
- Test installation to /tmp (default behavior)
- Remote availability check
- Auto-fix with user choice (all at once or step-by-step)
- Output in chat window

---

## Steps

### 1. Create Command Documentation

Create agent/commands/acp.package-validate.md with complete validation workflow.

### 2. Implement Shell Validation

Create agent/scripts/acp.package-validate.sh with shell checks.

### 3. Implement LLM Validation

Add LLM-based content quality checks.

### 4. Implement Test Installation

Add test installation to /tmp directory.

### 5. Implement Auto-Fix

Add auto-fix capabilities with user guidance.

### 6. Implement Reporting

Generate comprehensive validation report.

### 7. Test Validation

Test with various package states.

---

## Verification

- [ ] acp.package-validate.md created
- [ ] acp.package-validate.sh implemented
- [ ] Shell validation works
- [ ] LLM validation works
- [ ] Test installation works
- [ ] Auto-fix works
- [ ] All scenarios tested

---

**Next Task**: [Task 21: Enhanced @acp.validate](task-21-enhanced-acp-validate.md)  
