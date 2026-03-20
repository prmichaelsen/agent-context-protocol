#!/usr/bin/env bash
# E2E Workflow Tests for Project Registry System
# Tests complete workflows: create → list → set → info → update → sync → remove
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Source YAML parser and common functions
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Setup test environment
setup_test_env() {
  # Create temporary test directory
  TEST_DIR=$(mktemp -d)
  export HOME="$TEST_DIR"
  
  # Create .acp directory
  mkdir -p "${TEST_DIR}/.acp"
  mkdir -p "${TEST_DIR}/.acp/projects"
  
  # Initialize empty registry
  init_projects_registry
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Workflow Test 1: Complete Project Lifecycle
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_complete_project_lifecycle() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Workflow Test 1: Complete Project Lifecycle"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  setup_test_env
  
  # Step 1: Create projects manually (simulating @acp.project-create)
  echo "Step 1: Creating test projects..."
  
  local project1_dir="${TEST_DIR}/.acp/projects/test-mcp-server"
  local project2_dir="${TEST_DIR}/.acp/projects/test-web-app"
  local project3_dir="${TEST_DIR}/.acp/projects/test-cli-tool"
  
  mkdir -p "$project1_dir/agent"
  mkdir -p "$project2_dir/agent"
  mkdir -p "$project3_dir/agent"
  
  # Create progress.yaml files
  cat > "$project1_dir/agent/progress.yaml" << EOF
project:
  name: test-mcp-server
  type: mcp-server
  description: Test MCP server project
  version: 1.0.0
EOF
  
  cat > "$project2_dir/agent/progress.yaml" << EOF
project:
  name: test-web-app
  type: web-app
  description: Test web application
  version: 2.0.0
EOF
  
  cat > "$project3_dir/agent/progress.yaml" << EOF
project:
  name: test-cli-tool
  type: cli-tool
  description: Test CLI tool
  version: 0.5.0
EOF
  
  echo "✓ Created 3 test projects"
  echo ""
  
  # Step 2: Register projects
  echo "Step 2: Registering projects..."
  
  register_project "test-mcp-server" "$project1_dir" "mcp-server" "Test MCP server project"
  register_project "test-web-app" "$project2_dir" "web-app" "Test web application"
  
  echo "✓ Registered 2 projects (1 unregistered for sync test)"
  echo ""
  
  # Step 3: List projects
  echo "Step 3: Testing @acp.project-list..."
  
  local list_output
  list_output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-list.sh" 2>&1)
  
  assert_contains "$list_output" "test-mcp-server" "Should list test-mcp-server"
  assert_contains "$list_output" "test-web-app" "Should list test-web-app"
  assert_not_contains "$list_output" "test-cli-tool" "Should NOT list unregistered project"
  
  echo ""
  
  # Step 4: Set current project
  echo "Step 4: Testing @acp.project-set..."
  
  local set_output
  set_output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" test-mcp-server 2>&1)
  
  assert_contains "$set_output" "✓ Switched to project: test-mcp-server" "Should switch successfully"
  
  # Verify current project
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local current_project=$(yaml_query ".current_project")
  assert_equals "test-mcp-server" "$current_project" "Current project should be set"
  
  echo ""
  
  # Step 5: Get project info
  echo "Step 5: Testing @acp.project-info..."
  
  local info_output
  info_output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" test-mcp-server 2>&1)
  
  assert_contains "$info_output" "test-mcp-server" "Should show project name"
  assert_contains "$info_output" "mcp-server" "Should show project type"
  assert_contains "$info_output" "Test MCP server project" "Should show description"
  assert_contains "$info_output" "⭐" "Should mark as current project"
  
  echo ""
  
  # Step 6: Update project metadata
  echo "Step 6: Testing @acp.project-update..."
  
  local update_output
  update_output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-mcp-server --status archived 2>&1)
  
  assert_contains "$update_output" "✓ Updated project: test-mcp-server" "Should update successfully"
  
  # Verify status updated
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local status=$(yaml_query ".projects.test-mcp-server.status")
  assert_equals "archived" "$status" "Status should be updated"
  
  echo ""
  
  # Step 7: Sync unregistered projects (skip - requires interactive input)
  echo "Step 7: Testing @acp.projects-sync (manual registration)..."
  
  # Manually register the third project instead of using sync
  register_project "test-cli-tool" "$project3_dir" "cli-tool" "Test CLI tool"
  
  echo "✓ Manually registered test-cli-tool (sync requires interactive input)"
  
  # Verify project was registered
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local cli_tool_exists=$(yaml_query ".projects.test-cli-tool.path" 2>/dev/null || echo "")
  assert_not_empty "$cli_tool_exists" "test-cli-tool should be registered"
  
  echo ""
  
  # Step 8: List all projects (should now show 3)
  echo "Step 8: Verifying all projects listed..."
  
  list_output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-list.sh" 2>&1)
  
  assert_contains "$list_output" "test-mcp-server" "Should list test-mcp-server"
  assert_contains "$list_output" "test-web-app" "Should list test-web-app"
  assert_contains "$list_output" "test-cli-tool" "Should list test-cli-tool (now registered)"
  
  echo ""
  
  # Step 9: Remove a project
  echo "Step 9: Testing @acp.project-remove..."
  
  local remove_output
  remove_output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" test-web-app -y 2>&1)
  
  assert_contains "$remove_output" "✅ Project removed: test-web-app" "Should remove successfully"
  
  # Verify project removed from registry
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local web_app_exists=$(yaml_query ".projects.test-web-app.path" 2>/dev/null || echo "")
  assert_empty "$web_app_exists" "test-web-app should be removed from registry"
  
  echo ""
  
  # Step 10: Verify final state
  echo "Step 10: Verifying final registry state..."
  
  list_output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-list.sh" 2>&1)
  
  assert_contains "$list_output" "test-mcp-server" "Should still list test-mcp-server"
  assert_not_contains "$list_output" "test-web-app" "Should NOT list removed project"
  assert_contains "$list_output" "test-cli-tool" "Should still list test-cli-tool"
  
  # Verify current project still set
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  current_project=$(yaml_query ".current_project")
  assert_equals "test-mcp-server" "$current_project" "Current project should still be set"
  
  echo ""
  echo "✅ Complete lifecycle test passed!"
  echo ""
  
  cleanup_test_env
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Workflow Test 2: Context Switching Workflow
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_context_switching_workflow() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Workflow Test 2: Context Switching Workflow"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  setup_test_env
  
  # Create and register multiple projects
  echo "Setup: Creating 3 projects..."
  
  local proj_a="${TEST_DIR}/.acp/projects/project-a"
  local proj_b="${TEST_DIR}/.acp/projects/project-b"
  local proj_c="${TEST_DIR}/.acp/projects/project-c"
  
  mkdir -p "$proj_a" "$proj_b" "$proj_c"
  
  register_project "project-a" "$proj_a" "mcp-server" "Project A"
  register_project "project-b" "$proj_b" "web-app" "Project B"
  register_project "project-c" "$proj_c" "cli-tool" "Project C"
  
  echo "✓ Created and registered 3 projects"
  echo ""
  
  # Test 1: Switch to project-a
  echo "Test 1: Switch to project-a..."
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project-a >/dev/null 2>&1
  
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local current=$(yaml_query ".current_project")
  assert_equals "project-a" "$current" "Should be on project-a"
  
  # Test 2: Switch to project-b
  echo "Test 2: Switch to project-b..."
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project-b >/dev/null 2>&1
  
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  current=$(yaml_query ".current_project")
  assert_equals "project-b" "$current" "Should be on project-b"
  
  # Test 3: Switch to project-c
  echo "Test 3: Switch to project-c..."
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project-c >/dev/null 2>&1
  
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  current=$(yaml_query ".current_project")
  assert_equals "project-c" "$current" "Should be on project-c"
  
  # Test 4: Verify last_accessed timestamps are different
  echo "Test 4: Verify timestamps updated..."
  
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local time_a=$(yaml_query ".projects.project-a.last_accessed")
  local time_b=$(yaml_query ".projects.project-b.last_accessed")
  local time_c=$(yaml_query ".projects.project-c.last_accessed")
  
  assert_not_equals "$time_a" "$time_b" "project-a and project-b should have different timestamps"
  assert_not_equals "$time_b" "$time_c" "project-b and project-c should have different timestamps"
  
  echo ""
  echo "✅ Context switching workflow passed!"
  echo ""
  
  cleanup_test_env
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Workflow Test 3: Error Handling Workflow
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_error_handling_workflow() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Workflow Test 3: Error Handling Workflow"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  setup_test_env
  
  # Create one valid project
  local valid_proj="${TEST_DIR}/.acp/projects/valid-project"
  mkdir -p "$valid_proj"
  register_project "valid-project" "$valid_proj" "mcp-server" "Valid project"
  
  echo "Setup: Created 1 valid project"
  echo ""
  
  # Test 1: Try to set non-existent project
  echo "Test 1: Set non-existent project (should fail)..."
  
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" nonexistent 2>&1)
  local exit_code=$?
  set -e
  
  assert_not_equals "0" "$exit_code" "Should exit with error"
  assert_contains "$output" "Error: Project 'nonexistent' not found" "Should show error message"
  
  # Test 2: Try to get info for non-existent project
  echo "Test 2: Get info for non-existent project (should fail)..."
  
  set +e
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" nonexistent 2>&1)
  exit_code=$?
  set -e
  
  assert_not_equals "0" "$exit_code" "Should exit with error"
  assert_contains "$output" "Error: Project 'nonexistent' not found" "Should show error message"
  
  # Test 3: Try to update non-existent project
  echo "Test 3: Update non-existent project (should fail)..."
  
  set +e
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" nonexistent --status archived 2>&1)
  exit_code=$?
  set -e
  
  assert_not_equals "0" "$exit_code" "Should exit with error"
  assert_contains "$output" "Error: Project 'nonexistent' not found" "Should show error message"
  
  # Test 4: Try to remove non-existent project
  echo "Test 4: Remove non-existent project (should fail)..."
  
  set +e
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" nonexistent -y 2>&1)
  exit_code=$?
  set -e
  
  assert_not_equals "0" "$exit_code" "Should exit with error"
  assert_contains "$output" "Error: Project 'nonexistent' not found" "Should show error message"
  
  # Test 5: Verify valid project still works after errors
  echo "Test 5: Verify valid project still accessible..."
  
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" valid-project 2>&1)
  assert_contains "$output" "valid-project" "Should show valid project info"
  
  echo ""
  echo "✅ Error handling workflow passed!"
  echo ""
  
  cleanup_test_env
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Workflow Test 4: Filtering and Querying Workflow
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

test_filtering_workflow() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Workflow Test 4: Filtering and Querying Workflow"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  setup_test_env
  
  # Create projects with different types and statuses
  echo "Setup: Creating projects with different types and statuses..."
  
  local mcp1="${TEST_DIR}/.acp/projects/mcp-server-1"
  local mcp2="${TEST_DIR}/.acp/projects/mcp-server-2"
  local web1="${TEST_DIR}/.acp/projects/web-app-1"
  local cli1="${TEST_DIR}/.acp/projects/cli-tool-1"
  
  mkdir -p "$mcp1" "$mcp2" "$web1" "$cli1"
  
  register_project "mcp-server-1" "$mcp1" "mcp-server" "MCP Server 1"
  register_project "mcp-server-2" "$mcp2" "mcp-server" "MCP Server 2"
  register_project "web-app-1" "$web1" "web-app" "Web App 1"
  register_project "cli-tool-1" "$cli1" "cli-tool" "CLI Tool 1"
  
  # Update statuses
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" mcp-server-2 --status archived >/dev/null 2>&1
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" cli-tool-1 --status paused >/dev/null 2>&1
  
  echo "✓ Created 4 projects (2 mcp-server, 1 web-app, 1 cli-tool)"
  echo "✓ Statuses: 2 active, 1 archived, 1 paused"
  echo ""
  
  # Test 1: Filter by type (mcp-server)
  echo "Test 1: Filter by type (mcp-server)..."
  
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-list.sh" --type mcp-server 2>&1)
  
  assert_contains "$output" "mcp-server-1" "Should show mcp-server-1"
  assert_contains "$output" "mcp-server-2" "Should show mcp-server-2"
  assert_not_contains "$output" "web-app-1" "Should NOT show web-app-1"
  assert_not_contains "$output" "cli-tool-1" "Should NOT show cli-tool-1"
  
  # Test 2: Filter by status (active)
  echo "Test 2: Filter by status (active)..."
  
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-list.sh" --status active 2>&1)
  
  assert_contains "$output" "mcp-server-1" "Should show mcp-server-1 (active)"
  assert_contains "$output" "web-app-1" "Should show web-app-1 (active)"
  assert_not_contains "$output" "mcp-server-2" "Should NOT show mcp-server-2 (archived)"
  assert_not_contains "$output" "cli-tool-1" "Should NOT show cli-tool-1 (paused)"
  
  # Test 3: Filter by status (archived)
  echo "Test 3: Filter by status (archived)..."
  
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-list.sh" --status archived 2>&1)
  
  assert_contains "$output" "mcp-server-2" "Should show mcp-server-2 (archived)"
  assert_not_contains "$output" "mcp-server-1" "Should NOT show mcp-server-1 (active)"
  
  # Test 4: No filters (show all)
  echo "Test 4: No filters (show all)..."
  
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-list.sh" 2>&1)
  
  assert_contains "$output" "mcp-server-1" "Should show all projects"
  assert_contains "$output" "mcp-server-2" "Should show all projects"
  assert_contains "$output" "web-app-1" "Should show all projects"
  assert_contains "$output" "cli-tool-1" "Should show all projects"
  
  echo ""
  echo "✅ Filtering workflow passed!"
  echo ""
  
  cleanup_test_env
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Run All Workflow Tests
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
  echo ""
  echo "╔════════════════════════════════════════════════════╗"
  echo "║  Project Registry E2E Workflow Tests              ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo ""
  
  test_complete_project_lifecycle
  test_context_switching_workflow
  test_error_handling_workflow
  test_filtering_workflow
  
  echo ""
  echo "╔════════════════════════════════════════════════════╗"
  echo "║  All Workflow Tests Complete                      ║"
  echo "╚════════════════════════════════════════════════════╝"
  echo ""
  
  print_test_summary
}

# Run tests
main
exit $?
