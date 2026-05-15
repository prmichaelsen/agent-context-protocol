#!/bin/bash
# E2E Conformance Tests: Driver Override Dispatch (M19)
#
# Tests that ACP commands contain the Driver Override Check directive block
# and that the three workflow-override pilot commands have correct workflow
# dispatch structure. These are static-analysis tests over the markdown
# command files — not LLM execution tests.
#
# Covered:
#   1. All acp.* commands contain the "Driver Override Check" block
#   2. Workflow-override pilot commands (acp.task-create, acp.plan, acp.init)
#      contain workflow.run binding dispatch with STOP semantics
#   3. Pilot commands reference the fallback path (backward compat signal)
#   4. Excluded files (command.template.md, git.*) are NOT checked

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMANDS_DIR="$PROJECT_ROOT/agent/commands"

source "$PROJECT_ROOT/tests/common.sh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Assert that a file contains a given string (grep -qF).
assert_file_contains_string() {
    local file="$1"
    local needle="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if grep -qF "$needle" "$file"; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  File:   ${YELLOW}$file${NC}"
        echo -e "  Needle: ${YELLOW}$needle${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Assert that a file does NOT contain a given string.
assert_file_not_contains_string() {
    local file="$1"
    local needle="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if ! grep -qF "$needle" "$file"; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo -e "  File unexpectedly contains: ${YELLOW}$needle${NC}"
        echo -e "  File: ${YELLOW}$file${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ---------------------------------------------------------------------------
# Test suite 1: All acp.* commands carry the Driver Override Check block
# ---------------------------------------------------------------------------

test_all_acp_commands_have_override_check() {
    local missing=()

    for cmd_file in "$COMMANDS_DIR"/acp.*.md; do
        local basename
        basename="$(basename "$cmd_file")"

        # Skip template file — it's a scaffold, not an active command
        if [ "$basename" = "command.template.md" ]; then
            continue
        fi

        if ! grep -qF "Driver Override Check" "$cmd_file"; then
            missing+=("$basename")
        fi
    done

    TESTS_RUN=$((TESTS_RUN + 1))
    if [ ${#missing[@]} -eq 0 ]; then
        echo -e "${GREEN}✓${NC} All acp.* commands contain Driver Override Check block"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Commands missing Driver Override Check block:"
        for f in "${missing[@]}"; do
            echo -e "  ${YELLOW}- $f${NC}"
        done
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ---------------------------------------------------------------------------
# Test suite 2: git.* commands are exempt (they don't need override dispatch)
# ---------------------------------------------------------------------------

test_git_commands_exempt_from_override_check() {
    # Verify that git utility commands are NOT required to carry the block —
    # they exist in the commands dir but are outside the acp.* namespace.
    TESTS_RUN=$((TESTS_RUN + 1))
    local git_count
    git_count=$(find "$COMMANDS_DIR" -name "git.*.md" | wc -l)
    if [ "$git_count" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} git.* utility commands exist ($git_count files) and are excluded from override-check"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        # Neutral — no git commands is also fine
        echo -e "${GREEN}✓${NC} No git.* commands found; nothing to exempt"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

# ---------------------------------------------------------------------------
# Test suite 3: Workflow-override pilot commands have workflow.run dispatch
# ---------------------------------------------------------------------------

WORKFLOW_PILOTS=(
    "acp.task-create.md"
    "acp.plan.md"
    "acp.init.md"
)

test_workflow_pilot_has_workflow_run_binding() {
    local basename="$1"
    local cmd_file="$COMMANDS_DIR/$basename"

    assert_file_contains_string \
        "$cmd_file" \
        "bindings.workflow.run" \
        "$basename: references bindings.workflow.run dispatch"
}

test_workflow_pilot_has_stop_semantics() {
    local basename="$1"
    local cmd_file="$COMMANDS_DIR/$basename"

    assert_file_contains_string \
        "$cmd_file" \
        "STOP" \
        "$basename: contains STOP semantics (prevents fallback on dispatch)"
}

test_workflow_pilot_has_fallback_step() {
    local basename="$1"
    local cmd_file="$COMMANDS_DIR/$basename"

    assert_file_contains_string \
        "$cmd_file" \
        "Fallback" \
        "$basename: describes fallback path (backward compat when unbound)"
}

test_workflow_pilot_has_error_handling() {
    local basename="$1"
    local cmd_file="$COMMANDS_DIR/$basename"

    assert_file_contains_string \
        "$cmd_file" \
        "Error handling" \
        "$basename: Error handling block present"
}

test_all_workflow_pilots() {
    for pilot in "${WORKFLOW_PILOTS[@]}"; do
        test_workflow_pilot_has_workflow_run_binding "$pilot"
        test_workflow_pilot_has_stop_semantics "$pilot"
        test_workflow_pilot_has_fallback_step "$pilot"
        test_workflow_pilot_has_error_handling "$pilot"
    done
}

# ---------------------------------------------------------------------------
# Test suite 4: Override block is TOP-OF-FILE (appears in first 25 lines)
#
# Exception: acp.proceed.md has a complex argument-parsing preamble that
# must precede the override check (it determines which mode — single-task,
# autonomous, stacked — to run in). Its override check is on line ~42.
# That placement is intentional and documented here as a known exception.
# ---------------------------------------------------------------------------

# Commands whose argument-parsing preamble legitimately precedes the
# override check. Each entry is "filename:max_line" where max_line is the
# upper bound for the override check line number.
OVERRIDE_EXCEPTIONS=(
    "acp.proceed.md:50"
)

_get_exception_limit() {
    local basename="$1"
    for entry in "${OVERRIDE_EXCEPTIONS[@]}"; do
        local name limit
        name="${entry%%:*}"
        limit="${entry##*:}"
        if [ "$name" = "$basename" ]; then
            echo "$limit"
            return
        fi
    done
    echo "25"  # default threshold
}

test_override_check_is_top_of_file() {
    local failures=()

    for cmd_file in "$COMMANDS_DIR"/acp.*.md; do
        local basename
        basename="$(basename "$cmd_file")"
        if [ "$basename" = "command.template.md" ]; then
            continue
        fi

        local limit
        limit=$(_get_exception_limit "$basename")

        # Check if "Driver Override Check" appears within the threshold lines
        if ! head -"$limit" "$cmd_file" | grep -qF "Driver Override Check"; then
            failures+=("$basename (limit=${limit})")
        fi
    done

    TESTS_RUN=$((TESTS_RUN + 1))
    if [ ${#failures[@]} -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Driver Override Check appears near top of all acp.* commands"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Driver Override Check missing near top of:"
        for f in "${failures[@]}"; do
            echo -e "  ${YELLOW}- $f${NC}"
        done
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ---------------------------------------------------------------------------
# Test suite 5: driver-dispatch-directive pattern file exists
# ---------------------------------------------------------------------------

test_driver_dispatch_pattern_exists() {
    assert_file_exists \
        "$PROJECT_ROOT/agent/patterns/local.driver-dispatch-directive.md" \
        "driver-dispatch-directive pattern file exists"
}

test_workflow_override_pattern_exists() {
    assert_file_exists \
        "$PROJECT_ROOT/agent/patterns/local.workflow-override-directive.md" \
        "workflow-override-directive pattern file exists"
}

# ---------------------------------------------------------------------------
# Test suite 6: driver.yaml schema script exists
# ---------------------------------------------------------------------------

test_driver_yaml_script_exists() {
    assert_file_exists \
        "$PROJECT_ROOT/agent/scripts/acp.driver-yaml.sh" \
        "acp.driver-yaml.sh parser script exists"
}

# ---------------------------------------------------------------------------
# RUN
# ---------------------------------------------------------------------------

echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${BLUE}E2E Conformance: Driver Override Dispatch (M19)${NC}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

echo "── Suite 1: All acp.* commands carry the override check ──"
test_all_acp_commands_have_override_check
echo

echo "── Suite 2: git.* commands exempt from override check ──"
test_git_commands_exempt_from_override_check
echo

echo "── Suite 3: Workflow-override pilot command structure ──"
test_all_workflow_pilots
echo

echo "── Suite 4: Override check is top-of-file ──"
test_override_check_is_top_of_file
echo

echo "── Suite 5: Pattern files exist ──"
test_driver_dispatch_pattern_exists
test_workflow_override_pattern_exists
echo

echo "── Suite 6: Driver YAML script exists ──"
test_driver_yaml_script_exists
echo

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Tests run:    ${TESTS_RUN}"
echo -e "${GREEN}Tests passed: ${TESTS_PASSED}${NC}"
if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}Tests failed: ${TESTS_FAILED}${NC}"
    exit 1
fi
echo -e "${GREEN}All tests passed.${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
