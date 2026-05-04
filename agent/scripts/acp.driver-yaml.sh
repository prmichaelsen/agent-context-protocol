#!/usr/bin/env bash
# acp.driver-yaml.sh — read agent/driver.yaml.
#
# Schema: agent/schemas/driver.schema.yaml
# Template: agent/driver.template.yaml
# Design: agent/design/local.pluggable-driver-system.md
#
# Convention: every helper returns 0 on success with stdout containing the
# requested value (or empty string when not set). Returns 0 even when the
# field is absent — callers test stdout, not exit code. Exit code is non-zero
# only on hard errors (malformed yaml, file unreadable).
#
# Usage:
#   acp.driver-yaml.sh present
#   acp.driver-yaml.sh get-driver-name
#   acp.driver-yaml.sh get-binding <ext-point-id>
#   acp.driver-yaml.sh get-workflow <command-name>
#   acp.driver-yaml.sh get-capability <name>
#   acp.driver-yaml.sh list-bindings
#   acp.driver-yaml.sh list-workflows

set -eu

# Path resolution with global fallback.
#
# Resolution order (first match wins):
#   1. <ACP_PROJECT_ROOT>/agent/driver.yaml   (project-local, highest priority)
#   2. ~/.acp/agent/driver.yaml               (global fallback)
#   3. (none) — empty stdout
#
# Project-local fully overrides global; the two are NOT merged. Echos the
# resolved absolute path to stdout, or empty string if neither exists.
driver_yaml_path() {
    local project_root="${ACP_PROJECT_ROOT:-$(pwd)}"
    local project_path="${project_root}/agent/driver.yaml"
    local global_path="${HOME}/.acp/agent/driver.yaml"

    if [ -f "$project_path" ]; then
        printf '%s\n' "$project_path"
    elif [ -f "$global_path" ]; then
        printf '%s\n' "$global_path"
    else
        printf ''
    fi
}

# True if agent/driver.yaml exists AND is non-empty AND parses as valid yaml.
# False otherwise. Echos "true" or "false" to stdout.
driver_yaml_present() {
    local path
    path="$(driver_yaml_path)"

    if [ -z "$path" ] || [ ! -s "$path" ]; then
        printf 'false\n'
        return 0
    fi

    # Minimal validity probe: must contain at least one yaml-shaped line
    # (a key followed by colon, ignoring comments). This is a soft check —
    # @acp.validate runs the authoritative schema validation.
    if grep -qE '^[a-zA-Z_][a-zA-Z0-9_.-]*:' "$path"; then
        printf 'true\n'
    else
        printf 'false\n'
    fi
}

# Extract a top-level scalar field (e.g., `driver:`).
# Strips comments, leading/trailing whitespace, and surrounding quotes.
_driver_yaml_top_scalar() {
    local path="$1"
    local key="$2"

    [ -f "$path" ] || { printf ''; return 0; }

    awk -v key="$key" '
        # Stop at the next top-level key after we found ours
        /^[a-zA-Z_]/ && in_key && $0 !~ "^"key":" { exit }
        $0 ~ "^"key":" {
            in_key = 1
            # strip "key:" prefix
            sub("^"key":[[:space:]]*", "")
            # strip trailing comment
            sub(/[[:space:]]+#.*$/, "")
            # strip surrounding double quotes
            sub(/^"/, ""); sub(/"$/, "")
            # strip surrounding single quotes
            sub(/^'\''/, ""); sub(/'\''$/, "")
            print
            exit
        }
    ' "$path"
}

# Generic helper: extract a value from a flat 2-level nested section.
# Input: file, parent-key (e.g., "bindings"), child-key (e.g., "marker.mint")
# Output: the scalar value, or empty string.
_driver_yaml_nested_scalar() {
    local path="$1"
    local parent="$2"
    local child="$3"

    [ -f "$path" ] || { printf ''; return 0; }

    awk -v parent="$parent" -v child="$child" '
        # Track when we enter the parent section
        $0 ~ "^"parent":" { in_section = 1; next }
        # Exit on the next top-level key (non-indented, non-blank, non-comment)
        in_section && /^[^[:space:]]/ && $0 !~ /^#/ { in_section = 0 }
        # Match indented key inside section
        in_section && $0 ~ "^[[:space:]]+"child"[[:space:]]*:" {
            sub("^[[:space:]]+"child"[[:space:]]*:[[:space:]]*", "")
            sub(/[[:space:]]+#.*$/, "")
            sub(/^"/, ""); sub(/"$/, "")
            sub(/^'\''/, ""); sub(/'\''$/, "")
            print
            exit
        }
    ' "$path"
}

# Generic helper: list all (key, value) pairs from a flat 2-level nested section.
# Output: tab-separated, one pair per line.
_driver_yaml_nested_list() {
    local path="$1"
    local parent="$2"

    [ -f "$path" ] || { printf ''; return 0; }

    awk -v parent="$parent" '
        BEGIN { in_section = 0 }
        $0 ~ "^"parent":" { in_section = 1; next }
        in_section && /^[^[:space:]]/ && $0 !~ /^#/ { in_section = 0 }
        in_section && /^[[:space:]]+[a-zA-Z_][a-zA-Z0-9_.-]*[[:space:]]*:/ {
            line = $0
            # Strip trailing comment
            sub(/[[:space:]]+#.*$/, "", line)
            # Strip leading whitespace
            sub(/^[[:space:]]+/, "", line)
            # Split on first colon: key before, value after
            colon = index(line, ":")
            if (colon == 0) next
            key = substr(line, 1, colon - 1)
            value = substr(line, colon + 1)
            # Trim leading whitespace from value
            sub(/^[[:space:]]+/, "", value)
            # Trim trailing whitespace from value
            sub(/[[:space:]]+$/, "", value)
            # Strip surrounding quotes
            sub(/^"/, "", value); sub(/"$/, "", value)
            sub(/^'\''/, "", value); sub(/'\''$/, "", value)
            # Skip empty placeholder values
            if (value != "" && value !~ /^</) {
                printf "%s\t%s\n", key, value
            }
        }
    ' "$path"
}

# Get the `driver:` field. Empty string if file absent or field missing.
driver_yaml_get_driver_name() {
    local path; path="$(driver_yaml_path)"
    [ -n "$path" ] || { printf ''; return 0; }
    _driver_yaml_top_scalar "$path" "driver"
}

# Get bindings.<ext-point-id>. ext-point-id is one of the 3 v1 ext points:
# marker.mint, query.run, workflow.run.
driver_yaml_get_binding() {
    local ext_point="${1:-}"
    [ -n "$ext_point" ] || { printf ''; return 0; }
    local path; path="$(driver_yaml_path)"
    [ -n "$path" ] || { printf ''; return 0; }
    _driver_yaml_nested_scalar "$path" "bindings" "$ext_point"
}

# Get workflows.<command-name>. command-name is an ACP command name like
# "acp.task-create" or "acp.plan". Empty string if not mapped.
driver_yaml_get_workflow() {
    local command_name="${1:-}"
    [ -n "$command_name" ] || { printf ''; return 0; }
    local path; path="$(driver_yaml_path)"
    [ -n "$path" ] || { printf ''; return 0; }
    _driver_yaml_nested_scalar "$path" "workflows" "$command_name"
}

# Get capabilities.<name>. Returns "true", "false", or empty (absent).
# Caller defaults absent to "false" per design (DR15 conservative default).
driver_yaml_get_capability() {
    local capability_name="${1:-}"
    [ -n "$capability_name" ] || { printf ''; return 0; }
    local path; path="$(driver_yaml_path)"
    [ -n "$path" ] || { printf ''; return 0; }
    _driver_yaml_nested_scalar "$path" "capabilities" "$capability_name"
}

# Echo every (ext-point, tool-name) pair from `bindings:`, one per line,
# tab-separated. Empty output if `bindings:` absent.
driver_yaml_list_bindings() {
    local path; path="$(driver_yaml_path)"
    [ -n "$path" ] || { printf ''; return 0; }
    _driver_yaml_nested_list "$path" "bindings"
}

# Echo every (command-name, workflow-name) pair from `workflows:`, one per
# line, tab-separated. Empty output if `workflows:` absent.
driver_yaml_list_workflows() {
    local path; path="$(driver_yaml_path)"
    [ -n "$path" ] || { printf ''; return 0; }
    _driver_yaml_nested_list "$path" "workflows"
}

# CLI dispatcher
case "${1:-}" in
    present)              driver_yaml_present ;;
    path)                 driver_yaml_path ;;
    get-driver-name)      driver_yaml_get_driver_name ;;
    get-binding)          shift; driver_yaml_get_binding "$@" ;;
    get-workflow)         shift; driver_yaml_get_workflow "$@" ;;
    get-capability)       shift; driver_yaml_get_capability "$@" ;;
    list-bindings)        driver_yaml_list_bindings ;;
    list-workflows)       driver_yaml_list_workflows ;;
    -h|--help|"")
        sed -n 's/^# //;3,30p' "$0"
        ;;
    *)
        echo "acp.driver-yaml.sh: unknown subcommand: $1" >&2
        exit 2
        ;;
esac
