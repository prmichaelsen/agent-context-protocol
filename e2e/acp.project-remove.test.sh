#!/usr/bin/env bash
# E2E Tests for acp.project-remove.sh

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Source common utilities for registry functions
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"

# Source YAML parser
source_yaml_parser

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Setup test environment
setup_test_env() {
  TEST_DIR=$(mktemp -d)
  TEST_PROJECT_DIR="${TEST_DIR}/test-project"
  
  # Create test project directory
  mkdir -p "$TEST_PROJECT_DIR"
  echo "test content" > "${TEST_PROJECT_DIR}/test.txt"
  
  # Create .acp directory structure
  mkdir -p "${TEST_DIR}/.acp"
  TEST_REGISTRY="${TEST_DIR}/.acp/projects.yaml"
  
  # Create test registry
  cat > "$TEST_REGISTRY" << EOF
version: 1.0.0
current_project: test-project
last_updated: 2026-02-26T00:00:00Z

projects:
  test-project:
    type: web-app
    status: active
    path: ${TEST_PROJECT_DIR}
    description: Test project
    created: 2026-02-26T00:00:00Z
    last_modified: 2026-02-26T00:00:00Z
    last_accessed: 2026-02-26T00:00:00Z
  
  other-project:
    type: mcp-server
    status: active
    path: ${TEST_DIR}/other-project
    description: Other test project
    created: 2026-02-26T00:00:00Z
    last_modified: 2026-02-26T00:00:00Z
    last_accessed: 2026-02-26T00:00:00Z

registry_version: 1.0.0
EOF
  
  # Create other project directory
  mkdir -p "${TEST_DIR}/other-project"
  
  # Export HOME for script to use
  export HOME="$TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}


# Test 1: Remove project from registry (registry only)
test_remove_registry_only() {
  print_test_header "Test 1: Remove project from registry (registry only)"
  
  setup_test_env
  
  # Run command with auto-confirm
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" test-project -y 2>&1)
  local exit_code=$?
  set -e
  
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Removed from registry: test-project" "Should confirm removal"
  assert_contains "$output" "Directory preserved:" "Should preserve directory"
  assert_dir_exists "$TEST_PROJECT_DIR" "Project directory should still exist"
  
  # Verify registry updated
  yaml_parse "$TEST_REGISTRY"
  local project_path=$(yaml_query ".projects.test-project.path" 2>/dev/null || echo "")
  assert_equals "" "$project_path" "Project should be removed from registry"
  
  # Verify current_project cleared
  local current=$(yaml_query ".current_project" 2>/dev/null || echo "")
  assert_equals "" "$current" "current_project should be cleared"
  
  cleanup_test_env
  
  print_test_result 0
}

# Test 2: Remove project with directory deletion
test_remove_with_delete() {
  print_test_header "Test 2: Remove project with directory deletion"
  
  setup_test_env
  
  # Run command with auto-confirm and delete-files
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" test-project --delete-files -y 2>&1)
  local exit_code=$?
  set -e
  
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Removed from registry: test-project" "Should confirm removal"
  assert_contains "$output" "Deleted from filesystem:" "Should confirm deletion"
  assert_dir_not_exists "$TEST_PROJECT_DIR" "Project directory should be deleted"
  
  # Verify registry updated
  yaml_parse "$TEST_REGISTRY"
  local project_path=$(yaml_query ".projects.test-project.path" 2>/dev/null || echo "")
  assert_equals "" "$project_path" "Project should be removed from registry"
  
  cleanup_test_env
  
  print_test_result 0
}

# Test 3: Remove non-current project
test_remove_non_current() {
  print_test_header "Test 3: Remove non-current project"
  
  setup_test_env
  
  # Set other-project as current
  yaml_parse "$TEST_REGISTRY"
  yaml_set "current_project" "other-project"
  yaml_write "$TEST_REGISTRY"
  
  # Remove test-project (not current)
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" test-project -y 2>&1)
  local exit_code=$?
  set -e
  
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_not_contains "$output" "This was the current project" "Should not warn about current project"
  
  # Verify current_project unchanged
  yaml_parse "$TEST_REGISTRY"
  local current=$(yaml_query ".current_project" 2>/dev/null || echo "")
  assert_equals "other-project" "$current" "current_project should remain unchanged"
  
  cleanup_test_env
  
  print_test_result 0
}

# Test 4: Project not found in registry
test_project_not_found() {
  print_test_header "Test 4: Project not found in registry"
  
  setup_test_env
  
  # Try to remove non-existent project
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" nonexistent-project -y 2>&1)
  local exit_code=$?
  set -e
  
  assert_equals 1 $exit_code "Exit code should be 1"
  assert_contains "$output" "not found in registry" "Should report project not found"
  assert_contains "$output" "Available projects:" "Should list available projects"
  
  cleanup_test_env
  
  print_test_result 0
}

# Test 5: No arguments provided
test_no_arguments() {
  print_test_header "Test 5: No arguments provided"
  
  setup_test_env
  
  # Run without arguments
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" 2>&1)
  local exit_code=$?
  set -e
  
  assert_equals 1 $exit_code "Exit code should be 1"
  assert_contains "$output" "Usage:" "Should show usage"
  
  cleanup_test_env
  
  print_test_result 0
}

# Test 6: Registry file not found
test_registry_not_found() {
  print_test_header "Test 6: Registry file not found"
  
  TEST_DIR=$(mktemp -d)
  export HOME="$TEST_DIR"
  
  # Don't create .acp directory or registry file
  
  # Try to remove project
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" test-project -y 2>&1)
  local exit_code=$?
  set -e
  
  assert_equals 1 $exit_code "Exit code should be 1"
  assert_contains "$output" "Project registry not found" "Should report registry not found"
  
  cleanup_test_env
  
  print_test_result 0
}

# Test 7: Remove project with missing directory
test_remove_missing_directory() {
  print_test_header "Test 7: Remove project with missing directory"
  
  setup_test_env
  
  # Delete project directory before removing
  rm -rf "$TEST_PROJECT_DIR"
  
  # Run command
  set +e
  local output
  output=$(bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" test-project -y 2>&1)
  local exit_code=$?
  set -e
  
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "already deleted or moved" "Should note directory missing"
  assert_contains "$output" "Removed from registry: test-project" "Should still remove from registry"
  
  cleanup_test_env
  
  print_test_result 0
}

# Test 8: Timestamp updates
test_timestamp_updates() {
  print_test_header "Test 8: Timestamp updates"
  
  setup_test_env
  
  # Get original timestamp
  yaml_parse "$TEST_REGISTRY"
  local old_timestamp=$(yaml_query ".last_updated")
  
  # Wait a moment to ensure timestamp changes
  sleep 1
  
  # Remove project
  bash "${PROJECT_ROOT}/agent/scripts/acp.project-remove.sh" test-project -y > /dev/null 2>&1
  
  # Check timestamp updated
  yaml_parse "$TEST_REGISTRY"
  local new_timestamp=$(yaml_query ".last_updated")
  
  assert_not_equals "$old_timestamp" "$new_timestamp" "Timestamp should be updated"
  
  cleanup_test_env
  
  print_test_result 0
}

# Run all tests
main() {
  print_suite_header "ACP Project Remove E2E Tests"
  
  test_remove_registry_only
  test_remove_with_delete
  test_remove_non_current
  test_project_not_found
  test_no_arguments
  test_registry_not_found
  test_remove_missing_directory
  test_timestamp_updates
  
  print_suite_summary
}

# Run tests
main
