#!/bin/bash
# E2E Tests for Experimental Features System
# Tests installation and update behavior with experimental features

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

# Create test package with experimental features
create_test_package() {
    local package_dir="$1"
    mkdir -p "$package_dir/agent"/{commands,patterns,design}
    
    # Create package.yaml
    cat > "$package_dir/package.yaml" <<'EOF'
name: test-experimental
version: 1.0.0
description: Test package for experimental features validation and testing
author: Test Author
license: MIT
repository: https://github.com/test/test-experimental.git

contents:
  commands:
    - name: stable-command.md
      description: A stable command
    
    - name: experimental-command.md
      description: An experimental command
      experimental: true
  
  patterns:
    - name: stable-pattern.md
      description: A stable pattern
    
    - name: experimental-pattern.md
      description: An experimental pattern
      experimental: true
EOF
    
    # Create stable command
    cat > "$package_dir/agent/commands/stable-command.md" <<'EOF'
# Command: stable-command

> **🤖 Agent Directive**: Test command

**Namespace**: test
**Version**: 1.0.0
**Status**: Active

---

**Purpose**: A stable command for testing
EOF
    
    # Create experimental command
    cat > "$package_dir/agent/commands/experimental-command.md" <<'EOF'
# Command: experimental-command

> **🤖 Agent Directive**: Test command

**Namespace**: test
**Version**: 0.1.0
**Status**: Experimental

---

**Purpose**: An experimental command for testing
EOF
    
    # Create stable pattern
    cat > "$package_dir/agent/patterns/stable-pattern.md" <<'EOF'
# Pattern: Stable Pattern

**Status**: Active
**Created**: 2026-02-23

---

## Overview
A stable pattern for testing
EOF
    
    # Create experimental pattern
    cat > "$package_dir/agent/patterns/experimental-pattern.md" <<'EOF'
# Pattern: Experimental Pattern

**Status**: Experimental
**Created**: 2026-02-23

---

## Overview
An experimental pattern for testing
EOF
    
    # Initialize git
    cd "$package_dir"
    git init -q
    git add -A
    git commit -q -m "Initial commit"
    git remote add origin https://github.com/test/test-experimental.git
    cd - >/dev/null
}

# Test: Install without --experimental skips experimental features
test_install_without_experimental() {
    print_test_header "Install without --experimental skips experimental features"
    
    local test_dir=$(mktemp -d)
    local package_dir="$test_dir/package"
    local install_dir="$test_dir/install"
    
    # Create test package
    create_test_package "$package_dir"
    
    # Initialize ACP in install directory
    mkdir -p "$install_dir"
    cd "$install_dir"
    "$PROJECT_ROOT/agent/scripts/acp.install.sh" -y >/dev/null 2>&1
    
    # Install without --experimental
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$package_dir" -y 2>&1)
    exit_code=$?
    set -e
    
    cd - >/dev/null
    
    # Assertions
    local test_result=0
    assert_equals "0" "$exit_code" "Installation succeeds" || test_result=1
    assert_file_exists "$install_dir/agent/commands/stable-command.md" || test_result=1
    assert_file_not_exists "$install_dir/agent/commands/experimental-command.md" || test_result=1
    assert_file_exists "$install_dir/agent/patterns/stable-pattern.md" || test_result=1
    assert_file_not_exists "$install_dir/agent/patterns/experimental-pattern.md" || test_result=1
    assert_contains "$output" "Skipping experimental" || test_result=1
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_test_result "$test_result"
}

# Test: Install with --experimental includes experimental features
test_install_with_experimental() {
    print_test_header "Install with --experimental includes experimental features"
    
    local test_dir=$(mktemp -d)
    local package_dir="$test_dir/package"
    local install_dir="$test_dir/install"
    
    # Create test package
    create_test_package "$package_dir"
    
    # Initialize ACP in install directory
    mkdir -p "$install_dir"
    cd "$install_dir"
    "$PROJECT_ROOT/agent/scripts/acp.install.sh" -y >/dev/null 2>&1
    
    # Install with --experimental
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$package_dir" --experimental -y 2>&1)
    exit_code=$?
    set -e
    
    cd - >/dev/null
    
    # Assertions
    local test_result=0
    assert_equals "0" "$exit_code" "Installation succeeds" || test_result=1
    assert_file_exists "$install_dir/agent/commands/stable-command.md" || test_result=1
    assert_file_exists "$install_dir/agent/commands/experimental-command.md" || test_result=1
    assert_file_exists "$install_dir/agent/patterns/stable-pattern.md" || test_result=1
    assert_file_exists "$install_dir/agent/patterns/experimental-pattern.md" || test_result=1
    assert_contains "$output" "Installing experimental" || test_result=1
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_test_result "$test_result"
}

# Test: Manifest tracks experimental status
test_manifest_tracking() {
    print_test_header "Manifest tracks experimental: true for experimental features"
    
    local test_dir=$(mktemp -d)
    local package_dir="$test_dir/package"
    local install_dir="$test_dir/install"
    
    # Create test package
    create_test_package "$package_dir"
    
    # Initialize ACP in install directory
    mkdir -p "$install_dir"
    cd "$install_dir"
    "$PROJECT_ROOT/agent/scripts/acp.install.sh" -y >/dev/null 2>&1
    
    # Install with --experimental
    "$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$package_dir" --experimental -y >/dev/null 2>&1
    
    cd - >/dev/null
    
    # Check manifest
    manifest_content=$(cat "$install_dir/agent/manifest.yaml")
    
    # Assertions
    local test_result=0
    assert_contains "$manifest_content" "experimental-command.md" || test_result=1
    assert_contains "$manifest_content" "experimental: true" || test_result=1
    assert_contains "$manifest_content" "stable-command.md" || test_result=1
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_test_result "$test_result"
}

# Test: Validation detects consistent marking
test_validation_consistent() {
    print_test_header "Validation passes for consistent experimental marking"
    
    local test_dir=$(mktemp -d)
    local package_dir="$test_dir/package"
    
    # Create test package
    create_test_package "$package_dir"
    
    # Run validation - just check experimental section
    cd "$package_dir"
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-validate.sh" 2>&1)
    set -e
    cd - >/dev/null
    
    # Extract just the Experimental Features section
    experimental_section=$(echo "$output" | grep -A 10 "^Experimental Features")
    
    # Assertions
    local test_result=0
    assert_contains "$experimental_section" "marked consistently" || test_result=1
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_test_result "$test_result"
}

# Test: Validation detects missing file metadata
test_validation_missing_file_metadata() {
    print_test_header "Validation detects missing Status: Experimental in file"
    
    local test_dir=$(mktemp -d)
    local package_dir="$test_dir/package"
    
    # Create test package
    create_test_package "$package_dir"
    
    # Change experimental-command to Active status
    sed -i 's/\*\*Status\*\*: Experimental/\*\*Status\*\*: Active/' "$package_dir/agent/commands/experimental-command.md"
    
    # Run validation
    cd "$package_dir"
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-validate.sh" 2>&1)
    set -e
    cd - >/dev/null
    
    # Check for the error message (should appear in output)
    # Assertions
    local test_result=0
    assert_contains "$output" "Marked experimental in package.yaml but missing 'Status: Experimental' in file" || test_result=1
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_test_result "$test_result"
}

# Test: Validation detects missing package.yaml field
test_validation_missing_yaml_field() {
    print_test_header "Validation detects missing experimental: true in package.yaml"
    
    local test_dir=$(mktemp -d)
    local package_dir="$test_dir/package"
    
    # Create test package
    create_test_package "$package_dir"
    
    # Remove experimental flag from package.yaml
    sed -i '/experimental: true/d' "$package_dir/package.yaml"
    
    # Run validation
    cd "$package_dir"
    set +e
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-validate.sh" 2>&1)
    set -e
    cd - >/dev/null
    
    # Extract experimental section
    experimental_section=$(echo "$output" | grep -A 10 "^Experimental Features")
    
    # Assertions
    local test_result=0
    assert_contains "$experimental_section" "not marked in package.yaml" || test_result=1
    
    # Cleanup
    rm -rf "$test_dir"
    
    print_test_result "$test_result"
}

# Run all tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "E2E Tests: Experimental Features System"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_install_without_experimental
test_install_with_experimental
test_manifest_tracking
test_validation_consistent
test_validation_missing_file_metadata
test_validation_missing_yaml_field

# Print summary
print_test_summary
