#!/usr/bin/env bash
# E2E tests for @acp.project-update command
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../tests/common.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.common.sh"

# Test setup
setup() {
    export HOME="/tmp/acp-test-$$-$(date +%N)"
    mkdir -p "$HOME/.acp"
    export SCRIPT_PATH="${SCRIPT_DIR}/../agent/scripts/acp.project-update.sh"
}

# Test teardown
teardown() {
    local old_home="$HOME"
    rm -rf "$old_home" 2>/dev/null || true
}

# Test 1: Update status
test_update_status() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project"
    
    local output
    output=$("$SCRIPT_PATH" test-project --status archived 2>&1)
    
    assert_contains "$output" "Updated status: archived" "Should confirm status update"
    assert_contains "$output" "Updates applied: 1" "Should show 1 update"
    
    # Verify in registry
    source_yaml_parser
    yaml_parse "$HOME/.acp/projects.yaml"
    local new_status=$(yaml_query ".projects.test-project.status")
    assert_equals "archived" "$new_status" "Status should be updated in registry"
    
    teardown
}

# Test 2: Update description
test_update_description() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Original description"
    
    local output
    output=$("$SCRIPT_PATH" test-project --description "New description" 2>&1)
    
    assert_contains "$output" "Updated description" "Should confirm description update"
    
    teardown
}

# Test 3: Update type
test_update_type() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test"
    
    local output
    output=$("$SCRIPT_PATH" test-project --type cli-tool 2>&1)
    
    assert_contains "$output" "Updated type: cli-tool" "Should confirm type update"
    
    teardown
}

# Test 4: Add tag
test_add_tag() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test"
    
    local output
    output=$("$SCRIPT_PATH" test-project --add-tag production 2>&1)
    
    assert_contains "$output" "Added tag: production" "Should confirm tag added"
    
    teardown
}

# Test 5: Add duplicate tag
test_add_duplicate_tag() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test"
    
    # Add tag first time
    "$SCRIPT_PATH" test-project --add-tag test-tag >/dev/null 2>&1
    
    # Try to add again
    local output
    output=$("$SCRIPT_PATH" test-project --add-tag test-tag 2>&1)
    
    assert_contains "$output" "Tag already exists: test-tag" "Should detect duplicate"
    
    teardown
}

# Test 6: Multiple updates
test_multiple_updates() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test"
    
    local output
    output=$("$SCRIPT_PATH" test-project --status paused --type cli-tool --description "Updated" 2>&1)
    
    assert_contains "$output" "Updated status: paused" "Should update status"
    assert_contains "$output" "Updated type: cli-tool" "Should update type"
    assert_contains "$output" "Updated description" "Should update description"
    assert_contains "$output" "Updates applied: 3" "Should show 3 updates"
    
    teardown
}

# Test 7: Invalid status
test_invalid_status() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test"
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" test-project --status invalid 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "Invalid status" "Should show error"
    assert_contains "$output" "Valid values: active, archived, paused" "Should show valid values"
    
    teardown
}

# Test 8: No updates specified
test_no_updates() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test"
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" test-project 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "No updates specified" "Should show error"
    
    teardown
}

# Test 9: Project not found
test_project_not_found() {
    setup
    init_projects_registry
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" nonexistent --status active 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "not found in registry" "Should show error"
    
    teardown
}

# Test 10: No project name
test_no_project_name() {
    setup
    init_projects_registry
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" --status active 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "Project name required" "Should show error"
    
    teardown
}

# Run all tests
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running @acp.project-update E2E tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_update_status
test_update_description
test_update_type
test_add_tag
test_add_duplicate_tag
test_multiple_updates
test_invalid_status
test_no_updates
test_project_not_found
test_no_project_name

echo ""
print_test_summary
