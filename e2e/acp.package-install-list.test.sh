#!/bin/bash
# E2E Tests for acp.package-install.sh --list (dry-run) flag
# Tests that --list shows a full file preview without installing anything

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

# Create a minimal test package with git repo
create_test_package() {
    local package_dir="$1"
    mkdir -p "$package_dir/agent"/{commands,patterns,design}

    # Create package.yaml
    cat > "$package_dir/package.yaml" <<'EOF'
name: test-list-pkg
version: 1.0.0
description: Test package for --list flag
author: Test Author
license: MIT
repository: https://github.com/test/test-list-pkg.git

contents:
  commands:
    - name: hello.md
      description: A hello command

  patterns:
    - name: greeting.md
      description: A greeting pattern

    - name: experimental-pattern.md
      description: An experimental pattern
      experimental: true
EOF

    # Create command with agent directive
    cat > "$package_dir/agent/commands/hello.md" <<'EOF'
# Command: hello

> **🤖 Agent Directive**: Test command

**Namespace**: test
**Version**: 1.0.0
**Status**: Active

---

**Purpose**: A hello command for testing
EOF

    # Create pattern
    cat > "$package_dir/agent/patterns/greeting.md" <<'EOF'
# Pattern: Greeting

**Status**: Active
**Created**: 2026-02-27

---

## Overview
A greeting pattern for testing
EOF

    # Create experimental pattern
    cat > "$package_dir/agent/patterns/experimental-pattern.md" <<'EOF'
# Pattern: Experimental

**Status**: Experimental
**Created**: 2026-02-27

---

## Overview
An experimental pattern for testing
EOF

    # Create design doc
    cat > "$package_dir/agent/design/overview.md" <<'EOF'
# Design: Overview

A design document for testing.
EOF

    # Initialize git
    cd "$package_dir"
    git init -q
    git add -A
    git commit -q -m "Initial commit"
    cd - >/dev/null
}

# Setup: create test package + install directory with ACP initialized
setup_test() {
    local test_dir=$(mktemp -d)
    local package_dir="$test_dir/package"
    local install_dir="$test_dir/install"

    create_test_package "$package_dir"

    mkdir -p "$install_dir"
    cd "$install_dir"
    "$PROJECT_ROOT/agent/scripts/acp.install.sh" -y >/dev/null 2>&1

    echo "$test_dir"
}

cleanup_test() {
    local test_dir="$1"
    if [ -n "$test_dir" ] && [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

# Test: --list exits with code 0
test_list_exits_zero() {
    print_test_header "--list exits with code 0"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    local output exit_code
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list 2>&1)
    exit_code=$?
    set -e

    cd "$PROJECT_ROOT"

    assert_equals "0" "$exit_code" "Exit code should be 0"

    cleanup_test "$test_dir"
}

# Test: --list shows dry-run message
test_list_shows_dry_run_message() {
    print_test_header "--list shows dry-run message"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    local output
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list 2>&1)
    set -e

    cd "$PROJECT_ROOT"

    assert_contains "$output" "dry run" "Should show dry-run message"
    assert_contains "$output" "no files were installed" "Should indicate nothing was installed"

    cleanup_test "$test_dir"
}

# Test: --list shows file scan results
test_list_shows_file_scan() {
    print_test_header "--list shows file scan results"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    local output
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list 2>&1)
    set -e

    cd "$PROJECT_ROOT"

    assert_contains "$output" "hello.md" "Should list hello.md command"
    assert_contains "$output" "greeting.md" "Should list greeting.md pattern"
    assert_contains "$output" "overview.md" "Should list overview.md design doc"
    assert_contains "$output" "Ready to install" "Should show install count summary"

    cleanup_test "$test_dir"
}

# Test: --list does NOT install files
test_list_does_not_install() {
    print_test_header "--list does NOT install files"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    set +e
    "$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list >/dev/null 2>&1
    set -e

    cd "$PROJECT_ROOT"

    assert_file_not_exists "$test_dir/install/agent/commands/hello.md" "Command file should NOT be installed"
    assert_file_not_exists "$test_dir/install/agent/patterns/greeting.md" "Pattern file should NOT be installed"
    assert_file_not_exists "$test_dir/install/agent/design/overview.md" "Design file should NOT be installed"

    cleanup_test "$test_dir"
}

# Test: --list skips experimental by default
test_list_skips_experimental() {
    print_test_header "--list skips experimental files by default"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    local output
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list 2>&1)
    set -e

    cd "$PROJECT_ROOT"

    assert_contains "$output" "experimental-pattern.md" "Should mention experimental file"
    assert_contains "$output" "experimental" "Should indicate experimental status"

    cleanup_test "$test_dir"
}

# Test: --list with --experimental includes experimental files
test_list_with_experimental() {
    print_test_header "--list with --experimental includes experimental files"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    local output
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list --experimental 2>&1)
    set -e

    cd "$PROJECT_ROOT"

    assert_contains "$output" "experimental-pattern.md" "Should list experimental file"
    assert_not_contains "$output" "use --experimental" "Should NOT suggest using --experimental flag"

    cleanup_test "$test_dir"
}

# Test: --list with selective --patterns flag
test_list_selective_patterns() {
    print_test_header "--list with --patterns shows only patterns"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    local output
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list --patterns 2>&1)
    set -e

    cd "$PROJECT_ROOT"

    assert_contains "$output" "greeting.md" "Should list greeting pattern"
    assert_not_contains "$output" "hello.md" "Should NOT list command files"
    assert_not_contains "$output" "overview.md" "Should NOT list design files"

    cleanup_test "$test_dir"
}

# Test: --list does not modify manifest
test_list_does_not_modify_manifest() {
    print_test_header "--list does not modify manifest"

    local test_dir=$(setup_test)
    cd "$test_dir/install"

    local manifest_before
    manifest_before=$(cat agent/manifest.yaml)

    set +e
    "$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$test_dir/package" --list >/dev/null 2>&1
    set -e

    local manifest_after
    manifest_after=$(cat agent/manifest.yaml)

    cd "$PROJECT_ROOT"

    assert_equals "$manifest_before" "$manifest_after" "Manifest should be unchanged"

    cleanup_test "$test_dir"
}

# Run all tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "E2E Tests: Package Install --list (dry-run)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_list_exits_zero
test_list_shows_dry_run_message
test_list_shows_file_scan
test_list_does_not_install
test_list_skips_experimental
test_list_with_experimental
test_list_selective_patterns
test_list_does_not_modify_manifest

# Print summary
print_test_summary
