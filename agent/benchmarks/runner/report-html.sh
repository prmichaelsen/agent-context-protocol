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
    grep "${field}:" "$file" | awk '{print $2}'
}

# --- Load data for each mode ---
declare -A INPUT_TOKENS OUTPUT_TOKENS NUM_TURNS DURATION COST
declare -A FILE_EXISTS FILE_EXECUTABLE OUTPUT_CORRECT ALL_PASSED

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
    fi
done

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BOTH=$( [ "${#MODES[@]}" -eq 2 ] && echo "true" || echo "false" )

# --- Helper: HTML class for pass/fail ---
pass_fail_class() {
    if [ "$1" = "true" ]; then echo "pass"; else echo "fail"; fi
}

# --- Helper: diff cell with color class (lower is better) ---
diff_cell() {
    local acp_val="$1"
    local baseline_val="$2"
    local diff=$((acp_val - baseline_val))
    if [ "$diff" -lt 0 ]; then
        echo "<td class=\"better\">${diff}</td>"
    elif [ "$diff" -gt 0 ]; then
        echo "<td class=\"worse\">+${diff}</td>"
    else
        echo "<td>0</td>"
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
    max-width: 800px;
    margin: 2rem auto;
    padding: 0 1rem;
    color: #24292e;
    background: #fff;
  }
  h1 { border-bottom: 1px solid #e1e4e8; padding-bottom: 0.3em; }
  h2 { margin-top: 1.5em; }
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
    echo "<tr><th>Metric</th><th>ACP</th><th>Baseline</th><th>Diff</th></tr>"
    echo "<tr><td>Input Tokens</td><td>${INPUT_TOKENS[acp]}</td><td>${INPUT_TOKENS[baseline]}</td>$(diff_cell "${INPUT_TOKENS[acp]}" "${INPUT_TOKENS[baseline]}")</tr>"
    echo "<tr><td>Output Tokens</td><td>${OUTPUT_TOKENS[acp]}</td><td>${OUTPUT_TOKENS[baseline]}</td>$(diff_cell "${OUTPUT_TOKENS[acp]}" "${OUTPUT_TOKENS[baseline]}")</tr>"
    echo "<tr><td>Turns</td><td>${NUM_TURNS[acp]}</td><td>${NUM_TURNS[baseline]}</td>$(diff_cell "${NUM_TURNS[acp]}" "${NUM_TURNS[baseline]}")</tr>"
    echo "<tr><td>Duration (s)</td><td>${DURATION[acp]}</td><td>${DURATION[baseline]}</td>$(diff_cell "${DURATION[acp]}" "${DURATION[baseline]}")</tr>"
    echo "<tr><td>Cost (USD)</td><td>${COST[acp]}</td><td>${COST[baseline]}</td><td>&mdash;</td></tr>"
else
    mode="${MODES[0]}"
    label="${mode^}"
    echo "<tr><th>Metric</th><th>$label</th></tr>"
    echo "<tr><td>Input Tokens</td><td>${INPUT_TOKENS[$mode]}</td></tr>"
    echo "<tr><td>Output Tokens</td><td>${OUTPUT_TOKENS[$mode]}</td></tr>"
    echo "<tr><td>Turns</td><td>${NUM_TURNS[$mode]}</td></tr>"
    echo "<tr><td>Duration (s)</td><td>${DURATION[$mode]}</td></tr>"
    echo "<tr><td>Cost (USD)</td><td>${COST[$mode]}</td></tr>"
fi

echo "</table>"

# --- Verification table ---
echo "<h2>Verification</h2>"
echo "<table>"

if [ "$BOTH" = "true" ]; then
    echo "<tr><th>Check</th><th>ACP</th><th>Baseline</th></tr>"
    echo "<tr><td>file_exists</td><td class=\"$(pass_fail_class "${FILE_EXISTS[acp]}")\">${FILE_EXISTS[acp]}</td><td class=\"$(pass_fail_class "${FILE_EXISTS[baseline]}")\">${FILE_EXISTS[baseline]}</td></tr>"
    echo "<tr><td>file_executable</td><td class=\"$(pass_fail_class "${FILE_EXECUTABLE[acp]}")\">${FILE_EXECUTABLE[acp]}</td><td class=\"$(pass_fail_class "${FILE_EXECUTABLE[baseline]}")\">${FILE_EXECUTABLE[baseline]}</td></tr>"
    echo "<tr><td>output_correct</td><td class=\"$(pass_fail_class "${OUTPUT_CORRECT[acp]}")\">${OUTPUT_CORRECT[acp]}</td><td class=\"$(pass_fail_class "${OUTPUT_CORRECT[baseline]}")\">${OUTPUT_CORRECT[baseline]}</td></tr>"
    echo "<tr><td><strong>Overall</strong></td><td class=\"$(pass_fail_class "${ALL_PASSED[acp]}")\"><strong>${ALL_PASSED[acp]}</strong></td><td class=\"$(pass_fail_class "${ALL_PASSED[baseline]}")\"><strong>${ALL_PASSED[baseline]}</strong></td></tr>"
else
    mode="${MODES[0]}"
    label="${mode^}"
    echo "<tr><th>Check</th><th>$label</th></tr>"
    echo "<tr><td>file_exists</td><td class=\"$(pass_fail_class "${FILE_EXISTS[$mode]}")\">${FILE_EXISTS[$mode]}</td></tr>"
    echo "<tr><td>file_executable</td><td class=\"$(pass_fail_class "${FILE_EXECUTABLE[$mode]}")\">${FILE_EXECUTABLE[$mode]}</td></tr>"
    echo "<tr><td>output_correct</td><td class=\"$(pass_fail_class "${OUTPUT_CORRECT[$mode]}")\">${OUTPUT_CORRECT[$mode]}</td></tr>"
    echo "<tr><td><strong>Overall</strong></td><td class=\"$(pass_fail_class "${ALL_PASSED[$mode]}")\"><strong>${ALL_PASSED[$mode]}</strong></td></tr>"
fi

echo "</table>"
echo "</body>"
echo "</html>"

} > "$REPORT_FILE"

echo "  HTML report written to $REPORT_FILE"
