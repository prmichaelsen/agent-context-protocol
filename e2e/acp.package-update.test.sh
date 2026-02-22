#!/bin/bash
# E2E Tests for @acp.package-update command
# Tests updating packages with various scenarios

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test utilities
source "$PROJECT_ROOT/tests/common.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment with a package
setup_test_with_package() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Create minimal ACP structure
    mkdir -p agent/{commands,patterns,designs}
    
    # Create a test pattern file
    cat > agent/patterns/test.pattern.md << 'EOF'
# Test Pattern

**Version**: 1.0.0
**Last Updated**: 2026-02-21

Test pattern content v1.0.0
EOF
    
    # Create manifest with installed package
    cat > agent/manifest.yaml << 'EOF'
packages:
  test-package:
    name: test-package
    package_version: 1.0.0
    source: https://github.com/test/test-package.git
    commit: abc123
    installed_at: 2026-02-21T00:00:00Z
    updated_at: 2026-02-21T00:00:00Z
    files:
      patterns:
        - name: test.pattern.md
          version: 1.0.0
          checksum: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      commands: []
      designs: []

manifest_version: 1.0.0
last_updated: 2026-02-21T00:00:00Z
EOF
    
    echo "$TEST_DIR"
}

# Cleanup test environment
cleanup_test() {
    local test_dir="$1"
    if [ -n "$test_dir" ] && [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

# Test: Update with empty manifest
test_update_empty_manifest() {
    print_test_header "Update with empty manifest"
    
    local test_dir=$(mktemp -d)
    cd "$test_dir"
    
    # Create minimal ACP structure with empty manifest
    mkdir -p agent/{commands,patterns,designs}
    cat > agent/manifest.yaml << 'EOF'
packages: {}
manifest_version: 1.0.0
last_updated: null
EOF
    
    # Run command from test directory
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "No packages installed" "Should show no packages message"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update non-existent package
test_update_nonexistent_package() {
    print_test_header "Update non-existent package"
    
    local test_dir=$(setup_test_with_package)
    
    # Run command from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" nonexistent-package 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_not_equals 0 $exit_code "Exit code should be non-zero"
    assert_contains "$output" "not installed" "Should show package not installed error"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update with missing manifest
test_update_no_manifest() {
    print_test_header "Update with missing manifest"
    
    local test_dir=$(mktemp -d)
    cd "$test_dir"
    
    # Create minimal ACP structure without manifest
    mkdir -p agent/{commands,patterns,designs}
    
    # Run command from test directory
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_not_equals 0 $exit_code "Exit code should be non-zero"
    assert_contains "$output" "No manifest found" "Should show manifest not found error"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update command accepts --check flag
test_update_check_flag() {
    print_test_header "Update command accepts --check flag"
    
    local test_dir=$(setup_test_with_package)
    
    # Run command with --check from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" --check 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify - command should reference package when checking
    assert_contains "$output" "test-package" "Should reference package name"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update command accepts --skip-modified flag
test_update_skip_modified_flag() {
    print_test_header "Update command accepts --skip-modified flag"
    
    local test_dir=$(setup_test_with_package)
    
    # Run command with --skip-modified from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" --skip-modified 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify - command should attempt to check packages
    assert_contains "$output" "test-package" "Should reference package name"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update command accepts --force flag
test_update_force_flag() {
    print_test_header "Update command accepts --force flag"
    
    local test_dir=$(setup_test_with_package)
    
    # Run command with --force from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" --force 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify - command should attempt to check packages
    assert_contains "$output" "test-package" "Should reference package name"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update command accepts -y flag
test_update_auto_confirm_flag() {
    print_test_header "Update command accepts -y flag"
    
    local test_dir=$(setup_test_with_package)
    
    # Run command with -y from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" -y 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify - command should attempt to check packages
    assert_contains "$output" "test-package" "Should reference package name"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update specific package by name
test_update_specific_package() {
    print_test_header "Update specific package by name"
    
    local test_dir=$(setup_test_with_package)
    
    # Run command with package name from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" test-package 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify - command should attempt to update specific package
    assert_contains "$output" "test-package" "Should reference the package name"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Update validates manifest exists
test_update_validates_manifest() {
    print_test_header "Update validates manifest exists"
    
    local test_dir=$(mktemp -d)
    cd "$test_dir"
    mkdir -p agent
    
    # Run command without manifest from test directory
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-update.sh" 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_not_equals 0 $exit_code "Exit code should be non-zero"
    assert_contains "$output" "manifest" "Should mention manifest in error"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Run all tests
main() {
    print_suite_header "Package Update Command Tests"
    
    test_update_empty_manifest
    test_update_nonexistent_package
    test_update_no_manifest
    test_update_check_flag
    test_update_skip_modified_flag
    test_update_force_flag
    test_update_auto_confirm_flag
    test_update_specific_package
    test_update_validates_manifest
    
    print_suite_summary
    
    # Return exit code based on test results
    [ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
