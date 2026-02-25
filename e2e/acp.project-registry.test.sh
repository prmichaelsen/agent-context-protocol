#!/bin/bash
# E2E tests for acp.project-info.sh and acp.project-update.sh
# Tests project information display and update functionality

set +e  # Don't exit on error in tests

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Test setup
setup_test_env() {
  TEST_DIR=$(mktemp -d)
  TEST_REGISTRY="${TEST_DIR}/projects.yaml"
  
  # Create test registry with proper YAML format
  cat > "$TEST_REGISTRY" << 'EOF'
current_project: test-project-1
projects:
  test-project-1:
    path: ~/.acp/projects/test-project-1
    type: mcp-server
    description: Test project 1 description
    created: 2026-02-25T10:00:00Z
    last_modified: 2026-02-25T11:00:00Z
    last_accessed: 2026-02-25T12:00:00Z
    status: active
    tags:
      - test
      - mcp
    related_projects:
      - test-project-2
    dependencies:
      npm:
        - dependency-1
        - dependency-2
  test-project-2:
    path: ~/.acp/projects/test-project-2
    type: web-app
    description: Test project 2 description
    created: 2026-02-24T10:00:00Z
    last_modified: 2026-02-24T11:00:00Z
    last_accessed: 2026-02-24T12:00:00Z
    status: archived
registry_version: 1.0.0
last_updated: 2026-02-25T12:00:00Z
EOF
  
  export TEST_REGISTRY
}

# Test cleanup
cleanup_test_env() {
  rm -rf "$TEST_DIR"
  unset TEST_REGISTRY
}

# Run tests
run_tests() {
  echo "Running E2E tests for project registry commands..."
  echo ""
  
  # Test 1: project-info with valid project
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test 1: project-info - Show project successfully"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  setup_test_env
  
  # Create wrapper script that overrides get_projects_registry_path
  cat > "${TEST_DIR}/test-info.sh" << EOF
#!/bin/bash
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser
get_projects_registry_path() { echo "$TEST_REGISTRY"; }
source <(sed '1,/^main() {/d; /^main "\$@"/d' "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh")
main "\$@"
EOF
  chmod +x "${TEST_DIR}/test-info.sh"
  
  output=$("${TEST_DIR}/test-info.sh" test-project-1 2>&1)
  exit_code=$?
  
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "test-project-1" "Should show project name"
  assert_contains "$output" "mcp-server" "Should show project type"
  assert_contains "$output" "active" "Should show status"
  assert_contains "$output" "⭐ Current" "Should mark as current project"
  cleanup_test_env
  
  # Test 2: project-info with missing project
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test 2: project-info - Project not found"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  setup_test_env
  
  cat > "${TEST_DIR}/test-info.sh" << EOF
#!/bin/bash
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser
get_projects_registry_path() { echo "$TEST_REGISTRY"; }
source <(sed '1,/^main() {/d; /^main "\$@"/d' "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh")
main "\$@"
EOF
  chmod +x "${TEST_DIR}/test-info.sh"
  
  output=$("${TEST_DIR}/test-info.sh" nonexistent 2>&1)
  exit_code=$?
  
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "not found in registry" "Should show error"
  cleanup_test_env
  
  # Test 3: project-info with no arguments
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test 3: project-info - No arguments"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  setup_test_env
  
  cat > "${TEST_DIR}/test-info.sh" << EOF
#!/bin/bash
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser
get_projects_registry_path() { echo "$TEST_REGISTRY"; }
source <(sed '1,/^main() {/d; /^main "\$@"/d' "${PROJECT_ROOT}/agent/scripts/acp.project-info.sh")
main "\$@"
EOF
  chmod +x "${TEST_DIR}/test-info.sh"
  
  output=$("${TEST_DIR}/test-info.sh" 2>&1)
  exit_code=$?
  
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "Project name required" "Should show error"
  cleanup_test_env
  
  # Test 4: project-update status
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test 4: project-update - Update status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  setup_test_env
  
  cat > "${TEST_DIR}/test-update.sh" << EOF
#!/bin/bash
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser
get_projects_registry_path() { echo "$TEST_REGISTRY"; }
source <(sed '1,/^main() {/d; /^main "\$@"/d' "${PROJECT_ROOT}/agent/scripts/acp.project-update.sh")
main "\$@"
EOF
  chmod +x "${TEST_DIR}/test-update.sh"
  
  output=$("${TEST_DIR}/test-update.sh" test-project-1 --status archived 2>&1)
  exit_code=$?
  
  assert_equals 0 $exit_code "Exit code should be 0"
  assert_contains "$output" "Updated status: archived" "Should confirm update"
  assert_contains "$output" "Updates applied: 1" "Should show 1 update"
  cleanup_test_env
  
  # Test 5: project-update with no updates
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test 5: project-update - No updates specified"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  setup_test_env
  
  cat > "${TEST_DIR}/test-update.sh" << EOF
#!/bin/bash
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser
get_projects_registry_path() { echo "$TEST_REGISTRY"; }
source <(sed '1,/^main() {/d; /^main "\$@"/d' "${PROJECT_ROOT}/agent/scripts/acp.project-update.sh")
main "\$@"
EOF
  chmod +x "${TEST_DIR}/test-update.sh"
  
  output=$("${TEST_DIR}/test-update.sh" test-project-1 2>&1)
  exit_code=$?
  
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "No updates specified" "Should show error"
  cleanup_test_env
  
  # Test 6: project-update invalid status
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test 6: project-update - Invalid status"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  setup_test_env
  
  cat > "${TEST_DIR}/test-update.sh" << EOF
#!/bin/bash
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser
get_projects_registry_path() { echo "$TEST_REGISTRY"; }
source <(sed '1,/^main() {/d; /^main "\$@"/d' "${PROJECT_ROOT}/agent/scripts/acp.project-update.sh")
main "\$@"
EOF
  chmod +x "${TEST_DIR}/test-update.sh"
  
  output=$("${TEST_DIR}/test-update.sh" test-project-1 --status invalid 2>&1)
  exit_code=$?
  
  assert_not_equals 0 $exit_code "Exit code should be non-zero"
  assert_contains "$output" "Invalid status" "Should show error"
  cleanup_test_env
  
  # Print summary
  print_test_summary
}

# Execute tests
run_tests
