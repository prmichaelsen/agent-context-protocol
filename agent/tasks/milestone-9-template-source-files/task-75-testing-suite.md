# Task 75: Testing Suite for Templates

**Milestone**: [M9 - Template Source Files Support](../../milestones/milestone-9-template-source-files.md)
**Estimated Time**: 6-8 hours
**Dependencies**: Task 74 (Command Updates)
**Status**: Not Started

---

## Objective

Create comprehensive test suite for template system including unit tests, integration tests, and E2E tests covering installation, updates, removal, and edge cases.

---

## Context

This is Phase 5 of the Template Source Files Support implementation. Comprehensive testing ensures the template system works correctly and handles edge cases gracefully.

**Design Document**: [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md)

---

## Steps

### 1. Create Test Package

Create test package with various template types:

**Actions**:
- Create test package in `/tmp/test-acp-templates/`
- Include templates with all features (required, optional, variables, experimental)
- Create actual template files
- Initialize as git repository

### 2. Create Unit Tests

Test individual template functions:

**Actions**:
- Create `tests/acp.template-functions.test.sh`
- Test `validate_target_path()` with valid and invalid paths
- Test `substitute_variables()` with various inputs
- Test `add_template_to_manifest()` function
- Test `is_template_modified()` detection

### 3. Create Integration Tests

Test template workflows:

**Actions**:
- Create `e2e/acp.template-installation.test.sh`
- Test full installation with templates
- Test selective installation (`--templates` flag)
- Test variable substitution
- Test experimental filtering
- Test conflict detection
- Test template updates
- Test template removal

### 4. Test Edge Cases

Test error conditions and edge cases:

**Actions**:
- Test missing template files
- Test invalid target paths
- Test variable substitution with special characters
- Test large templates (performance)
- Test templates with no variables
- Test overwriting existing files
- Test removing modified templates

### 5. Run All Tests

Execute complete test suite:

**Actions**:
- Run unit tests: `bash tests/acp.template-functions.test.sh`
- Run integration tests: `bash e2e/acp.template-installation.test.sh`
- Verify all assertions pass
- Document any failures
- Fix issues and retest

---

## Verification

- [ ] Test package created with all template types
- [ ] Unit tests created (10+ test cases)
- [ ] Integration tests created (15+ test cases)
- [ ] Edge case tests created (10+ test cases)
- [ ] All tests pass (100% success rate)
- [ ] Test coverage includes all template features
- [ ] Performance tests show acceptable speed (<100ms per template)
- [ ] Error handling tests pass
- [ ] Documentation for running tests

---

## Expected Output

### Test Results

```
Running Template System Tests
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Unit Tests (tests/acp.template-functions.test.sh):
  ✓ validate_target_path - valid paths (3/3)
  ✓ validate_target_path - invalid paths (3/3)
  ✓ substitute_variables - basic (1/1)
  ✓ substitute_variables - special chars (1/1)
  ✓ add_template_to_manifest (1/1)
  ✓ is_template_modified (2/2)
  
  Total: 11/11 assertions passed (100%)

Integration Tests (e2e/acp.template-installation.test.sh):
  ✓ Install all templates (5/5)
  ✓ Selective installation (3/3)
  ✓ Variable substitution (4/4)
  ✓ Experimental filtering (3/3)
  ✓ Conflict detection (2/2)
  ✓ Template updates (4/4)
  ✓ Template removal (3/3)
  ✓ Edge cases (5/5)
  
  Total: 29/29 assertions passed (100%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ All Tests Passed (40/40 assertions, 100%)
```

---

## Common Issues and Solutions

### Issue 1: Tests fail due to missing test package

**Symptom**: Cannot find test package files
**Solution**: Ensure test package created in `/tmp/`, verify git init ran

### Issue 2: Variable substitution tests fail

**Symptom**: Variables not substituted in test output
**Solution**: Check TEMPLATE_VARS array populated correctly, verify sed syntax

### Issue 3: Manifest assertions fail

**Symptom**: Manifest doesn't contain expected template entries
**Solution**: Verify `add_template_to_manifest()` called during installation, check YAML syntax

---

## Resources

- [`tests/common.sh`](../../../tests/common.sh): Test utilities
- [`e2e/acp.package-install.test.sh`](../../../e2e/acp.package-install.test.sh): Example E2E tests
- [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md): Design document

---

## Notes

- Use existing test utilities from `tests/common.sh`
- Follow E2E test patterns from other package tests
- Test both success and failure paths
- Include performance benchmarks
- Document test setup and teardown
- Consider adding visual test output formatting

---

**Next Task**: [Task 76: Documentation](task-76-documentation.md)
**Related Design Docs**: [Template Source Files Support](../../design/local.acp-template-source-files.md)
**Estimated Completion Date**: TBD
