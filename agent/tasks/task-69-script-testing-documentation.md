# Task 69: Script-Command Binding - Testing and Documentation

**Milestone**: [M3 - ACP Package Management System](../../milestones/milestone-3-package-management.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 66 (Installation Logic), Task 67 (Validation), Task 68 (Existing Commands)  
**Status**: Not Started  

---

## Objective

Create comprehensive E2E tests for script-command binding and update documentation to explain the system.

---

## Context

This is Phase 5 (final phase) of the script-command binding system. All implementation is complete; this task ensures quality through testing and documentation.

**Design Document**: [`agent/design/local.script-command-binding.md`](../../design/local.script-command-binding.md)  

---

## Steps

### 1. Create E2E Test Suite

Create `e2e/acp.script-command-binding.test.sh`:

**Test Scenarios**:
1. Install command → only its scripts installed
2. Install experimental command without flag → script not installed
3. Install experimental command with flag → script installed
4. Install multiple commands → shared utilities installed once
5. Selective installation → only selected command scripts
6. Update adds new command → new scripts installed
7. Update removes command → unused scripts removed
8. Validation catches frontmatter/package.yaml mismatch

**Actions**:
- Create test file with 8+ test scenarios
- Use temporary test packages
- Verify script installation/skipping
- Verify reference counting
- Verify experimental filtering
- All tests must pass (100%)

### 2. Update acp.package-update.sh

Implement script updates based on command changes:

**Actions**:
- When commands added: Install their scripts
- When commands removed: Remove unused scripts (check reference count)
- When command scripts change: Update accordingly
- Apply experimental filtering

### 3. Update Documentation

Update AGENT.md, README.md, and CHANGELOG.md:

**AGENT.md Updates**:
- Add "Script-Command Binding" section
- Explain dual declaration system
- Document Scripts field requirement
- Provide examples

**README.md Updates**:
- Add script binding examples
- Show how to declare dependencies
- Explain reference counting

**CHANGELOG.md Updates**:
- Add v3.14.0 entry (minor bump - new feature)
- Document script-command binding system
- List all changes across Tasks 65-69

### 4. Update Command Creation Docs

Update @acp.command-create documentation:

**Actions**:
- Document that Scripts field is required
- Explain how to determine script dependencies
- Provide examples with shared utilities
- Update command creation workflow

### 5. Run Full Test Suite

Verify everything works:

**Actions**:
- Run all E2E tests (script-command-binding + existing tests)
- Run validation on ACP core package
- Test installation scenarios manually
- Verify no regressions

---

## Verification

- [ ] E2E test suite created (8+ tests)
- [ ] All tests passing (100%)
- [ ] acp.package-update.sh handles script updates
- [ ] AGENT.md updated with script binding section
- [ ] README.md updated with examples
- [ ] CHANGELOG.md updated (v3.14.0)
- [ ] @acp.command-create docs updated
- [ ] Full test suite passes
- [ ] No regressions in existing functionality
- [ ] Documentation clear and comprehensive

---

## Expected Outcome

**Complete script-command binding system**:
- ✅ Selective installation (only needed scripts)
- ✅ Reference counting (shared utilities)
- ✅ Experimental support (scripts respect flag)
- ✅ Dual validation (consistency enforced)
- ✅ Comprehensive tests (100% passing)
- ✅ Complete documentation

**Version**: 3.13.0 → 3.14.0 (minor bump)  

---

**Next**: Milestone 3 complete (11/11 tasks, 100%)  
