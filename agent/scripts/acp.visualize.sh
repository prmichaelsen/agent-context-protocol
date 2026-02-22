#!/usr/bin/env bash
# ACP Progress Visualizer Server
# Automatically loads local progress.yaml and serves visualizer with auto-refresh

set -e

# Parse arguments
WATCH_MODE=true  # Default enabled
for arg in "$@"; do
    case $arg in
        --no-watch)
            WATCH_MODE=false
            shift
            ;;
        --watch|-w)
            WATCH_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--watch|-w|--no-watch]"
            echo ""
            echo "Options:"
            echo "  --watch, -w    Enable file watching (default)"
            echo "  --no-watch     Disable file watching"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common utilities
source "$SCRIPT_DIR/acp.common.sh"

# Check for progress.yaml
PROGRESS_FILE="$PROJECT_ROOT/agent/progress.yaml"
if [ ! -f "$PROGRESS_FILE" ]; then
    die "progress.yaml not found at $PROGRESS_FILE"
fi

# Check for visualizer
VISUALIZER_FILE="$SCRIPT_DIR/progress-visualizer.html"
if [ ! -f "$VISUALIZER_FILE" ]; then
    die "progress-visualizer.html not found. Run @acp.version-update to get latest ACP files"
fi

# Create temporary directory for server
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "${BLUE}🎯 ACP Progress Visualizer${NC}"
echo "========================================"
echo ""


# Find available port
PORT=8001
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; do
    PORT=$((PORT + 1))
done

info "Starting local server on port $PORT..."
echo ""
echo "Visualizer URL: ${GREEN}http://localhost:$PORT${NC}"
echo ""

# Detect if we're in a remote session
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
    warn "Remote session detected - open URL manually in your local browser"
    echo ""
    echo "If using VS Code Remote, the port may be forwarded automatically."
    echo "Check your VS Code ports panel or open: http://localhost:$PORT"
else
    # Local session - try to open browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:$PORT" &>/dev/null &
        success "Browser opened"
    elif command -v open &> /dev/null; then
        open "http://localhost:$PORT" &>/dev/null &
        success "Browser opened"
    elif command -v start &> /dev/null; then
        start "http://localhost:$PORT" &>/dev/null &
        success "Browser opened"
    else
        warn "Could not auto-open browser. Open URL manually: http://localhost:$PORT"
    fi
fi

echo ""
echo "Press Ctrl+C to stop the server"
echo ""
warn "💡 Tip: Keep this running and refresh browser after updating progress.yaml"
echo ""

# Start server
cd "$TEMP_DIR"

# Function to generate HTML with embedded data
generate_html() {
    local output_file="$1"
    
    # Create index.html with embedded data
    cat > "$output_file" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ACP Progress Visualizer</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/js-yaml/4.1.0/js-yaml.min.js"></script>
    <style>
HTMLEOF

    # Extract and append CSS
    sed -n '/<style>/,/<\/style>/p' "$VISUALIZER_FILE" | sed '1d;$d' >> "$output_file"

    cat >> "$output_file" << 'HTMLEOF'
    </style>
</head>
<body>
    <header>
        <div class="container">
            <h1>🎯 ACP Progress Visualizer</h1>
            <p style="color: var(--text-secondary);">Auto-loaded from agent/progress.yaml • Auto-refresh enabled</p>
            <div class="header-controls">
                <button onclick="location.reload()">🔄 Refresh</button>
                <button class="theme-toggle" onclick="toggleTheme()">🌓 Toggle Theme</button>
                <button onclick="window.print()">🖨️ Print</button>
            </div>
        </div>
    </header>

    <div class="container">
        <div id="content">
            <div id="stats" class="stats-grid"></div>
            <div id="milestones"></div>
        </div>
        <div id="error" class="error hidden"></div>
    </div>

    <script>
        // Progress data embedded by server (auto-reloads on file change)
        const embeddedProgressYaml = `
HTMLEOF

    # Append progress.yaml content (escaped)
    cat "$PROGRESS_FILE" | sed 's/`/\\`/g' | sed 's/\$/\\$/g' >> "$output_file"

    cat >> "$output_file" << 'HTMLEOF'
`;

        // Parse embedded data and render immediately
        let progressData = null;
        try {
            progressData = jsyaml.load(embeddedProgressYaml);
            renderVisualization();
        } catch (error) {
            showError('Failed to parse embedded progress.yaml', error);
        }
HTMLEOF

    # Append all JavaScript functions from visualizer
    cat >> "$output_file" << 'JSEOF'

        // Theme toggle
        function toggleTheme() {
            const html = document.documentElement;
            const currentTheme = html.getAttribute('data-theme');
            html.setAttribute('data-theme', currentTheme === 'dark' ? 'light' : 'dark');
            localStorage.setItem('theme', currentTheme === 'dark' ? 'light' : 'dark');
        }

        // Load saved theme
        const savedTheme = localStorage.getItem('theme') || 'light';
        document.documentElement.setAttribute('data-theme', savedTheme);

        function showError(message, error) {
            const errorDiv = document.getElementById('error');
            
            let errorHTML = `<div class="error-title">❌ Error</div><div>${message}</div>`;
            
            if (error) {
                if (error.stack) {
                    errorHTML += `<div class="error-stack"><strong>Stack Trace:</strong>\n${error.stack}</div>`;
                } else if (error.message) {
                    errorHTML += `<div class="error-stack"><strong>Details:</strong>\n${error.message}</div>`;
                }
            }
            
            errorDiv.innerHTML = errorHTML;
            errorDiv.classList.remove('hidden');
            document.getElementById('content').classList.add('hidden');
        }

        function renderVisualization() {
            document.getElementById('error').classList.add('hidden');
            document.getElementById('content').classList.remove('hidden');

            renderStats();
            renderMilestones();
        }

        function renderStats() {
            const stats = document.getElementById('stats');
            const milestones = progressData.milestones || [];
            const completedMilestones = milestones.filter(m => m.status === 'completed').length;
            const overallProgress = progressData.progress?.overall || 0;
            
            let totalTasks = 0;
            let completedTasks = 0;
            Object.values(progressData.tasks || {}).forEach(taskList => {
                taskList.forEach(task => {
                    totalTasks++;
                    if (task.status === 'completed') completedTasks++;
                });
            });

            stats.innerHTML = `
                <div class="stat-card">
                    <div class="stat-value">${overallProgress}%</div>
                    <div class="stat-label">Overall Progress</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${completedMilestones}/${milestones.length}</div>
                    <div class="stat-label">Milestones Complete</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${completedTasks}/${totalTasks}</div>
                    <div class="stat-label">Tasks Complete</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">${progressData.project?.version || 'N/A'}</div>
                    <div class="stat-label">Version</div>
                </div>
            `;
        }

        function renderMilestones() {
            const milestonesDiv = document.getElementById('milestones');
            const milestones = progressData.milestones || [];
            
            milestonesDiv.innerHTML = milestones.map((milestone, index) => {
                const statusClass = `status-${milestone.status.replace('_', '-')}`;
                const statusText = milestone.status.replace('_', ' ').toUpperCase();
                const progress = milestone.progress || 0;
                
                const milestoneKey = `milestone_${index + 1}`;
                const tasks = progressData.tasks?.[milestoneKey] || [];
                
                return `
                    <div class="milestone-card">
                        <div class="milestone-header" onclick="toggleTasks('milestone-${index}')">
                            <div>
                                <div class="milestone-title">${milestone.id}: ${milestone.name}</div>
                                <div class="milestone-meta">
                                    <span>📅 ${milestone.started || 'Not started'}</span>
                                    <span>📊 ${milestone.tasks_completed}/${milestone.tasks_total} tasks</span>
                                    ${milestone.estimated_weeks ? `<span>⏱️ Est: ${milestone.estimated_weeks} weeks</span>` : ''}
                                </div>
                            </div>
                            <span class="milestone-status ${statusClass}">${statusText}</span>
                        </div>
                        
                        <div class="progress-bar-container">
                            <div class="progress-bar" style="width: ${progress}%">
                                ${progress}%
                            </div>
                        </div>
                        
                        <div id="milestone-${index}" class="task-list">
                            ${tasks.map(task => renderTask(task)).join('')}
                        </div>
                    </div>
                `;
            }).join('');
        }

        function renderTask(task) {
            const icon = task.status === 'completed' ? '✅' :
                        task.status === 'in_progress' ? '⏳' : '⭕';
            
            const estimatedHours = task.estimated_hours || 'N/A';
            const actualHours = task.actual_hours || 'N/A';
            const variance = task.actual_hours && task.estimated_hours ?
                calculateVariance(task.estimated_hours, task.actual_hours) : '';
            
            return `
                <div class="task-item">
                    <span class="task-icon">${icon}</span>
                    <div class="task-info">
                        <div class="task-name">${task.name}</div>
                        <div class="task-meta">
                            Est: ${estimatedHours}h | Actual: ${actualHours}h ${variance}
                            ${task.completed_date ? `| Completed: ${task.completed_date}` : ''}
                        </div>
                    </div>
                </div>
            `;
        }

        function calculateVariance(estimated, actual) {
            const estNum = typeof estimated === 'string' && estimated.includes('-') ?
                (estimated.split('-').map(Number).reduce((a, b) => a + b) / 2) :
                Number(estimated);
            
            const variance = ((actual - estNum) / estNum * 100).toFixed(0);
            if (variance > 10) return `<span style="color: var(--warning-color)">⚠️ +${variance}%</span>`;
            if (variance < -10) return `<span style="color: var(--success-color)">✅ ${variance}%</span>`;
            return `<span style="color: var(--success-color)">✅ On target</span>`;
        }

        function toggleTasks(milestoneId) {
            const taskList = document.getElementById(milestoneId);
            taskList.classList.toggle('expanded');
        }
JSEOF

    cat >> "$output_file" << 'HTMLEOF'
    </script>
</body>
</html>
HTMLEOF
}

# Generate initial HTML
generate_html "$TEMP_DIR/index.html"

# Start file watcher in background (if watch mode enabled or tools available)
if [ "$WATCH_MODE" = true ] || command -v inotifywait &> /dev/null || command -v fswatch &> /dev/null; then
    if command -v inotifywait &> /dev/null; then
        # Linux - use inotifywait
        (
            while inotifywait -e modify "$PROGRESS_FILE" 2>/dev/null; do
                echo "${BLUE}[$(date +%H:%M:%S)]${NC} progress.yaml changed, regenerating..."
                generate_html "$TEMP_DIR/index.html"
                success "HTML regenerated - refresh browser to see changes"
            done
        ) &
        WATCHER_PID=$!
        trap "kill $WATCHER_PID 2>/dev/null; rm -rf $TEMP_DIR" EXIT
        info "File watcher enabled (inotifywait) - HTML auto-regenerates on changes"
    elif command -v fswatch &> /dev/null; then
        # macOS - use fswatch
        (
            fswatch -o "$PROGRESS_FILE" | while read; do
                echo "${BLUE}[$(date +%H:%M:%S)]${NC} progress.yaml changed, regenerating..."
                generate_html "$TEMP_DIR/index.html"
                success "HTML regenerated - refresh browser to see changes"
            done
        ) &
        WATCHER_PID=$!
        trap "kill $WATCHER_PID 2>/dev/null; rm -rf $TEMP_DIR" EXIT
        info "File watcher enabled (fswatch) - HTML auto-regenerates on changes"
    elif [ "$WATCH_MODE" = true ]; then
        # Fallback - pure bash polling
        (
            # Get initial modification time
            get_mtime() {
                if [ -f "$1" ]; then
                    stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo "0"
                else
                    echo "0"
                fi
            }
            
            last_mtime=$(get_mtime "$PROGRESS_FILE")
            
            while true; do
                sleep 2
                current_mtime=$(get_mtime "$PROGRESS_FILE")
                
                if [ "$current_mtime" != "$last_mtime" ]; then
                    echo "${BLUE}[$(date +%H:%M:%S)]${NC} progress.yaml changed, regenerating..."
                    generate_html "$TEMP_DIR/index.html"
                    success "HTML regenerated - refresh browser to see changes"
                    last_mtime="$current_mtime"
                fi
            done
        ) &
        WATCHER_PID=$!
        trap "kill $WATCHER_PID 2>/dev/null; rm -rf $TEMP_DIR" EXIT
        info "File watcher enabled (polling) - HTML auto-regenerates on changes"
    fi
else
    warn "File watcher not enabled. Use --watch flag or install inotifywait/fswatch for auto-regeneration"
    echo "Manually refresh browser after updating progress.yaml"
fi

echo ""

# Start Python HTTP server
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m http.server $PORT
else
    die "Python not found. Cannot start server. Install Python or open $TEMP_DIR/index.html manually"
fi
