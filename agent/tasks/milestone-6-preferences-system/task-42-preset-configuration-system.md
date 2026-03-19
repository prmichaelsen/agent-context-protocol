# Task 42: Preset Configuration System

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 37 (Preference Loading), Task 41 (Package Support)  
**Status**: Not Started  

---

## Objective

Implement the `--preset` flag system that allows commands to load predefined preference bundles, enabling workflow automation and reducing configuration overhead.

---

## Context

Presets are named preference bundles that configure multiple preferences at once for common workflows. For example, a `acp.batch-planning` preset might set:
- `plan.draft.create_mode: 'contextual'`
- `plan.batch.auto_confirm: true`
- `task.create.granularity: 2`

This enables users to switch between workflows with a single flag rather than configuring multiple preferences individually.

---

## Steps

### 1. Define Preset File Format

Presets are standard preference files with descriptive names:

**File**: `agent/preferences/acp.batch-planning.yaml`  

```yaml
# ACP Batch Planning Preset
# Optimized for rapid, automated planning without user interaction
# Usage: @acp.plan --preset acp.batch-planning

acp:
  plan.draft.create_mode: 'contextual'
  plan.batch.auto_confirm: true
  task.create.granularity: 2
  validation.auto_fix.enabled: true
  output.verbosity.level: 'quiet'
```

**Naming Convention**: `{namespace}.{preset-name}.yaml`  

### 2. Add Preset Loading to acp.preferences-get.sh

Add function to load preset:

```bash
# Load preset configuration
# Usage: load_preset "namespace" "preset_name"
# Returns: 0 if loaded, 1 if not found
load_preset() {
  local namespace="$1"
  local preset_name="$2"
  
  # Preset filename: {namespace}.{preset-name}.yaml
  local preset_file="./agent/preferences/${namespace}.${preset_name}.yaml"
  
  if [ ! -f "$preset_file" ]; then
    # Try user-level presets
    preset_file="$HOME/.acp/agent/preferences/${namespace}.${preset_name}.yaml"
  fi
  
  if [ ! -f "$preset_file" ]; then
    error "Preset not found: ${namespace}.${preset_name}"
    return 1
  fi
  
  # Parse preset file
  # Store in temporary location for this invocation
  # Preset has highest precedence (overrides project/workspace/user)
  
  info "Loaded preset: ${namespace}.${preset_name}"
  return 0
}

# Get preference with preset support
# Usage: get_preference_with_preset "namespace" "preference.path" "preset_name"
get_preference_with_preset() {
  local namespace="$1"
  local pref_path="$2"
  local preset_name="$3"
  
  # If preset specified, check preset first
  if [ -n "$preset_name" ]; then
    local preset_file="./agent/preferences/${namespace}.${preset_name}.yaml"
    if [ ! -f "$preset_file" ]; then
      preset_file="$HOME/.acp/agent/preferences/${namespace}.${preset_name}.yaml"
    fi
    
    if [ -f "$preset_file" ]; then
      local value=$(yaml_query "$preset_file" "${namespace}.${pref_path}")
      if [ -n "$value" ]; then
        echo "$value"
        return 0
      fi
    fi
  fi
  
  # Fall back to normal precedence
  get_preference "$namespace" "$pref_path"
}
```

### 3. Update Command Argument Parsing

Add preset support to commands. Update `@acp.plan` as example:

```markdown
## Arguments

**CLI-Style Arguments**:
- `--batch` or `--all` - Plan all undefined items
- `--milestone <id>` - Plan specific milestone
- `--task <id>` - Plan specific task
- `--draft <path>` - Use specific draft file
- `--preset <preset-name>` - Load preset configuration
- `--plan.draft.create_mode <value>` - Override specific preference

**Preset Usage**:
```bash
# Use batch planning preset
@acp.plan --preset acp.batch-planning

# Preset with override
@acp.plan --preset acp.batch-planning --plan.draft.create_mode structured
```

**Precedence** (highest to lowest):
1. Command-line overrides (`--plan.draft.create_mode`)
2. Preset (`--preset`)
3. Project preferences
4. Workspace preferences
5. User preferences
6. Defaults (from configurables)
```

### 4. Create Core ACP Presets

Create useful presets for common workflows:

**File**: `agent/preferences/acp.batch-planning.yaml`  
```yaml
# Batch Planning Preset - Automated planning without interaction
acp:
  plan.draft.create_mode: 'contextual'
  plan.batch.auto_confirm: true
  task.create.granularity: 2
  validation.auto_fix.enabled: true
  output.verbosity.level: 'quiet'
```

**File**: `agent/preferences/acp.interactive-planning.yaml`  
```yaml
# Interactive Planning Preset - Guided planning with user input
acp:
  plan.draft.create_mode: 'guided'
  plan.batch.auto_confirm: false
  task.create.granularity: 4
  validation.auto_fix.enabled: false
  output.verbosity.level: 'verbose'
```

**File**: `agent/preferences/acp.rapid-prototyping.yaml`  
```yaml
# Rapid Prototyping Preset - Fast iteration with minimal overhead
acp:
  plan.draft.create_mode: 'contextual'
  task.create.granularity: 1
  validation.auto_fix.enabled: true
  git.auto_commit.enabled: true
  output.verbosity.level: 'quiet'
```

### 5. Add Preset Discovery

Add function to list available presets:

```bash
# List available presets for namespace
# Usage: list_presets "namespace"
list_presets() {
  local namespace="$1"
  
  echo "Available presets for ${namespace}:"
  echo ""
  
  # Project presets
  if [ -d "./agent/preferences" ]; then
    echo "📁 Project Presets:"
    ls -1 "./agent/preferences/${namespace}."*.yaml 2>/dev/null | while read -r file; do
      local preset_name=$(basename "$file" .yaml | sed "s/^${namespace}\.//")
      if [ "$preset_name" != "default" ]; then
        echo "  • ${preset_name}"
      fi
    done
    echo ""
  fi
  
  # User presets
  if [ -d "$HOME/.acp/agent/preferences" ]; then
    echo "👤 User Presets:"
    ls -1 "$HOME/.acp/agent/preferences/${namespace}."*.yaml 2>/dev/null | while read -r file; do
      local preset_name=$(basename "$file" .yaml | sed "s/^${namespace}\.//")
      if [ "$preset_name" != "default" ]; then
        echo "  • ${preset_name}"
      fi
    done
  fi
}
```

### 6. Add Preset to @acp.preferences-show

Update `@acp.preferences-show` to support `--presets` flag:

```markdown
## Arguments

- `<namespace>` - Namespace to show (default: acp)
- `--all` - Show all namespaces
- `--presets` - List available presets instead of preferences

## Examples

```bash
# Show preferences
@acp.preferences-show acp

# List available presets
@acp.preferences-show acp --presets

# Output:
Available presets for acp:

📁 Project Presets:
  • batch-planning
  • interactive-planning
  • rapid-prototyping

👤 User Presets:
  • my-custom-workflow
```
```

### 7. Update Package Documentation

Add preset documentation to `@acp.package-create` README template:

```markdown
## Presets

This package provides the following preset configurations:

### {preset-name}
**File**: `agent/preferences/{package-name}.{preset-name}.yaml`  
**Description**: [What this preset configures]  

**Usage**:
```bash
@{package-command} --preset {package-name}.{preset-name}
```

**Configured Preferences**:
- `preference.path.1`: value1
- `preference.path.2`: value2
```

### 8. Test Preset System

Test preset loading and precedence:

```bash
# Test 1: Load preset
@acp.plan --preset acp.batch-planning
# Verify: Uses contextual mode, auto-confirms

# Test 2: Preset with override
@acp.plan --preset acp.batch-planning --plan.draft.create_mode structured
# Verify: Uses structured mode (override wins)

# Test 3: List presets
@acp.preferences-show acp --presets
# Verify: Shows all available presets

# Test 4: Invalid preset
@acp.plan --preset acp.nonexistent
# Verify: Clear error message
```

---

## Verification

- [ ] Preset loading function added to `acp.preferences-get.sh`
- [ ] `get_preference_with_preset()` function works correctly
- [ ] `list_presets()` function works correctly
- [ ] Three core ACP presets created (batch, interactive, rapid)
- [ ] `@acp.plan` supports `--preset` flag
- [ ] `@acp.preferences-show` supports `--presets` flag
- [ ] Preset precedence works correctly (preset > project > workspace > user > default)
- [ ] Command-line overrides work with presets
- [ ] Package documentation template includes preset section
- [ ] All tests passing
- [ ] Error handling for missing presets

---

## Expected Output

### Files Created
- `agent/preferences/acp.batch-planning.yaml` - Batch planning preset
- `agent/preferences/acp.interactive-planning.yaml` - Interactive preset
- `agent/preferences/acp.rapid-prototyping.yaml` - Rapid prototyping preset

### Files Modified
- `agent/scripts/acp.preferences-get.sh` - Added preset functions
- `agent/commands/acp.plan.md` - Added preset support
- `agent/commands/acp.preferences-show.md` - Added preset listing

### Preset Usage Example
```bash
$ @acp.plan --preset acp.batch-planning

📋 Planning Items Detected: 3 undefined tasks

Using preset: acp.batch-planning
  • plan.draft.create_mode: contextual
  • plan.batch.auto_confirm: true
  • task.create.granularity: 2

[Proceeds with automated planning...]
```

---

## Common Issues and Solutions

### Issue 1: Preset not found
**Symptom**: Error "Preset not found: acp.batch-planning"  
**Solution**: Check preset file exists in `./agent/preferences/` or `~/.acp/agent/preferences/`  

### Issue 2: Preset doesn't override
**Symptom**: Project preference used instead of preset  
**Solution**: Ensure preset is loaded before project preferences in precedence chain  

### Issue 3: Invalid preset values
**Symptom**: Preset contains invalid preference values  
**Solution**: Run `@acp.preferences-validate` to check preset files  

---

## Resources

- [Design Document](../design/acp-preferences-system.md) - Preset specifications
- [Preference Loading](../scripts/acp.preferences-get.sh) - Core functions
- [Command Template](../commands/command.template.md) - Command structure

---

## Notes

- Presets are just preference files with descriptive names
- Preset names should be descriptive (e.g., `batch-planning` not `bp`)
- Presets can be project-specific or user-specific
- Package presets should include namespace prefix
- Consider creating presets for common workflows as examples

---

**Next Task**: [Task 43: Preferences Testing Suite](task-43-preferences-testing-suite.md)  
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md)  
**Estimated Completion Date**: TBD  
