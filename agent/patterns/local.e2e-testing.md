# E2E Testing Pattern for Shell Scripts

**Category**: Testing  
**Applicable To**: Shell script projects, ACP packages, CLI tools  
**Status**: Stable  

---

## Overview

The E2E Testing Pattern provides a structured approach for writing comprehensive end-to-end tests for shell scripts. It emphasizes test isolation, clear assertions, and debugging workflows that enable rapid iteration when tests fail.

This pattern emerged from debugging Task 69 (Script-Command Binding), where systematic debugging with a reusable debug script enabled finding and fixing 4 critical bugs efficiently.

---

## When to Use This Pattern

✅ **Use this pattern when:**
- Testing shell scripts with complex logic and multiple code paths
- Testing installation scripts that modify filesystems
- Testing scripts that interact with external tools (git, package managers)
- You need reproducible test scenarios
- Debugging failures requires iterative investigation

❌ **Don't use this pattern when:**
- Testing simple scripts with 1-2 functions
- Unit tests are sufficient (no integration needed)
- Scripts have no side effects
- Test setup is trivial

---

## Core Principles

1. **Test Isolation**: Each test runs in a clean temporary directory with no shared state
2. **Reusable Debug Script**: Create `debug.sh` for rapid iteration during debugging
3. **Clear Assertions**: Use descriptive assertion messages that explain what should happen
4. **Comprehensive Coverage**: Test happy paths, error cases, edge cases, and experimental features
5. **Fast Feedback**: Tests should complete quickly (<2 minutes for full suite)

---

## Implementation

### Structure

```
project-root/
├── e2e/                              # E2E test directory
│   ├── feature.test.sh               # Test suite for feature
│   └── another-feature.test.sh       # Another test suite
├── tests/                            # Unit tests and utilities
│   ├── common.sh                     # Shared test utilities
│   └── fixtures/                     # Test data
├── debug.sh                          # Reusable debug script (gitignored)
└── debug-output.txt                  # Debug output (gitignored)
```

### Test Suite Template

```bash
#!/bin/bash
# E2E Tests for {Feature Name}

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

. "${PROJECT_ROOT}/tests/common.sh"

# Test setup
TEST_NAME="{Feature Name}"
TEST_FAILURES=0

echo "${BLUE}Running E2E Tests: ${TEST_NAME}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Helper function to create test fixtures
create_test_fixture() {
    local fixture_dir="$1"
    mkdir -p "$fixture_dir"
    
    # Create test files
    # ...
}

# Test 1: Happy path
test_happy_path() {
    echo "${BLUE}Test 1: Happy path${NC}"
    
    local test_dir=$(mktemp -d)
    
    # Setup
    create_test_fixture "$test_dir"
    
    # Execute
    cd "$test_dir"
    "${PROJECT_ROOT}/script-under-test.sh" --option value >/dev/null 2>&1
    
    # Assert
    assert_file_exists "$test_dir/expected-file.txt" "Expected file should be created"
    assert_equals "expected" "$(cat $test_dir/result.txt)" "Result should match expected"
    
    # Cleanup
    rm -rf "$test_dir"
    echo ""
}

# Test 2: Error case
test_error_case() {
    echo "${BLUE}Test 2: Error case${NC}"
    
    local test_dir=$(mktemp -d)
    
    # Setup with invalid input
    create_test_fixture "$test_dir"
    
    # Execute (expect failure)
    cd "$test_dir"
    set +e  # Disable exit on error
    "${PROJECT_ROOT}/script-under-test.sh" --invalid 2>/dev/null
    local exit_code=$?
    set -e
    
    # Assert
    assert_not_equals "0" "$exit_code" "Should fail with invalid input"
    
    # Cleanup
    rm -rf "$test_dir"
    echo ""
}

# Run all tests
test_happy_path
test_error_case

# Print summary
print_test_summary

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
```

### Debug Script Template

```bash
#!/bin/bash
# Debug script for {Feature} E2E test failures
# Modify this script to test different scenarios during debugging

set -e

PROJECT_ROOT="/path/to/project"
TEST_DIR=$(mktemp -d)
OUTPUT_FILE="$PROJECT_ROOT/debug-output.txt"

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Redirect output to file AND console
exec > >(tee "$OUTPUT_FILE") 2>&1

echo "=========================================="
echo "Debug Script for {Feature}"
echo "=========================================="
echo "Output saved to: $OUTPUT_FILE"
echo ""

# Test Scenario 1: Reproduce failing test
test_scenario_1() {
    echo "=========================================="
    echo "Test Scenario 1: {Description}"
    echo "=========================================="
    echo ""
    
    cd "$TEST_DIR"
    
    # Setup
    # ...
    
    # Execute with verbose output
    "$PROJECT_ROOT/script-under-test.sh" --option value 2>&1 | grep -E "(DEBUG|ERROR|key-pattern)"
    
    # Check results
    echo ""
    echo "Results:"
    echo "  Expected file: $([ -f "$TEST_DIR/file.txt" ] && echo "✓ YES" || echo "✗ NO")"
    echo ""
}

# Run scenarios
test_scenario_1

echo "=========================================="
echo "Debug Complete"
echo "=========================================="
```

---

## Examples

### Example 1: Testing Installation Script

**Scenario**: Test that package installation creates correct files  

```bash
test_install_creates_files() {
    echo "${BLUE}Test: Installation creates files${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    # Create test package
    mkdir -p "$pkg_dir/agent/commands"
    cat > "$pkg_dir/package.yaml" << 'EOF'
name: test-pkg
version: 1.0.0
contents:
  commands:
    - name: test.cmd.md
      description: Test command
EOF
    
    cat > "$pkg_dir/agent/commands/test.cmd.md" << 'EOF'
# Command: cmd
**Namespace**: test  
**Version**: 1.0.0  
**Status**: Active  
**Scripts**: None  
EOF
    
    # Execute installation
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" -y >/dev/null 2>&1
    
    # Assert
    assert_file_exists "$test_dir/agent/commands/test.cmd.md" "Command should be installed"
    assert_file_exists "$test_dir/agent/manifest.yaml" "Manifest should be created"
    
    # Cleanup
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}
```

### Example 2: Testing with set -e

**Scenario**: Script uses `set -e`, need to test error cases  

```bash
test_error_handling() {
    echo "${BLUE}Test: Error handling${NC}"
    
    local test_dir=$(mktemp -d)
    
    # Execute (expect failure)
    cd "$test_dir"
    set +e  # Disable exit on error temporarily
    "${PROJECT_ROOT}/script.sh" --invalid-option 2>/dev/null
    local exit_code=$?
    set -e  # Re-enable
    
    # Assert non-zero exit
    assert_not_equals "0" "$exit_code" "Should fail with invalid option"
    
    rm -rf "$test_dir"
    echo ""
}
```

### Example 3: Debug Script Usage

**Scenario**: E2E tests failing, need to debug  

**Workflow**:
1. Create `debug.sh` with failing test scenario
2. Run `./debug.sh` (auto-approved by user)
3. Read `debug-output.txt` to see what happened
4. Modify `debug.sh` to add more debug output
5. Run `./debug.sh` again
6. Repeat until bug found
7. Fix bug in source code
8. Run full E2E suite to verify fix

**Example debug.sh**:
```bash
#!/bin/bash
set -e
OUTPUT_FILE="./debug-output.txt"
exec > >(tee "$OUTPUT_FILE") 2>&1

echo "Testing scenario that fails..."
# Reproduce failing test with extra debug output
./script.sh --option value 2>&1 | grep -E "(DEBUG|ERROR)"

echo "Results:"
echo "  File created: $([ -f result.txt ] && echo "YES" || echo "NO")"
```

---

## Benefits

### 1. Rapid Debugging Workflow
The debug.sh pattern enables fast iteration during debugging. Instead of waiting for approval for each debugging command, you modify debug.sh and run it repeatedly. This reduced Task 69 debugging from hours to minutes.

### 2. Test Isolation
Each test runs in a clean temporary directory, preventing test pollution and ensuring reproducible results. Tests can run in parallel without conflicts.

### 3. Clear Failure Messages
Descriptive assertion messages make it immediately clear what failed and why, reducing time spent understanding test failures.

### 4. Comprehensive Coverage
Systematic test scenarios (happy path, error cases, edge cases, experimental features) ensure all code paths are tested.

---

## Trade-offs

### 1. Test Execution Time
**Downside**: Creating temporary directories and running full installations for each test adds overhead (2-3 minutes for 8 tests).  
**Mitigation**: Run tests in parallel where possible. Use debug.sh for rapid iteration during development.  

### 2. Maintenance Burden
**Downside**: E2E tests need updates when script behavior changes.  
**Mitigation**: Keep tests focused on behavior, not implementation. Use helper functions to reduce duplication.  

---

## Anti-Patterns

### ❌ Anti-Pattern 1: Testing Implementation Details

**Description**: Tests that check internal variables or implementation specifics rather than observable behavior.  

**Why it's bad**: Tests break when refactoring, even if behavior is unchanged.  

**Instead, do this**: Test observable outcomes (files created, exit codes, output messages).  

```bash
# ❌ Bad: Testing internal variable
test_bad() {
    result=$(./script.sh)
    # Trying to check internal variable (not possible/reliable)
    assert_contains "$result" "INTERNAL_VAR=value"
}

# ✅ Good: Testing observable behavior
test_good() {
    ./script.sh >/dev/null 2>&1
    assert_file_exists "output.txt" "Script should create output file"
    assert_equals "expected" "$(cat output.txt)" "Output should match expected"
}
```

### ❌ Anti-Pattern 2: Shared State Between Tests

**Description**: Tests that depend on previous tests or share directories/files.  

**Why it's bad**: Tests fail in isolation, order-dependent, hard to debug.  

**Instead, do this**: Each test creates its own temporary directory and cleans up after.  

```bash
# ❌ Bad: Shared directory
SHARED_DIR="/tmp/test-dir"
test_1() {
    mkdir -p "$SHARED_DIR"
    ./script.sh --output "$SHARED_DIR/file1.txt"
}
test_2() {
    # Depends on test_1 having run
    assert_file_exists "$SHARED_DIR/file1.txt"
}

# ✅ Good: Isolated tests
test_1() {
    local test_dir=$(mktemp -d)
    ./script.sh --output "$test_dir/file1.txt"
    assert_file_exists "$test_dir/file1.txt"
    rm -rf "$test_dir"
}
test_2() {
    local test_dir=$(mktemp -d)
    # Independent test
    rm -rf "$test_dir"
}
```

### ❌ Anti-Pattern 3: No Debug Workflow

**Description**: Running full E2E suite repeatedly during debugging, waiting minutes for each iteration.  

**Why it's bad**: Wastes time, slows down debugging, frustrating workflow.  

**Instead, do this**: Create debug.sh that reproduces failing scenario with extra output.  

```bash
# ❌ Bad: Debugging by running full suite
$ bash e2e/feature.test.sh  # Wait 3 minutes
# Test 5 fails
# Modify code
$ bash e2e/feature.test.sh  # Wait 3 minutes again
# Still fails
# Repeat...

# ✅ Good: Use debug.sh for rapid iteration
$ cat > debug.sh << 'EOF'
#!/bin/bash
# Reproduce Test 5 with debug output
./script.sh --option value 2>&1 | grep DEBUG
echo "Result: $([ -f output.txt ] && echo "YES" || echo "NO")"
EOF
$ ./debug.sh  # Runs in seconds
# See debug output immediately
# Modify code
$ ./debug.sh  # Runs in seconds
# Fixed!
$ bash e2e/feature.test.sh  # Final verification
```

---

## Testing Strategy

### Unit Testing
Not covered by this pattern. Use separate unit test framework for testing individual functions.

### Integration Testing
This pattern focuses on integration/E2E testing where the script runs end-to-end with real filesystem operations.

**Approach**:
1. Create isolated test environment (temp directories)
2. Execute script with real inputs
3. Verify observable outcomes
4. Clean up test environment

---

## Debugging Workflow

### Step 1: Identify Failing Test

Run E2E suite and note which test fails:

```bash
$ bash e2e/feature.test.sh
Test 5: Selective installation
✗ common utility should be installed
  Expected file to exist: /tmp/tmp.xyz/agent/scripts/test.common.sh
```

### Step 2: Create debug.sh

Create a debug script that reproduces the failing scenario:

```bash
#!/bin/bash
set -e
PROJECT_ROOT="/path/to/project"
OUTPUT_FILE="$PROJECT_ROOT/debug-output.txt"
exec > >(tee "$OUTPUT_FILE") 2>&1

echo "Reproducing Test 5 failure..."

# Reproduce exact test scenario
TEST_DIR=$(mktemp -d)
# ... setup code from failing test ...

# Execute with verbose output
"$PROJECT_ROOT/script.sh" --option value 2>&1 | grep -E "(DEBUG|ERROR|INSTALL)"

# Check results
echo "Results:"
echo "  File exists: $([ -f "$TEST_DIR/file.txt" ] && echo "YES" || echo "NO")"

rm -rf "$TEST_DIR"
```

### Step 3: Add Debug Output to Source

Add debug output to the source script being tested:

```bash
# In source script
for item in "${ARRAY[@]}"; do
    echo "[DEBUG] Processing: $item"  # Add this
    process_item "$item"
    echo "[DEBUG] Completed: $item"   # Add this
done
echo "[DEBUG] Loop completed"        # Add this
```

### Step 4: Iterate with debug.sh

```bash
$ ./debug.sh                    # Run (auto-approved)
# Read debug-output.txt
# See: "[DEBUG] Processing: item1" but no "[DEBUG] Completed: item1"
# Conclusion: process_item() is failing

# Add more debug output
$ ./debug.sh                    # Run again
# See: process_item fails because of X
# Fix X in source code

$ ./debug.sh                    # Verify fix
# All debug output appears, file created
# Success!
```

### Step 5: Remove Debug Output

Once bug is fixed, remove debug output from source:

```bash
# Remove [DEBUG] lines
# Keep code clean for production
```

### Step 6: Verify with Full Suite

```bash
$ bash e2e/feature.test.sh
# All tests passing
```

---

## Common Pitfalls with set -e

### Pitfall 1: Functions Returning Non-Zero

**Problem**: Function returns non-zero exit code, script exits  

```bash
#!/bin/bash
set -e

get_value() {
    if [ ! -f "file.txt" ]; then
        echo "default"
        return 1  # ← Script exits here!
    fi
    cat file.txt
}

value=$(get_value)  # Script exits if file doesn't exist
```

**Solution**: Return 0 or handle error  

```bash
get_value() {
    if [ ! -f "file.txt" ]; then
        echo "default"
        return 0  # ← Fixed
    fi
    cat file.txt
}
```

### Pitfall 2: Grep with No Matches

**Problem**: `grep` returns 1 when no matches, script exits  

```bash
#!/bin/bash
set -e

result=$(grep "pattern" file.txt)  # ← Exits if no match
```

**Solution**: Add `|| true`  

```bash
result=$(grep "pattern" file.txt || true)  # ← Fixed
```

### Pitfall 3: Command in Loop Fails

**Problem**: Command in loop fails, entire script exits  

```bash
#!/bin/bash
set -e

for item in "${ARRAY[@]}"; do
    process_item "$item"  # ← If this fails, script exits
done
```

**Solution**: Handle errors in loop  

```bash
for item in "${ARRAY[@]}"; do
    if ! process_item "$item"; then
        echo "Warning: Failed to process $item"
        # Continue with next item
    fi
done
```

---

## Related Patterns

- **[Unit Testing Pattern](./local.unit-testing.md)**: For testing individual functions
- **[Debug Workflow Pattern](./local.debug-workflow.md)**: General debugging strategies
- **[Test Fixtures Pattern](./local.test-fixtures.md)**: Managing test data

---

## Checklist for Implementation

- [ ] E2E test suite created in e2e/ directory
- [ ] Tests use temporary directories for isolation
- [ ] Each test has clear, descriptive assertions
- [ ] Test suite completes in reasonable time (<5 minutes)
- [ ] debug.sh created for rapid debugging iteration
- [ ] debug.sh and debug-output.txt added to .gitignore
- [ ] Common test utilities extracted to tests/common.sh
- [ ] All tests passing (100%)
- [ ] Tests cover happy paths, error cases, and edge cases
- [ ] Debug output removed from source code after debugging

---

## Real-World Example: Task 69 Debugging

**Context**: Script-command binding E2E tests failing (7/28 passing, 25%)  

**Problem**: Scripts not being installed during package installation  

**Debug Workflow**:

1. **Created debug.sh** with 3 test scenarios matching E2E tests
2. **Ran ./debug.sh** → saw scripts not installed
3. **Added debug output** to installation script (20+ DEBUG lines)
4. **Ran ./debug.sh** → saw loop processing only 1 script then stopping
5. **Added more debug** around each command in loop
6. **Ran ./debug.sh** → saw loop stopped at `add_file_to_manifest`
7. **Found bug**: `add_file_to_manifest` returned exit code 1, causing script to exit with `set -e`
8. **Fixed bug**: Wrapped call in `if` statement with error handling
9. **Ran ./debug.sh** → all scripts installed!
10. **Ran E2E suite** → 28/28 passing (100%)

**Time**: 4 hours total (including finding 3 other bugs)  

**Key Success Factor**: debug.sh enabled rapid iteration (seconds per test) vs. full E2E suite (minutes per test)  

---

**Status**: Production Ready  
**Recommendation**: Use this pattern for all shell script E2E testing  
**Last Updated**: 2026-02-25  
**Contributors**: ACP Project (learned from Task 69)  
