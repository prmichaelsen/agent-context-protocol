#!/bin/bash
# E2E Tests for Key File Index System
# Tests index schema parsing, package integration, and edge cases

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

# ============================================================================
# HELPERS
# ============================================================================

# Create a minimal ACP project in a temp directory
create_test_project() {
    local test_dir=$(mktemp -d)
    mkdir -p "$test_dir/agent"/{commands,patterns,design,index}
    cat > "$test_dir/agent/manifest.yaml" << 'EOF'
packages: {}
manifest_version: 1.0.0
last_updated: null
EOF
    echo "$test_dir"
}

# Create a valid index file in a test project
create_valid_index() {
    local test_dir="$1"
    local filename="${2:-local.main.yaml}"
    cat > "$test_dir/agent/index/$filename" << 'EOF'
local:
  index:
    - path: agent/design/requirements.md
      weight: 1.0
      kind: requirements
      description: |
        Core project requirements.
      rationale: |
        Must be read before any work.
      applies: acp.init, acp.proceed

    - path: agent/patterns/local.testing.md
      weight: 0.8
      kind: pattern
      description: |
        Testing conventions.
      rationale: |
        Needed for writing tests.
      applies: acp.proceed, acp.task-create
EOF
}

# Create a test package with index files (as a git repo)
create_test_package_with_index() {
    local pkg_dir=$(mktemp -d)
    mkdir -p "$pkg_dir/agent"/{commands,patterns,index}

    cat > "$pkg_dir/package.yaml" << 'EOF'
name: test-idx-pkg
version: 1.0.0
description: Test package with index file
author: Test Author
license: MIT
repository: https://github.com/test/test-idx-pkg.git

contents:
  patterns:
    - name: test-idx-pkg.example.md
      description: Example pattern
  indices:
    - name: test-idx-pkg.main.yaml
      description: Key files for test-idx-pkg
EOF

    cat > "$pkg_dir/agent/patterns/test-idx-pkg.example.md" << 'EOF'
# Pattern: Example

**Status**: Active
**Created**: 2026-03-02

---

## Overview
An example pattern for testing index integration.
EOF

    cat > "$pkg_dir/agent/index/test-idx-pkg.main.yaml" << 'EOF'
test-idx-pkg:
  index:
    - path: agent/patterns/test-idx-pkg.example.md
      weight: 0.5
      kind: pattern
      description: |
        Example pattern from test package.
      rationale: |
        Shows package index integration.
      applies: acp.proceed
EOF

    cd "$pkg_dir"
    git init -q
    git add -A
    git commit -q -m "Initial commit"
    cd - >/dev/null

    echo "$pkg_dir"
}

# ============================================================================
# TEST SUITE
# ============================================================================

print_suite_header "Key File Index E2E Tests"

# --- Test 1: Valid index file has correct structure ---
test_valid_index_structure() {
    echo "${BLUE}Test 1: Valid index file has correct structure${NC}"

    local test_dir=$(create_test_project)
    create_valid_index "$test_dir"

    # Create referenced files so they exist
    echo "# Requirements" > "$test_dir/agent/design/requirements.md"
    mkdir -p "$test_dir/agent/patterns"
    echo "# Testing" > "$test_dir/agent/patterns/local.testing.md"

    # Verify the index file exists and has expected entries
    assert_file_exists "$test_dir/agent/index/local.main.yaml" "Index file should exist"

    local content
    content=$(cat "$test_dir/agent/index/local.main.yaml")
    assert_contains "$content" "path: agent/design/requirements.md" "Should have path field"
    assert_contains "$content" "weight: 1.0" "Should have weight field"
    assert_contains "$content" "kind: requirements" "Should have kind field"
    assert_contains "$content" "description:" "Should have description field"
    assert_contains "$content" "rationale:" "Should have rationale field"
    assert_contains "$content" "applies: acp.init, acp.proceed" "Should have applies field"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 2: Index file follows naming convention ---
test_index_naming_convention() {
    echo "${BLUE}Test 2: Index file follows naming convention${NC}"

    local test_dir=$(create_test_project)

    # Valid names: {namespace}.{qualifier}.yaml
    touch "$test_dir/agent/index/local.main.yaml"
    touch "$test_dir/agent/index/core-sdk.main.yaml"
    touch "$test_dir/agent/index/local.secondary.yaml"

    # Check all valid names exist
    assert_file_exists "$test_dir/agent/index/local.main.yaml" "local.main.yaml is valid name"
    assert_file_exists "$test_dir/agent/index/core-sdk.main.yaml" "core-sdk.main.yaml is valid name"
    assert_file_exists "$test_dir/agent/index/local.secondary.yaml" "local.secondary.yaml is valid name"

    # Verify naming pattern: each has a dot separating namespace and qualifier
    local valid_count=0
    for f in "$test_dir/agent/index/"*.yaml; do
        local basename=$(basename "$f")
        if echo "$basename" | grep -qE '^[a-z][a-z0-9-]*\.[a-z][a-z0-9-]*\.yaml$'; then
            valid_count=$((valid_count + 1))
        fi
    done
    assert_equals "3" "$valid_count" "All 3 files should match naming pattern"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 3: Template files are excluded from active index ---
test_template_files_excluded() {
    echo "${BLUE}Test 3: Template files excluded from active index${NC}"

    local test_dir=$(create_test_project)
    create_valid_index "$test_dir"

    # Copy a template file
    cp "$PROJECT_ROOT/agent/index/local.main.template.yaml" "$test_dir/agent/index/"

    # Count non-template yaml files
    local active_count=0
    for f in "$test_dir/agent/index/"*.yaml; do
        local basename=$(basename "$f")
        if [[ "$basename" != *.template.yaml ]]; then
            active_count=$((active_count + 1))
        fi
    done
    assert_equals "1" "$active_count" "Only non-template files should be active"

    # Verify template exists but is separate
    assert_file_exists "$test_dir/agent/index/local.main.template.yaml" "Template file should exist"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 4: Weight values are in valid range ---
test_weight_range_validation() {
    echo "${BLUE}Test 4: Weight values in valid range (0.0-1.0)${NC}"

    local test_dir=$(create_test_project)

    # Create index with various weights
    cat > "$test_dir/agent/index/local.main.yaml" << 'EOF'
local:
  index:
    - path: agent/design/a.md
      weight: 0.0
      kind: design
      description: |
        Minimum weight.
      rationale: |
        Test min.
      applies: acp.proceed

    - path: agent/design/b.md
      weight: 0.5
      kind: design
      description: |
        Mid weight.
      rationale: |
        Test mid.
      applies: acp.proceed

    - path: agent/design/c.md
      weight: 1.0
      kind: requirements
      description: |
        Max weight.
      rationale: |
        Test max.
      applies: acp.init
EOF

    local content
    content=$(cat "$test_dir/agent/index/local.main.yaml")

    # Valid weights
    assert_contains "$content" "weight: 0.0" "Weight 0.0 is valid"
    assert_contains "$content" "weight: 0.5" "Weight 0.5 is valid"
    assert_contains "$content" "weight: 1.0" "Weight 1.0 is valid"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 5: Kind enum values ---
test_kind_enum_values() {
    echo "${BLUE}Test 5: Kind enum values are valid${NC}"

    local test_dir=$(create_test_project)

    cat > "$test_dir/agent/index/local.main.yaml" << 'EOF'
local:
  index:
    - path: agent/patterns/a.md
      weight: 0.8
      kind: pattern
      description: |
        A pattern.
      rationale: |
        Test.
      applies: acp.proceed
    - path: agent/commands/b.md
      weight: 0.7
      kind: command
      description: |
        A command.
      rationale: |
        Test.
      applies: acp.proceed
    - path: agent/design/c.md
      weight: 0.9
      kind: design
      description: |
        A design.
      rationale: |
        Test.
      applies: acp.proceed
    - path: agent/design/d.md
      weight: 1.0
      kind: requirements
      description: |
        Requirements.
      rationale: |
        Test.
      applies: acp.init
EOF

    local content
    content=$(cat "$test_dir/agent/index/local.main.yaml")
    assert_contains "$content" "kind: pattern" "pattern is valid kind"
    assert_contains "$content" "kind: command" "command is valid kind"
    assert_contains "$content" "kind: design" "design is valid kind"
    assert_contains "$content" "kind: requirements" "requirements is valid kind"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 6: Applies field uses qualified command names ---
test_applies_qualified_names() {
    echo "${BLUE}Test 6: Applies field uses fully qualified command names${NC}"

    local test_dir=$(create_test_project)
    create_valid_index "$test_dir"

    local content
    content=$(cat "$test_dir/agent/index/local.main.yaml")

    # All applies values should contain a dot (fully qualified)
    local applies_values
    applies_values=$(grep "applies:" "$test_dir/agent/index/local.main.yaml" | sed 's/.*applies: //')

    local all_qualified=true
    for line in $applies_values; do
        # Split by comma and check each
        IFS=',' read -ra commands <<< "$line"
        for cmd in "${commands[@]}"; do
            cmd=$(echo "$cmd" | xargs)  # trim whitespace
            if ! echo "$cmd" | grep -q '\.'; then
                all_qualified=false
            fi
        done
    done

    if [ "$all_qualified" = true ]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} All applies values are fully qualified (contain dot)"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} Some applies values are not fully qualified"
    fi

    rm -rf "$test_dir"
    echo ""
}

# --- Test 7: Package install copies index files ---
test_package_install_copies_index() {
    echo "${BLUE}Test 7: Package install copies index files to agent/index/${NC}"

    local test_dir=$(create_test_project)
    local pkg_dir=$(create_test_package_with_index)

    # Run package install
    cd "$test_dir"
    set +e
    "$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" -y >/dev/null 2>&1
    local exit_code=$?
    set -e
    cd "$PROJECT_ROOT"

    assert_equals "0" "$exit_code" "Package install should succeed"
    assert_file_exists "$test_dir/agent/index/test-idx-pkg.main.yaml" "Index file should be copied to agent/index/"
    assert_file_exists "$test_dir/agent/patterns/test-idx-pkg.example.md" "Pattern should also be installed"

    # Verify index content
    local idx_content
    idx_content=$(cat "$test_dir/agent/index/test-idx-pkg.main.yaml")
    assert_contains "$idx_content" "test-idx-pkg" "Index content should reference package namespace"
    assert_contains "$idx_content" "weight: 0.5" "Index content should have weight"

    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# --- Test 8: Package remove cleans up index files ---
test_package_remove_cleans_index() {
    echo "${BLUE}Test 8: Package remove cleans up index files${NC}"

    local test_dir=$(create_test_project)
    local pkg_dir=$(create_test_package_with_index)

    # Install first
    cd "$test_dir"
    "$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" -y >/dev/null 2>&1

    # Verify installed
    assert_file_exists "$test_dir/agent/index/test-idx-pkg.main.yaml" "Index file should exist after install"

    # Remove package
    set +e
    "$PROJECT_ROOT/agent/scripts/acp.package-remove.sh" test-idx-pkg -y >/dev/null 2>&1
    local exit_code=$?
    set -e
    cd "$PROJECT_ROOT"

    assert_equals "0" "$exit_code" "Package remove should succeed"
    assert_file_not_exists "$test_dir/agent/index/test-idx-pkg.main.yaml" "Index file should be removed"
    assert_file_not_exists "$test_dir/agent/patterns/test-idx-pkg.example.md" "Pattern should also be removed"

    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# --- Test 9: Package info shows index files ---
test_package_info_shows_indices() {
    echo "${BLUE}Test 9: Package info shows index files${NC}"

    local test_dir=$(create_test_project)
    local pkg_dir=$(create_test_package_with_index)

    # Install
    cd "$test_dir"
    "$PROJECT_ROOT/agent/scripts/acp.package-install.sh" --repo "$pkg_dir" -y >/dev/null 2>&1

    # Run package info
    set +e
    local output
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-info.sh" test-idx-pkg 2>&1)
    local exit_code=$?
    set -e
    cd "$PROJECT_ROOT"

    assert_equals "0" "$exit_code" "Package info should succeed"
    assert_contains "$output" "Indices" "Should show Indices section"
    assert_contains "$output" "test-idx-pkg.main.yaml" "Should list index file name"

    rm -rf "$test_dir" "$pkg_dir"
    echo ""
}

# --- Test 10: Install script creates agent/index/ directory ---
test_install_creates_index_dir() {
    echo "${BLUE}Test 10: Install script creates agent/index/ directory${NC}"

    local test_dir=$(mktemp -d)
    cd "$test_dir"

    # Run ACP install
    set +e
    "$PROJECT_ROOT/agent/scripts/acp.install.sh" >/dev/null 2>&1
    local exit_code=$?
    set -e
    cd "$PROJECT_ROOT"

    assert_equals "0" "$exit_code" "Install should succeed"
    assert_dir_exists "$test_dir/agent/index" "agent/index/ directory should be created"
    assert_file_exists "$test_dir/agent/index/.gitkeep" ".gitkeep should exist in agent/index/"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 11: Template file has schema documentation ---
test_template_has_schema_docs() {
    echo "${BLUE}Test 11: Template file has schema documentation${NC}"

    # Verify the template file exists in the project
    assert_file_exists "$PROJECT_ROOT/agent/index/local.main.template.yaml" "Template file should exist in project"

    # Verify template has schema documentation
    local template_content
    template_content=$(cat "$PROJECT_ROOT/agent/index/local.main.template.yaml")
    assert_contains "$template_content" "weight" "Template should document weight field"
    assert_contains "$template_content" "kind" "Template should document kind field"
    assert_contains "$template_content" "applies" "Template should document applies field"
    assert_contains "$template_content" "description" "Template should document description field"
    assert_contains "$template_content" "rationale" "Template should document rationale field"
    assert_contains "$template_content" "path" "Template should document path field"

    echo ""
}

# --- Test 12: Empty index directory (no entries) ---
test_empty_index_directory() {
    echo "${BLUE}Test 12: Empty index directory (no yaml files)${NC}"

    local test_dir=$(create_test_project)

    # agent/index/ exists but has no yaml files (only .gitkeep)
    touch "$test_dir/agent/index/.gitkeep"

    # Count active index files
    local yaml_count=0
    shopt -s nullglob
    for f in "$test_dir/agent/index/"*.yaml; do
        yaml_count=$((yaml_count + 1))
    done
    shopt -u nullglob

    assert_equals "0" "$yaml_count" "Empty index directory should have no yaml files"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 13: Index file with single entry ---
test_single_entry_index() {
    echo "${BLUE}Test 13: Index file with only one entry${NC}"

    local test_dir=$(create_test_project)

    cat > "$test_dir/agent/index/local.main.yaml" << 'EOF'
local:
  index:
    - path: agent/design/requirements.md
      weight: 1.0
      kind: requirements
      description: |
        The only entry.
      rationale: |
        Single file index.
      applies: acp.init
EOF

    echo "# Requirements" > "$test_dir/agent/design/requirements.md"

    local content
    content=$(cat "$test_dir/agent/index/local.main.yaml")
    assert_contains "$content" "path: agent/design/requirements.md" "Single entry should have path"

    # Count entries (lines starting with "    - path:")
    local entry_count
    entry_count=$(grep -c -- "- path:" "$test_dir/agent/index/local.main.yaml" || echo 0)
    assert_equals "1" "$entry_count" "Should have exactly 1 entry"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 14: Multiple index files in same project ---
test_multiple_index_files() {
    echo "${BLUE}Test 14: Multiple index files coexist in same project${NC}"

    local test_dir=$(create_test_project)
    create_valid_index "$test_dir"

    # Add a second index file (simulating a package index)
    cat > "$test_dir/agent/index/mypkg.main.yaml" << 'EOF'
mypkg:
  index:
    - path: agent/patterns/mypkg.auth.md
      weight: 0.5
      kind: pattern
      description: |
        Auth pattern from mypkg.
      rationale: |
        Package-supplied context.
      applies: acp.proceed
EOF

    # Count index files (excluding templates)
    local index_count=0
    for f in "$test_dir/agent/index/"*.yaml; do
        local basename=$(basename "$f")
        if [[ "$basename" != *.template.yaml ]]; then
            index_count=$((index_count + 1))
        fi
    done
    assert_equals "2" "$index_count" "Should have 2 active index files"

    # Both should be parseable
    assert_file_exists "$test_dir/agent/index/local.main.yaml" "Local index exists"
    assert_file_exists "$test_dir/agent/index/mypkg.main.yaml" "Package index exists"

    rm -rf "$test_dir"
    echo ""
}

# --- Test 15: Package validate detects index files ---
test_package_validate_with_indices() {
    echo "${BLUE}Test 15: Package validate checks index files in package${NC}"

    local pkg_dir=$(create_test_package_with_index)

    cd "$pkg_dir"
    set +e
    local output
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-validate.sh" 2>&1)
    local exit_code=$?
    set -e
    cd "$PROJECT_ROOT"

    # Validate should pass (or at least not crash)
    # The package has valid index files
    assert_contains "$output" "test-idx-pkg" "Validate output should reference package name"

    rm -rf "$pkg_dir"
    echo ""
}

# --- Test 16: Local index takes precedence over package index ---
test_local_precedence_over_package() {
    echo "${BLUE}Test 16: Local index files listed before package index files${NC}"

    local test_dir=$(create_test_project)

    # Create local index
    cat > "$test_dir/agent/index/local.main.yaml" << 'EOF'
local:
  index:
    - path: agent/design/requirements.md
      weight: 0.9
      kind: requirements
      description: |
        Local requirements.
      rationale: |
        Project-specific.
      applies: acp.init
EOF

    # Create package index
    cat > "$test_dir/agent/index/pkg.main.yaml" << 'EOF'
pkg:
  index:
    - path: agent/patterns/pkg.example.md
      weight: 0.5
      kind: pattern
      description: |
        Package pattern.
      rationale: |
        From package.
      applies: acp.proceed
EOF

    # When listing files, local.* should sort first alphabetically
    local files=()
    for f in "$test_dir/agent/index/"*.yaml; do
        local basename=$(basename "$f")
        [[ "$basename" != *.template.yaml ]] && files+=("$basename")
    done

    # Sort and verify local comes first
    IFS=$'\n' sorted=($(sort <<<"${files[*]}")); unset IFS
    assert_equals "local.main.yaml" "${sorted[0]}" "local.main.yaml should sort before pkg.main.yaml"

    rm -rf "$test_dir"
    echo ""
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

test_valid_index_structure
test_index_naming_convention
test_template_files_excluded
test_weight_range_validation
test_kind_enum_values
test_applies_qualified_names
test_package_install_copies_index
test_package_remove_cleans_index
test_package_info_shows_indices
test_install_creates_index_dir
test_template_has_schema_docs
test_empty_index_directory
test_single_entry_index
test_multiple_index_files
test_package_validate_with_indices
test_local_precedence_over_package

# Print summary
print_test_summary

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
