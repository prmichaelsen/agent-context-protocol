#!/bin/bash
# E2E Tests for @acp.package-create command - Path Logic Tests
# Tests target directory path handling without full package creation

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test utilities
source "$PROJECT_ROOT/tests/common.sh"

echo "Testing: acp.package-create (path logic)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test the path logic directly (extracted from acp.package-create.sh)
test_path_logic() {
    local package_name="$1"
    local target_input="$2"
    local target_dir="$target_input"
    
    # Expand ~ to home directory
    target_dir="${target_dir/#\~/$HOME}"
    # Expand $HOME
    target_dir=$(eval echo "$target_dir")
    
    # If target ends with / or is a common parent directory, append acp-{package-name}
    if [[ "$target_dir" == */ ]] || [[ "$target_dir" == */projects ]] || [[ "$target_dir" == */packages ]]; then
        # Remove trailing slash if present
        target_dir="${target_dir%/}"
        # Append package name with prefix
        target_dir="${target_dir}/acp-${package_name}"
    fi
    
    echo "$target_dir"
}

# Test 1: Trailing slash appends acp- prefix
print_test_header "Trailing slash appends acp- prefix"

result=$(test_path_logic "my-package" "/tmp/test/")
expected="/tmp/test/acp-my-package"
assert_equals "$result" "$expected" "Path with trailing slash"

# Test 2: No trailing slash uses exact path
print_test_header "No trailing slash uses exact path"

result=$(test_path_logic "my-package" "/tmp/test/custom-name")
expected="/tmp/test/custom-name"
assert_equals "$result" "$expected" "Path without trailing slash"

# Test 3: Tilde expansion with trailing slash
print_test_header "Tilde expansion with trailing slash"

result=$(test_path_logic "my-package" "~/projects/")
expected="$HOME/projects/acp-my-package"
assert_equals "$result" "$expected" "Tilde expansion with trailing slash"

# Test 4: Tilde expansion without trailing slash
print_test_header "Tilde expansion without trailing slash"

result=$(test_path_logic "my-package" "~/projects/custom")
expected="$HOME/projects/custom"
assert_equals "$result" "$expected" "Tilde expansion without trailing slash"

# Test 5: $HOME variable expansion
print_test_header "\$HOME variable expansion"

result=$(test_path_logic "my-package" "\$HOME/.acp/projects/")
expected="$HOME/.acp/projects/acp-my-package"
assert_equals "$result" "$expected" "\$HOME expansion with trailing slash"

# Test 6: Parent directory without trailing slash (projects)
print_test_header "Parent directory 'projects' without trailing slash"

result=$(test_path_logic "my-package" "~/.acp/projects")
expected="$HOME/.acp/projects/acp-my-package"
assert_equals "$result" "$expected" "Parent dir 'projects' appends prefix"

# Test 7: Parent directory without trailing slash (packages)
print_test_header "Parent directory 'packages' without trailing slash"

result=$(test_path_logic "my-package" "~/.acp/packages")
expected="$HOME/.acp/packages/acp-my-package"
assert_equals "$result" "$expected" "Parent dir 'packages' appends prefix"

print_test_summary
