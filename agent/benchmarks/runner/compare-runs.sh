#!/bin/bash
# compare-runs.sh — Compare benchmark results across runs
# Usage: bash compare-runs.sh [--latest N] [--task TASK]
# Compares the N most recent benchmark runs, showing trends.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$BENCHMARKS_DIR/reports"

# --- Parse arguments ---
LATEST=3
TASK=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --latest) LATEST="$2"; shift 2 ;;
        --task) TASK="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# --- Helper: extract a field value from a YAML file ---
get_field() {
    local file="$1"
    local field="$2"
    grep "${field}:" "$file" 2>/dev/null | head -1 | awk '{print $2}' || true
}

# --- Find recent runs ---
RUNS=$(ls -td "$REPORTS_DIR"/benchmark-*/ 2>/dev/null | head -"$LATEST")

if [ -z "$RUNS" ]; then
    echo "No benchmark runs found in $REPORTS_DIR"
    exit 0
fi

RUN_COUNT=$(echo "$RUNS" | wc -l)
echo "═══════════════════════════════════════════════════════"
echo "  Benchmark Comparison — Last $RUN_COUNT Runs"
echo "═══════════════════════════════════════════════════════"
echo ""

# --- Header ---
printf "%-30s" "Metric"
for run_dir in $RUNS; do
    run_name=$(basename "$run_dir" | sed 's/benchmark-//')
    printf "  %-16s" "$run_name"
done
echo ""
printf "%-30s" "------------------------------"
for _ in $RUNS; do
    printf "  %-16s" "----------------"
done
echo ""

# --- Collect tasks across all runs ---
if [ -n "$TASK" ]; then
    TASKS="$TASK"
else
    TASKS=""
    for run_dir in $RUNS; do
        for yaml in "$run_dir"/*.yaml; do
            [ "$(basename "$yaml")" = "summary.yaml" ] && continue
            task_mode=$(basename "$yaml" .yaml)
            task_name=$(echo "$task_mode" | sed 's/-\(baseline\|acp\)$//')
            TASKS="$TASKS $task_name"
        done
    done
    TASKS=$(echo "$TASKS" | tr ' ' '\n' | sort -u | tr '\n' ' ')
fi

# --- Print metrics per task/mode ---
for task in $TASKS; do
    for mode in baseline acp; do
        label="${task} (${mode})"
        printf "%-30s" "$label"
        for run_dir in $RUNS; do
            yaml="$run_dir/${task}-${mode}.yaml"
            if [ -f "$yaml" ]; then
                score=$(get_field "$yaml" "overall_score")
                tokens=$(get_field "$yaml" "output_tokens")
                if [ -n "$score" ]; then
                    printf "  score=%-9s" "$score"
                elif [ -n "$tokens" ]; then
                    printf "  tok=%-11s" "$tokens"
                else
                    printf "  %-16s" "(no data)"
                fi
            else
                printf "  %-16s" "-"
            fi
        done
        echo ""
    done
done

echo ""
echo "═══════════════════════════════════════════════════════"
