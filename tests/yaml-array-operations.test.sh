#!/bin/bash
# Unit tests for YAML array operations
# Tests yaml_array_append functionality

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Source YAML parser
source "${PROJECT_ROOT}/agent/scripts/acp.yaml-parser.sh"

# Run tests
run_tests() {
  echo "Running unit tests for YAML array operations..."
  echo ""
  
  # Test 1: Append to empty array
  test_case "Append to empty array"
  TEST_FILE=$(mktemp)
  cat > "$TEST_FILE" << 'EOF'
tags: []
EOF
  yaml_parse "$TEST_FILE"
  result=$(yaml_array_append ".tags" "production" 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Should succeed appending to empty array"
  yaml_write "$TEST_FILE"
  value=$(yaml_query ".tags[0]")
  assert_equals "production" "$value" "Should have added value to array"
  rm -f "$TEST_FILE"
  
  # Test 2: Append to array with existing items
  test_case "Append to array with existing items"
  TEST_FILE=$(mktemp)
  cat > "$TEST_FILE" << 'EOF'
tags:
  - test
  - mcp
EOF
  yaml_parse "$TEST_FILE"
  result=$(yaml_array_append ".tags" "production" 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Should succeed appending to existing array"
  yaml_write "$TEST_FILE"
  value=$(yaml_query ".tags[2]")
  assert_equals "production" "$value" "Should have added value at index 2"
  rm -f "$TEST_FILE"
  
  # Test 3: Append to nested empty array
  test_case "Append to nested empty array"
  TEST_FILE=$(mktemp)
  cat > "$TEST_FILE" << 'EOF'
projects:
  test-project:
    tags: []
EOF
  yaml_parse "$TEST_FILE"
  result=$(yaml_array_append ".projects.test-project.tags" "production" 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Should succeed appending to nested empty array"
  yaml_write "$TEST_FILE"
  value=$(yaml_query ".projects.test-project.tags[0]")
  assert_equals "production" "$value" "Should have added value to nested array"
  rm -f "$TEST_FILE"
  
  # Test 4: Append to non-existent field (should fail)
  test_case "Append to non-existent field"
  TEST_FILE=$(mktemp)
  cat > "$TEST_FILE" << 'EOF'
name: test
EOF
  yaml_parse "$TEST_FILE"
  result=$(yaml_array_append ".tags" "production" 2>&1)
  exit_code=$?
  assert_not_equals 0 $exit_code "Should fail when field doesn't exist"
  rm -f "$TEST_FILE"
  
  # Test 5: Append to scalar field (should fail)
  test_case "Append to scalar field"
  TEST_FILE=$(mktemp)
  cat > "$TEST_FILE" << 'EOF'
name: test
EOF
  yaml_parse "$TEST_FILE"
  result=$(yaml_array_append ".name" "production" 2>&1)
  exit_code=$?
  assert_not_equals 0 $exit_code "Should fail when field is scalar"
  assert_contains "$result" "does not point to an array" "Should show appropriate error"
  rm -f "$TEST_FILE"
  
  # Test 6: Create array with yaml_set then append
  test_case "Create array with yaml_set then append"
  TEST_FILE=$(mktemp)
  cat > "$TEST_FILE" << 'EOF'
name: test
EOF
  yaml_parse "$TEST_FILE"
  yaml_set ".tags" "[]"
  result=$(yaml_array_append ".tags" "production" 2>&1)
  exit_code=$?
  assert_equals 0 $exit_code "Should succeed appending to array created with yaml_set"
  yaml_write "$TEST_FILE"
  value=$(yaml_query ".tags[0]")
  assert_equals "production" "$value" "Should have added value to created array"
  rm -f "$TEST_FILE"
  
  # Print summary
  print_test_summary
}

# Execute tests
run_tests
