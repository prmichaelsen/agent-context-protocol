# E2E Testing Pattern for ACP Scripts

**Pattern Name**: E2E Testing for Shell Scripts with YAML Parser
**Created**: 2026-02-25
**Status**: Active Pattern
**Success Rate**: 100% (when followed correctly)

---

## Overview

This pattern documents the proven approach for writing E2E tests for ACP shell scripts that use the YAML parser. It's based on successful tests from `acp.project-list.test.sh` (21/21 passing) and `acp.project-set.test.sh` (29/29 passing).

---

## Core Principles

### 1. Don't Use `set -euo pipefail`

**❌ Wrong**:
```bash
#!/usr/bin/env bash
set -euo pipefail  # Causes issues with YAML parser AST cleanup
```

**✅ Correct**:
```bash
#!/usr/bin/env bash
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues
```

**Reason**: The YAML parser uses temporary files for AST storage and cleanup. The `-u` flag (unbound variable check) conflicts with the parser's internal variable handling.

### 2. Use Temporary HOME Directory

**✅ Correct Pattern**:
```bash
setup() {
    export HOME="/tmp/acp-test-$$-$(date +%N)"
    mkdir -p "$HOME/.acp"
    export SCRIPT_PATH="${SCRIPT_DIR}/../agent/scripts/your-script.sh"
}

teardown() {
    local old_home="$HOME"
    rm -rf "$old_home" 2>/dev/null || true
}
```

**Why**: This isolates tests from the real `~/.acp/` directory and prevents test pollution.

### 3. Source Common Utilities Directly

**✅ Correct Pattern**:
```bash
# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../tests/common.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.common.sh"
```

**Why**: Sourcing `acp.common.sh` gives access to `init_projects_registry()`, `register_project()`, and other utilities.

### 4. Use Registry Helper Functions

**✅ Correct Pattern**:
```bash
test_example() {
    setup
    init_projects_registry  # Creates ~/.acp/projects.yaml
    register_project "my-project" "$HOME/.acp/projects/my-project" "mcp-server" "Description"
    
    # Run your script
    local output
    output=$("$SCRIPT_PATH" my-project 2>&1)
    
    # Assertions
    assert_contains "$output" "my-project" "Should show project name"
    
    teardown
}
```

**Why**: These functions create properly formatted YAML that the parser can read.

### 5. Capture Exit Codes Properly

**✅ Correct Pattern**:
```bash
# For commands that should succeed
local output
output=$("$SCRIPT_PATH" arg1 arg2 2>&1)

# For commands that should fail
local output
local exit_code
output=$("$SCRIPT_PATH" bad-arg 2>&1) || exit_code=$?

assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
```

**Why**: Using `|| exit_code=$?` prevents the test from exiting when the command fails.

### 6. Add Error Handling to yaml_query Calls

**❌ Wrong** (in scripts being tested):
```bash
tags=$(yaml_query ".projects.${project_name}.tags")
```

**✅ Correct** (in scripts being tested):
```bash
tags=$(yaml_query ".projects.${project_name}.tags" 2>/dev/null || echo "")
```

**Why**: Optional fields may not exist. Without error handling, `set -e` causes the script to exit silently.

---

## Complete Test Template

```bash
#!/usr/bin/env bash
# E2E tests for @acp.your-command
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../tests/common.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.common.sh"

# Test setup
setup() {
    export HOME="/tmp/acp-test-$$-$(date +%N)"
    mkdir -p "$HOME/.acp"
    export SCRIPT_PATH="${SCRIPT_DIR}/../agent/scripts/your-script.sh"
}

# Test teardown
teardown() {
    local old_home="$HOME"
    rm -rf "$old_home" 2>/dev/null || true
}

# Test 1: Success case
test_success() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test"
    
    local output
    output=$("$SCRIPT_PATH" test-project 2>&1)
    
    assert_contains "$output" "expected text" "Should show expected output"
    
    teardown
}

# Test 2: Error case
test_error() {
    setup
    init_projects_registry
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" nonexistent 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "error message" "Should show error"
    
    teardown
}

# Run all tests
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running @acp.your-command E2E tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_success
test_error

echo ""
print_test_summary
```

---

## Script Requirements

For scripts to be testable with this pattern, they must:

### 1. Handle Missing Optional Fields

**✅ Required**:
```bash
# In your script
tags=$(yaml_query ".projects.${project_name}.tags" 2>/dev/null || echo "")
related=$(yaml_query ".projects.${project_name}.related_projects" 2>/dev/null || echo "")
```

### 2. Use Appropriate Error Mode

**✅ For scripts**:
```bash
#!/usr/bin/env bash
set -e  # Exit on error, but not on unbound variables
```

**❌ Avoid**:
```bash
set -euo pipefail  # The -u flag breaks YAML parser
```

### 3. Validate Inputs Safely

**✅ Correct**:
```bash
local project_name="${1:-}"  # Default to empty if not provided

if [ -z "$project_name" ]; then
    echo "Error: Project name required"
    return 1
fi
```

---

## Common Pitfalls

### Pitfall 1: Using `set -euo pipefail`
**Problem**: Script exits silently when YAML parser encounters unbound variables
**Solution**: Use `set -e` only, or no set flags

### Pitfall 2: Not Handling Optional Fields
**Problem**: Script exits when querying non-existent YAML fields
**Solution**: Add `2>/dev/null || echo ""` to all optional field queries

### Pitfall 3: Array Operations
**Problem**: `yaml_array_append` and `yaml_set` with array indices don't work reliably
**Solution**: Use sed to modify YAML directly, or avoid array operations in scripts

### Pitfall 4: Not Capturing Exit Codes
**Problem**: Test exits when command fails
**Solution**: Use `|| exit_code=$?` pattern

---

## Verified Working Examples

- ✅ [`e2e/acp.project-list.test.sh`](../../e2e/acp.project-list.test.sh) - 21/21 passing (100%)
- ✅ [`e2e/acp.project-set.test.sh`](../../e2e/acp.project-set.test.sh) - 29/29 passing (100%)
- ✅ [`e2e/acp.project-info.test.sh`](../../e2e/acp.project-info.test.sh) - 23/23 passing (100%)
- ⚠️ [`e2e/acp.project-update.test.sh`](../../e2e/acp.project-update.test.sh) - 18/20 passing (90%) - array operations fail

---

## Known Limitations

### YAML Array Operations

**Issue**: `yaml_array_append()` fails with "Error: Path does not point to an array" even when the field is `tags: []`

**Workaround**: Avoid adding/removing array elements in scripts, or use sed-based manipulation

**Example of Limitation**:
```bash
# This fails:
yaml_array_append ".projects.test.tags" "production"
# Error: Path does not point to an array

# This works:
yaml_set ".projects.test.status" "archived"  # Scalar fields work fine
```

---

**Status**: Active Pattern
**Recommendation**: Follow this pattern for all new E2E tests
**Next Steps**: Document array operation workarounds or fix YAML parser array handling
