#!/bin/bash
# run-benchmark.sh — Main entry point for running ACP benchmarks
# Usage: bash run-benchmark.sh [--task <name>] [--mode <acp|baseline|both>] [--runs <N>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$BENCHMARKS_DIR/../.." && pwd)"
SUITE_DIR="$BENCHMARKS_DIR/suite"

# --- Parse arguments ---
TASK="hello-world"
MODE="both"
RUNS=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task) TASK="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        --runs) RUNS="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

if [ "$MODE" != "acp" ] && [ "$MODE" != "baseline" ] && [ "$MODE" != "both" ]; then
    echo "Error: --mode must be 'acp', 'baseline', or 'both'" >&2
    exit 1
fi

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [ "$RUNS" -lt 1 ]; then
    echo "Error: --runs must be a positive integer" >&2
    exit 1
fi

# --- Validate task exists ---
TASK_DIR="$SUITE_DIR/$TASK"
if [ ! -d "$TASK_DIR" ]; then
    echo "Error: Task '$TASK' not found in $SUITE_DIR/" >&2
    exit 1
fi

if [ ! -f "$TASK_DIR/prompt.md" ] && ! grep -q '^steps:' "$TASK_DIR/config.yaml" 2>/dev/null; then
    echo "Error: Task '$TASK' missing prompt.md and has no steps in config.yaml" >&2
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
mkdir -p "$REPORT_DIR/runs"

echo "========================================"
echo "ACP Benchmark Runner"
echo "========================================"
echo "Task:       $TASK"
echo "Mode(s):    ${MODES[*]}"
echo "Runs:       $RUNS"
echo "Report dir: $REPORT_DIR"
echo "========================================"
echo ""

# --- Run each mode x run ---
for run_mode in "${MODES[@]}"; do
    for run_num in $(seq 1 "$RUNS"); do
        if [ "$RUNS" -gt 1 ]; then
            echo "--- Running: $TASK [$run_mode] (run $run_num/$RUNS) ---"
            OUTPUT_FILE="$REPORT_DIR/runs/${TASK}-${run_mode}-run${run_num}.yaml"
        else
            echo "--- Running: $TASK [$run_mode] ---"
            OUTPUT_FILE="$REPORT_DIR/${TASK}-${run_mode}.yaml"
        fi

        bash "$SCRIPT_DIR/run-single.sh" \
            --task "$TASK" \
            --mode "$run_mode" \
            --task-dir "$TASK_DIR" \
            --output "$OUTPUT_FILE" \
            --project-root "$PROJECT_ROOT"

        echo ""
    done
done

# --- Generate summary ---
SUMMARY_FILE="$REPORT_DIR/summary.yaml"

echo "Generating summary..."

cat > "$SUMMARY_FILE" << EOF
benchmark_summary:
  task: $TASK
  timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
  modes_run: [$(IFS=,; echo "${MODES[*]}" | sed 's/,/, /g')]
  runs_per_mode: $RUNS

results:
EOF

for run_mode in "${MODES[@]}"; do
    if [ "$RUNS" -eq 1 ]; then
        # Single run: use direct file
        RESULT_FILE="$REPORT_DIR/${TASK}-${run_mode}.yaml"
        if [ -f "$RESULT_FILE" ]; then
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
    else
        # Multi-run: aggregate across runs
        bash "$SCRIPT_DIR/metrics-collector.sh" \
            --mode "$run_mode" \
            --task "$TASK" \
            --runs "$RUNS" \
            --report-dir "$REPORT_DIR" \
            >> "$SUMMARY_FILE"
    fi
done

# --- Compute diff if both modes ran ---
if [ "${#MODES[@]}" -eq 2 ]; then
    if [ "$RUNS" -eq 1 ]; then
        ACP_FILE="$REPORT_DIR/${TASK}-acp.yaml"
        BASELINE_FILE="$REPORT_DIR/${TASK}-baseline.yaml"
    else
        # For multi-run, use the averaged values from summary
        # We'll compute diff from the summary file itself
        ACP_FILE=""
        BASELINE_FILE=""
    fi

    if [ -n "$ACP_FILE" ] && [ -f "$ACP_FILE" ] && [ -f "$BASELINE_FILE" ]; then
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

# --- Generate reports ---
if [ "$RUNS" -eq 1 ]; then
    # Single-run: generate markdown and HTML reports
    bash "$SCRIPT_DIR/report-markdown.sh" "$REPORT_DIR" "$TASK" "${MODES[@]}"
    bash "$SCRIPT_DIR/report-html.sh" "$REPORT_DIR" "$TASK" "${MODES[@]}"
else
    echo "  (Multi-run reports: see summary.yaml — enhanced reports available in future)"
fi

echo ""
echo "========================================"
echo "Summary"
echo "========================================"
cat "$SUMMARY_FILE"
echo ""
echo "========================================"
echo "Reports:"
echo "  YAML:     $REPORT_DIR/summary.yaml"
if [ "$RUNS" -eq 1 ]; then
    echo "  Markdown: $REPORT_DIR/report.md"
    echo "  HTML:     $REPORT_DIR/report.html"
fi
echo "========================================"
