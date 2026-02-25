#!/usr/bin/env bash
# E2E tests for @acp.project-info command
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../tests/common.sh"
source "${SCRIPT_DIR}/../agent/scripts/acp.common.sh"

# Test setup
setup() {
    export HOME="/tmp/acp-test-$$-$(date +%N)"
    mkdir -p "$HOME/.acp"
    export SCRIPT_PATH="${SCRIPT_DIR}/../agent/scripts/acp.project-info.sh"
}

# Test teardown
teardown() {
    local old_home="$HOME"
    rm -rf "$old_home" 2>/dev/null || true
}

# Test 1: Show project info successfully
test_show_project_info() {
    setup
    init_projects_registry
    register_project "test-project" "$HOME/.acp/projects/test-project" "mcp-server" "Test project description"
    
    # Create project directory with AGENT.md
    mkdir -p "$HOME/.acp/projects/test-project/agent"
    echo "# Agent Context Protocol" > "$HOME/.acp/projects/test-project/AGENT.md"
    cat > "$HOME/.acp/projects/test-project/agent/progress.yaml" << 'EOF'
project:
  version: 1.2.3
EOF
    
    local output
    output=$("$SCRIPT_PATH" test-project 2>&1)
    
    assert_contains "$output" "test-project" "Should show project name"
    assert_contains "$output" "mcp-server" "Should show project type"
    assert_contains "$output" "Test project description" "Should show description"
    assert_contains "$output" "active" "Should show status"
    assert_contains "$output" "⭐ Current" "Should mark as current project"
    assert_contains "$output" "✅ Project directory exists" "Should confirm directory"
    assert_contains "$output" "✅ ACP project" "Should detect ACP project"
    assert_contains "$output" "Version: 1.2.3" "Should show project version"
    
    teardown
}

# Test 2: Project not found
test_project_not_found() {
    setup
    init_projects_registry
    register_project "existing-project" "$HOME/.acp/projects/existing" "mcp-server" "Existing"
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" nonexistent 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "not found in registry" "Should show error"
    assert_contains "$output" "Available projects:" "Should list available"
    assert_contains "$output" "existing-project" "Should list existing project"
    
    teardown
}

# Test 3: No arguments
test_no_arguments() {
    setup
    init_projects_registry
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "Project name required" "Should show error"
    assert_contains "$output" "Usage:" "Should show usage"
    
    teardown
}

# Test 4: Registry not found
test_registry_not_found() {
    setup
    # Don't initialize registry
    
    local output
    local exit_code
    output=$("$SCRIPT_PATH" test-project 2>&1) || exit_code=$?
    
    assert_not_equals "0" "${exit_code:-0}" "Should exit with error"
    assert_contains "$output" "registry not found" "Should show error"
    
    teardown
}

# Test 5: Project without optional fields
test_project_minimal() {
    setup
    init_projects_registry
    register_project "minimal-project" "$HOME/.acp/projects/minimal" "web-app" "Minimal project"
    
    # Don't create directory (test missing directory detection)
    
    local output
    output=$("$SCRIPT_PATH" minimal-project 2>&1)
    
    assert_contains "$output" "minimal-project" "Should show project name"
    assert_contains "$output" "web-app" "Should show type"
    assert_contains "$output" "Minimal project" "Should show description"
    assert_contains "$output" "❌ Project directory not found" "Should detect missing directory"
    
    teardown
}

# Test 6: Non-current project
test_non_current_project() {
    setup
    init_projects_registry
    register_project "project1" "$HOME/.acp/projects/project1" "mcp-server" "Project 1"
    register_project "project2" "$HOME/.acp/projects/project2" "web-app" "Project 2"
    
    # project1 is current (registered first), check project2
    local output
    output=$("$SCRIPT_PATH" project2 2>&1)
    
    assert_contains "$output" "project2" "Should show project name"
    assert_not_contains "$output" "⭐ Current" "Should not mark as current"
    
    teardown
}

# Run all tests
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Running @acp.project-info E2E tests..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_show_project_info
test_project_not_found
test_no_arguments
test_registry_not_found
test_project_minimal
test_non_current_project

echo ""
print_test_summary
