#!/usr/bin/env bash
# E2E tests for @acp.project-list command
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../tests/common.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.common.sh"

# Test setup
setup() {
    export HOME="/tmp/acp-test-$$-$RANDOM"
    mkdir -p "$HOME/.acp"
    export SCRIPT_PATH="${SCRIPT_DIR}/../agent/scripts/acp.project-list.sh"
}

# Test teardown
teardown() {
    local old_home="$HOME"
    rm -rf "$old_home" 2>/dev/null || true
}

# Test 1: Empty registry (no registry file)
test_empty_registry_no_file() {
    setup
    
    local output
    output=$("$SCRIPT_PATH" 2>&1)
    
    assert_contains "$output" "No projects registry found" "Should show no registry message"
    assert_contains "$output" "@acp.project-create" "Should suggest creating projects"
    
    teardown
}

# Test 2: Empty registry (registry exists but empty)
test_empty_registry_with_file() {
    setup
    init_projects_registry
    
    local output
    output=$("$SCRIPT_PATH" 2>&1)
    
    assert_contains "$output" "No projects registered yet" "Should show no projects message"
    assert_contains "$output" "@acp.project-create" "Should suggest creating projects"
    
    teardown
}

# Test 3: Single project
test_single_project() {
    setup
    init_projects_registry
    register_project "my-project" "$HOME/.acp/projects/my-project" "mcp-server" "My test project"
    
    local output
    output=$("$SCRIPT_PATH" 2>&1)
    
    assert_contains "$output" "my-project" "Should show project name"
    assert_contains "$output" "mcp-server" "Should show project type"
    assert_contains "$output" "My test project" "Should show project description"
    assert_contains "$output" "⭐ Current" "Should mark as current project"
    assert_contains "$output" "Showing 1 of 1 projects" "Should show correct count"
    
    teardown
}

# Test 4: Multiple projects
test_multiple_projects() {
    setup
    init_projects_registry
    register_project "project-1" "$HOME/.acp/projects/project-1" "mcp-server" "First project"
    register_project "project-2" "$HOME/.acp/projects/project-2" "web-app" "Second project"
    register_project "project-3" "$HOME/.acp/projects/project-3" "cli-tool" "Third project"
    
    local output
    output=$("$SCRIPT_PATH" 2>&1)
    
    assert_contains "$output" "project-1" "Should show first project"
    assert_contains "$output" "project-2" "Should show second project"
    assert_contains "$output" "project-3" "Should show third project"
    assert_contains "$output" "Showing 3 of 3 projects" "Should show correct count"
    
    teardown
}

# Test 5: Filter by type (matching)
test_filter_by_type_matching() {
    setup
    init_projects_registry
    register_project "server-1" "$HOME/.acp/projects/server-1" "mcp-server" "Server 1"
    register_project "server-2" "$HOME/.acp/projects/server-2" "mcp-server" "Server 2"
    register_project "webapp-1" "$HOME/.acp/projects/webapp-1" "web-app" "Web App"
    
    local output
    output=$("$SCRIPT_PATH" --type mcp-server 2>&1)
    
    assert_contains "$output" "server-1" "Should show first server"
    assert_contains "$output" "server-2" "Should show second server"
    assert_not_contains "$output" "webapp-1" "Should not show web app"
    assert_contains "$output" "Showing 2 of 3 projects" "Should show filtered count"
    
    teardown
}

# Test 6: Filter by type (no matches)
test_filter_by_type_no_matches() {
    setup
    init_projects_registry
    register_project "server-1" "$HOME/.acp/projects/server-1" "mcp-server" "Server 1"
    
    local output
    output=$("$SCRIPT_PATH" --type web-app 2>&1)
    
    assert_contains "$output" "No projects match filters" "Should show no matches message"
    
    teardown
}

# Test 7: Current project marker
test_current_project_marker() {
    setup
    init_projects_registry
    register_project "first" "$HOME/.acp/projects/first" "mcp-server" "First"
    register_project "second" "$HOME/.acp/projects/second" "web-app" "Second"
    
    # First project should be current (registered first)
    local output
    output=$("$SCRIPT_PATH" 2>&1)
    
    # Count how many times ⭐ appears (should be exactly once)
    local star_count
    star_count=$(echo "$output" | grep -c "⭐" || echo "0")
    assert_equals "1" "$star_count" "Should have exactly one current project marker"
    
    teardown
}

# Test 8: Invalid filter option
test_invalid_filter_option() {
    setup
    init_projects_registry
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" --invalid-option 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "Unknown option" "Should show error message"
    
    teardown
}

# Run all tests
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running @acp.project-list E2E tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_empty_registry_no_file
test_empty_registry_with_file
test_single_project
test_multiple_projects
test_filter_by_type_matching
test_filter_by_type_no_matches
test_current_project_marker
test_invalid_filter_option

echo ""
print_test_summary
exit $?
