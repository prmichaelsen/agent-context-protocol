#!/bin/bash
# report-html.sh — Generate a standalone HTML report from benchmark results
# Usage: bash report-html.sh <report_dir> <task> <mode1> [mode2]
# Can be re-run independently against any existing report directory.

set -euo pipefail

REPORT_DIR="$1"
TASK="$2"
shift 2
MODES=("$@")

REPORT_FILE="$REPORT_DIR/report.html"

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

# --- Helpers ---
pass_fail_class() {
    if [ "$1" = "true" ]; then echo "pass"; else echo "fail"; fi
}

diff_cell() {
    local acp_val="$1"
    local baseline_val="$2"
    if ! [[ "$acp_val" =~ ^[0-9]+$ ]] || ! [[ "$baseline_val" =~ ^[0-9]+$ ]]; then
        echo "<td>&mdash;</td>"
        return
    fi
    local diff=$((acp_val - baseline_val))
    if [ "$diff" -lt 0 ]; then
        echo "<td class=\"better\">${diff}</td>"
    elif [ "$diff" -gt 0 ]; then
        echo "<td class=\"worse\">+${diff}</td>"
    else
        echo "<td>0</td>"
    fi
}

pct_cell() {
    local acp_val="$1"
    local baseline_val="$2"
    if ! [[ "$acp_val" =~ ^[0-9]+$ ]] || ! [[ "$baseline_val" =~ ^[0-9]+$ ]] || [ "$baseline_val" -eq 0 ]; then
        echo "<td>&mdash;</td>"
        return
    fi
    local diff=$((acp_val - baseline_val))
    local pct=$(( (diff * 100) / baseline_val ))
    if [ "$pct" -lt 0 ]; then
        echo "<td class=\"better\">${pct}%</td>"
    elif [ "$pct" -gt 0 ]; then
        echo "<td class=\"worse\">+${pct}%</td>"
    else
        echo "<td>0%</td>"
    fi
}

score_class() {
    local score="$1"
    if [ -z "$score" ] || [ "$score" = "—" ]; then echo ""; return; fi
    local int_score="${score%%.*}"
    if [ "$int_score" -ge 8 ] 2>/dev/null; then echo "score-high"
    elif [ "$int_score" -ge 4 ] 2>/dev/null; then echo "score-mid"
    else echo "score-low"
    fi
}

# --- Write HTML report ---
{
cat << 'STYLE_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    max-width: 960px;
    margin: 2rem auto;
    padding: 0 1rem;
    color: #24292e;
    background: #fff;
  }
  h1 { border-bottom: 1px solid #e1e4e8; padding-bottom: 0.3em; }
  h2 { margin-top: 1.5em; }
  h3 { margin-top: 1em; color: #586069; }
  .meta { color: #586069; font-size: 0.9em; margin-bottom: 1.5em; }
  table {
    border-collapse: collapse;
    width: 100%;
    margin: 1em 0;
  }
  th, td {
    border: 1px solid #e1e4e8;
    padding: 8px 12px;
    text-align: left;
  }
  th { background: #f6f8fa; font-weight: 600; }
  tr:nth-child(even) { background: #fafbfc; }
  .pass { background: #dcffe4; color: #22863a; font-weight: 600; }
  .fail { background: #ffeef0; color: #cb2431; font-weight: 600; }
  .better { background: #dcffe4; color: #22863a; }
  .worse { background: #ffeef0; color: #cb2431; }
  .score-high { background: #dcffe4; color: #22863a; font-weight: 600; }
  .score-mid { background: #fff8c5; color: #735c0f; font-weight: 600; }
  .score-low { background: #ffeef0; color: #cb2431; font-weight: 600; }
  .eval-summary { background: #f6f8fa; border-left: 3px solid #0366d6; padding: 0.8em 1em; margin: 1em 0; font-style: italic; }
  .radar-container { display: flex; justify-content: center; margin: 1.5em 0; }
  canvas { max-width: 400px; }
  .step-table { font-size: 0.9em; }
  .step-table td { padding: 6px 10px; }
</style>
STYLE_EOF

echo "<title>Benchmark: $TASK</title>"
echo "</head>"
echo "<body>"
echo "<h1>Benchmark Report: $TASK</h1>"
echo "<p class=\"meta\">Generated: $TIMESTAMP &mdash; Modes: ${MODES[*]}</p>"

# --- Metrics table ---
echo "<h2>Metrics</h2>"
echo "<table>"

if [ "$BOTH" = "true" ]; then
    echo "<tr><th>Metric</th><th>ACP</th><th>Baseline</th><th>Diff</th><th>Change</th></tr>"
    echo "<tr><td>Input Tokens</td><td>${INPUT_TOKENS[acp]:-0}</td><td>${INPUT_TOKENS[baseline]:-0}</td>$(diff_cell "${INPUT_TOKENS[acp]:-0}" "${INPUT_TOKENS[baseline]:-0}")$(pct_cell "${INPUT_TOKENS[acp]:-0}" "${INPUT_TOKENS[baseline]:-0}")</tr>"
    echo "<tr><td>Output Tokens</td><td>${OUTPUT_TOKENS[acp]:-0}</td><td>${OUTPUT_TOKENS[baseline]:-0}</td>$(diff_cell "${OUTPUT_TOKENS[acp]:-0}" "${OUTPUT_TOKENS[baseline]:-0}")$(pct_cell "${OUTPUT_TOKENS[acp]:-0}" "${OUTPUT_TOKENS[baseline]:-0}")</tr>"
    echo "<tr><td>Turns</td><td>${NUM_TURNS[acp]:-0}</td><td>${NUM_TURNS[baseline]:-0}</td>$(diff_cell "${NUM_TURNS[acp]:-0}" "${NUM_TURNS[baseline]:-0}")$(pct_cell "${NUM_TURNS[acp]:-0}" "${NUM_TURNS[baseline]:-0}")</tr>"
    echo "<tr><td>Duration (s)</td><td>${DURATION[acp]:-0}</td><td>${DURATION[baseline]:-0}</td>$(diff_cell "${DURATION[acp]:-0}" "${DURATION[baseline]:-0}")$(pct_cell "${DURATION[acp]:-0}" "${DURATION[baseline]:-0}")</tr>"
    echo "<tr><td>Cost (USD)</td><td>${COST[acp]:-0}</td><td>${COST[baseline]:-0}</td><td>&mdash;</td><td>&mdash;</td></tr>"
else
    mode="${MODES[0]}"
    label="${mode^}"
    echo "<tr><th>Metric</th><th>$label</th></tr>"
    echo "<tr><td>Input Tokens</td><td>${INPUT_TOKENS[$mode]:-0}</td></tr>"
    echo "<tr><td>Output Tokens</td><td>${OUTPUT_TOKENS[$mode]:-0}</td></tr>"
    echo "<tr><td>Turns</td><td>${NUM_TURNS[$mode]:-0}</td></tr>"
    echo "<tr><td>Duration (s)</td><td>${DURATION[$mode]:-0}</td></tr>"
    echo "<tr><td>Cost (USD)</td><td>${COST[$mode]:-0}</td></tr>"
fi

echo "</table>"

# --- Verification table ---
echo "<h2>Verification</h2>"
echo "<table>"

if [ "$BOTH" = "true" ]; then
    echo "<tr><th>Check</th><th>ACP</th><th>Baseline</th></tr>"
    echo "<tr><td>file_exists</td><td class=\"$(pass_fail_class "${FILE_EXISTS[acp]:-false}")\">${FILE_EXISTS[acp]:-—}</td><td class=\"$(pass_fail_class "${FILE_EXISTS[baseline]:-false}")\">${FILE_EXISTS[baseline]:-—}</td></tr>"
    echo "<tr><td>file_executable</td><td class=\"$(pass_fail_class "${FILE_EXECUTABLE[acp]:-false}")\">${FILE_EXECUTABLE[acp]:-—}</td><td class=\"$(pass_fail_class "${FILE_EXECUTABLE[baseline]:-false}")\">${FILE_EXECUTABLE[baseline]:-—}</td></tr>"
    echo "<tr><td>output_correct</td><td class=\"$(pass_fail_class "${OUTPUT_CORRECT[acp]:-false}")\">${OUTPUT_CORRECT[acp]:-—}</td><td class=\"$(pass_fail_class "${OUTPUT_CORRECT[baseline]:-false}")\">${OUTPUT_CORRECT[baseline]:-—}</td></tr>"
    echo "<tr><td>Checks</td><td>${CHECKS[acp]:-—}</td><td>${CHECKS[baseline]:-—}</td></tr>"
    echo "<tr><td><strong>Overall</strong></td><td class=\"$(pass_fail_class "${ALL_PASSED[acp]:-false}")\"><strong>${ALL_PASSED[acp]:-—}</strong></td><td class=\"$(pass_fail_class "${ALL_PASSED[baseline]:-false}")\"><strong>${ALL_PASSED[baseline]:-—}</strong></td></tr>"
else
    mode="${MODES[0]}"
    label="${mode^}"
    echo "<tr><th>Check</th><th>$label</th></tr>"
    echo "<tr><td>file_exists</td><td class=\"$(pass_fail_class "${FILE_EXISTS[$mode]:-false}")\">${FILE_EXISTS[$mode]:-—}</td></tr>"
    echo "<tr><td>file_executable</td><td class=\"$(pass_fail_class "${FILE_EXECUTABLE[$mode]:-false}")\">${FILE_EXECUTABLE[$mode]:-—}</td></tr>"
    echo "<tr><td>output_correct</td><td class=\"$(pass_fail_class "${OUTPUT_CORRECT[$mode]:-false}")\">${OUTPUT_CORRECT[$mode]:-—}</td></tr>"
    echo "<tr><td>Checks</td><td>${CHECKS[$mode]:-—}</td></tr>"
    echo "<tr><td><strong>Overall</strong></td><td class=\"$(pass_fail_class "${ALL_PASSED[$mode]:-false}")\"><strong>${ALL_PASSED[$mode]:-—}</strong></td></tr>"
fi

echo "</table>"

# --- Per-step breakdown ---
has_steps="false"
for mode in "${MODES[@]}"; do
    file="$REPORT_DIR/${TASK}-${mode}.yaml"
    if [ -f "$file" ] && grep -q '^steps:' "$file" 2>/dev/null; then
        has_steps="true"
        break
    fi
done

if [ "$has_steps" = "true" ]; then
    echo "<h2>Per-Step Breakdown</h2>"
    for mode in "${MODES[@]}"; do
        file="$REPORT_DIR/${TASK}-${mode}.yaml"
        if [ -f "$file" ] && grep -q '^steps:' "$file" 2>/dev/null; then
            label="${mode^}"
            echo "<h3>$label</h3>"
            echo "<table class=\"step-table\">"
            echo "<tr><th>Step</th><th>Phase</th><th>Duration (s)</th><th>Input Tokens</th><th>Output Tokens</th><th>Turns</th></tr>"
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
                        if [ -n "$step_id" ]; then
                            echo "<tr><td>$step_id</td><td>${step_phase:-—}</td><td>${step_dur:-—}</td><td>${step_in:-—}</td><td>${step_out:-—}</td><td>${step_turns:-—}</td></tr>"
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
            if [ -n "$step_id" ]; then
                echo "<tr><td>$step_id</td><td>${step_phase:-—}</td><td>${step_dur:-—}</td><td>${step_in:-—}</td><td>${step_out:-—}</td><td>${step_turns:-—}</td></tr>"
            fi
            echo "</table>"
        fi
    done
fi

# --- Evaluation table ---
has_eval="false"
for mode in "${MODES[@]}"; do
    if [ -n "${EVAL_SCORE[$mode]:-}" ]; then has_eval="true"; break; fi
done

if [ "$has_eval" = "true" ]; then
    echo "<h2>LLM Evaluation</h2>"

    # Radar chart using Chart.js CDN
    echo '<div class="radar-container"><canvas id="radarChart" width="400" height="400"></canvas></div>'
    echo '<script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>'
    echo '<script>'
    echo 'const ctx = document.getElementById("radarChart").getContext("2d");'
    echo 'new Chart(ctx, {'
    echo '  type: "radar",'
    echo '  data: {'
    echo '    labels: ["Correctness", "Completeness", "Code Style", "Documentation", "Architecture", "Testing"],'
    echo '    datasets: ['

    first_ds="true"
    for mode in "${MODES[@]}"; do
        if [ -n "${EVAL_CORRECTNESS[$mode]:-}" ]; then
            if [ "$first_ds" = "false" ]; then echo ','; fi
            first_ds="false"
            label="${mode^}"
            if [ "$mode" = "acp" ]; then
                color="54, 162, 235"
            else
                color="255, 99, 132"
            fi
            echo "      {"
            echo "        label: \"$label\","
            echo "        data: [${EVAL_CORRECTNESS[$mode]:-0}, ${EVAL_COMPLETENESS[$mode]:-0}, ${EVAL_CODE_STYLE[$mode]:-0}, ${EVAL_DOCUMENTATION[$mode]:-0}, ${EVAL_ARCHITECTURE[$mode]:-0}, ${EVAL_TESTING[$mode]:-0}],"
            echo "        borderColor: \"rgba($color, 1)\","
            echo "        backgroundColor: \"rgba($color, 0.2)\","
            echo "        pointBackgroundColor: \"rgba($color, 1)\""
            echo "      }"
        fi
    done

    echo '    ]'
    echo '  },'
    echo '  options: {'
    echo '    scales: { r: { min: 0, max: 10, ticks: { stepSize: 2 } } },'
    echo '    plugins: { legend: { position: "bottom" } }'
    echo '  }'
    echo '});'
    echo '</script>'

    # Score table
    echo "<table>"
    if [ "$BOTH" = "true" ]; then
        echo "<tr><th>Category</th><th>ACP</th><th>Baseline</th></tr>"
        for cat_label_var in "Correctness:EVAL_CORRECTNESS" "Completeness:EVAL_COMPLETENESS" "Code Style:EVAL_CODE_STYLE" "Documentation:EVAL_DOCUMENTATION" "Architecture:EVAL_ARCHITECTURE" "Testing:EVAL_TESTING"; do
            cat_label="${cat_label_var%%:*}"
            cat_var="${cat_label_var##*:}"
            eval "acp_val=\${${cat_var}[acp]:-—}"
            eval "base_val=\${${cat_var}[baseline]:-—}"
            echo "<tr><td>$cat_label</td><td class=\"$(score_class "$acp_val")\">$acp_val</td><td class=\"$(score_class "$base_val")\">$base_val</td></tr>"
        done
        echo "<tr><td><strong>Overall</strong></td><td class=\"$(score_class "${EVAL_SCORE[acp]:-}")\"><strong>${EVAL_SCORE[acp]:-—} (${EVAL_RATING[acp]:-—})</strong></td><td class=\"$(score_class "${EVAL_SCORE[baseline]:-}")\"><strong>${EVAL_SCORE[baseline]:-—} (${EVAL_RATING[baseline]:-—})</strong></td></tr>"
    else
        mode="${MODES[0]}"
        label="${mode^}"
        echo "<tr><th>Category</th><th>$label</th></tr>"
        for cat_label_var in "Correctness:EVAL_CORRECTNESS" "Completeness:EVAL_COMPLETENESS" "Code Style:EVAL_CODE_STYLE" "Documentation:EVAL_DOCUMENTATION" "Architecture:EVAL_ARCHITECTURE" "Testing:EVAL_TESTING"; do
            cat_label="${cat_label_var%%:*}"
            cat_var="${cat_label_var##*:}"
            eval "val=\${${cat_var}[$mode]:-—}"
            echo "<tr><td>$cat_label</td><td class=\"$(score_class "$val")\">$val</td></tr>"
        done
        echo "<tr><td><strong>Overall</strong></td><td class=\"$(score_class "${EVAL_SCORE[$mode]:-}")\"><strong>${EVAL_SCORE[$mode]:-—} (${EVAL_RATING[$mode]:-—})</strong></td></tr>"
    fi
    echo "</table>"

    for mode in "${MODES[@]}"; do
        if [ -n "${EVAL_SUMMARY[$mode]:-}" ]; then
            label="${mode^}"
            echo "<div class=\"eval-summary\"><strong>${label}:</strong> ${EVAL_SUMMARY[$mode]}</div>"
        fi
    done
fi

echo "</body>"
echo "</html>"

} > "$REPORT_FILE"

echo "  HTML report written to $REPORT_FILE"
