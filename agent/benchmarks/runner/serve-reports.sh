#!/bin/bash
# serve-reports.sh — Generate an index.html listing all benchmark reports and serve over HTTP
# Usage: bash serve-reports.sh [--port <N>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$BENCHMARKS_DIR/reports"

# --- Parse arguments ---
PORT=9876

GENERATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --generate-only) GENERATE_ONLY=true; shift ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# --- Helper: extract a field value from a YAML file ---
get_field() {
    local file="$1"
    local field="$2"
    grep "${field}:" "$file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '[]' || true
}

# --- Function: generate index.html ---
generate_index() {
    local INDEX_FILE="$REPORTS_DIR/index.html"

    {
    cat << 'STYLE_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Benchmark Reports</title>
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
  a { color: #0366d6; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .links a { margin-right: 0.5em; }
  .empty { color: #586069; font-style: italic; text-align: center; padding: 2em; }
</style>
</head>
<body>
STYLE_EOF

    echo "<h1>Benchmark Reports</h1>"
    echo "<p class=\"meta\">Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")</p>"

    # Collect benchmark directories (reverse sorted = newest first)
    local dirs=()
    for dir in "$REPORTS_DIR"/benchmark-*/; do
        [ -d "$dir" ] && dirs+=("$dir")
    done

    if [ ${#dirs[@]} -eq 0 ]; then
        echo "<p class=\"empty\">No benchmark reports found.</p>"
    else
        echo "<table>"
        echo "<tr><th>Timestamp</th><th>Task(s)</th><th>Modes</th><th>Result</th><th>Eval Score</th><th>Links</th></tr>"

        # Reverse sort (newest first) by directory name
        IFS=$'\n' local sorted=($(printf '%s\n' "${dirs[@]}" | sort -r)); unset IFS

        for dir in "${sorted[@]}"; do
            local dirname="$(basename "$dir")"
            local summary="$dir/summary.yaml"

            if [ ! -f "$summary" ]; then
                local timestamp="${dirname#benchmark-}"
                echo "<tr>"
                echo "  <td>$timestamp</td>"
                echo "  <td>&mdash;</td>"
                echo "  <td>&mdash;</td>"
                echo "  <td>&mdash;</td>"
                echo "  <td>&mdash;</td>"
                echo "  <td class=\"links\">&mdash;</td>"
                echo "</tr>"
                continue
            fi

            local tasks_raw="$(get_field "$summary" "tasks")"
            [ -z "$tasks_raw" ] && tasks_raw="$(get_field "$summary" "task")"
            local timestamp="$(get_field "$summary" "timestamp")"
            local modes="$(get_field "$summary" "modes_run")"

            # Parse task list (may be comma-separated)
            local tasks_display="${tasks_raw//,/ }"

            # Determine overall pass/fail
            local overall_pass="true"
            local mode_name
            for mode_name in $(echo "$modes" | tr ',' ' '); do
                local mode_passed="$(grep -A5 "^  ${mode_name}:" "$summary" 2>/dev/null | grep "passed:" | head -1 | awk '{print $2}')"
                if [ "$mode_passed" != "true" ] && [ -n "$mode_passed" ]; then
                    overall_pass="false"
                fi
            done

            local result_class result_text
            if [ "$overall_pass" = "true" ]; then
                result_class="pass"
                result_text="PASS"
            else
                result_class="fail"
                result_text="FAIL"
            fi

            # Extract eval scores if available
            local eval_display="&mdash;"
            local acp_eval="$(grep 'overall_score:' "$summary" 2>/dev/null | head -1 | awk '{print $2}')"
            if [ -n "$acp_eval" ]; then
                local acp_rating="$(grep 'overall_rating:' "$summary" 2>/dev/null | head -1 | awk '{print $2}')"
                eval_display="${acp_eval} (${acp_rating:-—})"
            fi

            # Build links — check for multi-task reports
            local links=""
            [ -f "$dir/summary.yaml" ] && links="$links<a href=\"$dirname/summary.yaml\">YAML</a> "
            if [ -f "$dir/report.html" ]; then
                links="$links<a href=\"$dirname/report.html\">HTML</a> "
            else
                # Check for per-task reports
                for rpt in "$dir"/report-*.html; do
                    [ -f "$rpt" ] || continue
                    local rpt_name="$(basename "$rpt" .html)"
                    local task_name="${rpt_name#report-}"
                    links="$links<a href=\"$dirname/$(basename "$rpt")\">$task_name</a> "
                done
            fi
            [ -z "$links" ] && links="&mdash;"

            echo "<tr>"
            echo "  <td>$timestamp</td>"
            echo "  <td>$tasks_display</td>"
            echo "  <td>$modes</td>"
            echo "  <td class=\"$result_class\">$result_text</td>"
            echo "  <td>$eval_display</td>"
            echo "  <td class=\"links\">$links</td>"
            echo "</tr>"
        done

        echo "</table>"
    fi

    echo "</body>"
    echo "</html>"
    } > "$INDEX_FILE"
}

# --- Generate index ---
generate_index

if [ "$GENERATE_ONLY" = "true" ]; then
    exit 0
fi

echo "Index generated: $REPORTS_DIR/index.html"
echo "Serving at http://localhost:$PORT"
echo "Regenerates index.html on file changes — just refresh the page."
echo "Press Ctrl+C to stop."
echo ""

cd "$REPORTS_DIR"
export REPORTS_DIR
export SCRIPT="$SCRIPT_DIR/serve-reports.sh"

python3 -c "
import http.server
import subprocess
import os

REPORTS_DIR = os.environ['REPORTS_DIR']
SCRIPT = os.environ['SCRIPT']

class ReloadHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path in ('/', '/index.html'):
            subprocess.run(['bash', SCRIPT, '--generate-only'], check=False)
        return super().do_GET()

http.server.HTTPServer(('', $PORT), ReloadHandler).serve_forever()
"
