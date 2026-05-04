#!/bin/bash
# E2E Tests for agent/scripts/acp.driver-yaml.sh
# Tests parser helpers used by M19 (Pluggable Driver System)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DRIVER_YAML_SH="$PROJECT_ROOT/agent/scripts/acp.driver-yaml.sh"

source "$PROJECT_ROOT/tests/common.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# HELPERS
# ============================================================================

# Create a minimal project directory with a driver.yaml and return its path.
# Sets ACP_PROJECT_ROOT for the parser to find it.
create_project_with_driver_yaml() {
    local content="$1"
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/agent"
    if [ -n "$content" ]; then
        printf '%s\n' "$content" > "$test_dir/agent/driver.yaml"
    fi
    echo "$test_dir"
}

run_helper() {
    local project_dir="$1"
    shift
    ACP_PROJECT_ROOT="$project_dir" bash "$DRIVER_YAML_SH" "$@"
}

# ============================================================================
# TESTS
# ============================================================================

test_present_returns_true_when_file_exists() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
bindings:
  marker.mint: t')
    local result
    result=$(run_helper "$project_dir" present)
    assert_equals "true" "$result" "present returns 'true' when driver.yaml exists"
    rm -rf "$project_dir"
}

test_present_returns_false_when_file_absent() {
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/agent"
    local result
    result=$(ACP_PROJECT_ROOT="$test_dir" bash "$DRIVER_YAML_SH" present)
    assert_equals "false" "$result" "present returns 'false' when driver.yaml is absent"
    rm -rf "$test_dir"
}

test_present_returns_false_when_file_empty() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml '')
    # Create an empty file explicitly
    > "$project_dir/agent/driver.yaml"
    local result
    result=$(run_helper "$project_dir" present)
    assert_equals "false" "$result" "present returns 'false' when driver.yaml is empty"
    rm -rf "$project_dir"
}

test_get_driver_name() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@example-org/example-driver"
bindings:
  marker.mint: m')
    local result
    result=$(run_helper "$project_dir" get-driver-name)
    assert_equals "@example-org/example-driver" "$result" "get-driver-name strips quotes"
    rm -rf "$project_dir"
}

test_get_binding_each_ext_point() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
bindings:
  marker.mint: example_mint
  query.run: example_sql
  workflow.run: example_workflow')

    local mint query workflow
    mint=$(run_helper "$project_dir" get-binding marker.mint)
    query=$(run_helper "$project_dir" get-binding query.run)
    workflow=$(run_helper "$project_dir" get-binding workflow.run)

    assert_equals "example_mint" "$mint" "get-binding marker.mint"
    assert_equals "example_sql" "$query" "get-binding query.run"
    assert_equals "example_workflow" "$workflow" "get-binding workflow.run"
    rm -rf "$project_dir"
}

test_get_binding_returns_empty_when_unbound() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
bindings:
  marker.mint: example_mint')

    local result
    result=$(run_helper "$project_dir" get-binding query.run)
    assert_equals "" "$result" "get-binding returns empty for unbound ext point"
    rm -rf "$project_dir"
}

test_get_workflow() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
bindings:
  workflow.run: w
workflows:
  acp.task-create: task_create
  acp.plan: plan
  acp.init: init')

    local tc plan init missing
    tc=$(run_helper "$project_dir" get-workflow acp.task-create)
    plan=$(run_helper "$project_dir" get-workflow acp.plan)
    init=$(run_helper "$project_dir" get-workflow acp.init)
    missing=$(run_helper "$project_dir" get-workflow acp.nonexistent)

    assert_equals "task_create" "$tc" "get-workflow acp.task-create"
    assert_equals "plan" "$plan" "get-workflow acp.plan"
    assert_equals "init" "$init" "get-workflow acp.init"
    assert_equals "" "$missing" "get-workflow returns empty for unmapped command"
    rm -rf "$project_dir"
}

test_get_capability_watcher_true() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
capabilities:
  watcher: true
bindings:
  marker.mint: m')
    local result
    result=$(run_helper "$project_dir" get-capability watcher)
    assert_equals "true" "$result" "get-capability watcher returns 'true'"
    rm -rf "$project_dir"
}

test_get_capability_returns_empty_when_absent() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
bindings:
  marker.mint: m')
    local result
    result=$(run_helper "$project_dir" get-capability watcher)
    assert_equals "" "$result" "get-capability returns empty when capabilities block absent"
    rm -rf "$project_dir"
}

test_list_bindings() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
bindings:
  marker.mint: m_tool
  query.run: q_tool
  workflow.run: w_tool')

    local result
    result=$(run_helper "$project_dir" list-bindings | sort)
    local expected="marker.mint	m_tool
query.run	q_tool
workflow.run	w_tool"

    assert_equals "$expected" "$result" "list-bindings returns all bindings tab-separated"
    rm -rf "$project_dir"
}

test_list_workflows() {
    local project_dir
    project_dir=$(create_project_with_driver_yaml 'driver: "@org/test"
bindings:
  workflow.run: w
workflows:
  acp.task-create: tc
  acp.plan: pl')

    local result
    result=$(run_helper "$project_dir" list-workflows | sort)
    local expected="acp.plan	pl
acp.task-create	tc"

    assert_equals "$expected" "$result" "list-workflows returns all mappings tab-separated"
    rm -rf "$project_dir"
}

test_global_fallback() {
    # Create a project with NO project-local driver.yaml,
    # but a global ~/.acp/agent/driver.yaml.
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/agent"

    local fake_home
    fake_home=$(mktemp -d)
    mkdir -p "$fake_home/.acp/agent"
    cat > "$fake_home/.acp/agent/driver.yaml" <<'EOF'
driver: "@org/global"
bindings:
  marker.mint: global_mint
EOF

    local result
    result=$(ACP_PROJECT_ROOT="$test_dir" HOME="$fake_home" bash "$DRIVER_YAML_SH" get-driver-name)
    assert_equals "@org/global" "$result" "global ~/.acp/agent/driver.yaml is used when project-local is absent"

    rm -rf "$test_dir" "$fake_home"
}

test_project_local_overrides_global() {
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/agent"
    cat > "$test_dir/agent/driver.yaml" <<'EOF'
driver: "@org/project-local"
bindings:
  marker.mint: local_mint
EOF

    local fake_home
    fake_home=$(mktemp -d)
    mkdir -p "$fake_home/.acp/agent"
    cat > "$fake_home/.acp/agent/driver.yaml" <<'EOF'
driver: "@org/global"
bindings:
  marker.mint: global_mint
EOF

    local result
    result=$(ACP_PROJECT_ROOT="$test_dir" HOME="$fake_home" bash "$DRIVER_YAML_SH" get-driver-name)
    assert_equals "@org/project-local" "$result" "project-local overrides global"

    rm -rf "$test_dir" "$fake_home"
}

# ============================================================================
# RUN
# ============================================================================

echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${BLUE}E2E Tests: agent/scripts/acp.driver-yaml.sh${NC}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

test_present_returns_true_when_file_exists
test_present_returns_false_when_file_absent
test_present_returns_false_when_file_empty
test_get_driver_name
test_get_binding_each_ext_point
test_get_binding_returns_empty_when_unbound
test_get_workflow
test_get_capability_watcher_true
test_get_capability_returns_empty_when_absent
test_list_bindings
test_list_workflows
test_global_fallback
test_project_local_overrides_global

echo
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Tests run:    ${TESTS_RUN}"
echo -e "${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}Tests failed: ${TESTS_FAILED}${NC}"
    exit 1
fi
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
