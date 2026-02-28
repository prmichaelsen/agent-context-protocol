#!/usr/bin/env bash
# E2E Tests for template file installation (contents.files with target paths, variables)
# Tests that files declared in contents.files install to correct targets with variable substitution
# Note: Not using set -euo pipefail due to YAML parser AST cleanup issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$PROJECT_ROOT/tests/common.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

INSTALL_SCRIPT="$PROJECT_ROOT/agent/scripts/acp.package-install.sh"

# Create a test package with contents.files metadata (target paths, variables, experimental)
create_template_package() {
    local pkg_dir="$1"
    mkdir -p "$pkg_dir/agent"/{commands,patterns,files/config,files/src/schemas}

    cat > "$pkg_dir/package.yaml" <<'YAML'
name: test-templates
version: 1.0.0
description: Test package for template file features
author: Test Author
license: MIT
repository: https://github.com/test/test-templates.git

contents:
  commands:
    - name: test-templates.hello.md
      description: Hello command
      scripts: []

  files:
    - name: config/tsconfig.json
      description: TypeScript config for testing purposes
      target: ./
      required: true

    - name: config/settings.json.template
      description: Settings file with variable substitution
      target: config/
      required: false
      variables:
        - PROJECT_NAME
        - AUTHOR_NAME

    - name: src/schemas/example.schema.ts
      description: Example schema for data validation layer
      target: src/schemas/
      required: false

    - name: config/experimental.json
      description: Experimental config for early testing features
      target: ./
      required: false
      experimental: true
YAML

    # Create command
    cat > "$pkg_dir/agent/commands/test-templates.hello.md" <<'MD'
# Command: hello

> **🤖 Agent Directive**: Test command

**Namespace**: test-templates
**Version**: 1.0.0
**Status**: Active
**Scripts**: None

---

**Purpose**: A hello command for testing
MD

    # Create template files
    echo '{"compilerOptions": {"target": "ES2022"}}' > "$pkg_dir/agent/files/config/tsconfig.json"
    cat > "$pkg_dir/agent/files/config/settings.json.template" <<'TMPL'
{
  "name": "{{PROJECT_NAME}}",
  "author": "{{AUTHOR_NAME}}",
  "version": "1.0.0"
}
TMPL
    echo 'export const ExampleSchema = {}' > "$pkg_dir/agent/files/src/schemas/example.schema.ts"
    echo '{"experimental": true}' > "$pkg_dir/agent/files/config/experimental.json"

    # Init git repo (required for install script)
    cd "$pkg_dir"
    git init -q
    git add -A
    git commit -q -m "init"
    cd "$PROJECT_ROOT"
}

# Create a backward-compat package (files/ dir but NO contents.files metadata)
create_legacy_files_package() {
    local pkg_dir="$1"
    mkdir -p "$pkg_dir/agent"/{commands,files/config}

    cat > "$pkg_dir/package.yaml" <<'YAML'
name: test-legacy-files
version: 1.0.0
description: Test package with legacy files support
author: Test Author
license: MIT
repository: https://github.com/test/test-legacy-files.git

contents:
  commands:
    - name: test-legacy-files.hello.md
      description: Hello command
      scripts: []
YAML

    cat > "$pkg_dir/agent/commands/test-legacy-files.hello.md" <<'MD'
# Command: hello

> **🤖 Agent Directive**: Test command

**Namespace**: test-legacy-files
**Version**: 1.0.0
**Status**: Active
**Scripts**: None

---

**Purpose**: Hello command
MD

    echo '{"legacy": true}' > "$pkg_dir/agent/files/config/legacy.json"

    cd "$pkg_dir"
    git init -q
    git add -A
    git commit -q -m "init"
    cd "$PROJECT_ROOT"
}

# ============================================================================
# Tests
# ============================================================================

test_files_install_to_target_paths() {
    echo ""
    echo "${BOLD}Test: Files install to target paths from package.yaml${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    # Set up target project
    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    # Pipe dummy variable values (PROJECT_NAME, AUTHOR_NAME) for the template with variables
    local output
    output=$(printf 'test-proj\nTest Author\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # tsconfig.json has target: ./ → should be at ./tsconfig.json
    assert_file_exists "./tsconfig.json" "tsconfig.json installed to project root"

    # example.schema.ts has target: src/schemas/ → should be at src/schemas/example.schema.ts
    assert_file_exists "src/schemas/example.schema.ts" "schema installed to src/schemas/"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_template_extension_stripped() {
    echo ""
    echo "${BOLD}Test: .template extension stripped during installation${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    # Provide variable values via stdin
    local output
    output=$(printf 'my-project\nJohn Doe\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # settings.json.template has target: config/ → should be config/settings.json (no .template)
    assert_file_exists "config/settings.json" ".template extension stripped"

    # The .template version should NOT exist
    if [ -f "config/settings.json.template" ]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  ${RED}✗${NC} .template file should not exist at target"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ${GREEN}✓${NC} .template file correctly not present"
    fi

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_variable_substitution() {
    echo ""
    echo "${BOLD}Test: Variable substitution replaces {{PLACEHOLDERS}}${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    # Provide variable values: PROJECT_NAME=acme-project, AUTHOR_NAME=Jane Smith
    local output
    output=$(printf 'acme-project\nJane Smith\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    assert_file_exists "config/settings.json" "Settings file installed"

    local content
    content=$(cat "config/settings.json")
    assert_contains "$content" "acme-project" "PROJECT_NAME substituted"
    assert_contains "$content" "Jane Smith" "AUTHOR_NAME substituted"
    assert_not_contains "$content" "{{PROJECT_NAME}}" "No remaining PROJECT_NAME placeholder"
    assert_not_contains "$content" "{{AUTHOR_NAME}}" "No remaining AUTHOR_NAME placeholder"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_experimental_files_skipped() {
    echo ""
    echo "${BOLD}Test: Experimental files skipped without --experimental${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(printf 'test-proj\nTest Author\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # experimental.json has experimental: true → should be skipped
    if [ -f "./experimental.json" ]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  ${RED}✗${NC} Experimental file should NOT be installed"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ${GREEN}✓${NC} Experimental file correctly skipped"
    fi

    assert_contains "$output" "experimental" "Output mentions experimental skip"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_experimental_files_installed_with_flag() {
    echo ""
    echo "${BOLD}Test: Experimental files installed with --experimental flag${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(printf 'test-proj\nTest Author\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y --experimental 2>&1)

    assert_file_exists "./experimental.json" "Experimental file installed with --experimental"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_list_shows_target_paths() {
    echo ""
    echo "${BOLD}Test: --list shows target paths for files${NC}"

    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    local output
    output=$(bash "$INSTALL_SCRIPT" --repo "$pkg_dir" --list 2>&1)

    # Should show target path info
    assert_contains "$output" "tsconfig.json" "Lists tsconfig.json"
    assert_contains "$output" "example.schema.ts" "Lists example.schema.ts"
    assert_contains "$output" "dry run" "Shows dry run message"

    cd "$PROJECT_ROOT"
    rm -rf "$pkg_dir"
}

test_unsafe_target_path_rejected() {
    echo ""
    echo "${BOLD}Test: Unsafe target paths are rejected${NC}"

    local pkg_dir=$(mktemp -d)
    mkdir -p "$pkg_dir/agent"/{commands,files/config}

    cat > "$pkg_dir/package.yaml" <<'YAML'
name: test-unsafe
version: 1.0.0
description: Test package with unsafe target path test
author: Test Author
license: MIT
repository: https://github.com/test/test-unsafe.git

contents:
  commands:
    - name: test-unsafe.hello.md
      description: Hello command
      scripts: []

  files:
    - name: config/evil.json
      description: File with unsafe target path escape
      target: ../../
      required: false
YAML

    cat > "$pkg_dir/agent/commands/test-unsafe.hello.md" <<'MD'
# Command: hello

> **🤖 Agent Directive**: Test command

**Namespace**: test-unsafe
**Version**: 1.0.0
**Status**: Active
**Scripts**: None

---

**Purpose**: Hello command
MD

    echo '{"evil": true}' > "$pkg_dir/agent/files/config/evil.json"

    cd "$pkg_dir"
    git init -q
    git add -A
    git commit -q -m "init"
    cd "$PROJECT_ROOT"

    local test_dir=$(mktemp -d)
    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1) || true

    # The file should NOT be installed at the unsafe target
    if [ -f "../../evil.json" ]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  ${RED}✗${NC} Unsafe target should be rejected"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ${GREEN}✓${NC} Unsafe target correctly rejected"
    fi

    assert_contains "$output" "unsafe" "Output mentions unsafe target"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_legacy_files_backward_compat() {
    echo ""
    echo "${BOLD}Test: Legacy files (no contents.files) still install to project root${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_legacy_files_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # Legacy behavior: files install to ./ preserving structure
    assert_file_exists "./config/legacy.json" "Legacy file installed to ./config/"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_selective_files_flag() {
    echo ""
    echo "${BOLD}Test: --files flag for selective file installation${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(bash "$INSTALL_SCRIPT" --repo "$pkg_dir" --files config/tsconfig.json -y 2>&1)

    # Only tsconfig.json should be installed
    assert_file_exists "./tsconfig.json" "Selected file installed"

    # Other files should NOT be installed
    if [ -f "src/schemas/example.schema.ts" ]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  ${RED}✗${NC} Non-selected file should NOT be installed"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ${GREEN}✓${NC} Non-selected files correctly skipped"
    fi

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_manifest_tracks_target_path() {
    echo ""
    echo "${BOLD}Test: Manifest tracks target path for files${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(printf 'test-proj\nTest Author\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # Check manifest exists
    assert_file_exists "agent/manifest.yaml" "Manifest created"

    # Check that target path is stored for tsconfig.json
    local manifest_content
    manifest_content=$(cat "agent/manifest.yaml")
    assert_contains "$manifest_content" "target:" "Manifest contains target field"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_manifest_tracks_variables() {
    echo ""
    echo "${BOLD}Test: Manifest tracks variable values for template files${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(printf 'my-app\nJane Doe\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # Check manifest for variable values
    local manifest_content
    manifest_content=$(cat "agent/manifest.yaml")
    assert_contains "$manifest_content" "variables:" "Manifest contains variables section"
    assert_contains "$manifest_content" "PROJECT_NAME" "Manifest tracks PROJECT_NAME variable"
    assert_contains "$manifest_content" "AUTHOR_NAME" "Manifest tracks AUTHOR_NAME variable"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_manifest_has_checksums_for_files() {
    echo ""
    echo "${BOLD}Test: Manifest has checksums for installed files${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    local output
    output=$(printf 'test-proj\nTest Author\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    local manifest_content
    manifest_content=$(cat "agent/manifest.yaml")
    assert_contains "$manifest_content" "checksum: sha256:" "Manifest has SHA256 checksums"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_variable_substitution_special_chars() {
    echo ""
    echo "${BOLD}Test: Variable substitution handles special characters${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    # Use values with special chars: ampersand, slash, quotes
    local output
    output=$(printf 'my-app/v2\nJohn & Jane\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    assert_file_exists "config/settings.json" "Settings file installed"

    local content
    content=$(cat "config/settings.json")
    assert_contains "$content" "my-app/v2" "PROJECT_NAME with slash substituted"
    assert_contains "$content" "John & Jane" "AUTHOR_NAME with ampersand substituted"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_remove_template_files() {
    echo ""
    echo "${BOLD}Test: Package remove deletes installed template files${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    # Install first
    local output
    output=$(printf 'test-proj\nTest Author\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # Verify files exist
    assert_file_exists "./tsconfig.json" "tsconfig.json installed before removal"

    # Remove the package
    local remove_output
    remove_output=$(bash "$PROJECT_ROOT/agent/scripts/acp.package-remove.sh" test-templates -y 2>&1)

    # tsconfig.json should be removed (it was at target: ./)
    if [ -f "./tsconfig.json" ]; then
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  ${RED}✗${NC} tsconfig.json should be removed"
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo "  ${GREEN}✓${NC} tsconfig.json correctly removed"
    fi

    # Manifest should be updated (package removed)
    local manifest_content
    manifest_content=$(cat "agent/manifest.yaml")
    assert_not_contains "$manifest_content" "test-templates:" "Package removed from manifest"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

test_overwrite_existing_file() {
    echo ""
    echo "${BOLD}Test: Template overwrites existing files with -y flag${NC}"

    local test_dir=$(mktemp -d)
    local pkg_dir=$(mktemp -d)
    create_template_package "$pkg_dir"

    mkdir -p "$test_dir/agent"
    cd "$test_dir"

    # Create existing file that will be overwritten
    echo '{"old": true}' > "./tsconfig.json"

    local output
    output=$(printf 'test-proj\nTest Author\n' | bash "$INSTALL_SCRIPT" --repo "$pkg_dir" -y 2>&1)

    # File should be overwritten with package content
    local content
    content=$(cat "./tsconfig.json")
    assert_contains "$content" "ES2022" "File was overwritten with package content"
    assert_not_contains "$content" "old" "Old content replaced"

    cd "$PROJECT_ROOT"
    rm -rf "$test_dir" "$pkg_dir"
}

# ============================================================================
# Run all tests
# ============================================================================

echo ""
echo "${BLUE}Running E2E Tests: Template File Installation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_files_install_to_target_paths
test_template_extension_stripped
test_variable_substitution
test_experimental_files_skipped
test_experimental_files_installed_with_flag
test_list_shows_target_paths
test_unsafe_target_path_rejected
test_legacy_files_backward_compat
test_selective_files_flag
test_manifest_tracks_target_path
test_manifest_tracks_variables
test_manifest_has_checksums_for_files
test_variable_substitution_special_chars
test_remove_template_files
test_overwrite_existing_file

echo ""
print_test_summary
