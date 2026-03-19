# Task 52: Project Registry Infrastructure

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 29 (Global ACP Auto-Initialization)  
**Status**: Not Started  

---

## Objective

Create the foundational infrastructure for the project registry system including the registry file structure, schema definition, and core utility functions for registry operations.

---

## Context

This task establishes the foundation for the entire project registry system. The registry (`~/.acp/projects.yaml`) will track all projects in `~/.acp/projects/` with metadata including type, status, tags, relationships, and dependencies. The `current_project` field enables context switching via `@acp.project-set`.

---

## Steps

### 1. Create Registry Schema

Create `agent/schemas/projects.schema.yaml`:

```yaml
# Schema for ~/.acp/projects.yaml
schema:
  required:
    - registry_version
    - last_updated
  
  fields:
    current_project:
      type: string
      description: Name of currently active project
      required: false
    
    registry_version:
      type: string
      pattern: "^[0-9]+\\.[0-9]+\\.[0-9]+$"
      description: Schema version (semver)
      required: true
    
    last_updated:
      type: string
      pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
      description: Last registry update timestamp (ISO 8601)
      required: true
    
    projects:
      type: object
      description: Map of project names to project metadata
      required: false
      schema:
        fields:
          path:
            type: string
            description: Absolute path to project directory
            required: true
          
          type:
            type: string
            description: Project type (mcp-server, web-app, cli-tool, etc.)
            required: true
          
          description:
            type: string
            description: One-line project description
            required: true
          
          created:
            type: string
            pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
            description: Project creation timestamp
            required: true
          
          last_modified:
            type: string
            pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
            description: Last modification timestamp
            required: true
          
          last_accessed:
            type: string
            pattern: "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
            description: Last access timestamp (updated by @acp.project-set)
            required: true
          
          status:
            type: enum
            values: [active, archived, paused]
            description: Project status
            required: true
          
          tags:
            type: array
            description: Searchable tags
            required: false
          
          related_projects:
            type: array
            description: Names of related projects
            required: false
          
          dependencies:
            type: object
            description: External dependencies by package manager
            required: false
```

### 2. Create Registry Template

Create `agent/projects.template.yaml`:

```yaml
# ACP Project Registry
# Tracks projects in global workspace (~/.acp/projects/)

# Current active project (set by @acp.project-set)
current_project: null

# Project entries
projects: {}

# Registry metadata
registry_version: 1.0.0
last_updated: null
```

### 3. Add Registry Utility Functions

Add to `agent/scripts/acp.common.sh`:

```bash
# ============================================================================
# Project Registry Functions
# ============================================================================

# Get path to projects registry
# Usage: registry_path=$(get_projects_registry_path)
get_projects_registry_path() {
    echo "$HOME/.acp/projects.yaml"
}

# Check if projects registry exists
# Usage: if projects_registry_exists; then ...
projects_registry_exists() {
    [ -f "$(get_projects_registry_path)" ]
}

# Initialize projects registry
# Usage: init_projects_registry
init_projects_registry() {
    local registry_path
    registry_path=$(get_projects_registry_path)
    
    if [ -f "$registry_path" ]; then
        return 0  # Already exists
    fi
    
    # Ensure ~/.acp/ exists
    mkdir -p "$HOME/.acp"
    
    # Copy template
    local template="agent/projects.template.yaml"
    if [ -f "$template" ]; then
        cp "$template" "$registry_path"
    else
        # Create minimal registry
        cat > "$registry_path" << 'EOF'
# ACP Project Registry
current_project: null
projects: {}
registry_version: 1.0.0
last_updated: null
EOF
    fi
    
    # Set initial timestamp
    local timestamp
    timestamp=$(get_timestamp)
    yaml_set "$registry_path" "last_updated" "$timestamp"
}

# Register project in registry
# Usage: register_project "project-name" "/path/to/project" "project-type" "description"
register_project() {
    local project_name="$1"
    local project_path="$2"
    local project_type="$3"
    local project_description="$4"
    local registry_path
    registry_path=$(get_projects_registry_path)
    
    # Initialize registry if needed
    if ! projects_registry_exists; then
        init_projects_registry
    fi
    
    # Get timestamp
    local timestamp
    timestamp=$(get_timestamp)
    
    # Add project entry
    yaml_set "$registry_path" "projects.${project_name}.path" "$project_path"
    yaml_set "$registry_path" "projects.${project_name}.type" "$project_type"
    yaml_set "$registry_path" "projects.${project_name}.description" "$project_description"
    yaml_set "$registry_path" "projects.${project_name}.created" "$timestamp"
    yaml_set "$registry_path" "projects.${project_name}.last_modified" "$timestamp"
    yaml_set "$registry_path" "projects.${project_name}.last_accessed" "$timestamp"
    yaml_set "$registry_path" "projects.${project_name}.status" "active"
    
    # Set as current project if first project
    local current
    current=$(yaml_query "$registry_path" "current_project")
    if [ -z "$current" ] || [ "$current" = "null" ]; then
        yaml_set "$registry_path" "current_project" "$project_name"
    fi
    
    # Update registry timestamp
    yaml_set "$registry_path" "last_updated" "$timestamp"
}

# Check if project exists in registry
# Usage: if project_exists "project-name"; then ...
project_exists() {
    local project_name="$1"
    local registry_path
    registry_path=$(get_projects_registry_path)
    
    if ! projects_registry_exists; then
        return 1
    fi
    
    yaml_has_key "$registry_path" "projects.${project_name}"
}

# Get current project name
# Usage: current=$(get_current_project)
get_current_project() {
    local registry_path
    registry_path=$(get_projects_registry_path)
    
    if ! projects_registry_exists; then
        return 1
    fi
    
    local current
    current=$(yaml_query "$registry_path" "current_project")
    if [ "$current" != "null" ]; then
        echo "$current"
    fi
}

# Get current project path
# Usage: path=$(get_current_project_path)
get_current_project_path() {
    local current
    current=$(get_current_project)
    
    if [ -z "$current" ]; then
        pwd  # Fallback to current directory
        return 0
    fi
    
    local registry_path
    registry_path=$(get_projects_registry_path)
    yaml_query "$registry_path" "projects.${current}.path"
}
```

### 4. Update init_global_acp()

Add registry initialization to `init_global_acp()` in `acp.common.sh`:

```bash
# In init_global_acp() function, after creating ~/.acp/agent/manifest.yaml:

# Initialize projects registry
if [ ! -f "$HOME/.acp/projects.yaml" ]; then
    init_projects_registry
    echo "${GREEN}✓${NC} Initialized projects registry"
fi
```

### 5. Make Functions Executable

Ensure all functions are properly sourced and tested:

```bash
# Test in shell
source agent/scripts/acp.common.sh
init_projects_registry
echo "Registry path: $(get_projects_registry_path)"
```

### 6. Create Unit Tests

Create `tests/acp.project-registry.test.sh`:

```bash
#!/usr/bin/env bash
# Unit tests for project registry functions

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/../agent/scripts/acp.common.sh"

# Setup test environment
setup() {
    export HOME="/tmp/acp-test-$$"
    mkdir -p "$HOME/.acp"
}

# Cleanup
teardown() {
    rm -rf "$HOME"
}

# Test 1: Registry initialization
test_init_projects_registry() {
    setup
    init_projects_registry
    assert_file_exists "$HOME/.acp/projects.yaml"
    teardown
}

# Test 2: Project registration
test_register_project() {
    setup
    init_projects_registry
    register_project "test-project" "/path/to/project" "mcp-server" "Test project"
    assert_equals "$(yaml_query "$HOME/.acp/projects.yaml" "projects.test-project.type")" "mcp-server"
    teardown
}

# Test 3: Project exists check
test_project_exists() {
    setup
    init_projects_registry
    register_project "test-project" "/path/to/project" "mcp-server" "Test"
    assert_true project_exists "test-project"
    assert_false project_exists "nonexistent"
    teardown
}

# Test 4: Current project tracking
test_current_project() {
    setup
    init_projects_registry
    register_project "first-project" "/path/1" "mcp-server" "First"
    assert_equals "$(get_current_project)" "first-project"
    teardown
}

# Run all tests
run_tests
```

---

## Verification

- [ ] `agent/schemas/projects.schema.yaml` created
- [ ] `agent/projects.template.yaml` created
- [ ] 8 registry functions added to `acp.common.sh`
- [ ] `init_global_acp()` updated to initialize registry
- [ ] Unit tests created and passing
- [ ] Registry can be created and initialized
- [ ] Projects can be registered
- [ ] Current project can be tracked
- [ ] All functions are POSIX-compliant
- [ ] No syntax errors (`bash -n acp.common.sh`)

---

## Expected Output

### Files Created
- `agent/schemas/projects.schema.yaml` - Registry schema definition
- `agent/projects.template.yaml` - Registry template
- `tests/acp.project-registry.test.sh` - Unit tests

### Files Modified
- `agent/scripts/acp.common.sh` - Added 8 registry functions

### Test Output
```bash
$ ./tests/acp.project-registry.test.sh
Running tests...
✓ test_init_projects_registry
✓ test_register_project
✓ test_project_exists
✓ test_current_project

4/4 tests passed (100%)
```

---

## Common Issues and Solutions

### Issue 1: Registry not created
**Symptom**: Functions fail with "file not found"  
**Solution**: Call `init_projects_registry()` before other operations  

### Issue 2: YAML parser not available
**Symptom**: yaml_set/yaml_query commands not found  
**Solution**: Ensure `acp.yaml-parser.sh` is sourced  

### Issue 3: HOME not set
**Symptom**: Registry path is incorrect  
**Solution**: Ensure $HOME environment variable is set  

---

## Resources

- [Design Document](../../design/local.projects-yaml-feature.md) - Complete design specification
- [YAML Parser](../../scripts/acp.yaml-parser.sh) - YAML processing functions
- [Package Schema](../../schemas/package.schema.yaml) - Similar schema example

---

## Notes

- Registry is optional - projects work without it
- Registry auto-created on first use
- Functions are idempotent (safe to call multiple times)
- Schema validation will be added in later tasks
- Current project defaults to first registered project

---

**Next Task**: [Task 53: @acp.project-list Command](task-53-project-list.md)  
**Related Design Docs**: [Global ACP Project Registry](../../design/local.projects-yaml-feature.md)  
**Estimated Completion Date**: TBD  
