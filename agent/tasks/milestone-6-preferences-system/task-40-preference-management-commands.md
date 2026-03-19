# Task 40: Preference Management Commands

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)  
**Estimated Time**: 8-10 hours  
**Dependencies**: Task 37 (Preference Loading), Task 38 (Configurables Enhancement)  
**Status**: Not Started  

---

## Objective

Create five preference management commands that enable users to get, create, view, modify, and validate preferences at any level (user/workspace/project).

---

## Context

Users need tools to manage preferences without manually editing YAML files. These commands provide a user-friendly interface for preference management and ensure consistency through validation.

The five commands work together as a complete preference management suite:
- **get**: Generate complete preference set (invokes `acp.preferences.sh`)
- **create**: Create new preference files (follows entity creation pattern)
- **show**: Display current effective preferences with sources
- **set**: Modify preference values interactively
- **validate**: Ensure preferences are valid against configurables

---

## Steps

### 1. Create @acp.preferences-get Command

Create `agent/commands/acp.preferences-get.md`:

```markdown
# Command: preferences-get

> **🤖 Agent Directive**: Run `./agent/scripts/acp.preferences.sh get <namespace>`
> to generate complete preferences with precedence applied.

**Purpose**: Generate and display complete preference set for a namespace  
**Category**: Utility  
**Frequency**: As Needed  

---

## Steps

### 1. Parse Arguments
- Namespace (default: acp)
- Format (yaml or json)

### 2. Run Shell Script
```bash
./agent/scripts/acp.preferences.sh get <namespace> [yaml|json]
```

### 3. Display Output
Show generated preferences to user.

---

## Examples

```bash
# Get ACP preferences
@acp.preferences-get acp

# Get package preferences as JSON
@acp.preferences-get mcp-auth-server-base json
```
```

### 2. Create @acp.preferences-create Command

Create `agent/commands/acp.preferences-create.md`:

```markdown
# Command: preferences-create

> **🤖 Agent Directive**: Create preference files at the specified level.

**Purpose**: Create new preference files with default values (follows entity creation pattern)  
**Category**: Setup  
**Frequency**: Once per level  

---

## Steps

### 1. Determine Target Level

Ask user which level to initialize:
- User-global (`~/.acp/agent/preferences/`)
- Workspace (`.vscode/preferences/`)
- Project (`./agent/preferences/`)

### 2. Determine Namespace

Ask which namespace to initialize:
- `acp` (core ACP preferences)
- Package name (e.g., `mcp-auth-server-base`)
- All installed packages

### 3. Create Preference File

Copy defaults from configurables:

```bash
# For ACP
cp agent/configurables/acp.configurables.yaml \
   <target-level>/preferences/acp.default.yaml

# Extract defaults and create preference file
```

### 4. Confirm Creation

Display created file and location:
```
✅ Preferences initialized!

File: ~/.acp/agent/preferences/acp.default.yaml
Preferences: 8 defaults set

Run @acp.preferences-show to view effective preferences.
```

---

## Examples

```bash
# Create user-level ACP preferences
@acp.preferences-create --level user --namespace acp

# Create project-level preferences for all packages
@acp.preferences-create --level project --all
```
```

### 3. Create @acp.preferences-show Command

Create `agent/commands/acp.preferences-show.md`:

```markdown
# Command: preferences-show

> **🤖 Agent Directive**: Display effective preferences with source indication.

**Purpose**: Show current preference values and where they come from  
**Category**: Utility  
**Frequency**: As Needed  

---

## Steps

### 1. Parse Arguments

Determine which namespace to show:
- Default: `acp`
- Specified: Package name

### 2. Generate Preferences

Invoke `@acp.preferences-get <namespace>` to get complete preference set.

### 3. Get Sources

For each preference, determine source using `get_preference_source()`.

### 4. Display with Formatting

Show preferences with color-coded sources:

```
📊 Effective Preferences for: acp

plan.draft.create_mode: 'structured'
  └─ Source: 📁 Project (./agent/preferences/acp.default.yaml)

task.create.granularity: 3
  └─ Source: 👤 User (~/.acp/agent/preferences/acp.default.yaml)

validation.auto_fix.enabled: true
  └─ Source: ⚙️  Default (./agent/configurables/acp.configurables.yaml)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Legend:
  📁 Project   - ./agent/preferences/
  💼 Workspace - .vscode/preferences/
  👤 User      - ~/.acp/agent/preferences/
  ⚙️  Default   - ./agent/configurables/
```

---

## Examples

```bash
# Show ACP preferences
@acp.preferences-show

# Show package preferences
@acp.preferences-show mcp-auth-server-base

# Show all namespaces
@acp.preferences-show --all
```
```

### 3. Create @acp.preferences-set Command

Create `agent/commands/acp.preferences-set.md`:

```markdown
# Command: preferences-set

> **🤖 Agent Directive**: Set preference value at specified level.

**Purpose**: Modify preference values interactively  
**Category**: Configuration  
**Frequency**: As Needed  

---

## Steps

### 1. Parse Arguments

Extract:
- Namespace (e.g., `acp`)
- Preference path (e.g., `plan.draft.create_mode`)
- Value (e.g., `guided`)
- Level flag (`--user`, `--workspace`, `--project`)

### 2. Validate Preference

Check against configurables:
- Preference exists
- Value is valid option (for string types)
- Value is in range (for number types)
- Value is boolean (for boolean types)

### 3. Determine Target File

Based on level flag:
- `--user` or `--global`: `~/.acp/agent/preferences/{namespace}.default.yaml`
- `--workspace`: `.vscode/preferences/{namespace}.yaml`
- `--project` or no flag: `./agent/preferences/{namespace}.default.yaml`

### 4. Update Preference File

Use YAML parser to set value:

```bash
yaml_set "$target_file" "${namespace}.${pref_path}" "$value"
```

### 5. Confirm Change

Display updated preference:
```
✅ Preference updated!

Namespace: acp
Preference: plan.draft.create_mode
Value: 'guided'
Level: User (~/.acp/agent/preferences/acp.default.yaml)

Run @acp.preferences-show to see effective preferences.
```

---

## Examples

```bash
# Set user-level preference
@acp.preferences-set acp plan.draft.create_mode guided --user

# Set project-level preference
@acp.preferences-set acp task.create.granularity 2 --project

# Interactive mode (prompts for all values)
@acp.preferences-set
```
```

### 4. Create @acp.preferences-validate Command

Create `agent/commands/acp.preferences-validate.md`:

```markdown
# Command: preferences-validate

> **🤖 Agent Directive**: Validate all preference files against configurables.

**Purpose**: Ensure preference values are valid and consistent  
**Category**: Validation  
**Frequency**: As Needed  

---

## Steps

### 1. Scan Preference Files

Find all preference files:
- User: `~/.acp/agent/preferences/*.yaml`
- Workspace: `.vscode/preferences/*.yaml`
- Project: `./agent/preferences/*.yaml`

### 2. Validate Each File

For each preference file:
- Parse YAML structure
- Extract namespace and preferences
- Load corresponding configurables
- Validate each preference:
  - Preference exists in configurables
  - Value matches type (string/number/boolean)
  - Value is valid option (for string types)
  - Value is in range (for number types)

### 3. Report Issues

Display validation results:

```
🔍 Validating Preferences...

✅ User Preferences (acp): Valid
   - 5 preferences checked
   - 0 errors, 0 warnings

❌ Project Preferences (acp): Invalid
   - 8 preferences checked
   - 2 errors:
     • plan.draft.create_mode: Invalid value 'invalid' (valid: structured, unstructured, guided, contextual)
     • task.create.granularity: Value 15 exceeds maximum 8

⚠️  Workspace Preferences (mcp-auth-server): Warnings
   - 3 preferences checked
   - 1 warning:
     • init.server.type: Preference not defined in configurables (may be outdated)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: FAIL (2 errors, 1 warning)

Run @acp.preferences-set to fix invalid values.
```

---

## Examples

```bash
# Validate all preferences
@acp.preferences-validate

# Validate specific namespace
@acp.preferences-validate acp

# Validate with auto-fix
@acp.preferences-validate --fix
```
```

### 5. Implement Shell Script Support

Add preference management functions to `acp.preferences-get.sh`:

```bash
# Set preference value
# Usage: set_preference "namespace" "preference.path" "value" "level"
set_preference() {
  local namespace="$1"
  local pref_path="$2"
  local value="$3"
  local level="$4"  # user, workspace, project
  
  # Determine target file based on level
  local target_file
  case "$level" in
    user|global)
      target_file="$HOME/.acp/agent/preferences/${namespace}.default.yaml"
      ;;
    workspace)
      target_file=".vscode/preferences/${namespace}.yaml"
      ;;
    project)
      target_file="./agent/preferences/${namespace}.default.yaml"
      ;;
    *)
      error "Invalid level: $level"
      return 1
      ;;
  esac
  
  # Create file if doesn't exist
  if [ ! -f "$target_file" ]; then
    mkdir -p "$(dirname "$target_file")"
    echo "${namespace}:" > "$target_file"
  fi
  
  # Set value using YAML parser
  yaml_set "$target_file" "${namespace}.${pref_path}" "$value"
}

# Validate preference value against configurables
# Usage: validate_preference "namespace" "preference.path" "value"
# Returns: 0 if valid, 1 if invalid
validate_preference() {
  local namespace="$1"
  local pref_path="$2"
  local value="$3"
  
  # Load configurables
  local configurable="./agent/configurables/${namespace}.configurables.yaml"
  if [ ! -f "$configurable" ]; then
    error "Configurables not found: $configurable"
    return 1
  fi
  
  # Check if preference exists
  local pref_def=$(yaml_query "$configurable" "${namespace}.${pref_path}")
  if [ -z "$pref_def" ]; then
    error "Preference not defined: ${pref_path}"
    return 1
  fi
  
  # Validate based on type
  local pref_type=$(yaml_query "$configurable" "${namespace}.${pref_path}.type")
  
  case "$pref_type" in
    string)
      # Check if value is in options (if options defined)
      # Return 0 if valid, 1 if invalid
      ;;
    number)
      # Check if value is number and in range
      ;;
    boolean)
      # Check if value is true or false
      ;;
  esac
  
  return 0
}
```

### 6. Test All Commands

Create integration tests for each command:

```bash
# Test init
@acp.preferences-init --level user --namespace acp
# Verify: File created with defaults

# Test show
@acp.preferences-show acp
# Verify: Displays preferences with sources

# Test set
@acp.preferences-set acp plan.draft.create_mode guided --user
# Verify: Value updated in file

# Test validate
@acp.preferences-validate
# Verify: Reports validation status
```

### 7. Update Documentation

Add commands to command list in AGENT.md and README.md.

---

## Verification

- [ ] `@acp.preferences-init` command created
- [ ] `@acp.preferences-show` command created
- [ ] `@acp.preferences-set` command created
- [ ] `@acp.preferences-validate` command created
- [ ] Shell functions added to `acp.preferences-get.sh`
- [ ] All commands tested and working
- [ ] Error handling implemented
- [ ] User-friendly output with colors
- [ ] Commands follow ACP command template structure
- [ ] Version and metadata complete
- [ ] Examples provided for each command

---

## Expected Output

### Files Created
- `agent/commands/acp.preferences-init.md` - Initialize preferences
- `agent/commands/acp.preferences-show.md` - Display preferences
- `agent/commands/acp.preferences-set.md` - Set preferences
- `agent/commands/acp.preferences-validate.md` - Validate preferences

### Files Modified
- `agent/scripts/acp.preferences-get.sh` - Added management functions

### Command Count
- Total ACP commands: 26 → 30 (4 new preference commands)

---

## Common Issues and Solutions

### Issue 1: Permission denied creating user preferences
**Symptom**: Error creating `~/.acp/agent/preferences/`  
**Solution**: Ensure `~/.acp/` directory exists and is writable  

### Issue 2: Workspace preferences not found
**Symptom**: Warning about missing `.vscode/preferences/`  
**Solution**: This is normal for non-VSCode projects - use project preferences instead  

### Issue 3: Invalid preference value
**Symptom**: Validation fails for set value  
**Solution**: Check configurables for valid options, use `@acp.preferences-show` to see available values  

---

## Resources

- [Design Document](../design/acp-preferences-system.md) - Management command specifications
- [Command Template](../commands/command.template.md) - Command structure
- [Preference Loading](../scripts/acp.preferences-get.sh) - Core functions

---

## Notes

- These are the primary user-facing commands for preference management
- Commands should be intuitive and forgiving (helpful error messages)
- `@acp.preferences-show` is most frequently used (for debugging)
- `@acp.preferences-set` should validate before writing
- Consider adding `--dry-run` flag to set command

---

**Next Task**: [Task 41: Package Preference Support](task-41-package-preference-support.md)  
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md)  
**Estimated Completion Date**: TBD  
