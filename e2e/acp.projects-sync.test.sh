#!/usr/bin/env bash
# E2E tests for @acp.projects-sync command

# Note: Don't use set -u in tests due to variable scoping
set -eo pipefail

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../tests/common.sh"

# Source the script under test
PROJECTS_SYNC_SCRIPT="${SCRIPT_DIR}/../agent/scripts/acp.projects-sync.sh"

# Test setup
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    TEST_PROJECTS_DIR="$TEST_DIR/.acp/projects"
    TEST_REGISTRY="$TEST_DIR/.acp/projects.yaml"
    
    mkdir -p "$TEST_PROJECTS_DIR"
    
    # Override HOME for testing
    export HOME="$TEST_DIR"
    
    echo "$TEST_DIR"
}

cleanup_test_env() {
    local test_dir=$1
    rm -rf "$test_dir"
}

# Create a mock ACP project
create_mock_project() {
    local test_projects_dir=$1
    local project_name=$2
    local project_type=${3:-"application"}
    local project_desc=${4:-"Test project"}
    
    local project_dir="$test_projects_dir/$project_name"
    mkdir -p "$project_dir/agent"
    
    cat > "$project_dir/agent/progress.yaml" <<EOF
project:
  name: $project_name
  type: $project_type
  description: $project_desc
  version: 1.0.0
  status: active
EOF
}

# Initialize registry with a project
init_registry_with_project() {
    local test_registry=$1
    local test_projects_dir=$2
    local project_name=$3
    local project_path="$test_projects_dir/$project_name"
    
    cat > "$test_registry" <<EOF
version: 1.0.0
last_updated: 2026-02-26T00:00:00Z
current_project: null

projects:
  $project_name:
    path: $project_path
    type: application
    status: active
    description: Already registered project
    created: 2026-02-26T00:00:00Z
    last_modified: 2026-02-26T00:00:00Z
    last_accessed: 2026-02-26T00:00:00Z
EOF
}

echo "Running @acp.projects-sync E2E tests..."
echo ""

# Test 1: Empty projects directory
test_empty_directory() {
    local test_dir=$(setup_test_env)
    
    # Run sync (should handle empty directory gracefully)
    local output
    output=$(bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 1.1: Exit code should be 0 for empty directory"
    assert_contains "$output" "Scanning for ACP projects" "Test 1.2: Should show scanning message"
    
    cleanup_test_env "$test_dir"
}

# Test 2: Single unregistered project
test_single_unregistered() {
    local test_dir=$(setup_test_env)
    local test_projects_dir="$test_dir/.acp/projects"
    local test_registry="$test_dir/.acp/projects.yaml"
    
    # Create one project
    create_mock_project "$test_projects_dir" "test-project-1" "application" "Test application"
    
    # Run sync with auto-yes (simulate user pressing 'y')
    local output
    output=$(echo "y" | bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 2.1: Exit code should be 0"
    assert_contains "$output" "test-project-1 (not registered)" "Test 2.2: Should show unregistered project"
    assert_contains "$output" "Type: application" "Test 2.3: Should show project type"
    assert_contains "$output" "Description: Test application" "Test 2.4: Should show description"
    assert_contains "$output" "✓ Registered" "Test 2.5: Should show registration success"
    assert_contains "$output" "Found: 1 projects" "Test 2.6: Should count found projects"
    assert_contains "$output" "Registered: 1 new projects" "Test 2.7: Should count registered projects"
    
    # Verify registry was created and updated
    assert_file_exists "$test_registry" "Test 2.8: Registry should exist"
    
    cleanup_test_env "$test_dir"
}

# Test 3: Already registered project
test_already_registered() {
    local test_dir=$(setup_test_env)
    local test_projects_dir="$test_dir/.acp/projects"
    local test_registry="$test_dir/.acp/projects.yaml"
    
    # Create project and register it
    create_mock_project "$test_projects_dir" "registered-project" "application" "Already registered"
    init_registry_with_project "$test_registry" "$test_projects_dir" "registered-project"
    
    # Run sync
    local output
    output=$(bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 3.1: Exit code should be 0"
    assert_contains "$output" "registered-project (already registered)" "Test 3.2: Should show already registered"
    assert_contains "$output" "Found: 1 projects" "Test 3.3: Should count found projects"
    assert_contains "$output" "Registered: 0 new projects" "Test 3.4: Should show 0 new registrations"
    
    cleanup_test_env "$test_dir"
}

# Test 4: Multiple projects (mixed registered/unregistered)
test_mixed_projects() {
    local test_dir=$(setup_test_env)
    local test_projects_dir="$test_dir/.acp/projects"
    local test_registry="$test_dir/.acp/projects.yaml"
    
    # Create 3 projects
    create_mock_project "$test_projects_dir" "project-1" "application" "First project"
    create_mock_project "$test_projects_dir" "project-2" "library" "Second project"
    create_mock_project "$test_projects_dir" "project-3" "tool" "Third project"
    
    # Register project-2
    init_registry_with_project "$test_registry" "$test_projects_dir" "project-2"
    
    # Run sync with auto-yes for both prompts
    local output
    output=$(echo -e "y\ny" | bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 4.1: Exit code should be 0"
    assert_contains "$output" "project-1 (not registered)" "Test 4.2: Should show project-1 unregistered"
    assert_contains "$output" "project-2 (already registered)" "Test 4.3: Should show project-2 registered"
    assert_contains "$output" "project-3 (not registered)" "Test 4.4: Should show project-3 unregistered"
    assert_contains "$output" "Found: 3 projects" "Test 4.5: Should count all projects"
    assert_contains "$output" "Registered: 2 new projects" "Test 4.6: Should count new registrations"
    
    cleanup_test_env "$test_dir"
}

# Test 5: User declines registration
test_decline_registration() {
    local test_dir=$(setup_test_env)
    local test_projects_dir="$test_dir/.acp/projects"
    
    # Create one project
    create_mock_project "$test_projects_dir" "declined-project" "application" "Will be declined"
    
    # Run sync with 'n' (decline)
    local output
    output=$(echo "n" | bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 5.1: Exit code should be 0"
    assert_contains "$output" "declined-project (not registered)" "Test 5.2: Should show unregistered"
    assert_contains "$output" "⊘ Skipped" "Test 5.3: Should show skipped"
    assert_contains "$output" "Registered: 0 new projects" "Test 5.4: Should show 0 registrations"
    
    cleanup_test_env "$test_dir"
}

# Test 6: Non-ACP directories (no progress.yaml)
test_non_acp_directories() {
    local test_dir=$(setup_test_env)
    local test_projects_dir="$test_dir/.acp/projects"
    
    # Create directories without progress.yaml
    mkdir -p "$test_projects_dir/not-acp-1"
    mkdir -p "$test_projects_dir/not-acp-2"
    
    # Create one valid ACP project
    create_mock_project "$test_projects_dir" "valid-project" "application" "Valid ACP project"
    
    # Run sync with auto-yes
    local output
    output=$(echo "y" | bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 6.1: Exit code should be 0"
    assert_not_contains "$output" "not-acp-1" "Test 6.2: Should not show non-ACP directory 1"
    assert_not_contains "$output" "not-acp-2" "Test 6.3: Should not show non-ACP directory 2"
    assert_contains "$output" "valid-project" "Test 6.4: Should show valid ACP project"
    assert_contains "$output" "Found: 1 projects" "Test 6.5: Should count only ACP projects"
    
    cleanup_test_env "$test_dir"
}

# Test 7: Malformed progress.yaml (missing fields)
test_malformed_progress() {
    local test_dir=$(setup_test_env)
    local test_projects_dir="$test_dir/.acp/projects"
    
    # Create project with minimal progress.yaml
    local project_dir="$test_projects_dir/minimal-project"
    mkdir -p "$project_dir/agent"
    echo "project:" > "$project_dir/agent/progress.yaml"
    
    # Run sync with auto-yes
    local output
    output=$(echo "y" | bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 7.1: Exit code should be 0"
    assert_contains "$output" "minimal-project (not registered)" "Test 7.2: Should show project"
    assert_contains "$output" "Type: unknown" "Test 7.3: Should use default type"
    assert_contains "$output" "Description: No description" "Test 7.4: Should use default description"
    assert_contains "$output" "✓ Registered" "Test 7.5: Should register with defaults"
    
    cleanup_test_env "$test_dir"
}

# Test 8: Registry auto-initialization
test_registry_auto_init() {
    local test_dir=$(setup_test_env)
    local test_projects_dir="$test_dir/.acp/projects"
    local test_registry="$test_dir/.acp/projects.yaml"
    
    # Create project but no registry
    create_mock_project "$test_projects_dir" "first-project" "application" "First project"
    
    # Verify registry doesn't exist
    assert_file_not_exists "$test_registry" "Test 8.1: Registry should not exist initially"
    
    # Run sync with auto-yes
    local output
    output=$(echo "y" | bash "$PROJECTS_SYNC_SCRIPT" 2>&1 || true)
    local exit_code=$?
    
    assert_equals 0 "$exit_code" "Test 8.2: Exit code should be 0"
    assert_contains "$output" "Initialized projects registry" "Test 8.3: Should show initialization"
    assert_file_exists "$test_registry" "Test 8.4: Registry should be created"
    
    cleanup_test_env "$test_dir"
}

# Run all tests
test_empty_directory
test_single_unregistered
test_already_registered
test_mixed_projects
test_decline_registration
test_non_acp_directories
test_malformed_progress
test_registry_auto_init

echo ""
echo "All @acp.projects-sync tests completed!"
print_test_summary
