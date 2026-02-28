#!/bin/bash
# run-benchmark.sh — Main entry point for running ACP benchmarks
# Usage: bash run-benchmark.sh [--task <name>] [--mode <acp|baseline|both>] [--runs <N>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$BENCHMARKS_DIR/../.." && pwd)"
SUITE_DIR="$BENCHMARKS_DIR/suite"

# --- Parse arguments ---
TASK_ARG="hello-world"
MODE="both"
RUNS=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --task) TASK_ARG="$2"; shift 2 ;;
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

# --- Resolve task list ---
TASKS=()
if [ "$TASK_ARG" = "all" ]; then
    # Discover tasks and sort by complexity (trivial < simple < medium < complex)
    declare -A COMPLEXITY_ORDER=( [trivial]=0 [simple]=1 [medium]=2 [complex]=3 )
    UNSORTED_TASKS=()
    UNSORTED_SCORES=()
    for task_dir in "$SUITE_DIR"/*/; do
        task_name=$(basename "$task_dir")
        if [ -f "$task_dir/prompt.md" ] || ([ -f "$task_dir/config.yaml" ] && grep -q '^steps:' "$task_dir/config.yaml" 2>/dev/null); then
            complexity=$(grep '^complexity:' "$task_dir/config.yaml" 2>/dev/null | awk '{print $2}' || echo "medium")
            score="${COMPLEXITY_ORDER[$complexity]:-2}"
            UNSORTED_TASKS+=("$task_name")
            UNSORTED_SCORES+=("$score")
        fi
    done
    if [ "${#UNSORTED_TASKS[@]}" -eq 0 ]; then
        echo "Error: No valid tasks found in $SUITE_DIR/" >&2
        exit 1
    fi
    # Sort by complexity score
    for score in 0 1 2 3; do
        for i in "${!UNSORTED_TASKS[@]}"; do
            if [ "${UNSORTED_SCORES[$i]}" = "$score" ]; then
                TASKS+=("${UNSORTED_TASKS[$i]}")
            fi
        done
    done
else
    TASK_DIR="$SUITE_DIR/$TASK_ARG"
    if [ ! -d "$TASK_DIR" ]; then
        echo "Error: Task '$TASK_ARG' not found in $SUITE_DIR/" >&2
        exit 1
    fi
    if [ ! -f "$TASK_DIR/prompt.md" ] && ! grep -q '^steps:' "$TASK_DIR/config.yaml" 2>/dev/null; then
        echo "Error: Task '$TASK_ARG' missing prompt.md and has no steps in config.yaml" >&2
        exit 1
    fi
    TASKS=("$TASK_ARG")
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
echo "Task(s):    ${TASKS[*]}"
echo "Mode(s):    ${MODES[*]}"
echo "Runs:       $RUNS"
echo "Report dir: $REPORT_DIR"
echo "========================================"
echo ""

# --- Run each task x mode x run ---
FAILED_TASKS=()
for TASK in "${TASKS[@]}"; do
    TASK_DIR="$SUITE_DIR/$TASK"

    for run_mode in "${MODES[@]}"; do
        for run_num in $(seq 1 "$RUNS"); do
            if [ "$RUNS" -gt 1 ]; then
                echo "--- Running: $TASK [$run_mode] (run $run_num/$RUNS) ---"
                OUTPUT_FILE="$REPORT_DIR/runs/${TASK}-${run_mode}-run${run_num}.yaml"
            else
                echo "--- Running: $TASK [$run_mode] ---"
                OUTPUT_FILE="$REPORT_DIR/${TASK}-${run_mode}.yaml"
            fi

            if ! bash "$SCRIPT_DIR/run-single.sh" \
                --task "$TASK" \
                --mode "$run_mode" \
                --task-dir "$TASK_DIR" \
                --output "$OUTPUT_FILE" \
                --project-root "$PROJECT_ROOT"; then
                echo "  ⚠ FAILED: $TASK [$run_mode] run $run_num"
                FAILED_TASKS+=("${TASK}:${run_mode}:run${run_num}")
            fi

            echo ""
        done
    done
done

if [ "${#FAILED_TASKS[@]}" -gt 0 ]; then
    echo "========================================"
    echo "⚠ ${#FAILED_TASKS[@]} run(s) failed:"
    for ft in "${FAILED_TASKS[@]}"; do
        echo "  - $ft"
    done
    echo "========================================"
    echo ""
fi

# --- Generate summary ---
SUMMARY_FILE="$REPORT_DIR/summary.yaml"

echo "Generating summary..."

cat > "$SUMMARY_FILE" << EOF
benchmark_summary:
  tasks: [$(IFS=,; echo "${TASKS[*]}" | sed 's/,/, /g')]
  timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
  modes_run: [$(IFS=,; echo "${MODES[*]}" | sed 's/,/, /g')]
  runs_per_mode: $RUNS

EOF

for TASK in "${TASKS[@]}"; do
    echo "task_${TASK//-/_}:" >> "$SUMMARY_FILE"

    for run_mode in "${MODES[@]}"; do
        if [ "$RUNS" -eq 1 ]; then
            RESULT_FILE="$REPORT_DIR/${TASK}-${run_mode}.yaml"
            if [ -f "$RESULT_FILE" ]; then
                input_tokens=$(grep 'input_tokens:' "$RESULT_FILE" | head -1 | awk '{print $2}')
                output_tokens=$(grep 'output_tokens:' "$RESULT_FILE" | head -1 | awk '{print $2}')
                num_turns=$(grep 'num_turns:' "$RESULT_FILE" | head -1 | awk '{print $2}')
                duration_s=$(grep 'duration_seconds:' "$RESULT_FILE" | head -1 | awk '{print $2}')
                cost=$(grep 'total_cost_usd:' "$RESULT_FILE" | head -1 | awk '{print $2}')
                all_passed=$(grep 'all_passed:' "$RESULT_FILE" | head -1 | awk '{print $2}')
                checks_passed=$(grep 'checks_passed:' "$RESULT_FILE" | head -1 | awk '{print $2}')
                checks_total=$(grep 'checks_total:' "$RESULT_FILE" | head -1 | awk '{print $2}')

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
            bash "$SCRIPT_DIR/metrics-collector.sh" \
                --mode "$run_mode" \
                --task "$TASK" \
                --runs "$RUNS" \
                --report-dir "$REPORT_DIR" \
                >> "$SUMMARY_FILE"
        fi
    done

    # Add evaluation scores to summary if available
    for run_mode in "${MODES[@]}"; do
        if [ "$RUNS" -eq 1 ]; then
            eval_json="$REPORT_DIR/${TASK}-${run_mode}.yaml.eval.json"
        else
            eval_json="$REPORT_DIR/runs/${TASK}-${run_mode}-run1.yaml.eval.json"
        fi
        if [ -f "$eval_json" ]; then
            eval_score=$(jq -r '.overall_score // empty' "$eval_json" 2>/dev/null || true)
            eval_rating=$(jq -r '.overall_rating // empty' "$eval_json" 2>/dev/null || true)
            if [ -n "$eval_score" ]; then
                cat >> "$SUMMARY_FILE" << EVALEOF
  ${run_mode}_evaluation:
    overall_score: $eval_score
    overall_rating: $eval_rating
    correctness: $(jq -r '.correctness.score // 0' "$eval_json" 2>/dev/null || echo 0)
    completeness: $(jq -r '.completeness.score // 0' "$eval_json" 2>/dev/null || echo 0)
    code_style: $(jq -r '.code_style.score // 0' "$eval_json" 2>/dev/null || echo 0)
    documentation: $(jq -r '.documentation.score // 0' "$eval_json" 2>/dev/null || echo 0)
    architecture: $(jq -r '.architecture.score // 0' "$eval_json" 2>/dev/null || echo 0)
    testing: $(jq -r '.testing.score // 0' "$eval_json" 2>/dev/null || echo 0)
EVALEOF
            fi
        fi
    done

    # Compute diff if both modes ran (single-run only)
    if [ "${#MODES[@]}" -eq 2 ] && [ "$RUNS" -eq 1 ]; then
        ACP_FILE="$REPORT_DIR/${TASK}-acp.yaml"
        BASELINE_FILE="$REPORT_DIR/${TASK}-baseline.yaml"

        if [ -f "$ACP_FILE" ] && [ -f "$BASELINE_FILE" ]; then
            acp_tokens=$(grep 'input_tokens:' "$ACP_FILE" | head -1 | awk '{print $2}')
            baseline_tokens=$(grep 'input_tokens:' "$BASELINE_FILE" | head -1 | awk '{print $2}')
            token_diff=$((acp_tokens - baseline_tokens))

            acp_output=$(grep 'output_tokens:' "$ACP_FILE" | head -1 | awk '{print $2}')
            baseline_output=$(grep 'output_tokens:' "$BASELINE_FILE" | head -1 | awk '{print $2}')
            output_diff=$((acp_output - baseline_output))

            acp_turns=$(grep 'num_turns:' "$ACP_FILE" | head -1 | awk '{print $2}')
            baseline_turns=$(grep 'num_turns:' "$BASELINE_FILE" | head -1 | awk '{print $2}')
            turns_diff=$((acp_turns - baseline_turns))

            acp_duration=$(grep 'duration_seconds:' "$ACP_FILE" | head -1 | awk '{print $2}')
            baseline_duration=$(grep 'duration_seconds:' "$BASELINE_FILE" | head -1 | awk '{print $2}')
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

    echo "" >> "$SUMMARY_FILE"
done

# --- Generate per-task reports ---
if [ "$RUNS" -eq 1 ]; then
    for TASK in "${TASKS[@]}"; do
        # Only generate if result files exist for this task
        has_results="false"
        for run_mode in "${MODES[@]}"; do
            if [ -f "$REPORT_DIR/${TASK}-${run_mode}.yaml" ]; then
                has_results="true"
                break
            fi
        done
        if [ "$has_results" = "true" ]; then
            bash "$SCRIPT_DIR/report-markdown.sh" "$REPORT_DIR" "$TASK" "${MODES[@]}"
            bash "$SCRIPT_DIR/report-html.sh" "$REPORT_DIR" "$TASK" "${MODES[@]}"
            # For multi-task, rename reports to include task name
            if [ "${#TASKS[@]}" -gt 1 ]; then
                [ -f "$REPORT_DIR/report.md" ] && mv "$REPORT_DIR/report.md" "$REPORT_DIR/report-${TASK}.md"
                [ -f "$REPORT_DIR/report.html" ] && mv "$REPORT_DIR/report.html" "$REPORT_DIR/report-${TASK}.html"
            fi
        fi
    done
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
    if [ "${#TASKS[@]}" -eq 1 ]; then
        echo "  Markdown: $REPORT_DIR/report.md"
        echo "  HTML:     $REPORT_DIR/report.html"
    else
        for TASK in "${TASKS[@]}"; do
            [ -f "$REPORT_DIR/report-${TASK}.md" ] && echo "  Markdown: $REPORT_DIR/report-${TASK}.md"
            [ -f "$REPORT_DIR/report-${TASK}.html" ] && echo "  HTML:     $REPORT_DIR/report-${TASK}.html"
        done
    fi
fi
echo "========================================"
