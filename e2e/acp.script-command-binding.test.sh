#!/bin/bash
# E2E Tests for Script-Command Binding System
# Tests selective script installation based on command dependencies

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

. "${PROJECT_ROOT}/tests/common.sh"

# Test setup
TEST_NAME="Script-Command Binding"
TEST_FAILURES=0

echo "${BLUE}Running E2E Tests: ${TEST_NAME}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create test package with multiple commands and scripts
create_test_package() {
    local pkg_dir="$1"
    mkdir -p "$pkg_dir/agent/commands"
    mkdir -p "$pkg_dir/agent/scripts"
    
    # Create package.yaml
    cat > "$pkg_dir/package.yaml" << 'EOF'
name: test-binding
version: 1.0.0
description: Test package for script-command binding
author: Test Author
license: MIT
repository: https://github.com/test/test-binding.git

contents:
  commands:
    - name: test.cmd1.md
      description: Command 1
      scripts:
        - test.cmd1.sh
        - test.common.sh
    
    - name: test.cmd2.md
      description: Command 2
      scripts:
        - test.cmd2.sh
        - test.common.sh
    
    - name: test.experimental.md
      description: Experimental command
      experimental: true
      scripts:
        - test.experimental.sh
        - test.common.sh
  
  scripts:
    - name: test.cmd1.sh
      description: Command 1 script
    
    - name: test.cmd2.sh
      description: Command 2 script
    
    - name: test.experimental.sh
      description: Experimental script
      experimental: true
    
    - name: test.common.sh
      description: Shared utility
      type: utility
EOF
    
    # Create command files
    cat > "$pkg_dir/agent/commands/test.cmd1.md" << 'EOF'
# Command: cmd1

> **🤖 Agent Directive**: Test command 1

**Namespace**: test
**Version**: 1.0.0
**Status**: Active
**Scripts**: test.cmd1.sh, test.common.sh

---

**Purpose**: Test command 1
EOF
    
    cat > "$pkg_dir/agent/commands/test.cmd2.md" << 'EOF'
# Command: cmd2

> **🤖 Agent Directive**: Test command 2

**Namespace**: test
**Version**: 1.0.0
**Status**: Active
**Scripts**: test.cmd2.sh, test.common.sh

---

**Purpose**: Test command 2
EOF
    
    cat > "$pkg_dir/agent/commands/test.experimental.md" << 'EOF'
# Command: experimental

> **🤖 Agent Directive**: Test experimental command

**Namespace**: test
**Version**: 1.0.0
**Status**: Experimental
**Scripts**: test.experimental.sh, test.common.sh

---

**Purpose**: Test experimental command
EOF
    
    # Create script files
    echo "#!/bin/bash" > "$pkg_dir/agent/scripts/test.cmd1.sh"
    echo "#!/bin/bash" > "$pkg_dir/agent/scripts/test.cmd2.sh"
    echo "#!/bin/bash" > "$pkg_dir/agent/scripts/test.experimental.sh"
    echo "#!/bin/bash" > "$pkg_dir/agent/scripts/test.common.sh"
}

# Test 1: Install single command → only its scripts installed
test_single_command_scripts() {
    echo "${BLUE}Test 1: Single command installation${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install only cmd1
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" --commands test.cmd1 -y >/dev/null 2>&1
    
    # Verify cmd1 script installed
    assert_file_exists "$test_dir/agent/scripts/test.cmd1.sh" "cmd1 script should be installed"
    
    # Verify common utility installed (needed by cmd1)
    assert_file_exists "$test_dir/agent/scripts/test.common.sh" "common utility should be installed"
    
    # Verify cmd2 script NOT installed
    assert_file_not_exists "$test_dir/agent/scripts/test.cmd2.sh" "cmd2 script should NOT be installed"
    
    # Verify experimental script NOT installed
    assert_file_not_exists "$test_dir/agent/scripts/test.experimental.sh" "experimental script should NOT be installed"
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Test 2: Install experimental command without flag → script not installed
test_experimental_without_flag() {
    echo "${BLUE}Test 2: Experimental command without --experimental flag${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install without --experimental
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" -y >/dev/null 2>&1
    
    # Verify experimental command NOT installed
    assert_file_not_exists "$test_dir/agent/commands/test.experimental.md" "experimental command should NOT be installed"
    
    # Verify experimental script NOT installed
    assert_file_not_exists "$test_dir/agent/scripts/test.experimental.sh" "experimental script should NOT be installed"
    
    # Verify non-experimental commands installed
    assert_file_exists "$test_dir/agent/commands/test.cmd1.md" "cmd1 should be installed"
    assert_file_exists "$test_dir/agent/scripts/test.cmd1.sh" "cmd1 script should be installed"
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Test 3: Install experimental command with flag → script installed
test_experimental_with_flag() {
    echo "${BLUE}Test 3: Experimental command with --experimental flag${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install with --experimental
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" --experimental -y >/dev/null 2>&1
    
    # Verify experimental command installed
    assert_file_exists "$test_dir/agent/commands/test.experimental.md" "experimental command should be installed"
    
    # Verify experimental script installed
    assert_file_exists "$test_dir/agent/scripts/test.experimental.sh" "experimental script should be installed"
    
    # Verify common utility installed
    assert_file_exists "$test_dir/agent/scripts/test.common.sh" "common utility should be installed"
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Test 4: Multiple commands → shared utility installed once
test_shared_utility_reference_counting() {
    echo "${BLUE}Test 4: Shared utility reference counting${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install both cmd1 and cmd2 (both use test.common.sh)
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" --commands test.cmd1 test.cmd2 -y >/dev/null 2>&1
    
    # Verify both command scripts installed
    assert_file_exists "$test_dir/agent/scripts/test.cmd1.sh" "cmd1 script should be installed"
    assert_file_exists "$test_dir/agent/scripts/test.cmd2.sh" "cmd2 script should be installed"
    
    # Verify common utility installed (only once, used by both)
    assert_file_exists "$test_dir/agent/scripts/test.common.sh" "common utility should be installed"
    
    # Count occurrences (should be exactly 1)
    local count=$(find "$test_dir/agent/scripts" -name "test.common.sh" 2>/dev/null | wc -l)
    assert_equals "1" "$count" "common utility should be installed exactly once"
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Test 5: Selective installation → only selected command scripts
test_selective_installation() {
    echo "${BLUE}Test 5: Selective installation${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install only cmd2 (not cmd1)
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" --commands test.cmd2 -y >/dev/null 2>&1
    
    # Verify cmd2 installed
    assert_file_exists "$test_dir/agent/commands/test.cmd2.md" "cmd2 should be installed"
    assert_file_exists "$test_dir/agent/scripts/test.cmd2.sh" "cmd2 script should be installed"
    
    # Verify cmd1 NOT installed
    assert_file_not_exists "$test_dir/agent/commands/test.cmd1.md" "cmd1 should NOT be installed"
    assert_file_not_exists "$test_dir/agent/scripts/test.cmd1.sh" "cmd1 script should NOT be installed"
    
    # Verify common utility installed (needed by cmd2)
    assert_file_exists "$test_dir/agent/scripts/test.common.sh" "common utility should be installed"
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Test 6: No commands installed → no scripts installed
test_no_commands_no_scripts() {
    echo "${BLUE}Test 6: No commands → no scripts${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install only patterns (no commands)
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" --patterns -y >/dev/null 2>&1 || true
    
    # Verify no scripts installed
    local script_count=$(find "$test_dir/agent/scripts" -name "test.*.sh" 2>/dev/null | wc -l)
    assert_equals "0" "$script_count" "no test scripts should be installed"
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Test 7: All commands → all scripts installed
test_all_commands_all_scripts() {
    echo "${BLUE}Test 7: All commands → all scripts${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install all (including experimental)
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" --experimental -y >/dev/null 2>&1
    
    # Verify all scripts installed
    assert_file_exists "$test_dir/agent/scripts/test.cmd1.sh" "cmd1 script should be installed"
    assert_file_exists "$test_dir/agent/scripts/test.cmd2.sh" "cmd2 script should be installed"
    assert_file_exists "$test_dir/agent/scripts/test.experimental.sh" "experimental script should be installed"
    assert_file_exists "$test_dir/agent/scripts/test.common.sh" "common utility should be installed"
    
    # Count total test scripts (should be 4)
    local script_count=$(find "$test_dir/agent/scripts" -name "test.*.sh" 2>/dev/null | wc -l)
    assert_equals "4" "$script_count" "all 4 test scripts should be installed"
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Test 8: Scripts are executable
test_scripts_executable() {
    echo "${BLUE}Test 8: Scripts are executable${NC}"
    
    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    
    create_test_package "$pkg_dir"
    
    # Install command
    cd "$test_dir"
    "${PROJECT_ROOT}/agent/scripts/acp.install.sh" >/dev/null 2>&1 || true
    "${PROJECT_ROOT}/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" --commands test.cmd1 -y >/dev/null 2>&1
    
    # Verify scripts are executable
    if [ -f "$test_dir/agent/scripts/test.cmd1.sh" ]; then
        if [ -x "$test_dir/agent/scripts/test.cmd1.sh" ]; then
            assert_equals "executable" "executable" "cmd1 script should be executable"
        else
            assert_equals "executable" "not-executable" "cmd1 script should be executable"
        fi
    else
        assert_equals "exists" "missing" "cmd1 script should exist"
    fi
    
    if [ -f "$test_dir/agent/scripts/test.common.sh" ]; then
        if [ -x "$test_dir/agent/scripts/test.common.sh" ]; then
            assert_equals "executable" "executable" "common script should be executable"
        else
            assert_equals "executable" "not-executable" "common script should be executable"
        fi
    else
        assert_equals "exists" "missing" "common script should exist"
    fi
    
    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# Run all tests
test_single_command_scripts
test_experimental_without_flag
test_experimental_with_flag
test_shared_utility_reference_counting
test_selective_installation
test_no_commands_no_scripts
test_all_commands_all_scripts
test_scripts_executable

# Print summary
print_test_summary

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
