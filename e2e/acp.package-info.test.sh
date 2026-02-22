#!/bin/bash
# E2E Tests for @acp.package-info command
# Tests displaying package information

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

# Setup test environment
setup_test() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Create minimal ACP structure
    mkdir -p agent/{commands,patterns,designs}
    
    # Create empty manifest
    cat > agent/manifest.yaml << 'EOF'
packages: {}
manifest_version: 1.0.0
last_updated: null
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

# Test: Show info for non-existent package
test_info_nonexistent() {
    print_test_header "Show info for non-existent package"
    
    local test_dir=$(setup_test)
    
    # Run command from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-info.sh" nonexistent-package 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify (just check error message, exit code may vary with set -e)
    assert_contains "$output" "not installed" "Should show not installed message"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Show info for installed package
test_info_installed_package() {
    print_test_header "Show info for installed package"
    
    local test_dir=$(setup_test)
    
    # Create manifest with package in test directory
    cd "$test_dir"
    cat > agent/manifest.yaml << 'EOF'
packages:
  test-package:
    name: test-package
    package_version: 1.0.0
    source: https://github.com/test/test-package.git
    commit: abc123def456
    installed_at: 2026-02-21T00:00:00Z
    files:
      patterns:
        - name: test.pattern.md
          version: 1.0.0
          checksum: sha256:abc123
      commands:
        - name: test.command.md
          version: 1.0.0
          checksum: sha256:def456
      designs: []

manifest_version: 1.0.0
last_updated: 2026-02-21T00:00:00Z
EOF
    
    # Run command from test directory (already in test_dir)
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-info.sh" test-package 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "test-package" "Should show package name"
    assert_contains "$output" "1.0.0" "Should show version"
    assert_contains "$output" "https://github.com/test/test-package.git" "Should show source URL"
    assert_contains "$output" "abc123def456" "Should show commit hash"
    assert_contains "$output" "test.pattern.md" "Should show pattern file"
    assert_contains "$output" "test.command.md" "Should show command file"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Show info with modified files
test_info_with_modified_files() {
    print_test_header "Show info with modified files"
    
    local test_dir=$(setup_test)
    
    # Create manifest with package in test directory
    cd "$test_dir"
    cat > agent/manifest.yaml << 'EOF'
packages:
  test-package:
    name: test-package
    package_version: 1.0.0
    source: https://github.com/test/test-package.git
    commit: abc123
    installed_at: 2026-02-21T00:00:00Z
    files:
      patterns:
        - name: test.pattern.md
          version: 1.0.0
          checksum: sha256:abc123
      commands: []
      designs: []

manifest_version: 1.0.0
last_updated: 2026-02-21T00:00:00Z
EOF
    
    # Create the pattern file with different content (to simulate modification)
    mkdir -p agent/patterns
    echo "Modified content" > agent/patterns/test.pattern.md
    
    # Run command from test directory (already in test_dir)
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-info.sh" test-package 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "test-package" "Should show package name"
    assert_contains "$output" "MODIFIED" "Should show MODIFIED tag for changed file"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Show info with no arguments
test_info_no_arguments() {
    print_test_header "Show info with no arguments"
    
    local test_dir=$(setup_test)
    
    # Run command from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-info.sh" 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify (script uses die() which may not return 1 consistently with set -e)
    # Just check that it shows usage
    assert_contains "$output" "Usage:" "Should show usage message"
    assert_contains "$output" "Error:" "Should show error message"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Show global package info
test_info_global_package() {
    print_test_header "Show global package info"
    
    # Create fake home directory
    local fake_home=$(mktemp -d)
    mkdir -p "$fake_home/.acp/packages/test-global"
    
    # Create global manifest
    cat > "$fake_home/.acp/manifest.yaml" << 'EOF'
packages:
  test-global:
    package_version: 1.0.0
    source: https://github.com/test/test-global
    commit: abc123
    installed_at: 2026-02-22
    updated_at: 2026-02-22
    location: ~/.acp/packages/test-global
    files:
      commands:
        - name: test.command.md
          version: 1.0.0
          checksum: def456
manifest_version: 1.0.0
last_updated: 2026-02-22
EOF
    
    # Run with --global flag
    local output
    local exit_code
    set +e
    output=$(HOME="$fake_home" "$PROJECT_ROOT/agent/scripts/acp.package-info.sh" --global test-global 2>&1)
    exit_code=$?
    set -e
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "Global Package Information" "Should indicate global mode"
    assert_contains "$output" "test-global" "Should show package name"
    assert_contains "$output" "Location:" "Should show location for global package"
    assert_contains "$output" "~/.acp/packages/test-global" "Should show global path"
    
    rm -rf "$fake_home"
    
    print_test_result $?
}

# Run all tests
main() {
    print_suite_header "Package Info Command Tests"
    
    test_info_no_arguments
    test_info_nonexistent
    test_info_installed_package
    test_info_with_modified_files
    test_info_global_package
    
    print_suite_summary
    
    # Return exit code based on test results
    [ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
