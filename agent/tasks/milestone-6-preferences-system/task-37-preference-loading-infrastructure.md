# Task 37: Preference Loading Infrastructure

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)  
**Estimated Time**: 4-6 hours  
**Dependencies**: Task 34 (Generic YAML Parser)  
**Status**: Not Started  

---

## Objective

Create the core preference infrastructure including the `acp.preferences.sh` shell script with all preference utilities (get, set, validate, generate), and the `@acp.preferences-get` command for agent invocation.

---

## Context

This task establishes the foundation for the entire preferences system. The unified shell script (`acp.preferences.sh`) contains all preference utilities: get, set, validate, generate, and preset operations. Commands provide agent-friendly interfaces for each operation.

The architecture enables both programmatic access (other scripts can source functions) and agent orchestration (commands can invoke the script and consume output).

---

## Steps

### 1. Create Shell Script Structure

Create `agent/scripts/acp.preferences.sh` with basic structure:

```bash
#!/usr/bin/env bash
# ACP Preferences System - Unified Utilities
# All preference operations: get, set, validate, generate, presets
# Can be invoked directly or sourced for functions

set -euo pipefail

# Source YAML parser
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/acp.yaml-parser.sh"
source "${SCRIPT_DIR}/acp.common.sh"

# Note: This script contains ALL preference utilities
# Other scripts can source this file to use preference functions
```

### 2. Implement get_preference() Function

Add function to resolve single preference value:

```bash
# Get preference value with precedence resolution
# Usage: get_preference "namespace" "preference.path"
# Returns: preference value or empty string
get_preference() {
  local namespace="$1"
  local pref_path="$2"
  
  # Load from project (highest precedence)
  local project_pref="./agent/preferences/${namespace}.default.yaml"
  if [ -f "$project_pref" ]; then
    local value=$(yaml_query "$project_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Load from workspace
  local workspace_pref=".vscode/preferences/${namespace}.yaml"
  if [ -f "$workspace_pref" ]; then
    local value=$(yaml_query "$workspace_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Load from user (lowest precedence)
  local user_pref="$HOME/.acp/agent/preferences/${namespace}.default.yaml"
  if [ -f "$user_pref" ]; then
    local value=$(yaml_query "$user_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Load default from configurables
  local configurable="./agent/configurables/${namespace}.configurables.yaml"
  if [ -f "$configurable" ]; then
    local value=$(yaml_query "$configurable" "${namespace}.${pref_path}.default")
    echo "$value"
    return 0
  fi
  
  return 1
}
```

### 3. Implement Helper Functions

Add utility functions:

```bash
# Check if preference exists at any level
# Usage: has_preference "namespace" "preference.path"
has_preference() {
  local namespace="$1"
  local pref_path="$2"
  local value=$(get_preference "$namespace" "$pref_path")
  [ -n "$value" ]
}

# Get preference with fallback
# Usage: get_preference_or "namespace" "preference.path" "fallback_value"
get_preference_or() {
  local namespace="$1"
  local pref_path="$2"
  local fallback="$3"
  local value=$(get_preference "$namespace" "$pref_path")
  echo "${value:-$fallback}"
}

# Get preference source (which file provided the value)
# Usage: get_preference_source "namespace" "preference.path"
# Returns: "project" | "workspace" | "user" | "default" | "none"
get_preference_source() {
  local namespace="$1"
  local pref_path="$2"
  
  # Check project
  local project_pref="./agent/preferences/${namespace}.default.yaml"
  if [ -f "$project_pref" ]; then
    local value=$(yaml_query "$project_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "project"
      return 0
    fi
  fi
  
  # Check workspace
  local workspace_pref=".vscode/preferences/${namespace}.yaml"
  if [ -f "$workspace_pref" ]; then
    local value=$(yaml_query "$workspace_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "workspace"
      return 0
    fi
  fi
  
  # Check user
  local user_pref="$HOME/.acp/agent/preferences/${namespace}.default.yaml"
  if [ -f "$user_pref" ]; then
    local value=$(yaml_query "$user_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "user"
      return 0
    fi
  fi
  
  # Check default
  local configurable="./agent/configurables/${namespace}.configurables.yaml"
  if [ -f "$configurable" ]; then
    local value=$(yaml_query "$configurable" "${namespace}.${pref_path}.default")
    if [ -n "$value" ]; then
      echo "default"
      return 0
    fi
  fi
  
  echo "none"
  return 1
}
```

### 4. Implement generate_preferences() Function

Add function to generate complete preference set:

```bash
# Generate complete preference set for namespace
# Usage: generate_preferences "namespace" [--format yaml|json]
# Outputs: Complete preference set with precedence applied
generate_preferences() {
  local namespace="$1"
  local format="${2:-yaml}"
  
  # Get all preference paths from configurables
  local configurable="./agent/configurables/${namespace}.configurables.yaml"
  if [ ! -f "$configurable" ]; then
    error "Configurables not found: $configurable"
    return 1
  fi
  
  # Parse configurables to get all preference paths
  # For each preference path, resolve value using get_preference()
  # Build output in requested format
  
  if [ "$format" = "yaml" ]; then
    echo "${namespace}:"
    # Output each preference as YAML
    # Example: "  plan.draft.create_mode: 'structured'"
  elif [ "$format" = "json" ]; then
    echo "{"
    echo "  \"${namespace}\": {"
    # Output each preference as JSON
    echo "  }"
    echo "}"
  fi
}
```

### 5. Add Main Entry Point

Add script execution logic:

```bash
# Main entry point when script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  # Parse arguments
  namespace="${1:-acp}"
  format="${2:-yaml}"
  
  # Validate namespace
  if [ -z "$namespace" ]; then
    error "Usage: $0 <namespace> [yaml|json]"
    exit 1
  fi
  
  # Generate and output preferences
  generate_preferences "$namespace" "$format"
fi
```

### 6. Create Command Document

Create `agent/commands/acp.preferences-get.md`:

```markdown
# Command: preferences-get

> **🤖 Agent Directive**: Run `./agent/scripts/acp.preferences-get.sh` to generate 
> complete preferences for the specified namespace with precedence applied.

**Namespace**: acp  
**Version**: 1.0.0  
**Purpose**: Generate and display complete preference set for a namespace  
**Category**: Utility  
**Frequency**: As Needed  

---

## What This Command Does

Generates a complete preference set for a namespace by applying precedence rules 
(Project > Workspace > User > Default). The output can be displayed to the user, 
saved to a file, or consumed by other commands.

---

## Steps

### 1. Parse Arguments

Extract namespace and format from command invocation:
- Namespace: Which preference set to generate (acp, package-name, etc.)
- Format: Output format (yaml or json)

### 2. Run Shell Script

Execute the preference generation script:

```bash
./agent/scripts/acp.preferences-get.sh <namespace> [yaml|json]
```

### 3. Display Output

Show the generated preferences to the user with clear formatting.

### 4. Optionally Save

If user requests, save to file or pass to another command.

---

## Examples

### Example 1: Get ACP Preferences
```bash
@acp.preferences-get acp
```

### Example 2: Get Package Preferences
```bash
@acp.preferences-get mcp-auth-server-base
```

---

## Related Commands

- `@acp.preferences-show` - Display preferences with source indication
- `@acp.preferences-set` - Set preference values
```

### 7. Make Script Executable

```bash
chmod +x agent/scripts/acp.preferences.sh
```

### 8. Create Unit Tests

Create `tests/acp.preferences.test.sh`:

```bash
#!/usr/bin/env bash
# Unit tests for acp.preferences.sh

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/../agent/scripts/acp.preferences.sh"

# Test 1: Preference precedence (project > workspace > user > default)
test_preference_precedence() {
  # Setup test files with different values
  # Assert project value wins
}

# Test 2: Fallback to default
test_preference_default_fallback() {
  # Setup: No preferences set
  # Assert: Returns default from configurables
}

# Test 3: Missing preference
test_missing_preference() {
  # Setup: Preference doesn't exist
  # Assert: Returns empty string
}

# Run tests
run_tests
```

---

## Verification

- [ ] `acp.preferences-get.sh` created with all functions
- [ ] Script is executable (`chmod +x`)
- [ ] `get_preference()` function works correctly
- [ ] `has_preference()` function works correctly
- [ ] `get_preference_or()` function works correctly
- [ ] `get_preference_source()` function works correctly
- [ ] `generate_preferences()` function works correctly
- [ ] Script can be executed directly: `./agent/scripts/acp.preferences-get.sh acp`
- [ ] Script can be sourced: `source agent/scripts/acp.preferences-get.sh`
- [ ] `@acp.preferences-get` command document created
- [ ] Unit tests created and passing
- [ ] No syntax errors (`bash -n acp.preferences-get.sh`)

---

## Expected Output

### Files Created
- `agent/scripts/acp.preferences-get.sh` - Shell script with preference functions
- `agent/commands/acp.preferences-get.md` - Command document
- `tests/acp.preferences-get.test.sh` - Unit tests

### Script Output Example

```bash
$ ./agent/scripts/acp.preferences-get.sh acp yaml
acp:
  plan.draft.create_mode: 'structured'
  task.create.granularity: 3
  validation.auto_fix.enabled: true
```

---

## Common Issues and Solutions

### Issue 1: YAML parser not found
**Symptom**: Error "acp.yaml-parser.sh: No such file or directory"  
**Solution**: Ensure YAML parser exists and script path is correct  

### Issue 2: Preference file not found
**Symptom**: Warning about missing preference files  
**Solution**: This is normal - preferences are optional. Script falls back to defaults.  

### Issue 3: Invalid preference path
**Symptom**: Empty string returned for valid preference  
**Solution**: Check dot notation syntax (e.g., `plan.draft.create_mode` not `plan/draft/create_mode`)  

---

## Resources

- [Design Document](../design/acp-preferences-system.md) - Complete design specification
- [YAML Parser](../scripts/acp.yaml-parser.sh) - YAML processing functions
- [Common Utilities](../scripts/acp.common.sh) - Shared utility functions

---

## Notes

- Script uses YAML parser's `yaml_query()` function for path-based queries
- Precedence is enforced by checking files in order (project → workspace → user → default)
- Script is sourceable - other scripts can use the functions
- Script is executable - can be run standalone for testing
- Command layer (`@acp.preferences-get`) provides agent interface
- Functions are POSIX-compliant where possible

---

**Next Task**: [Task 38: Configurables System Enhancement](task-38-configurables-system-enhancement.md)  
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md)  
**Estimated Completion Date**: TBD  
