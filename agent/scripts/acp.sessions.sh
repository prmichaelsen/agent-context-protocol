#!/usr/bin/env bash
# acp.sessions.sh - Global session tracking for concurrent multi-project agent work
# Part of Agent Context Protocol (ACP)
# Usage: ./acp.sessions.sh <subcommand> [options]
#
# Subcommands:
#   register    Register a new session
#   deregister  Remove a session
#   list        List active sessions
#   clean       Remove stale sessions
#   heartbeat   Update session activity
#   count       Output count of active sessions

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
source "${SCRIPT_DIR}/acp.common.sh"

# Source YAML parser
source_yaml_parser

# Sessions file location
SESSIONS_FILE="${HOME}/.acp/sessions.yaml"
SESSIONS_TEMPLATE="${SCRIPT_DIR}/../sessions.template.yaml"

# Stale thresholds (in seconds)
IDLE_THRESHOLD=1800    # 30 minutes
REMOVE_THRESHOLD=7200  # 2 hours

# ============================================================================
# HELPERS
# ============================================================================

# Generate a unique session ID
# Falls back to $RANDOM if xxd is unavailable
generate_session_id() {
    local hex
    if command -v xxd >/dev/null 2>&1; then
        hex=$(head -c 3 /dev/urandom | xxd -p)
    else
        hex=$(printf '%06x' $RANDOM)
    fi
    echo "sess_${hex}"
}

# Ensure sessions.yaml exists, creating from template if needed
ensure_sessions_file() {
    if [ ! -f "$SESSIONS_FILE" ]; then
        mkdir -p "$(dirname "$SESSIONS_FILE")"
        if [ -f "$SESSIONS_TEMPLATE" ]; then
            cp "$SESSIONS_TEMPLATE" "$SESSIONS_FILE"
        else
            cat > "$SESSIONS_FILE" << 'TMPL'
# ~/.acp/sessions.yaml
# Managed by acp.sessions.sh — do not edit manually

sessions: []

last_updated: null
TMPL
        fi
    fi
}

# Get current timestamp in epoch seconds
get_epoch() {
    date +%s
}

# Convert ISO timestamp to epoch seconds
iso_to_epoch() {
    local ts="$1"
    if [ -z "$ts" ] || [ "$ts" = "null" ]; then
        echo "0"
        return
    fi
    date -d "$ts" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || echo "0"
}

# Format seconds as relative time (e.g., "2m ago", "1h ago")
format_relative_time() {
    local seconds="$1"
    if [ "$seconds" -lt 60 ]; then
        echo "now"
    elif [ "$seconds" -lt 3600 ]; then
        echo "$((seconds / 60))m ago"
    elif [ "$seconds" -lt 86400 ]; then
        echo "$((seconds / 3600))h ago"
    else
        echo "$((seconds / 86400))d ago"
    fi
}

# Get session count from parsed YAML
get_session_count() {
    local count
    count=$(yaml_get_array "$SESSIONS_FILE" "sessions" 2>/dev/null || echo "0")
    echo "$count"
}

# Write sessions.yaml directly from session data arrays
# This bypasses yaml_delete limitations with array indices
# Args: space-separated list of indices to EXCLUDE
write_sessions_excluding() {
    local exclude_indices="$1"
    local now
    now=$(get_timestamp)

    # Read current session count (AST must already be loaded)
    local count
    count=$(yaml_get_array "$SESSIONS_FILE" "sessions" 2>/dev/null || echo "0")

    # Build output file
    local tmp_file="${SESSIONS_FILE}.tmp"
    {
        echo "# ~/.acp/sessions.yaml"
        echo "# Managed by acp.sessions.sh — do not edit manually"
        echo ""

        local has_sessions=false
        local i=0
        while [ "$i" -lt "$count" ]; do
            # Check if this index should be excluded
            local skip=false
            for ex in $exclude_indices; do
                if [ "$ex" = "$i" ]; then
                    skip=true
                    break
                fi
            done

            if [ "$skip" = "false" ]; then
                if [ "$has_sessions" = "false" ]; then
                    echo "sessions:"
                    has_sessions=true
                fi

                local id proj desc started last_activity status milestone task pid terminal remote_url
                id=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "")
                proj=$(yaml_query ".sessions[${i}].project" 2>/dev/null || echo "")
                desc=$(yaml_query ".sessions[${i}].description" 2>/dev/null || echo "")
                started=$(yaml_query ".sessions[${i}].started" 2>/dev/null || echo "")
                last_activity=$(yaml_query ".sessions[${i}].last_activity" 2>/dev/null || echo "")
                status=$(yaml_query ".sessions[${i}].status" 2>/dev/null || echo "active")
                milestone=$(yaml_query ".sessions[${i}].current_milestone" 2>/dev/null || echo "")
                task=$(yaml_query ".sessions[${i}].current_task" 2>/dev/null || echo "")
                pid=$(yaml_query ".sessions[${i}].pid" 2>/dev/null || echo "")
                terminal=$(yaml_query ".sessions[${i}].terminal" 2>/dev/null || echo "")
                remote_url=$(yaml_query ".sessions[${i}].remote_url" 2>/dev/null || echo "")

                # Normalize null values
                [ "$milestone" = "null" ] && milestone=""
                [ "$task" = "null" ] && task=""
                [ "$remote_url" = "null" ] && remote_url=""
                [ "$desc" = "null" ] && desc=""

                echo "  - id: ${id}"
                echo "    project: ${proj}"
                echo "    description: ${desc}"
                echo "    started: ${started}"
                echo "    last_activity: ${last_activity}"
                echo "    status: ${status}"
                echo "    current_milestone: ${milestone}"
                echo "    current_task: ${task}"
                echo "    pid: ${pid}"
                echo "    terminal: ${terminal}"
                echo "    remote_url: ${remote_url}"
            fi

            i=$((i + 1))
        done

        if [ "$has_sessions" = "false" ]; then
            echo "sessions: []"
        fi

        echo ""
        echo "last_updated: ${now}"
    } > "$tmp_file"

    mv "$tmp_file" "$SESSIONS_FILE"
}

# ============================================================================
# CLEAN SUBCOMMAND
# ============================================================================

# Remove stale sessions (dead PID or timed out)
do_clean() {
    local verbose="${1:-false}"
    ensure_sessions_file

    yaml_parse "$SESSIONS_FILE" || return 1

    local count
    count=$(get_session_count)

    if [ "$count" = "0" ] || [ -z "$count" ]; then
        if [ "$verbose" = "true" ]; then
            echo "No sessions to clean."
        fi
        return 0
    fi

    local cleaned=0
    local now_epoch
    now_epoch=$(get_epoch)
    local indices_to_remove=""
    local idle_indices=""

    # Check each session
    local i=0
    while [ "$i" -lt "$count" ]; do
        local pid last_activity status

        pid=$(yaml_query ".sessions[${i}].pid" 2>/dev/null || echo "")
        last_activity=$(yaml_query ".sessions[${i}].last_activity" 2>/dev/null || echo "")
        status=$(yaml_query ".sessions[${i}].status" 2>/dev/null || echo "active")

        local should_remove=false

        # Check 1: PID is dead
        if [ -n "$pid" ] && [ "$pid" != "null" ] && [ "$pid" != "0" ]; then
            if ! kill -0 "$pid" 2>/dev/null; then
                should_remove=true
                if [ "$verbose" = "true" ]; then
                    local proj sid
                    proj=$(yaml_query ".sessions[${i}].project" 2>/dev/null || echo "unknown")
                    sid=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "unknown")
                    echo "  ${sid}  ${proj} (PID ${pid} not running)"
                fi
            fi
        fi

        # Check 2: Timeout
        if [ "$should_remove" = "false" ] && [ -n "$last_activity" ] && [ "$last_activity" != "null" ]; then
            local activity_epoch elapsed
            activity_epoch=$(iso_to_epoch "$last_activity")
            elapsed=$((now_epoch - activity_epoch))

            if [ "$elapsed" -gt "$REMOVE_THRESHOLD" ]; then
                should_remove=true
                if [ "$verbose" = "true" ]; then
                    local proj sid
                    proj=$(yaml_query ".sessions[${i}].project" 2>/dev/null || echo "unknown")
                    sid=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "unknown")
                    echo "  ${sid}  ${proj} (inactive for $(format_relative_time "$elapsed"))"
                fi
            elif [ "$elapsed" -gt "$IDLE_THRESHOLD" ]; then
                idle_indices="${idle_indices} ${i}"
            fi
        fi

        if [ "$should_remove" = "true" ]; then
            indices_to_remove="${indices_to_remove} ${i}"
            cleaned=$((cleaned + 1))
        fi

        i=$((i + 1))
    done

    # Mark idle sessions (update in-place via yaml_set before rebuild)
    for idx in $idle_indices; do
        yaml_set ".sessions[${idx}].status" "idle"
    done

    # Remove flagged sessions by rebuilding file
    if [ -n "$indices_to_remove" ]; then
        write_sessions_excluding "$indices_to_remove"
    elif [ -n "$idle_indices" ]; then
        # If we only marked idle (no removals), persist the status changes
        yaml_set ".last_updated" "$(get_timestamp)"
        yaml_write "$SESSIONS_FILE"
    fi

    if [ "$verbose" = "true" ]; then
        if [ "$cleaned" -gt 0 ]; then
            echo ""
            local remaining=$((count - cleaned))
            echo "Active sessions remaining: ${remaining}"
        else
            echo "No stale sessions found."
        fi
    else
        echo "$cleaned"
    fi
}

# ============================================================================
# REGISTER SUBCOMMAND
# ============================================================================

do_register() {
    local project="" description="" remote_url="" explicit_pid=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --project) project="$2"; shift 2 ;;
            --description) description="$2"; shift 2 ;;
            --remote-url) remote_url="$2"; shift 2 ;;
            --pid) explicit_pid="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    if [ -z "$project" ]; then
        echo "Error: --project is required" >&2
        echo "Usage: $0 register --project <name> [--description <desc>] [--remote-url <url>] [--pid <pid>]" >&2
        return 1
    fi

    ensure_sessions_file

    # Clean stale sessions first
    do_clean "false" >/dev/null 2>&1 || true

    # Re-parse after clean
    yaml_parse "$SESSIONS_FILE" || return 1

    local session_id
    session_id=$(generate_session_id)

    local pid="${explicit_pid:-$PPID}"
    local terminal
    terminal=$(tty 2>/dev/null || echo "unknown")
    local now
    now=$(get_timestamp)

    # Auto-infer description if not provided
    if [ -z "$description" ]; then
        description="Working on ${project}"
    fi

    # Append new session object to sessions array
    local node_id
    node_id=$(yaml_array_append_object ".sessions")
    yaml_object_set "$node_id" "id" "$session_id" >/dev/null
    yaml_object_set "$node_id" "project" "$project" >/dev/null
    yaml_object_set "$node_id" "description" "$description" >/dev/null
    yaml_object_set "$node_id" "started" "$now" >/dev/null
    yaml_object_set "$node_id" "last_activity" "$now" >/dev/null
    yaml_object_set "$node_id" "status" "active" >/dev/null
    yaml_object_set "$node_id" "current_milestone" "" >/dev/null
    yaml_object_set "$node_id" "current_task" "" >/dev/null
    yaml_object_set "$node_id" "pid" "$pid" >/dev/null
    yaml_object_set "$node_id" "terminal" "$terminal" >/dev/null
    yaml_object_set "$node_id" "remote_url" "${remote_url:-}" >/dev/null

    yaml_set ".last_updated" "$now"
    yaml_write "$SESSIONS_FILE"

    echo "Session ${session_id} registered for ${project}."
    echo "$session_id"
}

# ============================================================================
# DEREGISTER SUBCOMMAND
# ============================================================================

do_deregister() {
    local target_id=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --id) target_id="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    ensure_sessions_file
    yaml_parse "$SESSIONS_FILE" || return 1

    local count
    count=$(get_session_count)

    if [ "$count" = "0" ] || [ -z "$count" ]; then
        echo "No active sessions."
        return 0
    fi

    # Auto-detect by PID if no --id
    if [ -z "$target_id" ]; then
        local current_pid=$PPID
        local i=0
        while [ "$i" -lt "$count" ]; do
            local pid
            pid=$(yaml_query ".sessions[${i}].pid" 2>/dev/null || echo "")
            if [ "$pid" = "$current_pid" ]; then
                target_id=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "")
                break
            fi
            i=$((i + 1))
        done
    fi

    if [ -z "$target_id" ]; then
        echo "No session found for current process (PPID: $PPID)."
        return 1
    fi

    # Find the session index by ID
    local found_idx=""
    local i=0
    while [ "$i" -lt "$count" ]; do
        local sid
        sid=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "")
        if [ "$sid" = "$target_id" ]; then
            found_idx="$i"
            break
        fi
        i=$((i + 1))
    done

    if [ -n "$found_idx" ]; then
        write_sessions_excluding "$found_idx"
        local remaining=$((count - 1))
        echo "Session ${target_id} deregistered."
        echo "Active sessions remaining: ${remaining}"
    else
        echo "Session ${target_id} not found."
        return 1
    fi
}

# ============================================================================
# LIST SUBCOMMAND
# ============================================================================

do_list() {
    local filter_project=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --project) filter_project="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    ensure_sessions_file

    # Clean stale sessions first
    do_clean "false" >/dev/null 2>&1 || true

    # Re-parse after clean
    yaml_parse "$SESSIONS_FILE" || return 1

    local count
    count=$(get_session_count)

    if [ "$count" = "0" ] || [ -z "$count" ]; then
        echo "No active sessions."
        return 0
    fi

    local now_epoch
    now_epoch=$(get_epoch)
    local current_pid=$PPID

    # Count matching sessions
    local total_matching=0
    local i=0
    while [ "$i" -lt "$count" ]; do
        local proj
        proj=$(yaml_query ".sessions[${i}].project" 2>/dev/null || echo "")
        if [ -z "$filter_project" ] || [ "$proj" = "$filter_project" ]; then
            total_matching=$((total_matching + 1))
        fi
        i=$((i + 1))
    done

    if [ "$total_matching" = "0" ]; then
        if [ -n "$filter_project" ]; then
            echo "No active sessions for project: ${filter_project}"
        else
            echo "No active sessions."
        fi
        return 0
    fi

    echo "Active Sessions (${total_matching}):"
    echo ""

    i=0
    while [ "$i" -lt "$count" ]; do
        local proj sid desc started last_activity pid status

        proj=$(yaml_query ".sessions[${i}].project" 2>/dev/null || echo "")

        if [ -n "$filter_project" ] && [ "$proj" != "$filter_project" ]; then
            i=$((i + 1))
            continue
        fi

        sid=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "")
        desc=$(yaml_query ".sessions[${i}].description" 2>/dev/null || echo "")
        started=$(yaml_query ".sessions[${i}].started" 2>/dev/null || echo "")
        last_activity=$(yaml_query ".sessions[${i}].last_activity" 2>/dev/null || echo "")
        pid=$(yaml_query ".sessions[${i}].pid" 2>/dev/null || echo "")
        status=$(yaml_query ".sessions[${i}].status" 2>/dev/null || echo "active")

        local started_ago="" active_ago=""
        if [ -n "$started" ] && [ "$started" != "null" ]; then
            local started_secs=$((now_epoch - $(iso_to_epoch "$started")))
            started_ago="Started $(format_relative_time "$started_secs")"
        fi
        if [ -n "$last_activity" ] && [ "$last_activity" != "null" ]; then
            local active_secs=$((now_epoch - $(iso_to_epoch "$last_activity")))
            active_ago="last active $(format_relative_time "$active_secs")"
        fi

        local indicator=""
        if [ "$pid" = "$current_pid" ]; then
            indicator="  (this session)"
        fi

        local status_marker=""
        if [ "$status" = "idle" ]; then
            status_marker=" [idle]"
        fi

        echo "  ${sid}  ${proj}${indicator}${status_marker}"
        if [ -n "$desc" ] && [ "$desc" != "null" ]; then
            echo "               ${desc}"
        fi
        if [ -n "$started_ago" ] || [ -n "$active_ago" ]; then
            local time_line=""
            [ -n "$started_ago" ] && time_line="$started_ago"
            if [ -n "$active_ago" ]; then
                [ -n "$time_line" ] && time_line="${time_line}, "
                time_line="${time_line}${active_ago}"
            fi
            echo "               ${time_line}"
        fi
        echo ""

        i=$((i + 1))
    done
}

# ============================================================================
# HEARTBEAT SUBCOMMAND
# ============================================================================

do_heartbeat() {
    local target_id="" new_task="" new_description=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --id) target_id="$2"; shift 2 ;;
            --task) new_task="$2"; shift 2 ;;
            --description) new_description="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    ensure_sessions_file
    yaml_parse "$SESSIONS_FILE" || return 1

    local count
    count=$(get_session_count)

    if [ "$count" = "0" ] || [ -z "$count" ]; then
        echo "No active sessions."
        return 1
    fi

    # Auto-detect by PID if no --id
    if [ -z "$target_id" ]; then
        local current_pid=$PPID
        local i=0
        while [ "$i" -lt "$count" ]; do
            local pid
            pid=$(yaml_query ".sessions[${i}].pid" 2>/dev/null || echo "")
            if [ "$pid" = "$current_pid" ]; then
                target_id=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "")
                break
            fi
            i=$((i + 1))
        done
    fi

    if [ -z "$target_id" ]; then
        echo "No session found for current process (PPID: $PPID)."
        return 1
    fi

    # Find the session and rebuild with updated fields
    local now
    now=$(get_timestamp)
    local found=false

    local tmp_file="${SESSIONS_FILE}.tmp"
    {
        echo "# ~/.acp/sessions.yaml"
        echo "# Managed by acp.sessions.sh — do not edit manually"
        echo ""
        echo "sessions:"

        local i=0
        while [ "$i" -lt "$count" ]; do
            local id proj desc started last_activity status milestone task pid terminal remote_url
            id=$(yaml_query ".sessions[${i}].id" 2>/dev/null || echo "")
            proj=$(yaml_query ".sessions[${i}].project" 2>/dev/null || echo "")
            desc=$(yaml_query ".sessions[${i}].description" 2>/dev/null || echo "")
            started=$(yaml_query ".sessions[${i}].started" 2>/dev/null || echo "")
            last_activity=$(yaml_query ".sessions[${i}].last_activity" 2>/dev/null || echo "")
            status=$(yaml_query ".sessions[${i}].status" 2>/dev/null || echo "active")
            milestone=$(yaml_query ".sessions[${i}].current_milestone" 2>/dev/null || echo "")
            task=$(yaml_query ".sessions[${i}].current_task" 2>/dev/null || echo "")
            pid=$(yaml_query ".sessions[${i}].pid" 2>/dev/null || echo "")
            terminal=$(yaml_query ".sessions[${i}].terminal" 2>/dev/null || echo "")
            remote_url=$(yaml_query ".sessions[${i}].remote_url" 2>/dev/null || echo "")

            # Normalize nulls
            [ "$milestone" = "null" ] && milestone=""
            [ "$task" = "null" ] && task=""
            [ "$remote_url" = "null" ] && remote_url=""
            [ "$desc" = "null" ] && desc=""

            # Apply updates to the target session
            if [ "$id" = "$target_id" ]; then
                found=true
                last_activity="$now"
                status="active"
                [ -n "$new_task" ] && task="$new_task"
                [ -n "$new_description" ] && desc="$new_description"
            fi

            echo "  - id: ${id}"
            echo "    project: ${proj}"
            echo "    description: ${desc}"
            echo "    started: ${started}"
            echo "    last_activity: ${last_activity}"
            echo "    status: ${status}"
            echo "    current_milestone: ${milestone}"
            echo "    current_task: ${task}"
            echo "    pid: ${pid}"
            echo "    terminal: ${terminal}"
            echo "    remote_url: ${remote_url}"

            i=$((i + 1))
        done

        echo ""
        echo "last_updated: ${now}"
    } > "$tmp_file"

    if [ "$found" = "true" ]; then
        mv "$tmp_file" "$SESSIONS_FILE"
        echo "Session ${target_id} updated."
        return 0
    else
        rm -f "$tmp_file"
        echo "Session ${target_id} not found."
        return 1
    fi
}

# ============================================================================
# COUNT SUBCOMMAND
# ============================================================================

do_count() {
    ensure_sessions_file

    # Clean stale sessions first
    do_clean "false" >/dev/null 2>&1 || true

    # Re-parse after clean
    yaml_parse "$SESSIONS_FILE" || return 1

    local count
    count=$(get_session_count)
    echo "${count:-0}"
}

# ============================================================================
# MAIN DISPATCH
# ============================================================================

main() {
    local subcommand="${1:-}"

    if [ -z "$subcommand" ]; then
        echo "Usage: $0 <subcommand> [options]"
        echo ""
        echo "Subcommands:"
        echo "  register    Register a new session"
        echo "  deregister  Remove a session"
        echo "  list        List active sessions"
        echo "  clean       Remove stale sessions"
        echo "  heartbeat   Update session activity"
        echo "  count       Output count of active sessions"
        echo ""
        echo "Options:"
        echo "  --project <name>       Project name (register, list)"
        echo "  --description <desc>   Session description (register, heartbeat)"
        echo "  --remote-url <url>     Remote session URL (register)"
        echo "  --id <session-id>      Target session (deregister, heartbeat)"
        echo "  --task <task-id>       Current task (heartbeat)"
        echo "  --pid <pid>            Explicit PID for stale detection (register)"
        return 1
    fi

    shift

    case "$subcommand" in
        register) do_register "$@" ;;
        deregister) do_deregister "$@" ;;
        list) do_list "$@" ;;
        clean) do_clean "true" ;;
        heartbeat) do_heartbeat "$@" ;;
        count) do_count ;;
        *)
            echo "Error: Unknown subcommand '${subcommand}'" >&2
            echo "Run '$0' without arguments for usage." >&2
            return 1
            ;;
    esac
}

main "$@"
