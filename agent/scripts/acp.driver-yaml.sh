#!/usr/bin/env bash
# acp.driver-yaml.sh — read agent/driver.yaml.
#
# STUB / SKETCH for review. No implementation yet — function signatures and
# contracts only. Implementation lands in task-121.
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
#
# Rationale: drivers commonly install globally (e.g., the user's MCP server
# is registered once with their agent runtime; bindings naturally apply
# across projects). A global default driver.yaml lets a user opt every
# project into a default driver while still allowing per-project override.
# An empty project-local agent/driver.yaml acts as an explicit opt-out.
driver_yaml_path() {
    : # TODO: implement
}

# True if agent/driver.yaml exists AND is non-empty AND parses as valid yaml.
# False otherwise. Echos "true" or "false" to stdout. Used by consumer
# commands to decide whether to consult bindings.
driver_yaml_present() {
    : # TODO: implement
}

# Get the `driver:` field. Empty string if file absent or field missing.
driver_yaml_get_driver_name() {
    : # TODO: implement
}

# Get bindings.<ext-point-id>. ext-point-id is one of the 3 v1 ext points:
# marker.mint, query.run, workflow.run.
#
# Empty string if:
#   - file absent
#   - `bindings:` section absent
#   - the specific ext-point not bound
#
# Caller is responsible for handling unknown ext-point-id (this helper is
# tolerant — returns empty for any unknown key).
driver_yaml_get_binding() {
    local ext_point="${1:-}"
    : # TODO: implement
}

# Get workflows.<command-name>. command-name is an ACP command name like
# "acp.task-create" or "acp.plan". Empty string if not mapped.
driver_yaml_get_workflow() {
    local command_name="${1:-}"
    : # TODO: implement
}

# Get capabilities.<name>. Returns "true", "false", or empty (absent).
# Caller defaults absent to "false" per design (D15 conservative default).
driver_yaml_get_capability() {
    local capability_name="${1:-}"
    : # TODO: implement
}

# Echo every (ext-point, tool-name) pair from `bindings:`, one per line,
# tab-separated. Empty output if `bindings:` absent. Useful for @acp.validate
# (task-122) iterating bindings without re-parsing per ext-point.
#
# Format:
#   marker.mint\t<tool-name>
#   query.run\t<tool-name>
#   workflow.run\t<tool-name>
driver_yaml_list_bindings() {
    : # TODO: implement
}

# Echo every (command-name, workflow-name) pair from `workflows:`, one per
# line, tab-separated. Empty output if `workflows:` absent.
#
# Format:
#   acp.task-create\t<workflow-name>
#   acp.plan\t<workflow-name>
#   ...
driver_yaml_list_workflows() {
    : # TODO: implement
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
