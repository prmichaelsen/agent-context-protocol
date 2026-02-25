# Task 70: Fix YAML Parser Array Operations

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)
**Estimated Time**: 2-3 hours
**Dependencies**: Task 56 (@acp.project-update Command)
**Status**: Not Started

---

## Objective

Fix the YAML parser's `yaml_array_append()` function to properly handle array operations, enabling tag and related project management in `@acp.project-update`.

---

## Context

The `yaml_array_append()` function in `acp.yaml-parser.sh` fails with "Error: Path does not point to an array" even when the field is correctly formatted as `tags: []`. This causes 2 test failures in `e2e/acp.project-update.test.sh` (90% passing, 18/20).

**Current Behavior**:
```bash
# This fails:
yaml_array_append ".projects.test.tags" "production"
# Error: Path does not point to an array
```

**Root Cause**: The array detection logic in `yaml_array_append()` (line ~709 in acp.yaml-parser.sh) fails to recognize empty arrays or arrays created via `yaml_set`.

---

## Steps

### 1. Analyze yaml_array_append Function

Read and understand the current implementation:

**Actions**:
- Read `agent/scripts/acp.yaml-parser.sh` lines 675-726
- Understand array node detection logic
- Identify why empty arrays aren't recognized
- Check how `find_child_by_key` works for arrays

**Expected Outcome**: Root cause identified

### 2. Create Test Cases

Create isolated test cases for array operations:

**Actions**:
- Create `tests/yaml-array-operations.test.sh`
- Test appending to empty array: `tags: []`
- Test appending to array with items: `tags: [item1]`
- Test appending to non-existent field
- Test appending to scalar field (should error)

**Expected Outcome**: Test suite for array operations

### 3. Fix Array Detection Logic

Modify `yaml_array_append()` to handle empty arrays:

**Possible Fixes**:
- Check node type before verifying children
- Handle empty arrays as special case
- Improve `find_child_by_key` to work with arrays
- Add debug output to understand failure mode

**Expected Outcome**: `yaml_array_append()` works with empty arrays

### 4. Verify Fix with Tests

Run test suite to confirm fix:

**Actions**:
- Run `tests/yaml-array-operations.test.sh`
- Run `e2e/acp.project-update.test.sh`
- Verify all tests pass (20/20)

**Expected Outcome**: 100% test coverage

### 5. Update project-update Script

Remove workarounds and use fixed `yaml_array_append`:

**Actions**:
- Update `agent/scripts/acp.project-update.sh`
- Remove sed-based workarounds
- Use `yaml_array_append()` directly
- Test tag operations work correctly

**Expected Outcome**: Clean implementation using parser API

### 6. Update Pattern Document

Document the fix in the E2E testing pattern:

**Actions**:
- Update `agent/patterns/local.e2e-testing-pattern.md`
- Remove "Known Limitations" section about arrays
- Add note that array operations now work
- Update success rate to 100%

**Expected Outcome**: Pattern document reflects fix

---

## Verification

- [ ] Array detection logic fixed in yaml-parser.sh
- [ ] Test suite created for array operations
- [ ] All array operation tests passing
- [ ] e2e/acp.project-update.test.sh: 20/20 passing (100%)
- [ ] project-update script uses yaml_array_append
- [ ] No sed-based workarounds remaining
- [ ] Pattern document updated
- [ ] No syntax errors in modified scripts

---

**Next Task**: [Task 57: @acp.project-remove Command](task-57-project-remove.md)
