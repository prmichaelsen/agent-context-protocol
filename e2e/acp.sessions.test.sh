#!/usr/bin/env bash
# E2E tests for acp.sessions.sh — sessions management system

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source test utilities
source "${PROJECT_ROOT}/tests/common.sh"

# Source YAML parser
source "${PROJECT_ROOT}/agent/scripts/acp.common.sh"
source_yaml_parser

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Sessions script path
SESSIONS_SCRIPT="${PROJECT_ROOT}/agent/scripts/acp.sessions.sh"

# Backup and restore helpers
ORIG_SESSIONS_FILE="${HOME}/.acp/sessions.yaml"
BACKUP_FILE=""

setup_test_env() {
    # Backup existing sessions.yaml if present
    if [ -f "$ORIG_SESSIONS_FILE" ]; then
        BACKUP_FILE=$(mktemp)
        cp "$ORIG_SESSIONS_FILE" "$BACKUP_FILE"
    fi
    # Remove sessions.yaml for clean test state
    rm -f "$ORIG_SESSIONS_FILE"
}

cleanup_test_env() {
    # Remove test sessions.yaml
    rm -f "$ORIG_SESSIONS_FILE"
    # Restore backup if one existed
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$ORIG_SESSIONS_FILE"
        rm -f "$BACKUP_FILE"
    fi
}

# Trap to ensure cleanup runs
trap cleanup_test_env EXIT

# ============================================================================
# TEST SUITE
# ============================================================================

print_suite_header "Sessions System E2E Tests"

# --- Test 1: Auto-create sessions.yaml on register ---
echo ""
echo "Test 1: Auto-create sessions.yaml on register"
setup_test_env

output=$("$SESSIONS_SCRIPT" register --project test-project --description "Test session" --pid $$)
assert_file_exists "$ORIG_SESSIONS_FILE" "sessions.yaml created on first register"
assert_contains "$output" "registered" "Register outputs confirmation"
assert_contains "$output" "sess_" "Register outputs session ID"

# --- Test 2: Register with all fields ---
echo ""
echo "Test 2: Register with all fields populated"
setup_test_env

output=$("$SESSIONS_SCRIPT" register --project my-project --description "Task 1: Build Feature" --pid $$)
assert_contains "$output" "registered" "Register confirms success"

# Verify YAML content
content=$(cat "$ORIG_SESSIONS_FILE")
assert_contains "$content" "project: my-project" "Project field stored"
assert_contains "$content" "description: Task 1: Build Feature" "Description field stored"
assert_contains "$content" "status: active" "Status set to active"
assert_contains "$content" "pid: $$" "PID stored correctly"

# --- Test 3: Register with remote URL ---
echo ""
echo "Test 3: Register with remote URL"
setup_test_env

"$SESSIONS_SCRIPT" register --project url-project --description "Remote test" --remote-url "https://example.com/session" --pid $$ >/dev/null
content=$(cat "$ORIG_SESSIONS_FILE")
assert_contains "$content" "remote_url: https://example.com/session" "Remote URL stored"

# --- Test 4: List sessions ---
echo ""
echo "Test 4: List active sessions"
setup_test_env

"$SESSIONS_SCRIPT" register --project proj-a --description "Session A" --pid $$ >/dev/null
"$SESSIONS_SCRIPT" register --project proj-b --description "Session B" --pid $$ >/dev/null

output=$("$SESSIONS_SCRIPT" list)
assert_contains "$output" "Active Sessions (2)" "List shows correct count"
assert_contains "$output" "proj-a" "List contains first project"
assert_contains "$output" "proj-b" "List contains second project"
assert_contains "$output" "Session A" "List shows first description"
assert_contains "$output" "Session B" "List shows second description"

# --- Test 5: List with project filter ---
echo ""
echo "Test 5: List with project filter"

output=$("$SESSIONS_SCRIPT" list --project proj-a)
assert_contains "$output" "Active Sessions (1)" "Filtered list shows correct count"
assert_contains "$output" "proj-a" "Filtered list shows matching project"
assert_not_contains "$output" "proj-b" "Filtered list excludes non-matching project"

# --- Test 6: List empty ---
echo ""
echo "Test 6: List when no sessions"
setup_test_env

output=$("$SESSIONS_SCRIPT" list)
assert_contains "$output" "No active sessions" "Empty list shows appropriate message"

# --- Test 7: Deregister by ID ---
echo ""
echo "Test 7: Deregister by ID"
setup_test_env

reg_output=$("$SESSIONS_SCRIPT" register --project dereg-test --description "To be removed" --pid $$)
sid=$(echo "$reg_output" | grep "^sess_" | head -1)

output=$("$SESSIONS_SCRIPT" deregister --id "$sid")
assert_contains "$output" "deregistered" "Deregister confirms removal"
assert_contains "$output" "Active sessions remaining: 0" "Remaining count is 0"

# Verify it's gone
list_output=$("$SESSIONS_SCRIPT" list)
assert_contains "$list_output" "No active sessions" "Deregistered session no longer listed"

# --- Test 8: Deregister by PID (auto-detect) ---
echo ""
echo "Test 8: Deregister by PID (auto-detect)"
setup_test_env

# Write a session manually with PID matching what the deregister script's $PPID will be.
# When called directly (not in subshell), the script's $PPID is $$ of this test.
cat > "$ORIG_SESSIONS_FILE" << EOF
sessions:
  - id: sess_pidauto
    project: pid-test
    description: PID auto-detect test
    started: 2026-03-01T00:00:00Z
    last_activity: 2026-03-01T00:00:00Z
    status: active
    current_milestone:
    current_task:
    pid: $$
    terminal: /dev/pts/0
    remote_url:

last_updated: 2026-03-01T00:00:00Z
EOF

# Call deregister without --id, redirecting to file (avoids $() subshell PPID mismatch)
"$SESSIONS_SCRIPT" deregister > /tmp/acp_test_dereg_output 2>&1 || true
output=$(cat /tmp/acp_test_dereg_output)
rm -f /tmp/acp_test_dereg_output
assert_contains "$output" "deregistered" "Deregister by PPID auto-detection"

# --- Test 9: Clean stale (dead PID) ---
echo ""
echo "Test 9: Clean stale sessions (dead PID)"
setup_test_env

# Register with a PID that doesn't exist
"$SESSIONS_SCRIPT" register --project stale-project --description "Dead PID session" --pid 99999 >/dev/null

output=$("$SESSIONS_SCRIPT" clean)
assert_contains "$output" "99999 not running" "Clean detects dead PID"
assert_contains "$output" "Active sessions remaining: 0" "Clean removes stale session"

# --- Test 10: Clean stale (timeout) ---
echo ""
echo "Test 10: Clean stale sessions (old last_activity)"
setup_test_env

# Manually write a session with old timestamp
cat > "$ORIG_SESSIONS_FILE" << EOF
sessions:
  - id: sess_old123
    project: old-project
    description: Old session
    started: 2026-01-01T00:00:00Z
    last_activity: 2026-01-01T00:00:00Z
    status: active
    current_milestone:
    current_task:
    pid: $$
    terminal: /dev/pts/0
    remote_url:

last_updated: 2026-01-01T00:00:00Z
EOF

output=$("$SESSIONS_SCRIPT" clean)
assert_contains "$output" "inactive for" "Clean detects timeout"
assert_contains "$output" "Active sessions remaining: 0" "Clean removes timed-out session"

# --- Test 11: Heartbeat ---
echo ""
echo "Test 11: Heartbeat updates session"
setup_test_env

reg_output=$("$SESSIONS_SCRIPT" register --project heartbeat-test --description "Original desc" --pid $$)
sid=$(echo "$reg_output" | grep "^sess_" | head -1)

output=$("$SESSIONS_SCRIPT" heartbeat --id "$sid" --task task-42 --description "Updated desc")
assert_contains "$output" "updated" "Heartbeat confirms update"

# Verify the updates persisted
content=$(cat "$ORIG_SESSIONS_FILE")
assert_contains "$content" "current_task: task-42" "Heartbeat updated task"
assert_contains "$content" "description: Updated desc" "Heartbeat updated description"

# --- Test 12: Count ---
echo ""
echo "Test 12: Count outputs correct integer"
setup_test_env

"$SESSIONS_SCRIPT" register --project count-a --description "Count A" --pid $$ >/dev/null
"$SESSIONS_SCRIPT" register --project count-b --description "Count B" --pid $$ >/dev/null

output=$("$SESSIONS_SCRIPT" count)
assert_equals "2" "$output" "Count returns correct integer"

# --- Test 13: Multiple sessions same project ---
echo ""
echo "Test 13: Multiple sessions for same project"
setup_test_env

"$SESSIONS_SCRIPT" register --project same-proj --description "Session 1" --pid $$ >/dev/null
"$SESSIONS_SCRIPT" register --project same-proj --description "Session 2" --pid $$ >/dev/null

output=$("$SESSIONS_SCRIPT" list --project same-proj)
assert_contains "$output" "Active Sessions (2)" "Two sessions for same project"
assert_contains "$output" "Session 1" "First session listed"
assert_contains "$output" "Session 2" "Second session listed"

# --- Test 14: Usage help ---
echo ""
echo "Test 14: Usage help on no arguments"

output=$("$SESSIONS_SCRIPT" 2>&1 || true)
assert_contains "$output" "Usage:" "Usage shown on no arguments"
assert_contains "$output" "register" "Usage lists register subcommand"
assert_contains "$output" "deregister" "Usage lists deregister subcommand"
assert_contains "$output" "list" "Usage lists list subcommand"

# --- Test 15: Unknown subcommand ---
echo ""
echo "Test 15: Unknown subcommand error"

output=$("$SESSIONS_SCRIPT" foobar 2>&1 || true)
assert_contains "$output" "Unknown subcommand" "Unknown subcommand shows error"

# --- Test 16: Register missing project ---
echo ""
echo "Test 16: Register without --project shows error"

output=$("$SESSIONS_SCRIPT" register 2>&1 || true)
assert_contains "$output" "Error" "Register without project shows error"
assert_contains "$output" "project is required" "Error mentions project requirement"

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
print_test_summary
