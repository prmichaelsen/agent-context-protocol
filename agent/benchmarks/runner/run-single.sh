#!/bin/bash
# run-single.sh — Execute a single benchmark run (one task, one mode)
# Usage: bash run-single.sh --task <name> --mode <acp|baseline> --task-dir <path> --output <path> --project-root <path>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Parse arguments ---
TASK=""
MODE=""
TASK_DIR=""
OUTPUT=""
PROJECT_ROOT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task) TASK="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --task-dir) TASK_DIR="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$TASK" ] || [ -z "$MODE" ] || [ -z "$TASK_DIR" ] || [ -z "$OUTPUT" ] || [ -z "$PROJECT_ROOT" ]; then
    echo "Usage: run-single.sh --task <name> --mode <acp|baseline> --task-dir <path> --output <path> --project-root <path>" >&2
    exit 1
fi

if [ "$MODE" != "acp" ] && [ "$MODE" != "baseline" ]; then
    echo "Error: --mode must be 'acp' or 'baseline'" >&2
    exit 1
fi

# --- Pre-flight checks ---
if ! command -v claude &>/dev/null; then
    echo "Error: 'claude' CLI not found in PATH" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: 'jq' not found in PATH" >&2
    exit 1
fi

# --- Create isolated workspace ---
WORKSPACE=$(mktemp -d)
cleanup() {
    rm -rf "$WORKSPACE"
}
trap cleanup EXIT

echo "  Workspace: $WORKSPACE"

# --- Setup workspace ---
(cd "$WORKSPACE" && git init --quiet)

if [ "$MODE" = "acp" ]; then
    echo "  Installing ACP..."
    (cd "$WORKSPACE" && bash "$PROJECT_ROOT/agent/scripts/acp.install.sh") > "$OUTPUT.acp-install.log" 2>&1
    echo "  ACP installed"
fi

# --- Read prompt ---
PROMPT=$(cat "$TASK_DIR/prompt.md")

# --- Read max_turns from config ---
MAX_TURNS=10
if [ -f "$TASK_DIR/config.yaml" ]; then
    config_turns=$(grep '^max_turns:' "$TASK_DIR/config.yaml" | awk '{print $2}')
    if [ -n "$config_turns" ]; then
        MAX_TURNS="$config_turns"
    fi
fi

# --- Execute claude ---
echo "  Running claude (mode=$MODE, max_turns=$MAX_TURNS)..."
STDERR_LOG="$OUTPUT.stderr.log"
START_TIME=$(date +%s)

CLAUDE_OUTPUT=""
CLAUDE_EXIT=0
CLAUDE_OUTPUT=$(cd "$WORKSPACE" && claude -p "$PROMPT" \
    --output-format json \
    --allowedTools "Bash,Read,Edit,Write,Glob,Grep" \
    --max-turns "$MAX_TURNS" \
    2>"$STDERR_LOG") || CLAUDE_EXIT=$?

END_TIME=$(date +%s)
DURATION_S=$((END_TIME - START_TIME))

echo "  Claude exited with code $CLAUDE_EXIT (${DURATION_S}s)"

# --- Parse JSON output ---
SESSION_ID=""
INPUT_TOKENS=0
OUTPUT_TOKENS=0
NUM_TURNS=0
TOTAL_COST_USD="0"
RESULT_TEXT=""

if [ -n "$CLAUDE_OUTPUT" ]; then
    SESSION_ID=$(echo "$CLAUDE_OUTPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
    INPUT_TOKENS=$(echo "$CLAUDE_OUTPUT" | jq -r '.input_tokens // 0' 2>/dev/null || echo 0)
    OUTPUT_TOKENS=$(echo "$CLAUDE_OUTPUT" | jq -r '.output_tokens // 0' 2>/dev/null || echo 0)
    NUM_TURNS=$(echo "$CLAUDE_OUTPUT" | jq -r '.num_turns // 0' 2>/dev/null || echo 0)
    TOTAL_COST_USD=$(echo "$CLAUDE_OUTPUT" | jq -r '.cost_usd // 0' 2>/dev/null || echo 0)
    RESULT_TEXT=$(echo "$CLAUDE_OUTPUT" | jq -r '.result // empty' 2>/dev/null || true)
fi

# --- Run verification ---
echo "  Verifying..."
source "$SCRIPT_DIR/verify.sh"

VERIFY_PASS="false"
verify_hello_world "$WORKSPACE" && VERIFY_PASS="true"

CHECKS_PASSED=0
CHECKS_TOTAL=3
[ "$FILE_EXISTS" = "true" ] && CHECKS_PASSED=$((CHECKS_PASSED + 1))
[ "$FILE_EXECUTABLE" = "true" ] && CHECKS_PASSED=$((CHECKS_PASSED + 1))
[ "$OUTPUT_CORRECT" = "true" ] && CHECKS_PASSED=$((CHECKS_PASSED + 1))

echo "  Checks: $CHECKS_PASSED/$CHECKS_TOTAL (exists=$FILE_EXISTS, exec=$FILE_EXECUTABLE, output=$OUTPUT_CORRECT)"

# --- Write per-run YAML report ---
cat > "$OUTPUT" << EOF
task: $TASK
mode: $MODE
timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
session_id: $SESSION_ID
claude_exit_code: $CLAUDE_EXIT

metrics:
  input_tokens: $INPUT_TOKENS
  output_tokens: $OUTPUT_TOKENS
  num_turns: $NUM_TURNS
  duration_seconds: $DURATION_S
  total_cost_usd: $TOTAL_COST_USD

verification:
  all_passed: $VERIFY_PASS
  checks_passed: $CHECKS_PASSED
  checks_total: $CHECKS_TOTAL
  details:
    file_exists: $FILE_EXISTS
    file_executable: $FILE_EXECUTABLE
    output_correct: $OUTPUT_CORRECT
EOF

echo "  Report written to $OUTPUT"
