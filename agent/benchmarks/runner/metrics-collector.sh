#!/bin/bash
# metrics-collector.sh — Aggregate per-run metrics into averaged summary
# Usage: bash metrics-collector.sh --mode <mode> --task <task> --runs <N> --report-dir <path>
# Outputs YAML fragment to stdout (appended to summary.yaml by run-benchmark.sh)

set -euo pipefail

# --- Parse arguments ---
MODE=""
TASK=""
RUNS=0
REPORT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        --task) TASK="$2"; shift 2 ;;
        --runs) RUNS="$2"; shift 2 ;;
        --report-dir) REPORT_DIR="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$MODE" ] || [ -z "$TASK" ] || [ "$RUNS" -lt 1 ] || [ -z "$REPORT_DIR" ]; then
    echo "Usage: metrics-collector.sh --mode <mode> --task <task> --runs <N> --report-dir <path>" >&2
    exit 1
fi

# --- Helper: extract numeric field from YAML ---
get_field() {
    local file="$1"
    local field="$2"
    grep "${field}:" "$file" 2>/dev/null | head -1 | awk '{print $2}' || true
}

# --- Collect per-run values ---
INPUT_TOKENS_LIST=""
OUTPUT_TOKENS_LIST=""
NUM_TURNS_LIST=""
DURATION_LIST=""
COST_LIST=""
PASS_COUNT=0
TOTAL_CHECKS_PASSED=0
TOTAL_CHECKS_TOTAL=0

for run_num in $(seq 1 "$RUNS"); do
    RESULT_FILE="$REPORT_DIR/runs/${TASK}-${MODE}-run${run_num}.yaml"
    if [ ! -f "$RESULT_FILE" ]; then
        echo "Warning: Missing result file: $RESULT_FILE" >&2
        continue
    fi

    input_tokens=$(get_field "$RESULT_FILE" "input_tokens")
    output_tokens=$(get_field "$RESULT_FILE" "output_tokens")
    num_turns=$(get_field "$RESULT_FILE" "num_turns")
    duration_s=$(get_field "$RESULT_FILE" "duration_seconds")
    cost=$(get_field "$RESULT_FILE" "total_cost_usd")
    all_passed=$(get_field "$RESULT_FILE" "all_passed")
    checks_passed=$(get_field "$RESULT_FILE" "checks_passed")
    checks_total=$(get_field "$RESULT_FILE" "checks_total")

    INPUT_TOKENS_LIST="${INPUT_TOKENS_LIST}${input_tokens} "
    OUTPUT_TOKENS_LIST="${OUTPUT_TOKENS_LIST}${output_tokens} "
    NUM_TURNS_LIST="${NUM_TURNS_LIST}${num_turns} "
    DURATION_LIST="${DURATION_LIST}${duration_s} "
    COST_LIST="${COST_LIST}${cost} "

    if [ "$all_passed" = "true" ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
    fi
    TOTAL_CHECKS_PASSED=$((TOTAL_CHECKS_PASSED + checks_passed))
    TOTAL_CHECKS_TOTAL=$((TOTAL_CHECKS_TOTAL + checks_total))
done

# --- Compute mean and stddev using awk ---
compute_stats() {
    local values="$1"
    echo "$values" | awk '{
        n = NF
        if (n == 0) { print "0 0"; exit }
        sum = 0
        for (i = 1; i <= n; i++) sum += $i
        mean = sum / n
        sumsq = 0
        for (i = 1; i <= n; i++) sumsq += ($i - mean)^2
        stddev = (n > 1) ? sqrt(sumsq / (n - 1)) : 0
        printf "%.2f %.2f\n", mean, stddev
    }'
}

INPUT_STATS=$(compute_stats "$INPUT_TOKENS_LIST")
OUTPUT_STATS=$(compute_stats "$OUTPUT_TOKENS_LIST")
TURNS_STATS=$(compute_stats "$NUM_TURNS_LIST")
DURATION_STATS=$(compute_stats "$DURATION_LIST")
COST_STATS=$(compute_stats "$COST_LIST")

INPUT_MEAN=$(echo "$INPUT_STATS" | awk '{print $1}')
INPUT_STDDEV=$(echo "$INPUT_STATS" | awk '{print $2}')
OUTPUT_MEAN=$(echo "$OUTPUT_STATS" | awk '{print $1}')
OUTPUT_STDDEV=$(echo "$OUTPUT_STATS" | awk '{print $2}')
TURNS_MEAN=$(echo "$TURNS_STATS" | awk '{print $1}')
TURNS_STDDEV=$(echo "$TURNS_STATS" | awk '{print $2}')
DURATION_MEAN=$(echo "$DURATION_STATS" | awk '{print $1}')
DURATION_STDDEV=$(echo "$DURATION_STATS" | awk '{print $2}')
COST_MEAN=$(echo "$COST_STATS" | awk '{print $1}')
COST_STDDEV=$(echo "$COST_STATS" | awk '{print $2}')

# --- Output YAML fragment ---
cat << EOF
  $MODE:
    runs: $RUNS
    pass_rate: $PASS_COUNT/$RUNS
    checks: $TOTAL_CHECKS_PASSED/$TOTAL_CHECKS_TOTAL
    input_tokens:
      mean: $INPUT_MEAN
      stddev: $INPUT_STDDEV
      values: [$INPUT_TOKENS_LIST]
    output_tokens:
      mean: $OUTPUT_MEAN
      stddev: $OUTPUT_STDDEV
      values: [$OUTPUT_TOKENS_LIST]
    num_turns:
      mean: $TURNS_MEAN
      stddev: $TURNS_STDDEV
      values: [$NUM_TURNS_LIST]
    duration_seconds:
      mean: $DURATION_MEAN
      stddev: $DURATION_STDDEV
      values: [$DURATION_LIST]
    cost_usd:
      mean: $COST_MEAN
      stddev: $COST_STDDEV
      values: [$COST_LIST]
EOF
