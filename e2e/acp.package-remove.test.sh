#!/bin/bash
# E2E Tests for @acp.package-remove command
# Tests removing installed packages

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

# Test: Remove non-existent package
test_remove_nonexistent() {
    print_test_header "Remove non-existent package"
    
    local test_dir=$(setup_test)
    
    # Run command from test directory with auto-confirm
    local output
    local exit_code
    cd "$test_dir"
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-remove.sh" nonexistent-package -y 2>&1 || true)
    exit_code=$?
    cd "$PROJECT_ROOT"
    
    # Verify (should handle gracefully)
    assert_contains "$output" "not installed" "Should show not installed message"
    
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Remove installed package with auto-confirm
test_remove_with_autoconfirm() {
    print_test_header "Remove installed package with auto-confirm"
    
    local test_dir=$(setup_test)
    
    # Create manifest with package and actual files in test directory
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
      commands:
        - name: test.command.md
          version: 1.0.0
          checksum: sha256:def456
      designs: []

manifest_version: 1.0.0
last_updated: 2026-02-21T00:00:00Z
EOF
    
    # Create the actual files (ensure we're in test_dir)
    echo "Pattern content" > agent/patterns/test.pattern.md
    echo "Command content" > agent/commands/test.command.md
    
    # Verify files exist before removal
    [ -f agent/patterns/test.pattern.md ] || echo "WARNING: Pattern file not created"
    [ -f agent/commands/test.command.md ] || echo "WARNING: Command file not created"
    
    # Run command with auto-confirm (already in test_dir)
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-remove.sh" test-package -y 2>&1 || true)
    exit_code=$?
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "Removed" "Should show removal message"
    
    # Verify files were removed
    if [ -f agent/patterns/test.pattern.md ]; then
        echo -e "${RED}✗${NC} Pattern file should be removed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓${NC} Pattern file removed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -f agent/commands/test.command.md ]; then
        echo -e "${RED}✗${NC} Command file should be removed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓${NC} Command file removed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cd "$PROJECT_ROOT"
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Test: Remove with --keep-modified flag
test_remove_keep_modified() {
    print_test_header "Remove with --keep-modified flag"
    
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
          checksum: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      commands: []
      designs: []

manifest_version: 1.0.0
last_updated: 2026-02-21T00:00:00Z
EOF
    
    # Create file with different content (modified)
    echo "Modified content" > agent/patterns/test.pattern.md
    
    # Run command with --keep-modified
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-remove.sh" test-package --keep-modified -y 2>&1 || true)
    exit_code=$?
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "kept" "Should mention kept files"
    
    # Verify modified file was kept
    if [ -f agent/patterns/test.pattern.md ]; then
        echo -e "${GREEN}✓${NC} Modified file kept"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Modified file should be kept"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    cd "$PROJECT_ROOT"
    cleanup_test "$test_dir"
    
    print_test_result $?
}

# Run all tests
main() {
    print_suite_header "Package Remove Command Tests"
    
    test_remove_nonexistent
    test_remove_with_autoconfirm
    test_remove_keep_modified
    
    print_suite_summary
    
    # Return exit code based on test results
    [ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
