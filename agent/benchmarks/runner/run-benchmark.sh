#!/bin/bash
# run-benchmark.sh — Main entry point for running ACP benchmarks
# Usage: bash run-benchmark.sh [--task <name>] [--mode <acp|baseline|both>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$BENCHMARKS_DIR/../.." && pwd)"
SUITE_DIR="$BENCHMARKS_DIR/suite"

# --- Parse arguments ---
TASK="hello-world"
MODE="both"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task) TASK="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

if [ "$MODE" != "acp" ] && [ "$MODE" != "baseline" ] && [ "$MODE" != "both" ]; then
    echo "Error: --mode must be 'acp', 'baseline', or 'both'" >&2
    exit 1
fi

# --- Validate task exists ---
TASK_DIR="$SUITE_DIR/$TASK"
if [ ! -d "$TASK_DIR" ]; then
    echo "Error: Task '$TASK' not found in $SUITE_DIR/" >&2
    exit 1
fi

if [ ! -f "$TASK_DIR/prompt.md" ]; then
    echo "Error: Task '$TASK' missing prompt.md" >&2
    exit 1
fi

# --- Build list of modes to run ---
MODES=()
if [ "$MODE" = "both" ]; then
    MODES=("acp" "baseline")
elif [ "$MODE" = "acp" ]; then
    MODES=("acp")
else
    MODES=("baseline")
fi

# --- Create report directory ---
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
REPORT_DIR="$BENCHMARKS_DIR/reports/benchmark-$TIMESTAMP"
mkdir -p "$REPORT_DIR"

echo "========================================"
echo "ACP Benchmark Runner"
echo "========================================"
echo "Task:       $TASK"
echo "Mode(s):    ${MODES[*]}"
echo "Report dir: $REPORT_DIR"
echo "========================================"
echo ""

# --- Run each mode ---
for run_mode in "${MODES[@]}"; do
    echo "--- Running: $TASK [$run_mode] ---"
    OUTPUT_FILE="$REPORT_DIR/${TASK}-${run_mode}.yaml"

    bash "$SCRIPT_DIR/run-single.sh" \
        --task "$TASK" \
        --mode "$run_mode" \
        --task-dir "$TASK_DIR" \
        --output "$OUTPUT_FILE" \
        --project-root "$PROJECT_ROOT"

    echo ""
done

# --- Generate summary ---
SUMMARY_FILE="$REPORT_DIR/summary.yaml"

echo "Generating summary..."

cat > "$SUMMARY_FILE" << EOF
benchmark_summary:
  task: $TASK
  timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
  modes_run: [$(IFS=,; echo "${MODES[*]}" | sed 's/,/, /g')]

results:
EOF

for run_mode in "${MODES[@]}"; do
    RESULT_FILE="$REPORT_DIR/${TASK}-${run_mode}.yaml"
    if [ -f "$RESULT_FILE" ]; then
        # Extract metrics from per-run YAML
        input_tokens=$(grep 'input_tokens:' "$RESULT_FILE" | awk '{print $2}')
        output_tokens=$(grep 'output_tokens:' "$RESULT_FILE" | awk '{print $2}')
        num_turns=$(grep 'num_turns:' "$RESULT_FILE" | awk '{print $2}')
        duration_s=$(grep 'duration_seconds:' "$RESULT_FILE" | awk '{print $2}')
        cost=$(grep 'total_cost_usd:' "$RESULT_FILE" | awk '{print $2}')
        all_passed=$(grep 'all_passed:' "$RESULT_FILE" | awk '{print $2}')
        checks_passed=$(grep 'checks_passed:' "$RESULT_FILE" | awk '{print $2}')
        checks_total=$(grep 'checks_total:' "$RESULT_FILE" | awk '{print $2}')

        cat >> "$SUMMARY_FILE" << EOF
  $run_mode:
    passed: $all_passed
    checks: $checks_passed/$checks_total
    input_tokens: $input_tokens
    output_tokens: $output_tokens
    num_turns: $num_turns
    duration_seconds: $duration_s
    cost_usd: $cost
EOF
    fi
done

# --- Compute diff if both modes ran ---
if [ "${#MODES[@]}" -eq 2 ]; then
    ACP_FILE="$REPORT_DIR/${TASK}-acp.yaml"
    BASELINE_FILE="$REPORT_DIR/${TASK}-baseline.yaml"

    if [ -f "$ACP_FILE" ] && [ -f "$BASELINE_FILE" ]; then
        acp_tokens=$(grep 'input_tokens:' "$ACP_FILE" | awk '{print $2}')
        baseline_tokens=$(grep 'input_tokens:' "$BASELINE_FILE" | awk '{print $2}')
        token_diff=$((acp_tokens - baseline_tokens))

        acp_output=$(grep 'output_tokens:' "$ACP_FILE" | awk '{print $2}')
        baseline_output=$(grep 'output_tokens:' "$BASELINE_FILE" | awk '{print $2}')
        output_diff=$((acp_output - baseline_output))

        acp_turns=$(grep 'num_turns:' "$ACP_FILE" | awk '{print $2}')
        baseline_turns=$(grep 'num_turns:' "$BASELINE_FILE" | awk '{print $2}')
        turns_diff=$((acp_turns - baseline_turns))

        acp_duration=$(grep 'duration_seconds:' "$ACP_FILE" | awk '{print $2}')
        baseline_duration=$(grep 'duration_seconds:' "$BASELINE_FILE" | awk '{print $2}')
        duration_diff=$((acp_duration - baseline_duration))

        cat >> "$SUMMARY_FILE" << EOF

comparison:
  input_tokens_diff: $token_diff
  output_tokens_diff: $output_diff
  turns_diff: $turns_diff
  duration_diff_seconds: $duration_diff
EOF
    fi
fi

echo ""
echo "========================================"
echo "Summary"
echo "========================================"
cat "$SUMMARY_FILE"
echo ""
echo "========================================"
echo "Full reports: $REPORT_DIR/"
echo "========================================"
