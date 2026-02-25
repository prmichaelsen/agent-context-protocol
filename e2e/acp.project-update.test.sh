#!/bin/bash
# E2E tests for acp.project-update.sh
# Tests project metadata update functionality

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Test setup
setup_test_env() {
  TEST_DIR=$(mktemp -d)
  TEST_REGISTRY="${TEST_DIR}/projects.yaml"
  
  # Create test registry
  cat > "$TEST_REGISTRY" << 'EOF'
current_project: test-project-1

projects:
  test-project-1:
    path: ~/.acp/projects/test-project-1
    type: mcp-server
    description: Original description
    created: 2026-02-25T10:00:00Z
    last_modified: 2026-02-25T11:00:00Z
    last_accessed: 2026-02-25T12:00:00Z
    status: active
    tags:
      - test
      - mcp
    related_projects:
      - test-project-2

registry_version: 1.0.0
last_updated: 2026-02-25T12:00:00Z
EOF
  
  # Mock get_projects_registry_path to return test registry
  export TEST_REGISTRY
}

# Test cleanup
cleanup_test_env() {
  rm -rf "$TEST_DIR"
  unset TEST_REGISTRY
}

# Override get_projects_registry_path for testing
get_projects_registry_path() {
  echo "$TEST_REGISTRY"
}
export -f get_projects_registry_path

# Run tests
run_tests() {
  echo "Running E2E tests for acp.project-update.sh..."
  echo ""
  
  # Test 1: Update status
  test_case "Update project status"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --status archived 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Updated status: archived" "Should confirm status update"
  assert_contains "$output" "Updates applied: 1" "Should show 1 update"
  # Verify in registry
  source "${PROJECT_ROOT}/agent/scripts/acp.yaml-parser.sh"
  yaml_parse "$TEST_REGISTRY"
  new_status=$(yaml_query ".projects.test-project-1.status")
  assert_equals "archived" "$new_status" "Status should be updated in registry"
  cleanup_test_env
  
  # Test 2: Update description
  test_case "Update project description"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --description "New description" 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Updated description" "Should confirm description update"
  cleanup_test_env
  
  # Test 3: Add tag
  test_case "Add tag to project"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --add-tag production 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Added tag: production" "Should confirm tag added"
  cleanup_test_env
  
  # Test 4: Add duplicate tag
  test_case "Add duplicate tag (should skip)"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --add-tag test 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Tag already exists: test" "Should detect duplicate"
  cleanup_test_env
  
  # Test 5: Remove tag
  test_case "Remove tag from project"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --remove-tag test 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Removed tag: test" "Should confirm tag removed"
  cleanup_test_env
  
  # Test 6: Multiple updates
  test_case "Multiple updates in single command"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --status paused --add-tag critical --type cli-tool 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Updated status: paused" "Should update status"
  assert_contains "$output" "Added tag: critical" "Should add tag"
  assert_contains "$output" "Updated type: cli-tool" "Should update type"
  assert_contains "$output" "Updates applied: 3" "Should show 3 updates"
  cleanup_test_env
  
  # Test 7: Invalid status value
  test_case "Invalid status value"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --status invalid 2>&1)
  exit_code=$?
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "Invalid status" "Should show error"
  assert_contains "$output" "Valid values: active, archived, paused" "Should show valid values"
  cleanup_test_env
  
  # Test 8: No updates specified
  test_case "No updates specified"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 2>&1)
  exit_code=$?
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "No updates specified" "Should show error"
  cleanup_test_env
  
  # Test 9: Project not found
  test_case "Project not found in registry"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" nonexistent --status active 2>&1)
  exit_code=$?
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "not found in registry" "Should show error"
  cleanup_test_env
  
  # Test 10: No project name provided
  test_case "No project name provided"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" --status active 2>&1)
  exit_code=$?
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "Project name required" "Should show error"
  cleanup_test_env
  
  # Test 11: Add related project
  test_case "Add related project"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --add-related test-project-3 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Added related project: test-project-3" "Should confirm addition"
  cleanup_test_env
  
  # Test 12: Remove related project
  test_case "Remove related project"
  setup_test_env
  output=$("${PROJECT_ROOT}/agent/scripts/acp.project-update.sh" test-project-1 --remove-related test-project-2 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Removed related project: test-project-2" "Should confirm removal"
  cleanup_test_env
  
  # Print summary
  print_test_summary
}

# Execute tests
run_tests
