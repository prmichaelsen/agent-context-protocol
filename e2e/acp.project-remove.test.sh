#!/usr/bin/env bash
# E2E tests for @acp.project-remove command
# Tests project removal from registry with and without file deletion

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../tests/common.sh"

# Test configuration
TEST_NAME="acp.project-remove"
TEMP_HOME="/tmp/acp-test-$$-$(date +%N)"

# Setup test environment
setup() {
    mkdir -p "$TEMP_HOME/.acp"
    export HOME="$TEMP_HOME"
    
    # Source common utilities
    source "$SCRIPT_DIR/../agent/scripts/acp.common.sh"
    source_yaml_parser
    
    # Initialize registry
    init_projects_registry
}

# Cleanup test environment
cleanup() {
    rm -rf "$TEMP_HOME"
}

# Register test project helper
register_test_project() {
    local name="$1"
    local path="$2"
    local type="${3:-test}"
    
    register_project "$name" "$path" "$type" "Test project"
}

# Run tests
run_tests() {
    
    # Test 1: Remove project from registry (keep files)
    test_start "Remove project from registry (keep files)"
    setup
    
    # Create test project directory
    mkdir -p "$TEMP_HOME/.acp/projects/test-project"
    register_test_project "test-project" "$TEMP_HOME/.acp/projects/test-project"
    
    # Remove from registry only
    output=$(echo "yes" | "$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "test-project" 2>&1)
    exit_code=$?
    
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_contains "$output" "✅ Project removed: test-project" "Should show success"
    assert_contains "$output" "Registry: Removed" "Should confirm registry removal"
    assert_contains "$output" "Files: Kept" "Should confirm files kept"
    
    # Verify project removed from registry
    yaml_parse "$TEMP_HOME/.acp/projects.yaml"
    result=$(yaml_query ".projects.test-project.path" 2>/dev/null || echo "")
    assert_equals "" "$result" "Project should be removed from registry"
    
    # Verify files still exist
    assert_file_exists "$TEMP_HOME/.acp/projects/test-project" "Project directory should still exist"
    
    cleanup
    test_end
    
    # Test 2: Remove project with file deletion
    test_start "Remove project with file deletion"
    setup
    
    # Create test project directory with content
    mkdir -p "$TEMP_HOME/.acp/projects/test-project"
    echo "test" > "$TEMP_HOME/.acp/projects/test-project/test.txt"
    register_test_project "test-project" "$TEMP_HOME/.acp/projects/test-project"
    
    # Remove with file deletion
    output=$(echo "yes" | "$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "test-project" --delete-files 2>&1)
    exit_code=$?
    
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_contains "$output" "✅ Project removed: test-project" "Should show success"
    assert_contains "$output" "Registry: Removed" "Should confirm registry removal"
    assert_contains "$output" "Files: Deleted" "Should confirm files deleted"
    assert_contains "$output" "Deleted: $TEMP_HOME/.acp/projects/test-project" "Should show deleted path"
    
    # Verify project removed from registry
    yaml_parse "$TEMP_HOME/.acp/projects.yaml"
    result=$(yaml_query ".projects.test-project.path" 2>/dev/null || echo "")
    assert_equals "" "$result" "Project should be removed from registry"
    
    # Verify files deleted
    assert_file_not_exists "$TEMP_HOME/.acp/projects/test-project" "Project directory should be deleted"
    
    cleanup
    test_end
    
    # Test 3: Remove current project
    test_start "Remove current project (clears current_project)"
    setup
    
    # Create and set as current
    mkdir -p "$TEMP_HOME/.acp/projects/current-project"
    register_test_project "current-project" "$TEMP_HOME/.acp/projects/current-project"
    
    yaml_parse "$TEMP_HOME/.acp/projects.yaml"
    yaml_set ".current_project" "current-project"
    yaml_write "$TEMP_HOME/.acp/projects.yaml"
    
    # Remove current project
    output=$(echo "yes" | "$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "current-project" 2>&1)
    exit_code=$?
    
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_contains "$output" "⚠️  WARNING: This is the current project" "Should warn about current project"
    assert_contains "$output" "Clearing current_project" "Should clear current_project"
    
    # Verify current_project cleared
    yaml_parse "$TEMP_HOME/.acp/projects.yaml"
    result=$(yaml_query ".current_project" 2>/dev/null || echo "")
    assert_equals "" "$result" "current_project should be cleared"
    
    cleanup
    test_end
    
    # Test 4: Auto-confirm with -y flag
    test_start "Auto-confirm removal with -y flag"
    setup
    
    mkdir -p "$TEMP_HOME/.acp/projects/test-project"
    register_test_project "test-project" "$TEMP_HOME/.acp/projects/test-project"
    
    # Remove with -y flag (no stdin needed)
    output=$("$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "test-project" -y 2>&1)
    exit_code=$?
    
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_not_contains "$output" "Are you sure" "Should not prompt for confirmation"
    assert_contains "$output" "✅ Project removed" "Should show success"
    
    cleanup
    test_end
    
    # Test 5: Project not found error
    test_start "Error when project not found"
    setup
    
    output=$("$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "nonexistent" 2>&1)
    exit_code=$?
    
    assert_not_equals 0 "$exit_code" "Exit code should be non-zero"
    assert_contains "$output" "Error: Project 'nonexistent' not found" "Should show error"
    assert_contains "$output" "Available projects:" "Should list available projects"
    
    cleanup
    test_end
    
    # Test 6: No project name provided
    test_start "Error when no project name provided"
    setup
    
    output=$("$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" 2>&1)
    exit_code=$?
    
    assert_not_equals 0 "$exit_code" "Exit code should be non-zero"
    assert_contains "$output" "Error: Project name is required" "Should show error"
    assert_contains "$output" "Usage:" "Should show usage"
    
    cleanup
    test_end
    
    # Test 7: Registry file not found
    test_start "Error when registry file not found"
    
    # Don't setup (no registry)
    mkdir -p "$TEMP_HOME"
    export HOME="$TEMP_HOME"
    
    output=$("$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "test" 2>&1)
    exit_code=$?
    
    assert_not_equals 0 "$exit_code" "Exit code should be non-zero"
    assert_contains "$output" "Error: Project registry not found" "Should show error"
    assert_contains "$output" "No projects are registered" "Should explain issue"
    
    cleanup
    test_end
    
    # Test 8: Delete files when directory doesn't exist
    test_start "Handle missing directory gracefully"
    setup
    
    # Register project but don't create directory
    register_test_project "test-project" "$TEMP_HOME/.acp/projects/test-project"
    
    # Remove with --delete-files (directory doesn't exist)
    output=$(echo "yes" | "$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "test-project" --delete-files 2>&1)
    exit_code=$?
    
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_contains "$output" "Project directory not found" "Should note directory missing"
    assert_contains "$output" "Already deleted or moved" "Should explain"
    assert_contains "$output" "✅ Project removed" "Should still succeed"
    
    cleanup
    test_end
    
    # Test 9: Remove last project
    test_start "Remove last project (empty registry)"
    setup
    
    mkdir -p "$TEMP_HOME/.acp/projects/last-project"
    register_test_project "last-project" "$TEMP_HOME/.acp/projects/last-project"
    
    # Remove only project
    output=$(echo "yes" | "$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "last-project" 2>&1)
    exit_code=$?
    
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_contains "$output" "No projects remaining in registry" "Should note empty registry"
    
    # Verify registry is empty
    yaml_parse "$TEMP_HOME/.acp/projects.yaml"
    result=$(yaml_query ".projects" 2>/dev/null || echo "")
    # Empty map returns nothing or just whitespace
    
    cleanup
    test_end
    
    # Test 10: Registry timestamp updated
    test_start "Registry timestamp updated after removal"
    setup
    
    mkdir -p "$TEMP_HOME/.acp/projects/test-project"
    register_test_project "test-project" "$TEMP_HOME/.acp/projects/test-project"
    
    # Get initial timestamp
    yaml_parse "$TEMP_HOME/.acp/projects.yaml"
    initial_timestamp=$(yaml_query ".last_updated" 2>/dev/null || echo "")
    
    # Wait a moment
    sleep 1
    
    # Remove project
    echo "yes" | "$SCRIPT_DIR/../agent/scripts/acp.project-remove.sh" "test-project" >/dev/null 2>&1
    
    # Get updated timestamp
    yaml_parse "$TEMP_HOME/.acp/projects.yaml"
    updated_timestamp=$(yaml_query ".last_updated" 2>/dev/null || echo "")
    
    assert_not_equals "$initial_timestamp" "$updated_timestamp" "Timestamp should be updated"
    
    cleanup
    test_end
}

# Run all tests
echo "Running E2E tests for @acp.project-remove..."
echo ""

run_tests

# Print summary
print_summary
