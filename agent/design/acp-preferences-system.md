# ACP Preferences System

**Concept**: Multi-level preference system enabling users to configure agent behavior at user, workspace, and project levels with clear precedence rules
**Created**: 2026-02-22
**Status**: Design Specification

---

## Overview

The ACP Preferences System provides a hierarchical configuration mechanism that allows users to customize agent behavior, command defaults, and template substitutions at three distinct levels: user-global, workspace, and project. This system enables consistent, repeatable workflows while maintaining flexibility for different contexts.

The preferences system integrates with ACP commands (like [`@acp.plan`](../commands/acp.plan.md:1)) and templates to provide context-aware defaults, reducing repetitive configuration and enabling sophisticated workflow automation. It supports both core ACP preferences and package-specific preferences, creating a unified configuration experience across the entire ACP ecosystem.

**Key Innovation**: Preferences are defined in [`agent/configurables/`](../configurables/acp.configurables.yaml:1) files that specify available options, descriptions, and defaults. Preference instances in [`agent/preferences/`](../preferences/acp.default.yaml:1) reference these definitions, ensuring type safety and discoverability.

---

## Problem Statement

### Current Limitations

1. **Repetitive Configuration**: Users must specify the same preferences repeatedly (e.g., "structured draft" vs "unstructured draft" every time they run `@acp.plan`)

2. **No Context Awareness**: Commands cannot adapt behavior based on user preferences, workspace conventions, or project standards

3. **Limited Workflow Automation**: Cannot create preset workflows (e.g., "always use guided mode for this project")

4. **Package Configuration Complexity**: Third-party packages have no standard way to expose configuration options

5. **Inconsistent Behavior**: Same command behaves differently across sessions because preferences aren't persisted

6. **No Discoverability**: Users don't know what preferences are available or what values are valid

### Consequences

- **Reduced Productivity**: Users waste time re-entering the same preferences
- **Inconsistent Results**: Different agents may make different choices without explicit preferences
- **Poor Package UX**: Package authors can't provide preset configurations
- **Friction**: Users abandon advanced features because configuration is too tedious

---

## Solution

### High-Level Approach

Implement a **three-tier hierarchical preference system** with clear precedence rules:

1. **User Preferences** (`~/.acp/agent/preferences/`) - Global defaults for all projects
2. **Workspace Preferences** (`.vscode/preferences/` or workspace root) - IDE/workspace-specific settings
3. **Project Preferences** (`./agent/preferences/`) - Project-specific overrides

**Precedence**: Project > Workspace > User (more specific overrides more general)

### Key Components

1. **Configurables System** - Define available preferences with metadata
2. **Preference Files** - YAML files containing preference values
3. **Preference Resolution** - Load and merge preferences based on precedence
4. **Command Integration** - Commands read preferences to inform behavior
5. **Package Support** - Namespaced preferences for third-party packages

### Alternative Approaches Considered

**Alternative 1: Single-level configuration (project only)**
- ❌ Rejected: Users would need to duplicate preferences across all projects
- ❌ No way to set personal defaults

**Alternative 2: Environment variables**
- ❌ Rejected: Not structured enough for complex preferences
- ❌ Poor discoverability
- ❌ No type validation

**Alternative 3: JSON configuration**
- ❌ Rejected: YAML is already used throughout ACP
- ❌ Less human-friendly for editing

---

## Implementation

### 1. Directory Structure

```
# User-level (global)
~/.acp/
  └── agent/
      ├── preferences/
      │   ├── acp.default.yaml              # User's ACP preferences
      │   └── {package-name}.default.yaml   # User's package preferences
      └── configurables/
          └── {package-name}.configurables.yaml  # Installed package configurables

# Workspace-level (IDE-specific)
.vscode/
  └── preferences/
      ├── acp.yaml                          # Workspace ACP preferences
      └── {package-name}.yaml               # Workspace package preferences

# OR (for non-VSCode workspaces)
{workspace-root}/
  └── agent/
      └── preferences/
          ├── acp.workspace.yaml
          └── {package-name}.workspace.yaml

# Project-level (repository)
./agent/
  ├── configurables/
  │   └── acp.configurables.yaml            # Core ACP configurables definition
  ├── preferences/
  │   ├── acp.default.yaml                  # Project ACP preferences
  │   └── {package-name}.default.yaml       # Project package preferences
  └── ...
```

### 2. Configurables Definition Format

**File**: `agent/configurables/acp.configurables.yaml`

```yaml
# Configurables define AVAILABLE preferences with metadata
# Preference files reference these definitions

acp:
  plan:
    draft:
      create_mode:
        id: 'acp.plan.draft.create_mode'
        description: Define your agent's default behavior when creating draft documents.
        default: structured
        options:
          - name: unstructured
            description: |
              Drafts will be created as empty documents placed in the 
              appropriate location with appropriate filenames
            value: unstructured
          
          - name: structured
            description: | 
              Drafts will be created as structured documents with clear
              template sections and placeholders for user input,
              placed in the appropriate location with appropriate filenames
            value: structured
          
          - name: guided
            description: | 
              Draft contents should be collected via chat conversation,
              then no draft need be created because the interactive guided session
              should have completed all context required to handle 
              the user's current goal. No draft document is actually created.
              The draft summary is provided to the user in chat.
            value: guided
          
          - name: contextual
            description: | 
              Draft contents should be inferred by existing context
              and the inferred current user goal. No clarification questions are 
              asked, no draft document is actually created. Instead, the draft 
              summary is provided to the user in chat generated exclusively 
              from the agent's current understanding of the task.
            value: contextual

  task:
    create:
      granularity:
        # granularity options

  validation:
    auto_fix:
      enabled:
        id: 'validation.auto_fix.enabled'
        description: Automatically fix validation issues when possible
        default: true
        type: boolean
```

### 3. Preference Instance Format

**File**: `agent/preferences/acp.default.yaml`

```yaml
# Preference instances reference configurables definitions
# Three-part dot path notation

acp:
  # Dot path: acp.plan.draft.create_mode
  plan.draft.create_mode: 'structured'
  
  # Dot path: acp.task.granularity.default_hours
  task.create.granularity: # value
  
  # Dot path: acp.validation.auto_fix.enabled
  validation.auto_fix.enabled: true
```

### 4. Package-Specific Preferences

**File**: `agent/configurables/mcp-auth-server-base.configurables.yaml`

```yaml
mcp-auth-server-base:
  init:
    server:
      type:
        id: 'init.server.type'
        description: Default server authentication type
        default: static
        options:
          - name: static
            description: Static JWT authentication
            value: static
          - name: static_credentials
            description: Static credentials with JWT
            value: static_credentials
          - name: dynamic
            description: Dynamic Firebase authentication
            value: dynamic
```

**File**: `agent/preferences/mcp-auth-server-base.default.yaml`

```yaml
mcp-auth-server-base:
  init.server.type: 'static_credentials'
```

**File**: `agent/preferences/mcp-auth-server-base.static-jwt-auth.yaml` (preset)

```yaml
# Preset configuration for static JWT authentication
mcp-auth-server-base:
  init.server.type: 'static'
  init.jwt.algorithm: 'HS256'
  init.jwt.expiry: '24h'
```

### 5. Preference Resolution Algorithm

```bash
# Pseudocode for preference resolution

resolve_preference(namespace, preference_path) {
  # 1. Load configurables to get default
  default_value = load_configurable(namespace, preference_path)
  
  # 2. Check user-level preferences
  user_value = load_user_preference(namespace, preference_path)
  value = user_value ?? default_value
  
  # 3. Check workspace-level preferences (overrides user)
  workspace_value = load_workspace_preference(namespace, preference_path)
  value = workspace_value ?? value
  
  # 4. Check project-level preferences (overrides workspace)
  project_value = load_project_preference(namespace, preference_path)
  value = project_value ?? value
  
  return value
}
```

### 6. Command Integration Example

**In [`@acp.plan`](../commands/acp.plan.md:1) command**:

```markdown
### 3. Gather Requirements

Based on user selection, gather requirements:

**Option A: Design Document First**
- Check preference: `acp.plan.draft.create_mode`
- If 'structured': Create structured draft with 3 key questions
- If 'unstructured': Create empty draft file
- If 'guided': Collect requirements in chat (no draft file)
- If 'contextual': Infer from context (no draft file)
- If not set: Ask user which mode to use
```

### 7. Preference Utilities Architecture

**Design**: The preferences system uses a unified shell script with multiple functions:

**File**: `agent/scripts/acp.preferences.sh`

This single script contains all preference utilities:
- `get_preference()` - Get single preference value with precedence
- `set_preference()` - Set preference value at specified level
- `validate_preference()` - Validate value against configurables
- `generate_preferences()` - Generate complete preference set
- `list_presets()` - List available presets
- `load_preset()` - Load preset configuration

**Benefits**:
- Single source of truth for all preference operations
- Can be sourced by other scripts or invoked directly
- Commands provide agent-friendly interface with error handling
- Clear separation between utilities (shell) and orchestration (commands)

**Note**: Using `acp.preferences.sh` (not `acp.preferences-get.sh`) since the script handles all preference operations, not just getting.

```bash
#!/usr/bin/env bash
# ACP Preferences System - Unified Utilities
# All preference operations: get, set, validate, generate, presets
# Can be invoked directly or sourced for functions

# Get preference value with precedence resolution
# Usage: get_preference "namespace" "preference.path"
# Returns: preference value or empty string
get_preference() {
  local namespace="$1"
  local pref_path="$2"
  
  # Load from project (highest precedence)
  local project_pref="./agent/preferences/${namespace}.default.yaml"
  if [ -f "$project_pref" ]; then
    local value=$(yaml_get "$project_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Load from workspace
  local workspace_pref=".vscode/preferences/${namespace}.yaml"
  if [ -f "$workspace_pref" ]; then
    local value=$(yaml_get "$workspace_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Load from user (lowest precedence)
  local user_pref="$HOME/.acp/agent/preferences/${namespace}.default.yaml"
  if [ -f "$user_pref" ]; then
    local value=$(yaml_get "$user_pref" "${namespace}.${pref_path}")
    if [ -n "$value" ]; then
      echo "$value"
      return 0
    fi
  fi
  
  # Load default from configurables
  local configurable="./agent/configurables/${namespace}.configurables.yaml"
  if [ -f "$configurable" ]; then
    local value=$(yaml_get "$configurable" "${namespace}.${pref_path}.default")
    echo "$value"
    return 0
  fi
  
  return 1
}

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

# List all preferences for namespace
# Usage: list_preferences "namespace"
list_preferences() {
  local namespace="$1"
  
  echo "Preferences for namespace: $namespace"
  echo ""
  
  # Show project preferences
  local project_pref="./agent/preferences/${namespace}.default.yaml"
  if [ -f "$project_pref" ]; then
    echo "📁 Project Preferences:"
    yaml_get_all "$project_pref" "${namespace}"
    echo ""
  fi
  
  # Show workspace preferences
  local workspace_pref=".vscode/preferences/${namespace}.yaml"
  if [ -f "$workspace_pref" ]; then
    echo "💼 Workspace Preferences:"
    yaml_get_all "$workspace_pref" "${namespace}"
    echo ""
  fi
  
  # Show user preferences
  local user_pref="$HOME/.acp/agent/preferences/${namespace}.default.yaml"
  if [ -f "$user_pref" ]; then
    echo "👤 User Preferences:"
    yaml_get_all "$user_pref" "${namespace}"
    echo ""
  fi
}

# Generate complete preference set for namespace
# Usage: generate_preferences "namespace" [--format yaml|json]
# Outputs: Complete preference set with precedence applied
generate_preferences() {
  local namespace="$1"
  local format="${2:-yaml}"
  
  # Load all preference files
  local user_pref="$HOME/.acp/agent/preferences/${namespace}.default.yaml"
  local workspace_pref=".vscode/preferences/${namespace}.yaml"
  local project_pref="./agent/preferences/${namespace}.default.yaml"
  local configurable="./agent/configurables/${namespace}.configurables.yaml"
  
  # Parse and merge with precedence
  # Output merged YAML/JSON
  # (Implementation uses yaml_parse and yaml_query from acp.yaml-parser.sh)
}

# Main entry point when script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  # Parse arguments
  namespace="${1:-acp}"
  format="${2:-yaml}"
  
  # Generate and output preferences
  generate_preferences "$namespace" "$format"
fi
```

**Command**: `agent/commands/acp.preferences-get.md`

```markdown
# Command: preferences-get

> **🤖 Agent Directive**: Run `./agent/scripts/acp.preferences-get.sh` to generate
> complete preferences for the specified namespace with precedence applied.

**Purpose**: Generate and display complete preference set for a namespace

## Steps

1. Run shell script: `./agent/scripts/acp.preferences-get.sh <namespace> [yaml|json]`
2. Display generated preferences
3. Optionally save to file or pass to another command

## Usage Examples

```bash
# Get ACP preferences as YAML
./agent/scripts/acp.preferences-get.sh acp yaml

# Get package preferences as JSON
./agent/scripts/acp.preferences-get.sh mcp-auth-server-base json
```
```

### 8. Usage in Commands

**Example: `@acp.plan` using preferences**

```bash
# In the agent executing @acp.plan command

# Check user's preferred draft mode
draft_mode=$(get_preference "acp" "plan.draft.create_mode")

if [ "$draft_mode" = "structured" ]; then
  # Create structured draft with questions
  create_structured_draft "$requirement_title"
elif [ "$draft_mode" = "unstructured" ]; then
  # Create empty draft file
  create_unstructured_draft "$requirement_title"
elif [ "$draft_mode" = "guided" ]; then
  # Collect requirements in chat
  collect_requirements_in_chat
elif [ "$draft_mode" = "contextual" ]; then
  # Infer from context
  infer_requirements_from_context
else
  # No preference set - ask user
  ask_user_draft_mode
fi
```

**Note**: In practice, `@acp.plan` should invoke the `@acp.preferences-get` command as a subroutine to generate the complete preference set, then extract the specific preference value. This maintains command-level abstraction and enables proper error handling.

**Improved Approach**:
```markdown
### In @acp.plan command

1. Invoke `@acp.preferences-get acp` to generate complete ACP preferences
2. Extract `plan.draft.create_mode` from generated preferences
3. Use value to determine draft creation behavior
```

This approach allows other commands to consume the generated preferences without reimplementing precedence logic.

### 9. Preset Configurations

Users can create preset configuration files for common workflows:

**File**: `agent/preferences/acp.batch-planning.yaml`

```yaml
# Preset for batch planning mode
acp:
  plan.draft.create_mode: 'contextual'
  plan.batch.auto_confirm: true
  task.granularity.default_hours: 2
  validation.auto_fix.enabled: true
```

**Usage**: `@acp.plan --preset acp.batch-planning`

The command would load `agent/preferences/acp.batch-planning.yaml` and use those values for the current invocation only.

**Preset Naming**: Presets should include namespace prefix for clarity (e.g., `acp.batch-planning` not just `batch-planning`).

---

## Benefits

### 1. Reduced Friction
- **No Repetition**: Set preferences once, use everywhere
- **Faster Workflows**: Commands use sensible defaults automatically
- **Consistent Behavior**: Same preferences across all sessions

### 2. Context Awareness
- **Project Standards**: Enforce project-specific conventions
- **Team Alignment**: Workspace preferences ensure team consistency
- **Personal Defaults**: User preferences follow you across projects

### 3. Workflow Automation
- **Preset Configurations**: Create named presets for common workflows
- **Batch Operations**: Enable fully automated batch processing
- **Package Integration**: Packages can provide preset configurations

### 4. Discoverability
- **Self-Documenting**: Configurables define available options with descriptions
- **Type Safety**: Options are validated against configurables
- **Clear Defaults**: Every preference has a documented default

### 5. Extensibility
- **Package Support**: Third-party packages can define their own preferences
- **Namespace Isolation**: No conflicts between packages
- **Backward Compatible**: Commands work without preferences (use defaults)

---

## Trade-offs

### 1. Complexity
- **Trade-off**: Adds another layer of configuration to understand
- **Mitigation**: 
  - Preferences are optional (commands work without them)
  - Clear documentation with examples
  - `@acp.preferences-info` command to show current values
  - Configurables provide self-documentation

### 2. File Proliferation
- **Trade-off**: More YAML files to manage (configurables + preferences)
- **Mitigation**:
  - Preferences are optional (only create if needed)
  - Defaults in configurables mean most users need minimal preference files
  - `@acp.preferences-validate` ensures consistency

### 3. Precedence Confusion
- **Trade-off**: Users might not understand which preference is active
- **Mitigation**:
  - Clear precedence rules (Project > Workspace > User)
  - `@acp.preferences-show` displays effective values with source
  - Commands can log which preference source was used

### 4. Performance
- **Trade-off**: Loading preferences adds overhead to command execution
- **Mitigation**:
  - Lazy loading (only load when needed)
  - Cache preferences for session
  - YAML parser is fast (<100ms)

### 5. Migration
- **Trade-off**: Existing projects don't have preferences
- **Mitigation**:
  - Fully backward compatible (defaults used if no preferences)
  - Optional migration: `@acp.preferences-init` creates default files
  - No breaking changes to existing commands

---

## Dependencies

### Internal Dependencies
- **YAML Parser**: [`agent/scripts/acp.yaml-parser.sh`](../scripts/acp.yaml-parser.sh:1) - Read/write YAML files
- **Common Utilities**: [`agent/scripts/acp.common.sh`](../scripts/acp.common.sh:1) - Shared functions
- **Commands**: All commands that support preferences (plan, task-create, etc.)

### External Dependencies
- None (pure bash implementation)

### Related Design Documents
- [`acp-commands-design.md`](acp-commands-design.md:1) - Command system architecture
- [`yaml-parser-design.md`](yaml-parser-design.md:1) - YAML parsing implementation

---

## Testing Strategy

### Unit Tests

**Test File**: `tests/acp.preferences.test.sh`

```bash
# Test preference resolution precedence
test_preference_precedence() {
  # Setup: Create preferences at all levels
  # User: create_mode = 'unstructured'
  # Workspace: create_mode = 'structured'
  # Project: create_mode = 'guided'
  
  # Assert: Project value wins
  assert_equals "$(get_preference 'acp' 'plan.draft.create_mode')" "guided"
}

# Test fallback to default
test_preference_default_fallback() {
  # Setup: No preferences set
  # Assert: Returns default from configurables
  assert_equals "$(get_preference 'acp' 'plan.draft.create_mode')" "structured"
}

# Test missing preference
test_missing_preference() {
  # Setup: Preference doesn't exist in configurables
  # Assert: Returns empty string
  assert_equals "$(get_preference 'acp' 'nonexistent.preference')" ""
}
```

### Integration Tests

**Test File**: `e2e/acp.plan-with-preferences.test.sh`

```bash
# Test @acp.plan respects preferences
test_plan_uses_preferences() {
  # Setup: Set plan.draft.create_mode = 'contextual'
  # Run: @acp.plan for new feature
  # Assert: No draft file created (contextual mode)
  # Assert: Planning proceeds directly
}
```

### Validation Tests

```bash
# Test configurable validation
test_validate_configurables() {
  # Assert: All configurables have required fields (id, description, default)
  # Assert: All options have name, description, value
  # Assert: No duplicate IDs
}

# Test preference validation
test_validate_preferences() {
  # Assert: All preference values exist in configurables options
  # Assert: Preference paths match configurable structure
  # Assert: Types match (number, boolean, string)
}
```

---

## Migration Path

### Phase 1: Foundation (Week 1)
1. Create `agent/scripts/acp.preferences-get.sh` with core functions (matches entity CRUD pattern)
2. Create `agent/configurables/acp.configurables.yaml` with initial preferences
3. Create `agent/preferences/acp.default.yaml` template
4. Add preference loading to `acp.common.sh`

### Phase 2: Command Integration (Week 2)
1. Update `@acp.plan` to use `plan.draft.create_mode` preference
2. Update `@acp.task-create` to use `task.granularity.default_hours` preference
3. Update `@acp.validate` to use `validation.auto_fix.enabled` preference
4. Test command behavior with and without preferences

### Phase 3: Management Commands (Week 3)
1. Create `@acp.preferences-init` - Initialize preference files
2. Create `@acp.preferences-show` - Display effective preferences
3. Create `@acp.preferences-set` - Set preference values
4. Create `@acp.preferences-validate` - Validate preferences against configurables

### Phase 4: Package Support (Week 4)
1. Update `@acp.package-install` to copy configurables
2. Update `@acp.package-create` to create configurables template
3. Document package preference patterns
4. Create example package with preferences

### Phase 5: Documentation (Week 5)
1. Update AGENT.md with preferences section
2. Update README.md with preference examples
3. Create preference best practices guide
4. Update all command docs that support preferences

---

## Future Considerations

### 1. Preference Inheritance
- ~~Allow preferences to reference other preferences~~
- ~~Example: `acp.plan.draft.create_mode: ${acp.default.draft_mode}`~~
- **Decision**: Not implementing - unfurnished values use defaults automatically via precedence system. Variable references would add unnecessary complexity without significant benefit.

### 2. Conditional Preferences
- Preferences based on project type or environment
- Example: Use 'guided' mode for TypeScript projects, 'contextual' for Python

### 3. Preference Profiles
- Named profiles that bundle multiple preferences
- Example: `@acp.plan --profile rapid-prototyping`

### 4. Preference Discovery UI
- Interactive command to browse available preferences
- Example: `@acp.preferences-browse` with fuzzy search

### 5. Preference Validation Hooks
- Custom validation functions for complex preferences
- Example: Validate that server.type matches available auth providers

### 6. Preference Migration
- Automatic migration when configurables change
- Example: Rename preference paths, update values

### 7. Environment Variable Override
- Allow environment variables to override preferences
- Example: `ACP_PLAN_DRAFT_MODE=guided @acp.plan`

### 8. Preference Locking
- Lock preferences at workspace/project level to prevent user overrides
- Example: Enforce team standards

---

## Implementation Checklist

### Core Infrastructure
- [ ] Create `agent/scripts/acp.preferences-get.sh` with preference functions (entity CRUD pattern)
- [ ] Create `agent/configurables/acp.configurables.yaml` with core preferences
- [ ] Create `agent/preferences/acp.default.yaml` template
- [ ] Add preference loading to `acp.common.sh`
- [ ] Create unit tests for preference resolution

### Command Integration
- [ ] Update `@acp.plan` to use preferences
- [ ] Update `@acp.task-create` to use preferences
- [ ] Update `@acp.validate` to use preferences
- [ ] Test commands with various preference configurations

### Management Commands
- [ ] Create `@acp.preferences-init` command
- [ ] Create `@acp.preferences-show` command
- [ ] Create `@acp.preferences-set` command
- [ ] Create `@acp.preferences-validate` command

### Package Support
- [ ] Update `@acp.package-install` to handle configurables
- [ ] Update `@acp.package-create` to create configurables
- [ ] Document package preference patterns
- [ ] Create example package with preferences

### Documentation
- [ ] Update AGENT.md with preferences section
- [ ] Update README.md with preference examples
- [ ] Update command docs that support preferences
- [ ] Create preferences best practices guide

### Testing
- [ ] Unit tests for preference resolution
- [ ] Integration tests for command usage
- [ ] E2E tests for package preferences
- [ ] Validation tests for configurables

---

## Example Workflows

### Workflow 1: User Sets Global Preference

```bash
# User wants all drafts to be guided (chat-based)
@acp.preferences-set acp plan.draft.create_mode guided --global

# Now all @acp.plan invocations use guided mode by default
@acp.plan  # Uses guided mode automatically
```

### Workflow 2: Project Overrides User Preference

```bash
# User prefers guided mode globally
# ~/.acp/agent/preferences/acp.default.yaml:
#   acp.plan.draft.create_mode: 'guided'

# But this project requires structured drafts for compliance
# ./agent/preferences/acp.default.yaml:
#   acp.plan.draft.create_mode: 'structured'

# Result: Project preference wins
@acp.plan  # Uses structured mode (project override)
```

### Workflow 3: Package Preset Configuration

```bash
# Install package with preset configuration
@acp.package-install user/mcp-auth-server-base

# Use preset for static JWT auth
@mcp-auth-server-base.init --preset mcp-auth-server-base.static-jwt-auth

# Command loads agent/preferences/mcp-auth-server-base.static-jwt-auth.yaml
# Uses preset values without prompting user
# Preset name includes full namespace for clarity and discoverability
```

### Workflow 4: Temporary Override

```bash
# User has preference set, but wants to override for one invocation
@acp.plan --plan.draft.create_mode unstructured

# This invocation uses unstructured mode (dot notation for preference override)
# Next invocation uses stored preference again
# Override syntax: --{preference.path} {value}
```

---

## Security Considerations

### File Permissions
- Preference files may contain sensitive defaults (API endpoints, etc.)
- User-level preferences: `chmod 600 ~/.acp/agent/preferences/*.yaml`
- Project preferences: Normal git permissions (committed to repo)

### Validation
- All preference values validated against configurables
- Invalid values rejected with clear error messages
- Type checking (string, number, boolean)

### Secrets
- **NEVER** store secrets in preference files
- Use environment variables or secret management systems
- Preferences should reference secret names, not values

### Package Preferences
- Package configurables reviewed during `@acp.package-validate`
- Malicious packages cannot override core ACP preferences
- Namespace isolation prevents conflicts

---

## Status

**Status**: Design Specification
**Recommendation**: Proceed with implementation as Milestone 6
**Related Documents**: 
- [`acp-commands-design.md`](acp-commands-design.md:1) - Command system
- [`acp-package-management-system.md`](acp-package-management-system.md:1) - Package system
- [`yaml-parser-design.md`](yaml-parser-design.md:1) - YAML parsing

**Next Steps**:
1. Create Milestone 6: ACP Preferences System
2. Break down into 6-8 tasks
3. Implement core infrastructure first
4. Integrate with existing commands
5. Add management commands
6. Document and test
