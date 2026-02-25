#!/usr/bin/env bash
# E2E tests for @acp.project-info command

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Source YAML parser
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser

# Setup test environment
setup_test_env() {
  # Create temporary test directory
  TEST_DIR=$(mktemp -d)
  
  # Create mock project directories
  PROJECT1_DIR="${TEST_DIR}/project1"
  PROJECT2_DIR="${TEST_DIR}/project2"
  mkdir -p "$PROJECT1_DIR"
  mkdir -p "$PROJECT2_DIR"
  
  # Create AGENT.md in project1 to mark it as ACP project
  echo "# Agent Context Protocol" > "${PROJECT1_DIR}/AGENT.md"
  mkdir -p "${PROJECT1_DIR}/agent"
  cat > "${PROJECT1_DIR}/agent/progress.yaml" << 'EOF'
project:
  version: 1.0.0
EOF
  
  # Create registry with test projects
  mkdir -p "${TEST_DIR}/.acp"
  cat > "${TEST_DIR}/.acp/projects.yaml" << EOF
current_project: project1

projects:
  project1:
    path: ${PROJECT1_DIR}
    type: mcp-server
    description: Test project 1
    created: 2026-02-24T10:00:00Z
    last_modified: 2026-02-24T10:00:00Z
    last_accessed: 2026-02-24T10:00:00Z
    status: active
    tags:
      - test
      - mcp
    related_projects:
      - project2
    dependencies:
      npm:
        - dependency-1
        - dependency-2
  
  project2:
    path: ${PROJECT2_DIR}
    type: web-app
    description: Test project 2
    created: 2026-02-24T11:00:00Z
    last_modified: 2026-02-24T11:00:00Z
    last_accessed: 2026-02-24T11:00:00Z
    status: archived

registry_version: 1.0.0
last_updated: 2026-02-24T10:00:00Z
EOF
  
  export HOME="$TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# Test 1: Show project info successfully
test_show_project_info() {
  echo "Test 1: Show project info successfully"
  
  setup_test_env
  
  # Run project-info
  set +e
  local output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" project1 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "0" "$exit_code" "Exit code should be 0"
  
  # Check output
  assert_contains "$output" "project1" "Should show project name"
  assert_contains "$output" "mcp-server" "Should show project type"
  assert_contains "$output" "active" "Should show status"
  assert_contains "$output" "Test project 1" "Should show description"
  assert_contains "$output" "⭐ Current" "Should mark as current project"
  assert_contains "$output" "test" "Should show tags"
  assert_contains "$output" "project2" "Should show related projects"
  assert_contains "$output" "dependency-1" "Should show dependencies"
  assert_contains "$output" "✅ Project directory exists" "Should confirm directory exists"
  assert_contains "$output" "✅ ACP project" "Should detect ACP project"
  
  cleanup_test_env
  echo "✓ Test 1 passed"
  echo ""
}

# Test 2: Project not found
test_project_not_found() {
  echo "Test 2: Project not found in registry"
  
  setup_test_env
  
  # Run project-info with non-existent project
  set +e
  local output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" nonexistent 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "1" "$exit_code" "Exit code should be 1"
  
  # Check error message
  assert_contains "$output" "not found in registry" "Should show error"
  assert_contains "$output" "Available projects:" "Should list available projects"
  assert_contains "$output" "project1" "Should list project1"
  
  cleanup_test_env
  echo "✓ Test 2 passed"
  echo ""
}

# Test 3: No arguments provided
test_no_arguments() {
  echo "Test 3: No arguments provided"
  
  setup_test_env
  
  # Run project-info without arguments
  set +e
  local output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "1" "$exit_code" "Exit code should be 1"
  
  # Check usage message
  assert_contains "$output" "Project name required" "Should show error"
  assert_contains "$output" "Usage:" "Should show usage"
  
  cleanup_test_env
  echo "✓ Test 3 passed"
  echo ""
}

# Test 4: Registry not found
test_registry_not_found() {
  echo "Test 4: Registry file not found"
  
  setup_test_env
  
  # Remove registry
  rm -f "${TEST_DIR}/.acp/projects.yaml"
  
  # Run project-info
  set +e
  local output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" project1 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "1" "$exit_code" "Exit code should be 1"
  
  # Check error message
  assert_contains "$output" "registry not found" "Should show error"
  
  cleanup_test_env
  echo "✓ Test 4 passed"
  echo ""
}

# Test 5: Project without optional fields
test_project_without_optional_fields() {
  echo "Test 5: Project without optional fields"
  
  setup_test_env
  
  # Run project-info on project2 (no tags, related, dependencies)
  set +e
  local output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh" project2 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "0" "$exit_code" "Exit code should be 0"
  
  # Check output
  assert_contains "$output" "project2" "Should show project name"
  assert_contains "$output" "web-app" "Should show type"
  assert_contains "$output" "archived" "Should show status"
  assert_not_contains "$output" "⭐ Current" "Should not mark as current"
  
  cleanup_test_env
  echo "✓ Test 5 passed"
  echo ""
}

# Run all tests
main() {
  echo "======================================"
  echo "E2E Tests: @acp.project-info"
  echo "======================================"
  echo ""
  
  test_show_project_info
  test_project_not_found
  test_no_arguments
  test_registry_not_found
  test_project_without_optional_fields
  
  echo "======================================"
  echo "All tests passed! ✓"
  echo "======================================"
}

# Run tests
main
