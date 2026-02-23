#!/usr/bin/env bash
# Unit tests for project registry functions

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.yaml-parser.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.common.sh"

# Setup test environment (unique for each test)
setup() {
    export HOME="/tmp/acp-test-$$-$(date +%N)"
    mkdir -p "$HOME/.acp"
}

# Cleanup
teardown() {
    local old_home="$HOME"
    rm -rf "$old_home"
}

# Test 1: Registry initialization
test_init_projects_registry() {
    setup
    init_projects_registry
    assert_file_exists "$HOME/.acp/projects.yaml"
    teardown
}

# Test 2: Project registration
test_register_project() {
    setup
    init_projects_registry
    register_project "test-project" "/path/to/project" "mcp-server" "Test project"
    
    local type
    type=$(yaml_get "$HOME/.acp/projects.yaml" "projects.test-project.type" 2>/dev/null || echo "")
    type=$(echo "$type" | sed "s/^['\"]//; s/['\"]$//")
    assert_equals "mcp-server" "$type" "Project type should be mcp-server"
    teardown
}

# Test 3: Project exists check
test_project_exists() {
    setup
    init_projects_registry
    register_project "test-project" "/path/to/project" "mcp-server" "Test"
    
    project_exists "test-project"
    assert_true "Project should exist" $?
    
    project_exists "nonexistent"
    assert_false "Nonexistent project should not exist" $?
    
    teardown
}

# Test 4: Current project tracking
test_current_project() {
    setup
    init_projects_registry
    register_project "my-first-project" "/path/1" "mcp-server" "First"
    
    local current
    current=$(get_current_project)
    assert_equals "my-first-project" "$current" "Current project should be my-first-project"
    teardown
}

# Run all tests
echo ""
echo "Running project registry tests..."
echo ""

test_init_projects_registry
test_register_project
test_project_exists
test_current_project

print_test_summary
