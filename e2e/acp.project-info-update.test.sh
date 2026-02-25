#!/usr/bin/env bash
# E2E tests for @acp.project-info and @acp.project-update commands
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../tests/common.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.common.sh"

# Test setup
setup() {
    export HOME="/tmp/acp-test-$$-$(date +%N)"
    mkdir -p "$HOME/.acp"
    export INFO_SCRIPT="${SCRIPT_DIR}/../agent/scripts/acp.project-info.sh"
    export UPDATE_SCRIPT="${SCRIPT_DIR}/../agent/scripts/acp.project-update.sh"
}

# Test teardown
teardown() {
    local old_home="$HOME"
    rm -rf "$old_home" 2>/dev/null || true
}

# Test 1: project-info with valid project
test_project_info_success() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project description"
    
    # Create project directory
    mkdir -p "$HOME/.acp/projects/test-project"
    
    local output
    output=$("$INFO_SCRIPT" test-project 2>&1)
    
    assert_contains "$output" "test-project" "Should show project name"
    assert_contains "$output" "mcp-server" "Should show project type"
    assert_contains "$output" "Test project description" "Should show description"
    assert_contains "$output" "⭐ Current" "Should mark as current"
    
    teardown
}

# Test 2: project-info with missing project
test_project_info_not_found() {
    setup
    init_projects_registry
    
    local output
    local exit_code
    output=$("$INFO_SCRIPT" nonexistent 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "not found in registry" "Should show error"
    
    teardown
}

# Test 3: project-info with no arguments
test_project_info_no_args() {
    setup
    init_projects_registry
    
    local output
    local exit_code
    output=$("$INFO_SCRIPT" 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "Project name required" "Should show error"
    
    teardown
}

# Test 4: project-update status
test_project_update_status() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project"
    
    local output
    output=$("$UPDATE_SCRIPT" test-project --status archived 2>&1)
    
    assert_contains "$output" "Updated status: archived" "Should confirm update"
    assert_contains "$output" "Updates applied: 1" "Should show count"
    
    teardown
}

# Test 5: project-update invalid status
test_project_update_invalid_status() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project"
    
    local output
    local exit_code
    output=$("$UPDATE_SCRIPT" test-project --status invalid 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "Invalid status" "Should show error"
    
    teardown
}

# Test 6: project-update no updates
test_project_update_no_updates() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project"
    
    local output
    local exit_code
    output=$("$UPDATE_SCRIPT" test-project 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "No updates specified" "Should show error"
    
    teardown
}

# Test 7: project-update add tag
test_project_update_add_tag() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project"
    
    local output
    output=$("$UPDATE_SCRIPT" test-project --add-tag production 2>&1)
    
    assert_contains "$output" "Added tag: production" "Should confirm tag added"
    
    teardown
}

# Test 8: project-update multiple operations
test_project_update_multiple() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project"
    
    local output
    output=$("$UPDATE_SCRIPT" test-project --status paused --add-tag critical --type cli-tool 2>&1)
    
    assert_contains "$output" "Updated status: paused" "Should update status"
    assert_contains "$output" "Added tag: critical" "Should add tag"
    assert_contains "$output" "Updated type: cli-tool" "Should update type"
    assert_contains "$output" "Updates applied: 3" "Should show 3 updates"
    
    teardown
}

# Run all tests
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running @acp.project-info + @acp.project-update E2E tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_project_info_success
test_project_info_not_found
test_project_info_no_args
test_project_update_status
test_project_update_invalid_status
test_project_update_no_updates
test_project_update_add_tag
test_project_update_multiple

echo ""
print_test_summary
