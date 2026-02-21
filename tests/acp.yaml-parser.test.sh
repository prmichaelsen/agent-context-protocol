#!/bin/bash
# Test suite for acp.yaml-parser.sh - Generic YAML Parser with AST
# Tests lexer, parser, AST construction, and query engine

set -e

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "${SCRIPT_DIR}/tests/common.sh"

# Source the YAML parser
. "${SCRIPT_DIR}/agent/scripts/acp.yaml-parser.sh"

# Create test YAML files
setup_test_files() {
    mkdir -p test/yaml-parser-fixtures
    
    # Simple YAML
    cat > test/yaml-parser-fixtures/simple.yaml << 'EOF'
name: test-package
version: 1.0.0
description: Test package
author: Test Author
EOF
    
    # Nested YAML
    cat > test/yaml-parser-fixtures/nested.yaml << 'EOF'
project:
  name: test-project
  version: 1.0.0
  metadata:
    author: Test Author
    license: MIT
EOF
    
    # Simple array YAML
    cat > test/yaml-parser-fixtures/array.yaml << 'EOF'
tags:
  - tag1
  - tag2
  - tag3
EOF
    
    # Object array YAML
    cat > test/yaml-parser-fixtures/object-array.yaml << 'EOF'
contents:
  patterns:
    - name: namespace.pattern1.md
      version: 1.0.0
    - name: namespace.pattern2.md
      version: 1.1.0
  commands:
    - name: namespace.command1.md
      version: 2.0.0
EOF
    
    # Complex nested structure
    cat > test/yaml-parser-fixtures/complex.yaml << 'EOF'
project:
  name: complex-project
  version: 2.5.0
  metadata:
    author: Complex Author
    tags:
      - production
      - stable
  dependencies:
    - name: dep1
      version: 1.0.0
    - name: dep2
      version: 2.0.0
EOF
    
    # Mixed structure
    cat > test/yaml-parser-fixtures/mixed.yaml << 'EOF'
name: mixed
version: 1.0.0
tags:
  - tag1
  - tag2
config:
  enabled: true
  timeout: 30
items:
  - name: item1
    value: 100
  - name: item2
    value: 200
EOF
}

# Cleanup test files
cleanup_test_files() {
    rm -rf tests/fixtures
}

# Test Suite
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Generic YAML Parser with AST - Test Suite${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Setup
setup_test_files

# ============================================================================
# Test Group 1: Simple Key-Value Pairs
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 1: Simple Key-Value Pairs${NC}"
echo ""

yaml_parse "tests/fixtures/simple.yaml"
result=$(yaml_query ".name")
assert_equals "test-package" "$result" "Query simple key: .name"

result=$(yaml_query ".version")
assert_equals "1.0.0" "$result" "Query simple key: .version"

result=$(yaml_query ".description")
assert_equals "Test package" "$result" "Query simple key: .description"

result=$(yaml_query ".author")
assert_equals "Test Author" "$result" "Query simple key: .author"

echo ""

# ============================================================================
# Test Group 2: Nested Objects
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 2: Nested Objects${NC}"
echo ""

yaml_parse "tests/fixtures/nested.yaml"
result=$(yaml_query ".project.name")
assert_equals "test-project" "$result" "Query nested key: .project.name"

result=$(yaml_query ".project.version")
assert_equals "1.0.0" "$result" "Query nested key: .project.version"

result=$(yaml_query ".project.metadata.author")
assert_equals "Test Author" "$result" "Query deeply nested: .project.metadata.author"

result=$(yaml_query ".project.metadata.license")
assert_equals "MIT" "$result" "Query deeply nested: .project.metadata.license"

echo ""

# ============================================================================
# Test Group 3: Simple Arrays
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 3: Simple Arrays${NC}"
echo ""

yaml_parse "tests/fixtures/array.yaml"
result=$(yaml_query ".tags[0]")
assert_equals "tag1" "$result" "Query array index: .tags[0]"

result=$(yaml_query ".tags[1]")
assert_equals "tag2" "$result" "Query array index: .tags[1]"

result=$(yaml_query ".tags[2]")
assert_equals "tag3" "$result" "Query array index: .tags[2]"

echo ""

# ============================================================================
# Test Group 4: Object Arrays
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 4: Object Arrays${NC}"
echo ""

yaml_parse "tests/fixtures/object-array.yaml"
result=$(yaml_query ".contents.patterns[0].name")
assert_equals "namespace.pattern1.md" "$result" "Query object array: .contents.patterns[0].name"

result=$(yaml_query ".contents.patterns[0].version")
assert_equals "1.0.0" "$result" "Query object array: .contents.patterns[0].version"

result=$(yaml_query ".contents.patterns[1].name")
assert_equals "namespace.pattern2.md" "$result" "Query object array: .contents.patterns[1].name"

result=$(yaml_query ".contents.commands[0].name")
assert_equals "namespace.command1.md" "$result" "Query object array: .contents.commands[0].name"

result=$(yaml_query ".contents.commands[0].version")
assert_equals "2.0.0" "$result" "Query object array: .contents.commands[0].version"

echo ""

# ============================================================================
# Test Group 5: Complex Nested Structures
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 5: Complex Nested Structures${NC}"
echo ""

yaml_parse "tests/fixtures/complex.yaml"
result=$(yaml_query ".project.name")
assert_equals "complex-project" "$result" "Complex: .project.name"

result=$(yaml_query ".project.metadata.author")
assert_equals "Complex Author" "$result" "Complex: .project.metadata.author"

result=$(yaml_query ".project.metadata.tags[0]")
assert_equals "production" "$result" "Complex: .project.metadata.tags[0]"

result=$(yaml_query ".project.metadata.tags[1]")
assert_equals "stable" "$result" "Complex: .project.metadata.tags[1]"

result=$(yaml_query ".project.dependencies[0].name")
assert_equals "dep1" "$result" "Complex: .project.dependencies[0].name"

result=$(yaml_query ".project.dependencies[0].version")
assert_equals "1.0.0" "$result" "Complex: .project.dependencies[0].version"

result=$(yaml_query ".project.dependencies[1].name")
assert_equals "dep2" "$result" "Complex: .project.dependencies[1].name"

echo ""

# ============================================================================
# Test Group 6: Mixed Structures
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 6: Mixed Structures${NC}"
echo ""

yaml_parse "tests/fixtures/mixed.yaml"
result=$(yaml_query ".name")
assert_equals "mixed" "$result" "Mixed: .name"

result=$(yaml_query ".tags[0]")
assert_equals "tag1" "$result" "Mixed: .tags[0]"

result=$(yaml_query ".config.enabled")
assert_equals "true" "$result" "Mixed: .config.enabled"

result=$(yaml_query ".config.timeout")
assert_equals "30" "$result" "Mixed: .config.timeout"

result=$(yaml_query ".items[0].name")
assert_equals "item1" "$result" "Mixed: .items[0].name"

result=$(yaml_query ".items[0].value")
assert_equals "100" "$result" "Mixed: .items[0].value"

result=$(yaml_query ".items[1].name")
assert_equals "item2" "$result" "Mixed: .items[1].name"

echo ""

# ============================================================================
# Test Group 7: Edge Cases
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 7: Edge Cases${NC}"
echo ""

yaml_parse "tests/fixtures/simple.yaml"

# Nonexistent key
result=$(yaml_query ".nonexistent" 2>&1)
assert_empty "$result" "Edge case: nonexistent key returns empty"

# Out of bounds array index
yaml_parse "tests/fixtures/array.yaml"
result=$(yaml_query ".tags[99]" 2>&1)
assert_empty "$result" "Edge case: out of bounds array index returns empty"

# Invalid path
yaml_parse "tests/fixtures/simple.yaml"
result=$(yaml_query ".name.invalid" 2>&1)
assert_empty "$result" "Edge case: invalid nested path returns empty"

echo ""

# ============================================================================
# Test Group 8: Backward Compatibility
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 8: Backward Compatibility${NC}"
echo ""

# Test yaml_get wrapper
result=$(yaml_get "tests/fixtures/simple.yaml" "name")
assert_equals "test-package" "$result" "Backward compat: yaml_get"

# Test yaml_get_nested wrapper
result=$(yaml_get_nested "tests/fixtures/nested.yaml" "project.metadata.author")
assert_equals "Test Author" "$result" "Backward compat: yaml_get_nested"

result=$(yaml_get_nested "tests/fixtures/object-array.yaml" "contents.patterns[0].name")
assert_equals "namespace.pattern1.md" "$result" "Backward compat: yaml_get_nested with array"

echo ""

# ============================================================================
# Test Group 9: Update Operations (yaml_set)
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 9: Update Operations${NC}"
echo ""

# Create test file for updates
cp tests/fixtures/simple.yaml tests/fixtures/update-test.yaml

yaml_parse "tests/fixtures/update-test.yaml"
yaml_set ".version" "2.0.0"
result=$(yaml_query ".version")
assert_equals "2.0.0" "$result" "Update: yaml_set changes value in AST"

# Write back and verify
yaml_write "tests/fixtures/update-test.yaml"
yaml_parse "tests/fixtures/update-test.yaml"
result=$(yaml_query ".version")
assert_equals "2.0.0" "$result" "Update: yaml_write persists changes to file"

rm tests/fixtures/update-test.yaml

echo ""

# ============================================================================
# Test Group 10: Performance Tests
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 10: Performance Tests${NC}"
echo ""

# Parse time test
start_time=$(date +%s%N)
yaml_parse "tests/fixtures/complex.yaml"
end_time=$(date +%s%N)
parse_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

echo -e "  Parse time: ${YELLOW}${parse_time}ms${NC}"
if [ "$parse_time" -lt 1000 ]; then
    echo -e "${GREEN}✓${NC} Parse performance acceptable (< 1s)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Parse performance too slow (>= 1s)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Query time test (multiple queries on same AST)
start_time=$(date +%s%N)
for i in 1 2 3 4 5 6 7 8 9 10; do
    yaml_query ".project.name" > /dev/null
done
end_time=$(date +%s%N)
query_time=$(( (end_time - start_time) / 10000000 ))  # Average per query in ms

echo -e "  Query time (avg): ${YELLOW}${query_time}ms${NC}"
if [ "$query_time" -lt 100 ]; then
    echo -e "${GREEN}✓${NC} Query performance acceptable (< 100ms)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Query performance too slow (>= 100ms)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================================
# Test Group 11: AST Structure Tests
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 11: AST Structure Tests${NC}"
echo ""

yaml_parse "tests/fixtures/simple.yaml"
assert_not_empty "$AST_NODES" "AST: Nodes created"
assert_not_empty "$AST_NODE_COUNT" "AST: Node count tracked"
assert_not_empty "$AST_ROOT_ID" "AST: Root ID set"

# Check node count is reasonable
if [ "$AST_NODE_COUNT" -ge 4 ]; then
    echo -e "${GREEN}✓${NC} AST: Node count reasonable (>= 4 for simple.yaml)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} AST: Node count too low (< 4)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================================
# Test Group 12: Utility Functions
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 12: Utility Functions${NC}"
echo ""

# Test get_indent_level
result=$(get_indent_level "  key: value")
assert_equals "2" "$result" "Util: get_indent_level with 2 spaces"

result=$(get_indent_level "    key: value")
assert_equals "4" "$result" "Util: get_indent_level with 4 spaces"

result=$(get_indent_level "key: value")
assert_equals "0" "$result" "Util: get_indent_level with no indent"

# Test strip_comments
result=$(strip_comments "key: value # comment")
assert_equals "key: value " "$result" "Util: strip_comments removes comment"

result=$(strip_comments "key: value")
assert_equals "key: value" "$result" "Util: strip_comments preserves line without comment"

# Test trim
result=$(trim "  value  ")
assert_equals "value" "$result" "Util: trim removes whitespace"

# Test is_array_item
if is_array_item "  - item"; then
    echo -e "${GREEN}✓${NC} Util: is_array_item detects array item"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Util: is_array_item failed to detect array item"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

if ! is_array_item "key: value"; then
    echo -e "${GREEN}✓${NC} Util: is_array_item rejects non-array"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Util: is_array_item false positive"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# ============================================================================
# Test Group 13: Real-World Package.yaml
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 13: Real-World package.yaml${NC}"
echo ""

# Create realistic package.yaml
cat > tests/fixtures/package.yaml << 'EOF'
name: acp-firebase
version: 1.2.0
description: Firebase patterns and commands for ACP
author: Test Author
license: MIT
repository: https://github.com/user/acp-firebase.git
homepage: https://github.com/user/acp-firebase
tags:
  - firebase
  - patterns
  - commands
contents:
  patterns:
    - name: firebase.firestore-pattern.md
      version: 1.0.0
    - name: firebase.auth-pattern.md
      version: 1.1.0
  commands:
    - name: firebase.deploy.md
      version: 2.0.0
    - name: firebase.init.md
      version: 1.5.0
  designs:
    - name: firebase.architecture-design.md
      version: 1.0.0
release:
  branch: main
EOF

yaml_parse "tests/fixtures/package.yaml"
result=$(yaml_query ".name")
assert_equals "acp-firebase" "$result" "Real-world: package name"

result=$(yaml_query ".version")
assert_equals "1.2.0" "$result" "Real-world: package version"

result=$(yaml_query ".tags[0]")
assert_equals "firebase" "$result" "Real-world: tags[0]"

result=$(yaml_query ".tags[1]")
assert_equals "patterns" "$result" "Real-world: tags[1]"

result=$(yaml_query ".contents.patterns[0].name")
assert_equals "firebase.firestore-pattern.md" "$result" "Real-world: patterns[0].name"

result=$(yaml_query ".contents.patterns[0].version")
assert_equals "1.0.0" "$result" "Real-world: patterns[0].version"

result=$(yaml_query ".contents.commands[0].name")
assert_equals "firebase.deploy.md" "$result" "Real-world: commands[0].name"

result=$(yaml_query ".contents.designs[0].name")
assert_equals "firebase.architecture-design.md" "$result" "Real-world: designs[0].name"

result=$(yaml_query ".release.branch")
assert_equals "main" "$result" "Real-world: release.branch"

echo ""

# ============================================================================
# Test Group 14: Stress Tests
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 14: Stress Tests${NC}"
echo ""

# Create large YAML file
cat > tests/fixtures/large.yaml << 'EOF'
project:
  name: large-project
  items:
EOF

# Add 50 items
for i in $(seq 1 50); do
    echo "    - name: item$i" >> tests/fixtures/large.yaml
    echo "      value: $i" >> tests/fixtures/large.yaml
done

yaml_parse "tests/fixtures/large.yaml"
result=$(yaml_query ".project.items[0].name")
assert_equals "item1" "$result" "Stress: First item in large array"

result=$(yaml_query ".project.items[49].name")
assert_equals "item50" "$result" "Stress: Last item in large array (50 items)"

result=$(yaml_query ".project.items[25].value")
assert_equals "26" "$result" "Stress: Middle item in large array"

echo ""

# ============================================================================
# Test Group 15: Error Handling
# ============================================================================
echo -e "${BLUE}${BOLD}Test Group 15: Error Handling${NC}"
echo ""

# Test parsing nonexistent file
result=$(yaml_parse "tests/fixtures/nonexistent.yaml" 2>&1)
if echo "$result" | grep -q "Error"; then
    echo -e "${GREEN}✓${NC} Error handling: nonexistent file"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Error handling: should error on nonexistent file"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test query without parse
AST_NODES=""
result=$(yaml_query ".name" 2>&1)
if echo "$result" | grep -q "Error"; then
    echo -e "${GREEN}✓${NC} Error handling: query without parse"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} Error handling: should error when querying without parse"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""

# Cleanup
cleanup_test_files

# ============================================================================
# Summary
# ============================================================================
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Test Results${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_RUN -gt 0 ]; then
    pass_rate=$(( TESTS_PASSED * 100 / TESTS_RUN ))
    echo -e "Pass Rate:    ${YELLOW}${pass_rate}%${NC}"
fi

echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ All tests passed!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}❌ Some tests failed${NC}"
    echo ""
    exit 1
fi
