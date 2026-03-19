# Task 21: Enhanced @acp.validate

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 15 (Namespace Utilities)  
**Status**: Not Started  

---

## Objective

Enhance existing @acp.validate command to check namespace conventions and reserved name usage across all ACP documents.

---

## Context

From clarifications:
- Check all files use correct namespace
- Validate namespace in filename and content
- Reject reserved namespaces (acp, local)
- Integrate with existing validation

---

## Steps

### 1. Update Command Documentation

Update agent/commands/acp.validate.md:
- Add namespace validation section
- Document reserved namespaces
- Add examples

### 2. Add Namespace Validation

Enhance validation logic:
- Check command filenames use correct namespace
- Check pattern filenames use correct namespace
- Check design filenames use correct namespace
- Validate namespace format
- Check for reserved namespace usage

### 3. Test Enhanced Validation

Test namespace checking with various scenarios.

---

## Verification

- [ ] acp.validate.md updated
- [ ] Namespace validation implemented
- [ ] Reserved names checked
- [ ] All scenarios tested

---

**Next Task**: [Task 22: @acp.package-publish Command](task-22-package-publish-command.md)  
