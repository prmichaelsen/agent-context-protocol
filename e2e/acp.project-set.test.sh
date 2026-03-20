#!/usr/bin/env bash
# E2E tests for @acp.project-set command

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Source YAML parser
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Setup test environment
setup_test_env() {
  # Create temporary test directory
  TEST_DIR=$(mktemp -d)
  
  # Create mock registry
  REGISTRY_FILE="${TEST_DIR}/projects.yaml"
  
  # Create mock project directories
  PROJECT1_DIR="${TEST_DIR}/project1"
  PROJECT2_DIR="${TEST_DIR}/project2"
  mkdir -p "$PROJECT1_DIR"
  mkdir -p "$PROJECT2_DIR"
  
  # Create registry with test projects
  cat > "$REGISTRY_FILE" << EOF
current_project: null

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
  
  project2:
    path: ${PROJECT2_DIR}
    type: web-app
    description: Test project 2
    created: 2026-02-24T11:00:00Z
    last_modified: 2026-02-24T11:00:00Z
    last_accessed: 2026-02-24T11:00:00Z
    status: active
    tags:
      - test

registry_version: 1.0.0
last_updated: 2026-02-24T10:00:00Z
EOF
  
  export HOME="$TEST_DIR"
  mkdir -p "${TEST_DIR}/.acp"
  cp "$REGISTRY_FILE" "${TEST_DIR}/.acp/projects.yaml"
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# Test 1: Set project successfully
test_set_project_success() {
  echo "Test 1: Set project successfully"
  
  setup_test_env
  
  # Run project-set (capture exit code properly)
  set +e
  local output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project1 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "0" "$exit_code" "Exit code should be 0"
  
  # Check output contains success message
  assert_contains "$output" "✓ Switched to project: project1" "Should show success message"
  assert_contains "$output" "Path: ${PROJECT1_DIR}" "Should show project path"
  assert_contains "$output" "Type: mcp-server" "Should show project type"
  
  # Check registry updated
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local current_project=$(yaml_query ".current_project")
  assert_equals "$current_project" "project1" "Current project should be set"
  
  # Check last_accessed updated
  local last_accessed=$(yaml_query ".projects.project1.last_accessed")
  assert_not_equals "$last_accessed" "2026-02-24T10:00:00Z" "Last accessed should be updated"
  
  cleanup_test_env
  echo "✓ Test 1 passed"
  echo ""
}

# Test 2: Project not found in registry
test_project_not_found() {
  echo "Test 2: Project not found in registry"
  
  setup_test_env
  
  # Run project-set with non-existent project (capture exit code properly)
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" nonexistent 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "1" "$exit_code" "Exit code should be 1"
  
  # Check error message
  assert_contains "$output" "Error: Project 'nonexistent' not found in registry" "Should show error"
  assert_contains "$output" "Available projects:" "Should list available projects"
  assert_contains "$output" "project1" "Should list project1"
  assert_contains "$output" "project2" "Should list project2"
  
  cleanup_test_env
  echo "✓ Test 2 passed"
  echo ""
}

# Test 3: Project directory not found
test_project_directory_not_found() {
  echo "Test 3: Project directory not found"
  
  setup_test_env
  
  # Remove project directory
  rm -rf "$PROJECT1_DIR"
  
  # Run project-set (capture exit code properly)
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project1 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "1" "$exit_code" "Exit code should be 1"
  
  # Check error message
  assert_contains "$output" "Error: Project directory not found" "Should show error"
  assert_contains "$output" "${PROJECT1_DIR}" "Should show missing path"
  assert_contains "$output" "Project may have been moved or deleted" "Should explain issue"
  
  cleanup_test_env
  echo "✓ Test 3 passed"
  echo ""
}

# Test 4: No arguments provided
test_no_arguments() {
  echo "Test 4: No arguments provided"
  
  setup_test_env
  
  # Run project-set without arguments (capture exit code properly)
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "1" "$exit_code" "Exit code should be 1"
  
  # Check usage message
  assert_contains "$output" "Usage:" "Should show usage"
  assert_contains "$output" "acp.project-set.sh <project-name>" "Should show syntax"
  
  cleanup_test_env
  echo "✓ Test 4 passed"
  echo ""
}

# Test 5: Registry file not found
test_registry_not_found() {
  echo "Test 5: Registry file not found"
  
  setup_test_env
  
  # Remove registry
  rm -f "${TEST_DIR}/.acp/projects.yaml"
  
  # Run project-set (capture exit code properly)
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project1 2>&1)
  local exit_code=$?
  set -e
  
  # Check exit code
  assert_equals "1" "$exit_code" "Exit code should be 1"
  
  # Check error message
  assert_contains "$output" "Error: Project registry not found" "Should show error"
  assert_contains "$output" "@acp.project-create" "Should suggest creating project"
  
  cleanup_test_env
  echo "✓ Test 5 passed"
  echo ""
}

# Test 6: Switch between projects
test_switch_between_projects() {
  echo "Test 6: Switch between projects"
  
  setup_test_env
  
  # Set to project1
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project1 >/dev/null 2>&1
  
  # Check current_project
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local current=$(yaml_query ".current_project")
  assert_equals "project1" "$current" "Should be project1"
  
  # Set to project2
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project2 >/dev/null 2>&1
  
  # Check current_project changed
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  current=$(yaml_query ".current_project")
  assert_equals "project2" "$current" "Should be project2"
  
  cleanup_test_env
  echo "✓ Test 6 passed"
  echo ""
}

# Test 7: Tilde expansion in path
test_tilde_expansion() {
  echo "Test 7: Tilde expansion in path"
  
  setup_test_env
  
  # Create project with tilde path
  local project3_dir="${TEST_DIR}/project3"
  mkdir -p "$project3_dir"
  
  # Add project with tilde path to registry (insert before registry_version)
  # Use portable approach instead of GNU sed -i with \n
  local tmpfile="${TEST_DIR}/.acp/projects.yaml.tmp"
  awk '/^registry_version:/{
    print "  project3:"
    print "    path: ~/project3"
    print "    type: cli-tool"
    print "    description: Test project 3"
    print "    created: 2026-02-24T12:00:00Z"
    print "    last_modified: 2026-02-24T12:00:00Z"
    print "    last_accessed: 2026-02-24T12:00:00Z"
    print "    status: active"
    print ""
  }{print}' "${TEST_DIR}/.acp/projects.yaml" > "$tmpfile" && mv "$tmpfile" "${TEST_DIR}/.acp/projects.yaml"
  
  # Run project-set (capture exit code properly)
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project3 2>&1)
  local exit_code=$?
  set -e
  
  # Check success (tilde should be expanded)
  assert_equals "0" "$exit_code" "Exit code should be 0"
  assert_contains "$output" "✓ Switched to project: project3" "Should succeed"
  
  cleanup_test_env
  echo "✓ Test 7 passed"
  echo ""
}

# Test 8: Registry last_updated timestamp
test_registry_timestamp_updated() {
  echo "Test 8: Registry last_updated timestamp"
  
  setup_test_env
  
  # Get initial timestamp
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local initial_timestamp=$(yaml_query ".last_updated")
  
  # Wait a moment to ensure timestamp changes
  sleep 1
  
  # Run project-set
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-set.sh" project1 >/dev/null 2>&1
  
  # Check timestamp updated
  yaml_parse "${TEST_DIR}/.acp/projects.yaml"
  local new_timestamp=$(yaml_query ".last_updated")
  assert_not_equals "$initial_timestamp" "$new_timestamp" "Registry timestamp should be updated"
  
  cleanup_test_env
  echo "✓ Test 8 passed"
  echo ""
}

# Run all tests
main() {
  echo "======================================"
  echo "E2E Tests: @acp.project-set"
  echo "======================================"
  echo ""
  
  test_set_project_success
  test_project_not_found
  test_project_directory_not_found
  test_no_arguments
  test_registry_not_found
  test_switch_between_projects
  test_tilde_expansion
  test_registry_timestamp_updated
  
  echo "======================================"
  echo "All tests passed! ✓"
  echo "======================================"
}

# Run tests
main
