#!/bin/bash
# report-markdown.sh — Generate a Markdown report from benchmark results
# Usage: bash report-markdown.sh <report_dir> <task> <mode1> [mode2]
# Can be re-run independently against any existing report directory.

set -euo pipefail

REPORT_DIR="$1"
TASK="$2"
shift 2
MODES=("$@")

REPORT_FILE="$REPORT_DIR/report.md"

# --- Helper: extract a field value from a YAML file ---
get_field() {
    local file="$1"
    local field="$2"
    grep "${field}:" "$file" 2>/dev/null | head -1 | awk '{print $2}' || true
}

# --- Load data for each mode ---
declare -A INPUT_TOKENS OUTPUT_TOKENS NUM_TURNS DURATION COST
declare -A FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT ALL_PASSED CHECKS
declare -A EVAL_SCORE EVAL_RATING EVAL_CORRECTNESS EVAL_COMPLETENESS EVAL_CODE_STYLE
declare -A EVAL_DOCUMENTATION EVAL_ARCHITECTURE EVAL_TESTING EVAL_SUMMARY

for mode in "${MODES[@]}"; do
    file="$REPORT_DIR/${TASK}-${mode}.yaml"
    if [ -f "$file" ]; then
        INPUT_TOKENS[$mode]=$(get_field "$file" "input_tokens")
        OUTPUT_TOKENS[$mode]=$(get_field "$file" "output_tokens")
        NUM_TURNS[$mode]=$(get_field "$file" "num_turns")
        DURATION[$mode]=$(get_field "$file" "duration_seconds")
        COST[$mode]=$(get_field "$file" "total_cost_usd")
        FILE_EXISTS[$mode]=$(get_field "$file" "file_exists")
        FILE_EXECUTABLE[$mode]=$(get_field "$file" "file_executable")
        OUTPUT_CORRECT[$mode]=$(get_field "$file" "output_correct")
        ALL_PASSED[$mode]=$(get_field "$file" "all_passed")
        checks_passed=$(get_field "$file" "checks_passed")
        checks_total=$(get_field "$file" "checks_total")
        CHECKS[$mode]="${checks_passed:-0}/${checks_total:-0}"
        # Load evaluation data
        EVAL_SCORE[$mode]=$(get_field "$file" "overall_score")
        EVAL_RATING[$mode]=$(get_field "$file" "overall_rating")
        eval_json="$REPORT_DIR/${TASK}-${mode}.yaml.eval.json"
        if [ -f "$eval_json" ]; then
            EVAL_CORRECTNESS[$mode]=$(jq -r '.correctness.score // empty' "$eval_json" 2>/dev/null || true)
            EVAL_COMPLETENESS[$mode]=$(jq -r '.completeness.score // empty' "$eval_json" 2>/dev/null || true)
            EVAL_CODE_STYLE[$mode]=$(jq -r '.code_style.score // empty' "$eval_json" 2>/dev/null || true)
            EVAL_DOCUMENTATION[$mode]=$(jq -r '.documentation.score // empty' "$eval_json" 2>/dev/null || true)
            EVAL_ARCHITECTURE[$mode]=$(jq -r '.architecture.score // empty' "$eval_json" 2>/dev/null || true)
            EVAL_TESTING[$mode]=$(jq -r '.testing.score // empty' "$eval_json" 2>/dev/null || true)
            EVAL_SUMMARY[$mode]=$(jq -r '.summary // empty' "$eval_json" 2>/dev/null || true)
        fi
    fi
done

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BOTH=$( [ "${#MODES[@]}" -eq 2 ] && echo "true" || echo "false" )

# --- Helper: compute diff string (lower is better) ---
diff_str() {
    local acp_val="$1"
    local baseline_val="$2"
    if ! [[ "$acp_val" =~ ^[0-9]+$ ]] || ! [[ "$baseline_val" =~ ^[0-9]+$ ]]; then
        echo "—"
        return
    fi
    local diff=$((acp_val - baseline_val))
    if [ "$diff" -lt 0 ]; then
        echo "$diff (better)"
    elif [ "$diff" -gt 0 ]; then
        echo "+$diff (worse)"
    else
        echo "0"
    fi
}

# --- Helper: compute improvement percentage ---
pct_diff() {
    local acp_val="$1"
    local baseline_val="$2"
    if ! [[ "$acp_val" =~ ^[0-9]+$ ]] || ! [[ "$baseline_val" =~ ^[0-9]+$ ]] || [ "$baseline_val" -eq 0 ]; then
        echo "—"
        return
    fi
    local diff=$((acp_val - baseline_val))
    local pct=$(( (diff * 100) / baseline_val ))
    if [ "$pct" -lt 0 ]; then
        echo "${pct}%"
    elif [ "$pct" -gt 0 ]; then
        echo "+${pct}%"
    else
        echo "0%"
    fi
}

# --- Write report ---
{
    echo "# Benchmark Report: $TASK"
    echo ""
    echo "**Generated:** $TIMESTAMP"
    echo "**Modes:** ${MODES[*]}"
    echo ""

    # --- Metrics table ---
    echo "## Metrics"
    echo ""
    if [ "$BOTH" = "true" ]; then
        echo "| Metric | ACP | Baseline | Diff | Change |"
        echo "|--------|-----|----------|------|--------|"
        echo "| Input Tokens | ${INPUT_TOKENS[acp]:-0} | ${INPUT_TOKENS[baseline]:-0} | $(diff_str "${INPUT_TOKENS[acp]:-0}" "${INPUT_TOKENS[baseline]:-0}") | $(pct_diff "${INPUT_TOKENS[acp]:-0}" "${INPUT_TOKENS[baseline]:-0}") |"
        echo "| Output Tokens | ${OUTPUT_TOKENS[acp]:-0} | ${OUTPUT_TOKENS[baseline]:-0} | $(diff_str "${OUTPUT_TOKENS[acp]:-0}" "${OUTPUT_TOKENS[baseline]:-0}") | $(pct_diff "${OUTPUT_TOKENS[acp]:-0}" "${OUTPUT_TOKENS[baseline]:-0}") |"
        echo "| Turns | ${NUM_TURNS[acp]:-0} | ${NUM_TURNS[baseline]:-0} | $(diff_str "${NUM_TURNS[acp]:-0}" "${NUM_TURNS[baseline]:-0}") | $(pct_diff "${NUM_TURNS[acp]:-0}" "${NUM_TURNS[baseline]:-0}") |"
        echo "| Duration (s) | ${DURATION[acp]:-0} | ${DURATION[baseline]:-0} | $(diff_str "${DURATION[acp]:-0}" "${DURATION[baseline]:-0}") | $(pct_diff "${DURATION[acp]:-0}" "${DURATION[baseline]:-0}") |"
        echo "| Cost (USD) | ${COST[acp]:-0} | ${COST[baseline]:-0} | — | — |"
    else
        mode="${MODES[0]}"
        label="${mode^}"
        echo "| Metric | $label |"
        echo "|--------|-------|"
        echo "| Input Tokens | ${INPUT_TOKENS[$mode]:-0} |"
        echo "| Output Tokens | ${OUTPUT_TOKENS[$mode]:-0} |"
        echo "| Turns | ${NUM_TURNS[$mode]:-0} |"
        echo "| Duration (s) | ${DURATION[$mode]:-0} |"
        echo "| Cost (USD) | ${COST[$mode]:-0} |"
    fi

    echo ""

    # --- Verification table ---
    echo "## Verification"
    echo ""
    if [ "$BOTH" = "true" ]; then
        echo "| Check | ACP | Baseline |"
        echo "|-------|-----|----------|"
        echo "| file_exists | ${FILE_EXISTS[acp]:-—} | ${FILE_EXISTS[baseline]:-—} |"
        echo "| file_executable | ${FILE_EXECUTABLE[acp]:-—} | ${FILE_EXECUTABLE[baseline]:-—} |"
        echo "| output_correct | ${OUTPUT_CORRECT[acp]:-—} | ${OUTPUT_CORRECT[baseline]:-—} |"
        echo "| Checks | ${CHECKS[acp]:-—} | ${CHECKS[baseline]:-—} |"
        echo "| **Overall** | **${ALL_PASSED[acp]:-—}** | **${ALL_PASSED[baseline]:-—}** |"
    else
        mode="${MODES[0]}"
        label="${mode^}"
        echo "| Check | $label |"
        echo "|-------|-------|"
        echo "| file_exists | ${FILE_EXISTS[$mode]:-—} |"
        echo "| file_executable | ${FILE_EXECUTABLE[$mode]:-—} |"
        echo "| output_correct | ${OUTPUT_CORRECT[$mode]:-—} |"
        echo "| Checks | ${CHECKS[$mode]:-—} |"
        echo "| **Overall** | **${ALL_PASSED[$mode]:-—}** |"
    fi

    echo ""

    # --- Per-step breakdown (if available) ---
    has_steps="false"
    for mode in "${MODES[@]}"; do
        file="$REPORT_DIR/${TASK}-${mode}.yaml"
        if [ -f "$file" ] && grep -q '^steps:' "$file" 2>/dev/null; then
            has_steps="true"
            break
        fi
    done

    if [ "$has_steps" = "true" ]; then
        echo "## Per-Step Breakdown"
        echo ""
        for mode in "${MODES[@]}"; do
            file="$REPORT_DIR/${TASK}-${mode}.yaml"
            if [ -f "$file" ] && grep -q '^steps:' "$file" 2>/dev/null; then
                label="${mode^}"
                echo "### $label"
                echo ""
                echo "| Step | Phase | Duration (s) | Input Tokens | Output Tokens | Turns |"
                echo "|------|-------|-------------|-------------|--------------|-------|"
                # Parse step data from YAML
                in_steps="false"
                step_id="" step_phase="" step_dur="" step_in="" step_out="" step_turns=""
                while IFS= read -r line; do
                    if [[ "$line" =~ ^steps: ]]; then
                        in_steps="true"
                        continue
                    fi
                    if [ "$in_steps" = "true" ]; then
                        if [[ "$line" =~ ^[a-z] ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then break; fi
                        if [[ "$line" =~ "step_id:" ]]; then
                            # Print previous step if exists
                            if [ -n "$step_id" ]; then
                                echo "| $step_id | ${step_phase:-—} | ${step_dur:-—} | ${step_in:-—} | ${step_out:-—} | ${step_turns:-—} |"
                            fi
                            step_id=$(echo "$line" | awk '{print $2}')
                            step_phase="" step_dur="" step_in="" step_out="" step_turns=""
                        fi
                        [[ "$line" =~ "phase:" ]] && step_phase=$(echo "$line" | awk '{print $2}')
                        [[ "$line" =~ "duration_seconds:" ]] && step_dur=$(echo "$line" | awk '{print $2}')
                        [[ "$line" =~ "input_tokens:" ]] && step_in=$(echo "$line" | awk '{print $2}')
                        [[ "$line" =~ "output_tokens:" ]] && step_out=$(echo "$line" | awk '{print $2}')
                        [[ "$line" =~ "num_turns:" ]] && step_turns=$(echo "$line" | awk '{print $2}')
                    fi
                done < "$file"
                # Print last step
                if [ -n "$step_id" ]; then
                    echo "| $step_id | ${step_phase:-—} | ${step_dur:-—} | ${step_in:-—} | ${step_out:-—} | ${step_turns:-—} |"
                fi
                echo ""
            fi
        done
    fi

    # --- Evaluation table (if data available) ---
    has_eval="false"
    for mode in "${MODES[@]}"; do
        if [ -n "${EVAL_SCORE[$mode]:-}" ]; then has_eval="true"; break; fi
    done

    if [ "$has_eval" = "true" ]; then
        echo "## LLM Evaluation"
        echo ""
        if [ "$BOTH" = "true" ]; then
            echo "| Category | ACP | Baseline |"
            echo "|----------|-----|----------|"
            echo "| Correctness | ${EVAL_CORRECTNESS[acp]:-—} | ${EVAL_CORRECTNESS[baseline]:-—} |"
            echo "| Completeness | ${EVAL_COMPLETENESS[acp]:-—} | ${EVAL_COMPLETENESS[baseline]:-—} |"
            echo "| Code Style | ${EVAL_CODE_STYLE[acp]:-—} | ${EVAL_CODE_STYLE[baseline]:-—} |"
            echo "| Documentation | ${EVAL_DOCUMENTATION[acp]:-—} | ${EVAL_DOCUMENTATION[baseline]:-—} |"
            echo "| Architecture | ${EVAL_ARCHITECTURE[acp]:-—} | ${EVAL_ARCHITECTURE[baseline]:-—} |"
            echo "| Testing | ${EVAL_TESTING[acp]:-—} | ${EVAL_TESTING[baseline]:-—} |"
            echo "| **Overall** | **${EVAL_SCORE[acp]:-—} (${EVAL_RATING[acp]:-—})** | **${EVAL_SCORE[baseline]:-—} (${EVAL_RATING[baseline]:-—})** |"
        else
            mode="${MODES[0]}"
            label="${mode^}"
            echo "| Category | $label |"
            echo "|----------|-------|"
            echo "| Correctness | ${EVAL_CORRECTNESS[$mode]:-—} |"
            echo "| Completeness | ${EVAL_COMPLETENESS[$mode]:-—} |"
            echo "| Code Style | ${EVAL_CODE_STYLE[$mode]:-—} |"
            echo "| Documentation | ${EVAL_DOCUMENTATION[$mode]:-—} |"
            echo "| Architecture | ${EVAL_ARCHITECTURE[$mode]:-—} |"
            echo "| Testing | ${EVAL_TESTING[$mode]:-—} |"
            echo "| **Overall** | **${EVAL_SCORE[$mode]:-—} (${EVAL_RATING[$mode]:-—})** |"
        fi
        echo ""
        for mode in "${MODES[@]}"; do
            if [ -n "${EVAL_SUMMARY[$mode]:-}" ]; then
                label="${mode^}"
                echo "**${label} Summary:** ${EVAL_SUMMARY[$mode]}"
                echo ""
            fi
        done
    fi

} > "$REPORT_FILE"

echo "  Markdown report written to $REPORT_FILE"
