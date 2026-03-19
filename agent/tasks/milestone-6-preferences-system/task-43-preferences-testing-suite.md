# Task 43: Preferences Testing Suite

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)  
**Estimated Time**: 6-8 hours  
**Dependencies**: Task 37-42 (All preference infrastructure and commands)  
**Status**: Not Started  

---

## Objective

Create comprehensive unit, integration, and E2E tests for the preferences system, ensuring correct precedence resolution, validation, and command integration.

---

## Context

The preferences system has complex precedence rules and multiple integration points. Thorough testing ensures:
- Precedence works correctly (Project > Workspace > User > Default)
- Presets override correctly
- Command-line overrides work
- Validation catches invalid values
- Commands respect preferences
- Backward compatibility maintained

---

## Steps

### 1. Create Unit Test File

Create `tests/acp.preferences-get.test.sh`:

```bash
#!/usr/bin/env bash
# Unit tests for acp.preferences-get.sh

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/../agent/scripts/acp.preferences-get.sh"

# Test 1: Preference precedence (project > workspace > user > default)
test_preference_precedence() {
  setup_test_env
  
  # Create preferences at all levels with different values
  echo "acp:" > "$TEST_USER_PREF"
  echo "  plan.draft.create_mode: 'unstructured'" >> "$TEST_USER_PREF"
  
  echo "acp:" > "$TEST_WORKSPACE_PREF"
  echo "  plan.draft.create_mode: 'structured'" >> "$TEST_WORKSPACE_PREF"
  
  echo "acp:" > "$TEST_PROJECT_PREF"
  echo "  plan.draft.create_mode: 'guided'" >> "$TEST_PROJECT_PREF"
  
  # Assert: Project value wins
  local result=$(get_preference 'acp' 'plan.draft.create_mode')
  assert_equals "$result" "guided" "Project preference should win"
  
  cleanup_test_env
}

# Test 2: Fallback to default
test_preference_default_fallback() {
  setup_test_env
  
  # No preferences set, only configurables
  local result=$(get_preference 'acp' 'plan.draft.create_mode')
  assert_equals "$result" "structured" "Should use default from configurables"
  
  cleanup_test_env
}

# Test 3: Missing preference
test_missing_preference() {
  setup_test_env
  
  local result=$(get_preference 'acp' 'nonexistent.preference')
  assert_equals "$result" "" "Should return empty for missing preference"
  
  cleanup_test_env
}

# Test 4: Workspace overrides user
test_workspace_overrides_user() {
  setup_test_env
  
  echo "acp:" > "$TEST_USER_PREF"
  echo "  plan.draft.create_mode: 'unstructured'" >> "$TEST_USER_PREF"
  
  echo "acp:" > "$TEST_WORKSPACE_PREF"
  echo "  plan.draft.create_mode: 'structured'" >> "$TEST_WORKSPACE_PREF"
  
  # No project preference
  local result=$(get_preference 'acp' 'plan.draft.create_mode')
  assert_equals "$result" "structured" "Workspace should override user"
  
  cleanup_test_env
}

# Test 5: User overrides default
test_user_overrides_default() {
  setup_test_env
  
  echo "acp:" > "$TEST_USER_PREF"
  echo "  plan.draft.create_mode: 'guided'" >> "$TEST_USER_PREF"
  
  # No workspace or project preference
  local result=$(get_preference 'acp' 'plan.draft.create_mode')
  assert_equals "$result" "guided" "User should override default"
  
  cleanup_test_env
}

# Test 6: Preset overrides all
test_preset_overrides_all() {
  setup_test_env
  
  # Set preferences at all levels
  echo "acp:" > "$TEST_USER_PREF"
  echo "  plan.draft.create_mode: 'unstructured'" >> "$TEST_USER_PREF"
  
  echo "acp:" > "$TEST_PROJECT_PREF"
  echo "  plan.draft.create_mode: 'structured'" >> "$TEST_PROJECT_PREF"
  
  # Create preset
  echo "acp:" > "$TEST_PRESET"
  echo "  plan.draft.create_mode: 'contextual'" >> "$TEST_PRESET"
  
  local result=$(get_preference_with_preset 'acp' 'plan.draft.create_mode' 'test-preset')
  assert_equals "$result" "contextual" "Preset should override all"
  
  cleanup_test_env
}

# Test 7: Get preference source
test_get_preference_source() {
  setup_test_env
  
  echo "acp:" > "$TEST_PROJECT_PREF"
  echo "  plan.draft.create_mode: 'guided'" >> "$TEST_PROJECT_PREF"
  
  local source=$(get_preference_source 'acp' 'plan.draft.create_mode')
  assert_equals "$source" "project" "Should identify project as source"
  
  cleanup_test_env
}

# Test 8: Has preference check
test_has_preference() {
  setup_test_env
  
  echo "acp:" > "$TEST_USER_PREF"
  echo "  plan.draft.create_mode: 'guided'" >> "$TEST_USER_PREF"
  
  has_preference 'acp' 'plan.draft.create_mode'
  assert_equals "$?" "0" "Should return true for existing preference"
  
  has_preference 'acp' 'nonexistent.preference'
  assert_equals "$?" "1" "Should return false for missing preference"
  
  cleanup_test_env
}

# Run all tests
run_tests
```

### 2. Create Integration Test File

Create `e2e/acp.plan-with-preferences.test.sh`:

```bash
#!/usr/bin/env bash
# Integration tests for @acp.plan with preferences

source "$(dirname "$0")/../tests/common.sh"

# Test 1: @acp.plan respects preferences
test_plan_uses_preferences() {
  setup_test_project
  
  # Set preference
  mkdir -p "./agent/preferences"
  echo "acp:" > "./agent/preferences/acp.default.yaml"
  echo "  plan.draft.create_mode: 'contextual'" >> "./agent/preferences/acp.default.yaml"
  
  # Run @acp.plan (simulated)
  # Verify: No draft file created (contextual mode)
  # Verify: Planning proceeds directly
  
  cleanup_test_project
}

# Test 2: @acp.plan with preset
test_plan_with_preset() {
  setup_test_project
  
  # Create preset
  mkdir -p "./agent/preferences"
  cp "../agent/preferences/acp.batch-planning.yaml" "./agent/preferences/"
  
  # Run @acp.plan with preset (simulated)
  # Verify: Uses batch planning settings
  
  cleanup_test_project
}

# Test 3: @acp.plan with override
test_plan_with_override() {
  setup_test_project
  
  # Set preference
  mkdir -p "./agent/preferences"
  echo "acp:" > "./agent/preferences/acp.default.yaml"
  echo "  plan.draft.create_mode: 'structured'" >> "./agent/preferences/acp.default.yaml"
  
  # Run @acp.plan with override (simulated)
  # Verify: Uses override value, not preference
  
  cleanup_test_project
}

run_tests
```

### 3. Create Validation Tests

Create `tests/acp.preferences-validate.test.sh`:

```bash
#!/usr/bin/env bash
# Tests for preference validation

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/../agent/scripts/acp.preferences-get.sh"

# Test 1: Valid preference value
test_validate_valid_preference() {
  setup_test_env
  
  local result=$(validate_preference 'acp' 'plan.draft.create_mode' 'structured')
  assert_equals "$?" "0" "Should validate correct value"
  
  cleanup_test_env
}

# Test 2: Invalid preference value
test_validate_invalid_preference() {
  setup_test_env
  
  local result=$(validate_preference 'acp' 'plan.draft.create_mode' 'invalid')
  assert_equals "$?" "1" "Should reject invalid value"
  
  cleanup_test_env
}

# Test 3: Number range validation
test_validate_number_range() {
  setup_test_env
  
  # Valid range
  validate_preference 'acp' 'task.create.granularity' '5'
  assert_equals "$?" "0" "Should accept value in range"
  
  # Out of range
  validate_preference 'acp' 'task.create.granularity' '15'
  assert_equals "$?" "1" "Should reject value out of range"
  
  cleanup_test_env
}

# Test 4: Boolean validation
test_validate_boolean() {
  setup_test_env
  
  validate_preference 'acp' 'validation.auto_fix.enabled' 'true'
  assert_equals "$?" "0" "Should accept true"
  
  validate_preference 'acp' 'validation.auto_fix.enabled' 'false'
  assert_equals "$?" "0" "Should accept false"
  
  validate_preference 'acp' 'validation.auto_fix.enabled' 'yes'
  assert_equals "$?" "1" "Should reject non-boolean"
  
  cleanup_test_env
}

run_tests
```

### 4. Create Preset Tests

Create `tests/acp.preferences-preset.test.sh`:

```bash
#!/usr/bin/env bash
# Tests for preset system

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/../agent/scripts/acp.preferences-get.sh"

# Test 1: Load preset
test_load_preset() {
  setup_test_env
  
  # Create preset file
  mkdir -p "./agent/preferences"
  echo "acp:" > "./agent/preferences/acp.test-preset.yaml"
  echo "  plan.draft.create_mode: 'contextual'" >> "./agent/preferences/acp.test-preset.yaml"
  
  load_preset 'acp' 'test-preset'
  assert_equals "$?" "0" "Should load preset successfully"
  
  cleanup_test_env
}

# Test 2: Preset overrides project
test_preset_overrides_project() {
  setup_test_env
  
  # Project preference
  echo "acp:" > "./agent/preferences/acp.default.yaml"
  echo "  plan.draft.create_mode: 'structured'" >> "./agent/preferences/acp.default.yaml"
  
  # Preset
  echo "acp:" > "./agent/preferences/acp.test-preset.yaml"
  echo "  plan.draft.create_mode: 'guided'" >> "./agent/preferences/acp.test-preset.yaml"
  
  local result=$(get_preference_with_preset 'acp' 'plan.draft.create_mode' 'test-preset')
  assert_equals "$result" "guided" "Preset should override project"
  
  cleanup_test_env
}

# Test 3: List presets
test_list_presets() {
  setup_test_env
  
  # Create multiple presets
  mkdir -p "./agent/preferences"
  touch "./agent/preferences/acp.preset1.yaml"
  touch "./agent/preferences/acp.preset2.yaml"
  touch "./agent/preferences/acp.default.yaml"  # Should be excluded
  
  local output=$(list_presets 'acp')
  assert_contains "$output" "preset1" "Should list preset1"
  assert_contains "$output" "preset2" "Should list preset2"
  assert_not_contains "$output" "default" "Should not list default"
  
  cleanup_test_env
}

run_tests
```

### 5. Run All Tests

Execute test suite:

```bash
# Run unit tests
./tests/acp.preferences-get.test.sh

# Run validation tests
./tests/acp.preferences-validate.test.sh

# Run preset tests
./tests/acp.preferences-preset.test.sh

# Run integration tests
./e2e/acp.plan-with-preferences.test.sh

# Summary
echo "Test Results:"
echo "  Unit Tests: X/X passing"
echo "  Validation Tests: X/X passing"
echo "  Preset Tests: X/X passing"
echo "  Integration Tests: X/X passing"
```

### 6. Add Test Fixtures

Create test fixtures in `tests/fixtures/preferences/`:

```bash
mkdir -p tests/fixtures/preferences

# Valid preference file
cat > tests/fixtures/preferences/valid.yaml << 'EOF'
acp:
  plan.draft.create_mode: 'structured'
  task.create.granularity: 3
  validation.auto_fix.enabled: true
EOF

# Invalid preference file
cat > tests/fixtures/preferences/invalid.yaml << 'EOF'
acp:
  plan.draft.create_mode: 'invalid_value'
  task.create.granularity: 15
  nonexistent.preference: 'value'
EOF

# Preset file
cat > tests/fixtures/preferences/preset.yaml << 'EOF'
acp:
  plan.draft.create_mode: 'contextual'
  plan.batch.auto_confirm: true
EOF
```

### 7. Document Test Coverage

Create test coverage report:

```markdown
# Preferences System Test Coverage

## Unit Tests (tests/acp.preferences-get.test.sh)
- ✅ Preference precedence (project > workspace > user > default)
- ✅ Fallback to default
- ✅ Missing preference handling
- ✅ Workspace overrides user
- ✅ User overrides default
- ✅ Preset overrides all
- ✅ Get preference source
- ✅ Has preference check

## Validation Tests (tests/acp.preferences-validate.test.sh)
- ✅ Valid preference value
- ✅ Invalid preference value
- ✅ Number range validation
- ✅ Boolean validation
- ✅ String option validation

## Preset Tests (tests/acp.preferences-preset.test.sh)
- ✅ Load preset
- ✅ Preset overrides project
- ✅ List presets
- ✅ Missing preset error

## Integration Tests (e2e/acp.plan-with-preferences.test.sh)
- ✅ @acp.plan respects preferences
- ✅ @acp.plan with preset
- ✅ @acp.plan with override

## Coverage: 20/20 tests passing (100%)
```

---

## Verification

- [ ] Unit test file created (`tests/acp.preferences-get.test.sh`)
- [ ] Validation test file created (`tests/acp.preferences-validate.test.sh`)
- [ ] Preset test file created (`tests/acp.preferences-preset.test.sh`)
- [ ] Integration test file created (`e2e/acp.plan-with-preferences.test.sh`)
- [ ] Test fixtures created (`tests/fixtures/preferences/`)
- [ ] All unit tests passing (8/8)
- [ ] All validation tests passing (5/5)
- [ ] All preset tests passing (3/3)
- [ ] All integration tests passing (3/3)
- [ ] Test coverage documented
- [ ] Tests are executable (`chmod +x`)
- [ ] Tests use common.sh utilities

---

## Expected Output

### Files Created
- `tests/acp.preferences-get.test.sh` - Unit tests (8 tests)
- `tests/acp.preferences-validate.test.sh` - Validation tests (5 tests)
- `tests/acp.preferences-preset.test.sh` - Preset tests (3 tests)
- `e2e/acp.plan-with-preferences.test.sh` - Integration tests (3 tests)
- `tests/fixtures/preferences/` - Test fixtures directory
- `tests/fixtures/preferences/valid.yaml` - Valid preference fixture
- `tests/fixtures/preferences/invalid.yaml` - Invalid preference fixture
- `tests/fixtures/preferences/preset.yaml` - Preset fixture

### Test Output Example
```bash
$ ./tests/acp.preferences-get.test.sh

Running tests for acp.preferences-get.sh...

✅ test_preference_precedence
✅ test_preference_default_fallback
✅ test_missing_preference
✅ test_workspace_overrides_user
✅ test_user_overrides_default
✅ test_preset_overrides_all
✅ test_get_preference_source
✅ test_has_preference

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Results: 8/8 tests passing (100%)
Duration: 0.5s
```

---

## Common Issues and Solutions

### Issue 1: Tests fail due to missing YAML parser
**Symptom**: Error sourcing acp.yaml-parser.sh  
**Solution**: Ensure YAML parser exists and path is correct in test setup  

### Issue 2: Test environment pollution
**Symptom**: Tests affect each other's results  
**Solution**: Ensure `cleanup_test_env()` is called after each test  

### Issue 3: Fixture files not found
**Symptom**: Tests can't load fixture files  
**Solution**: Check fixture paths are relative to test file location  

---

## Resources

- [Test Utilities](../tests/common.sh) - Shared test functions
- [YAML Parser Tests](../tests/acp.yaml-parser.test.sh) - Example test structure
- [E2E Tests](../e2e/) - Example integration tests

---

## Notes

- Tests should be fast (<1s per test file)
- Use test fixtures to avoid creating files during tests
- Clean up test environment after each test
- Tests should be independent (no shared state)
- Consider adding performance tests (preference loading < 100ms)

---

**Next Task**: [Task 44: Preferences Documentation](task-44-preferences-documentation.md)  
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md)  
**Estimated Completion Date**: TBD  
