#!/bin/bash
# E2E Tests for @acp.package-list command
# Tests listing installed packages with various filters

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

# Test: List with no packages installed
test_list_empty() {
    print_test_header "List with no packages installed"
    
    local test_dir=$(setup_test)
    
    # Run command from test directory
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-list.sh" 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "No packages installed" "Should show no packages message"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: List with one package installed
test_list_single_package() {
    print_test_header "List with one package installed"
    
    local test_dir=$(setup_test)
    
    # Create manifest with one package in test directory
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
    
    # Run command from test directory (already in test_dir)
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-list.sh" 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "test-package" "Should show package name"
    assert_contains "$output" "1.0.0" "Should show version"
    assert_contains "$output" "1 file" "Should show file count"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: List with verbose flag
test_list_verbose() {
    print_test_header "List with verbose flag"
    
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
    
    # Run command with --verbose from test directory (already in test_dir)
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-list.sh" --verbose 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "test-package" "Should show package name"
    assert_contains "$output" "Source:" "Should show source in verbose mode"
    assert_contains "$output" "Installed:" "Should show install date in verbose mode"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Run all tests
main() {
    print_suite_header "Package List Command Tests"
    
    test_list_empty
    test_list_single_package
    test_list_verbose
    
    print_suite_summary
    
    # Return exit code based on test results
    [ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
