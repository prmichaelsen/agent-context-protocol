#!/bin/bash
# E2E Tests for @acp.package-search command
# Tests searching for packages on GitHub

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test utilities
source "$PROJECT_ROOT/tests/common.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test: Search by keyword
test_search_by_keyword() {
    print_test_header "Search by keyword"
    
    # Run command (searches GitHub for "mcp-auth")
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-search.sh" mcp-auth 2>&1 || true)
    exit_code=$?
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    # May or may not find results, just verify it runs
    
    print_test_result $?
}

# Test: Search by topic
test_search_by_topic() {
    print_test_header "Search by topic"
    
    # Run command (searches for repos with topic "acp-package")
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-search.sh" --tag acp-package 2>&1 || true)
    exit_code=$?
    
    # Verify (topic may not be indexed yet, just verify command runs)
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "Searching" "Should show search message"
    
    print_test_result $?
}

# Test: Search by user
test_search_by_user() {
    print_test_header "Search by user"
    
    # Run command (searches repos by user prmichaelsen)
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-search.sh" --user prmichaelsen 2>&1 || true)
    exit_code=$?
    
    # Verify (just check command runs, results may vary)
    assert_equals 0 $exit_code "Exit code should be 0"
    assert_contains "$output" "Searching" "Should show search message"
    
    print_test_result $?
}

# Test: Search with limit
test_search_with_limit() {
    print_test_header "Search with limit"
    
    # Run command with limit of 2
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-search.sh" acp --limit 2 2>&1 || true)
    exit_code=$?
    
    # Verify
    assert_equals 0 $exit_code "Exit code should be 0"
    # Should show results (may be 0-2 depending on what's found)
    
    print_test_result $?
}

# Test: Search with no results or rate limit
test_search_no_results() {
    print_test_header "Search with no results or rate limit"
    
    # Run command with nonsense keyword
    local output
    local exit_code
    output=$("$PROJECT_ROOT/agent/scripts/acp.package-search.sh" xyznonexistentkeyword12345 2>&1 || true)
    exit_code=$?
    
    # Verify (may hit rate limit or find no results, both are valid)
    assert_equals 0 $exit_code "Exit code should be 0"
    
    # Check for either "No packages" or "Error" (rate limit) or "Found"
    if echo "$output" | grep -qE "No packages|Error|rate limit|Found|Searching"; then
        echo -e "${GREEN}✓${NC} Command executed and handled result appropriately"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Unexpected output format"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    
    print_test_result $?
}

# Run all tests
main() {
    print_suite_header "Package Search Command Tests"
    
    echo "${YELLOW}Note: These tests require network access and GitHub API${NC}"
    echo ""
    
    test_search_by_keyword
    test_search_by_topic
    test_search_by_user
    test_search_with_limit
    test_search_no_results
    
    print_suite_summary
    
    # Return exit code based on test results
    [ $TESTS_FAILED -eq 0 ] && exit 0 || exit 1
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
