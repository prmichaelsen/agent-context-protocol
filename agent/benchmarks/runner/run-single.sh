#!/bin/bash
# run-single.sh — Execute a single benchmark run (one task, one mode)
# Supports both single-prompt and multi-turn step modes.
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

# --- Copy seed files if configured ---
if [ -f "$TASK_DIR/config.yaml" ]; then
    SEED_DIR=$(grep '^seed_dir:' "$TASK_DIR/config.yaml" | head -1 | awk '{print $2}' || true)
    if [ -n "$SEED_DIR" ]; then
        SEED_PATH="$TASK_DIR/$SEED_DIR"
        if [ -d "$SEED_PATH" ]; then
            echo "  Copying seed files from $SEED_DIR..."
            cp -r "$SEED_PATH"/* "$WORKSPACE/"
            echo "  Seed files ready"
        else
            echo "  Warning: seed_dir '$SEED_DIR' not found at $SEED_PATH"
        fi
    fi

    # Install npm dependencies if package.json exists
    if [ -f "$WORKSPACE/package.json" ]; then
        echo "  Installing seed dependencies..."
        (cd "$WORKSPACE" && npm install --quiet 2>/dev/null) || true
    fi
fi

ACP_PREAMBLE=""
ACP_PLAN_SUFFIX=""
ACP_PROCEED_SUFFIX=""
if [ "$MODE" = "acp" ]; then
    echo "  Installing ACP..."
    (cd "$WORKSPACE" && bash "$PROJECT_ROOT/agent/scripts/acp.install.sh") > "$OUTPUT.acp-install.log" 2>&1
    echo "  ACP installed"

    # Copy ACP seed overlay AFTER ACP install (project-specific docs on top of ACP framework)
    if [ -f "$TASK_DIR/config.yaml" ]; then
        SEED_DIR_ACP=$(grep '^seed_dir_acp:' "$TASK_DIR/config.yaml" | awk '{print $2}' || true)
        if [ -n "$SEED_DIR_ACP" ]; then
            SEED_ACP_PATH="$TASK_DIR/$SEED_DIR_ACP"
            if [ -d "$SEED_ACP_PATH" ]; then
                echo "  Copying ACP seed overlay from $SEED_DIR_ACP..."
                cp -r "$SEED_ACP_PATH"/* "$WORKSPACE/"
                echo "  ACP seed overlay ready"
            else
                echo "  Warning: seed_dir_acp '$SEED_DIR_ACP' not found at $SEED_ACP_PATH"
            fi
        fi
    fi

    # Build preamble to trigger ACP init on the first prompt
    ACP_PREAMBLE="@agent/commands/acp.init.md

"
    # ACP workflow directives injected into step prompts
    ACP_PLAN_SUFFIX="

---
ACP Workflow Directive: Before implementing, read @agent/commands/acp.plan.md and follow its planning approach. Create a brief plan (milestones, tasks, design considerations) in agent/ before writing code."

    ACP_PROCEED_SUFFIX="

---
ACP Workflow Directive: Read @agent/commands/acp.proceed.md and follow its structured implementation approach. Update agent/progress.yaml as you complete work."
fi

# --- Read config ---
MAX_TURNS=10
TIMEOUT=120
if [ -f "$TASK_DIR/config.yaml" ]; then
    config_turns=$(grep '^max_turns:' "$TASK_DIR/config.yaml" | awk '{print $2}' || true)
    if [ -n "$config_turns" ]; then
        MAX_TURNS="$config_turns"
    fi
    config_timeout=$(grep -E '^timeout(_minutes)?:' "$TASK_DIR/config.yaml" | awk '{print $2}' || true)
    if [ -n "$config_timeout" ]; then
        TIMEOUT="$config_timeout"
    fi
fi

# --- Detect steps mode ---
# If config.yaml has a steps: section, use multi-turn mode
# Otherwise, fall back to single-prompt mode using prompt.md
STEPS_MODE="false"
STEP_COUNT=0

if [ -f "$TASK_DIR/config.yaml" ] && grep -q '^steps:' "$TASK_DIR/config.yaml" 2>/dev/null; then
    STEPS_MODE="true"
    STEP_COUNT=$(grep -c '^\s*- id:' "$TASK_DIR/config.yaml" || true)
fi

# --- Create per-step metrics directory ---
METRICS_DIR="$(dirname "$OUTPUT")/steps-${TASK}-${MODE}"
mkdir -p "$METRICS_DIR"

# --- Helper: extract metric from JSON with fallback paths ---
# Tries .usage.<field> first (nested), then .<field> (top-level), then 0
extract_metric() {
    local json="$1"
    local field="$2"
    local value
    # Try nested .usage.<field> first
    value=$(echo "$json" | jq -r ".usage.${field} // empty" 2>/dev/null || true)
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        echo "$value"
        return
    fi
    # Try top-level .<field>
    value=$(echo "$json" | jq -r ".${field} // 0" 2>/dev/null || echo 0)
    echo "${value:-0}"
}

# --- Execute ---
SESSION_ID=""
TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0
TOTAL_NUM_TURNS=0
TOTAL_COST_USD="0"
TOTAL_DURATION_S=0
RESULT_TEXT=""
CLAUDE_EXIT=0

TOOLS="Bash,Read,Edit,Write,Glob,Grep"

if [ "$STEPS_MODE" = "true" ]; then
    echo "  Multi-turn mode: $STEP_COUNT steps"

    # Parse steps from config.yaml (simple line-by-line parser, no yq needed)
    STEP_IDS=()
    STEP_PROMPTS=()
    STEP_PHASES=()
    STEP_MAX_TURNS=()

    current_id=""
    current_prompt_file=""
    current_prompt_file_acp=""
    current_prompt_file_baseline=""
    current_phase=""
    current_max_turns=""
    in_steps="false"

    while IFS= read -r line; do
        if echo "$line" | grep -q '^steps:'; then
            in_steps="true"
            continue
        fi
        if [ "$in_steps" = "true" ]; then
            # Non-indented line after steps: means we've left the block
            if [ -n "$line" ] && echo "$line" | grep -qE '^[a-z]'; then
                in_steps="false"
                continue
            fi
            if echo "$line" | grep -q '^\s*- id:'; then
                # Save previous step if exists
                if [ -n "$current_id" ]; then
                    # Resolve prompt file: mode-specific takes priority over generic
                    resolved_prompt="$current_prompt_file"
                    if [ "$MODE" = "acp" ] && [ -n "$current_prompt_file_acp" ]; then
                        resolved_prompt="$current_prompt_file_acp"
                    elif [ "$MODE" = "baseline" ] && [ -n "$current_prompt_file_baseline" ]; then
                        resolved_prompt="$current_prompt_file_baseline"
                    fi
                    STEP_IDS+=("$current_id")
                    STEP_PROMPTS+=("$resolved_prompt")
                    STEP_PHASES+=("${current_phase:-unknown}")
                    STEP_MAX_TURNS+=("${current_max_turns:-$MAX_TURNS}")
                fi
                current_id=$(echo "$line" | sed 's/.*- id:\s*//' | tr -d '[:space:]')
                current_prompt_file=""
                current_prompt_file_acp=""
                current_prompt_file_baseline=""
                current_phase=""
                current_max_turns=""
            elif echo "$line" | grep -q 'prompt_file_acp:'; then
                current_prompt_file_acp=$(echo "$line" | sed 's/.*prompt_file_acp:\s*//' | tr -d '[:space:]')
            elif echo "$line" | grep -q 'prompt_file_baseline:'; then
                current_prompt_file_baseline=$(echo "$line" | sed 's/.*prompt_file_baseline:\s*//' | tr -d '[:space:]')
            elif echo "$line" | grep -q 'prompt_file:'; then
                current_prompt_file=$(echo "$line" | sed 's/.*prompt_file:\s*//' | tr -d '[:space:]')
            elif echo "$line" | grep -q 'phase:'; then
                current_phase=$(echo "$line" | sed 's/.*phase:\s*//' | tr -d '[:space:]')
            elif echo "$line" | grep -q 'max_turns:'; then
                current_max_turns=$(echo "$line" | sed 's/.*max_turns:\s*//' | tr -d '[:space:]')
            fi
        fi
    done < "$TASK_DIR/config.yaml"

    # Save last step
    if [ -n "$current_id" ]; then
        resolved_prompt="$current_prompt_file"
        if [ "$MODE" = "acp" ] && [ -n "$current_prompt_file_acp" ]; then
            resolved_prompt="$current_prompt_file_acp"
        elif [ "$MODE" = "baseline" ] && [ -n "$current_prompt_file_baseline" ]; then
            resolved_prompt="$current_prompt_file_baseline"
        fi
        STEP_IDS+=("$current_id")
        STEP_PROMPTS+=("$resolved_prompt")
        STEP_PHASES+=("${current_phase:-unknown}")
        STEP_MAX_TURNS+=("${current_max_turns:-$MAX_TURNS}")
    fi

    # Execute each step
    for i in "${!STEP_IDS[@]}"; do
        step_id="${STEP_IDS[$i]}"
        step_prompt_file="${STEP_PROMPTS[$i]}"
        step_phase="${STEP_PHASES[$i]}"
        step_max_turns="${STEP_MAX_TURNS[$i]}"

        STEP_PROMPT=$(cat "$TASK_DIR/$step_prompt_file")
        # Inject ACP workflow directives in ACP mode
        if [ "$MODE" = "acp" ]; then
            if [ "$i" -eq 0 ]; then
                # First step: init + plan (read context, plan before building)
                STEP_PROMPT="${ACP_PREAMBLE}${STEP_PROMPT}${ACP_PLAN_SUFFIX}"
            else
                # Subsequent steps: proceed (structured implementation)
                STEP_PROMPT="${STEP_PROMPT}${ACP_PROCEED_SUFFIX}"
            fi
        fi

        echo "  Step $((i+1))/$STEP_COUNT: $step_id (phase=$step_phase, max_turns=$step_max_turns)"

        STDERR_LOG="$METRICS_DIR/step-${step_id}-stderr.log"
        STEP_START=$(date +%s)

        STEP_OUTPUT=""
        STEP_EXIT=0

        if [ -z "$SESSION_ID" ]; then
            # First step — start new session
            STEP_OUTPUT=$(cd "$WORKSPACE" && claude -p "$STEP_PROMPT" \
                --output-format json \
                --allowedTools "$TOOLS" \
                --max-turns "$step_max_turns" \
                2>"$STDERR_LOG") || STEP_EXIT=$?
        else
            # Subsequent steps — resume same session
            STEP_OUTPUT=$(cd "$WORKSPACE" && claude -p "$STEP_PROMPT" \
                --resume "$SESSION_ID" \
                --output-format json \
                --allowedTools "$TOOLS" \
                --max-turns "$step_max_turns" \
                2>"$STDERR_LOG") || STEP_EXIT=$?
        fi

        STEP_END=$(date +%s)
        STEP_DURATION=$((STEP_END - STEP_START))

        # Save raw JSON for debugging
        echo "$STEP_OUTPUT" > "$METRICS_DIR/step-${step_id}-raw.json"

        # Extract per-step metrics
        step_input=0
        step_output_tokens=0
        step_turns=0
        step_cost="0"

        if [ -n "$STEP_OUTPUT" ]; then
            step_session_id=$(echo "$STEP_OUTPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
            if [ -n "$step_session_id" ]; then
                SESSION_ID="$step_session_id"
            fi

            step_input=$(extract_metric "$STEP_OUTPUT" "input_tokens")
            step_output_tokens=$(extract_metric "$STEP_OUTPUT" "output_tokens")
            step_turns=$(echo "$STEP_OUTPUT" | jq -r '.num_turns // 0' 2>/dev/null || echo 0)
            step_cost=$(extract_metric "$STEP_OUTPUT" "cost_usd")
            RESULT_TEXT=$(echo "$STEP_OUTPUT" | jq -r '.result // empty' 2>/dev/null || true)

            TOTAL_INPUT_TOKENS=$((TOTAL_INPUT_TOKENS + step_input))
            TOTAL_OUTPUT_TOKENS=$((TOTAL_OUTPUT_TOKENS + step_output_tokens))
            TOTAL_NUM_TURNS=$((TOTAL_NUM_TURNS + step_turns))
            TOTAL_COST_USD=$(echo "$TOTAL_COST_USD $step_cost" | awk '{printf "%.6f", $1 + $2}')
        fi

        TOTAL_DURATION_S=$((TOTAL_DURATION_S + STEP_DURATION))

        if [ "$STEP_EXIT" -ne 0 ]; then
            CLAUDE_EXIT=$STEP_EXIT
        fi

        # Save per-step metrics YAML
        cat > "$METRICS_DIR/step-${step_id}.yaml" << STEP_EOF
step_id: $step_id
phase: $step_phase
exit_code: $STEP_EXIT
duration_seconds: $STEP_DURATION
input_tokens: $step_input
output_tokens: $step_output_tokens
num_turns: $step_turns
cost_usd: $step_cost
STEP_EOF

        echo "    Done: ${STEP_DURATION}s, turns=$step_turns, tokens=${step_input}/${step_output_tokens}"
    done
else
    # --- Single-prompt mode (backward compatible) ---
    PROMPT=$(cat "$TASK_DIR/prompt.md")
    # Inject ACP workflow directives if in ACP mode
    if [ "$MODE" = "acp" ]; then
        PROMPT="${ACP_PREAMBLE}${PROMPT}${ACP_PLAN_SUFFIX}"
    fi

    echo "  Running claude (mode=$MODE, max_turns=$MAX_TURNS)..."
    STDERR_LOG="$OUTPUT.stderr.log"
    START_TIME=$(date +%s)

    CLAUDE_OUTPUT=""
    CLAUDE_OUTPUT=$(cd "$WORKSPACE" && claude -p "$PROMPT" \
        --output-format json \
        --allowedTools "$TOOLS" \
        --max-turns "$MAX_TURNS" \
        2>"$STDERR_LOG") || CLAUDE_EXIT=$?

    END_TIME=$(date +%s)
    TOTAL_DURATION_S=$((END_TIME - START_TIME))

    # Save raw JSON for debugging
    echo "$CLAUDE_OUTPUT" > "$METRICS_DIR/single-raw.json"

    if [ -n "$CLAUDE_OUTPUT" ]; then
        SESSION_ID=$(echo "$CLAUDE_OUTPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
        TOTAL_INPUT_TOKENS=$(extract_metric "$CLAUDE_OUTPUT" "input_tokens")
        TOTAL_OUTPUT_TOKENS=$(extract_metric "$CLAUDE_OUTPUT" "output_tokens")
        TOTAL_NUM_TURNS=$(echo "$CLAUDE_OUTPUT" | jq -r '.num_turns // 0' 2>/dev/null || echo 0)
        TOTAL_COST_USD=$(extract_metric "$CLAUDE_OUTPUT" "cost_usd")
        RESULT_TEXT=$(echo "$CLAUDE_OUTPUT" | jq -r '.result // empty' 2>/dev/null || true)
    fi
fi

echo "  Claude exited with code $CLAUDE_EXIT (${TOTAL_DURATION_S}s)"

# --- Run verification ---
echo "  Verifying..."
source "$SCRIPT_DIR/verify.sh"

VERIFY_PASS="false"
CHECKS_PASSED=0
CHECKS_TOTAL=0

# Task-aware verification dispatch: call verify_<task_name> (with hyphens replaced by underscores)
VERIFY_FUNC="verify_${TASK//-/_}"
if type "$VERIFY_FUNC" &>/dev/null; then
    "$VERIFY_FUNC" "$WORKSPACE" && VERIFY_PASS="true"

    # Count checks from exported vars (set by verify functions)
    if [ -f "$TASK_DIR/config.yaml" ]; then
        CHECKS_TOTAL=$(sed -n '/^expected_checks:/,/^[a-z]/p' "$TASK_DIR/config.yaml" 2>/dev/null | grep -c '^\s*- ' || true)
        # Ensure clean integer
        CHECKS_TOTAL=$(echo "$CHECKS_TOTAL" | tr -d '[:space:]')
        CHECKS_TOTAL="${CHECKS_TOTAL:-0}"
    fi
    # Fallback: count from standard check variables
    if [ "$CHECKS_TOTAL" -eq 0 ] 2>/dev/null; then
        CHECKS_TOTAL=3
    fi
    [ "${FILE_EXISTS:-false}" = "true" ] && CHECKS_PASSED=$((CHECKS_PASSED + 1))
    [ "${FILE_EXECUTABLE:-false}" = "true" ] && CHECKS_PASSED=$((CHECKS_PASSED + 1))
    [ "${OUTPUT_CORRECT:-false}" = "true" ] && CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "  Warning: No verify function '$VERIFY_FUNC' for task '$TASK', skipping verification"
    VERIFY_PASS="unknown"
fi

echo "  Checks: $CHECKS_PASSED/$CHECKS_TOTAL"

# --- Run LLM evaluator ---
EVAL_OUTPUT=""
EVAL_EXIT=0
EVAL_SCORE=""
EVAL_RATING=""

EVALUATOR_PROMPT="$SCRIPT_DIR/evaluator-prompt.md"
EVALUATOR_SCHEMA="$SCRIPT_DIR/evaluation-schema.json"

if [ -f "$EVALUATOR_PROMPT" ] && [ -f "$EVALUATOR_SCHEMA" ]; then
    echo "  Running LLM evaluator..."
    EVAL_STDERR="$OUTPUT.eval-stderr.log"

    EVAL_SCHEMA_JSON=$(cat "$EVALUATOR_SCHEMA")
    EVAL_OUTPUT=$(cd "$WORKSPACE" && claude -p "$(cat "$EVALUATOR_PROMPT")" \
        --output-format json \
        --json-schema "$EVAL_SCHEMA_JSON" \
        --allowedTools "Read,Glob,Grep,Bash" \
        --max-turns 10 \
        2>"$EVAL_STDERR") || EVAL_EXIT=$?

    if [ "$EVAL_EXIT" -eq 0 ] && [ -n "$EVAL_OUTPUT" ]; then
        # Save raw evaluation JSON
        echo "$EVAL_OUTPUT" > "$OUTPUT.eval-raw.json"

        # Extract structured output (--json-schema puts data in .structured_output)
        EVAL_JSON=$(echo "$EVAL_OUTPUT" | jq '.structured_output // empty' 2>/dev/null || true)

        # Fallback: try .result field (for non-schema responses)
        if [ -z "$EVAL_JSON" ] || [ "$EVAL_JSON" = "null" ]; then
            EVAL_RESULT=$(echo "$EVAL_OUTPUT" | jq -r '.result // empty' 2>/dev/null || true)
            if [ -n "$EVAL_RESULT" ]; then
                EVAL_JSON=$(echo "$EVAL_RESULT" | jq '.' 2>/dev/null || true)
                if [ -z "$EVAL_JSON" ]; then
                    EVAL_JSON=$(echo "$EVAL_RESULT" | sed -n '/^```json/,/^```/p' | sed '1d;$d' | jq '.' 2>/dev/null || true)
                fi
            fi
        fi

        if [ -n "$EVAL_JSON" ] && [ "$EVAL_JSON" != "null" ]; then
            echo "$EVAL_JSON" > "$OUTPUT.eval.json"
            EVAL_SCORE=$(echo "$EVAL_JSON" | jq -r '.overall_score // empty' 2>/dev/null || true)
            EVAL_RATING=$(echo "$EVAL_JSON" | jq -r '.overall_rating // empty' 2>/dev/null || true)
            echo "  Evaluation: score=$EVAL_SCORE rating=$EVAL_RATING"
        else
            echo "  Warning: Could not parse evaluation JSON from result"
        fi
    else
        echo "  Warning: Evaluator failed (exit=$EVAL_EXIT)"
    fi
else
    echo "  Skipping evaluation (evaluator files not found)"
fi

# --- Write per-run YAML report ---
cat > "$OUTPUT" << EOF
task: $TASK
mode: $MODE
timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
session_id: $SESSION_ID
claude_exit_code: $CLAUDE_EXIT
steps_mode: $STEPS_MODE
step_count: ${STEP_COUNT:-1}

metrics:
  input_tokens: $TOTAL_INPUT_TOKENS
  output_tokens: $TOTAL_OUTPUT_TOKENS
  num_turns: $TOTAL_NUM_TURNS
  duration_seconds: $TOTAL_DURATION_S
  total_cost_usd: $TOTAL_COST_USD

verification:
  all_passed: $VERIFY_PASS
  checks_passed: $CHECKS_PASSED
  checks_total: $CHECKS_TOTAL
  details:
    file_exists: ${FILE_EXISTS:-unknown}
    file_executable: ${FILE_EXECUTABLE:-unknown}
    output_correct: ${OUTPUT_CORRECT:-unknown}
EOF

# Append evaluation data if available
if [ -n "$EVAL_SCORE" ] && [ -f "$OUTPUT.eval.json" ]; then
    {
        echo ""
        echo "evaluation:"
        echo "  overall_score: $EVAL_SCORE"
        echo "  overall_rating: $EVAL_RATING"
        # Extract per-category scores
        for cat in correctness completeness code_style documentation architecture testing; do
            score=$(jq -r ".${cat}.score // empty" "$OUTPUT.eval.json" 2>/dev/null || true)
            rating=$(jq -r ".${cat}.rating // empty" "$OUTPUT.eval.json" 2>/dev/null || true)
            rationale=$(jq -r ".${cat}.rationale // empty" "$OUTPUT.eval.json" 2>/dev/null || true)
            if [ -n "$score" ]; then
                echo "  ${cat}:"
                echo "    score: $score"
                echo "    rating: $rating"
                echo "    rationale: \"$rationale\""
            fi
        done
        summary=$(jq -r '.summary // empty' "$OUTPUT.eval.json" 2>/dev/null || true)
        if [ -n "$summary" ]; then
            echo "  summary: \"$summary\""
        fi
    } >> "$OUTPUT"
fi

# Append per-step detail for multi-turn runs
if [ "$STEPS_MODE" = "true" ]; then
    {
        echo ""
        echo "steps:"
        for i in "${!STEP_IDS[@]}"; do
            step_id="${STEP_IDS[$i]}"
            step_file="$METRICS_DIR/step-${step_id}.yaml"
            if [ -f "$step_file" ]; then
                first_line="true"
                while IFS= read -r line; do
                    if [ "$first_line" = "true" ]; then
                        echo "  - $line"
                        first_line="false"
                    else
                        echo "    $line"
                    fi
                done < "$step_file"
            fi
        done
    } >> "$OUTPUT"
fi

echo "  Report written to $OUTPUT"
