# Script-Command Binding System

**Concept**: Selective script installation based on command dependencies with dual validation
**Created**: 2026-02-24
**Status**: Design Specification

---

## Overview

The Script-Command Binding System implements selective script installation where scripts are only installed when their corresponding commands are installed. This prevents script directory clutter from unused files in experimental or selectively-installed packages.

**Key Innovation**: Commands declare script dependencies in both frontmatter and package.yaml, with validation ensuring consistency. Shared utility scripts (like acp.common.sh) are installed via reference counting - if ANY installed command needs a utility, it's installed.

---

## Problem Statement

### Current Issues

1. **Indiscriminate Installation**: `acp.install.sh` copies ALL scripts without checking if corresponding commands are installed
2. **Experimental Mismatch**: Experimental commands are skipped, but their scripts are still installed
3. **Selective Installation Gap**: `--commands command1` installs command but all scripts
4. **No Dependency Tracking**: No way to know which scripts are needed for which commands
5. **Multi-Dependency Problem**: Scripts can be dependencies of MULTIPLE commands (e.g., acp.common.sh)

### Evidence

- 19 total scripts in agent/scripts/
- Only 2 scripts explicitly source acp.common.sh (but many depend on it)
- acp.common.sh and acp.yaml-parser.sh are shared utilities used by multiple commands
- No tracking of which commands need which scripts

### Consequences

- Script directory cluttered with unused files
- Experimental command scripts installed unnecessarily
- No way to clean up unused scripts
- Confusing for users (which scripts are actually used?)

---

## Solution

### ✅ ACCEPTED SOLUTION: Dual Declaration with Required Field

Commands declare script dependencies in TWO places with validation ensuring consistency:

1. **Command Frontmatter** - Self-documenting, visible to users
2. **package.yaml** - Authoritative source for installation, enables validation

**Both sources MUST match** - validated by `@acp.package-validate`.

---

## Implementation

### 1. Command Frontmatter Declaration

Add `**Scripts**:` field to all command files:

```markdown
# Command: project-set

**Namespace**: acp
**Version**: 1.0.0
**Status**: Experimental
**Scripts**: acp.project-set.sh, acp.common.sh, acp.yaml-parser.sh

---
```

**Rules**:
- List ALL script dependencies (direct + shared utilities)
- Comma-separated list
- Include .sh extension
- REQUIRED field for all commands

### 2. package.yaml Declaration

Add `scripts` array to command entries:

```yaml
contents:
  commands:
    - name: acp.project-set.md
      description: Context switching command
      experimental: true
      scripts:  # ✅ REQUIRED - must match frontmatter exactly
        - acp.project-set.sh
        - acp.common.sh
        - acp.yaml-parser.sh
  
  scripts:
    - name: acp.project-set.sh
      description: Context switching script
      experimental: true
    
    - name: acp.common.sh
      description: Shared utility functions
      type: utility
      experimental: false
```

**Rules**:
- `scripts` field REQUIRED in command entries
- Must match command frontmatter exactly
- All scripts must exist in scripts section
- Scripts section marks experimental status

### 3. Installation Logic

**Algorithm**:
```bash
# Collect required scripts from installed commands
required_scripts=()

for cmd in installed_commands; do
  # Read scripts array from package.yaml (authoritative)
  cmd_scripts=$(yaml_get "contents.commands[?name=='$cmd'].scripts[]")
  
  for script in $cmd_scripts; do
    # Add to required set (deduplication)
    if ! in_array "$script" "${required_scripts[@]}"; then
      required_scripts+=("$script")
    fi
  done
done

# Install unique set of required scripts
for script in "${required_scripts[@]}"; do
  # Check experimental status from package.yaml scripts section
  if should_install_script "$script"; then
    install_script "$script"
  fi
done
```

**Reference Counting**: Shared utilities (acp.common.sh) installed if ANY command needs them.

### 4. Validation Logic

**Consistency Validation** (`@acp.package-validate`):
```bash
for cmd in commands; do
  # Get scripts from frontmatter
  frontmatter_scripts=$(grep "^\*\*Scripts\*\*:" "$cmd" | awk -F': ' '{print $2}' | tr ',' '\n' | tr -d ' ' | sort)
  
  # Get scripts from package.yaml
  yaml_scripts=$(yaml_get "contents.commands[?name=='$cmd'].scripts[]" | sort)
  
  # Compare
  if [ "$frontmatter_scripts" != "$yaml_scripts" ]; then
    error "Command $cmd: Scripts mismatch"
    echo "  Frontmatter: $frontmatter_scripts"
    echo "  package.yaml: $yaml_scripts"
  fi
  
  # Verify all scripts exist in scripts section
  for script in $frontmatter_scripts; do
    if ! script_exists_in_yaml "$script"; then
      error "Command $cmd declares $script, but it's not in scripts section"
    fi
  done
done
```

### 5. Schema Updates

**package.schema.yaml**:
```yaml
contents:
  commands:
    items:
      properties:
        scripts:
          type: array
          required: true  # ✅ REQUIRED FIELD
          description: "Script dependencies for this command"
          items:
            type: string
            pattern: "^[a-z0-9-]+\\.[a-z0-9-]+\\.sh$"
```

---

## Benefits

### 1. Selective Installation
- Only install scripts for installed commands
- Experimental commands → experimental scripts skipped
- Selective commands → only those scripts installed

### 2. Reference Counting
- Shared utilities installed if ANY command needs them
- acp.common.sh installed once, used by many
- No duplicate installations

### 3. Dual Validation
- Frontmatter and package.yaml must match
- Prevents drift between documentation and definition
- Catches inconsistencies early

### 4. Self-Documenting
- Users can see command dependencies in frontmatter
- Clear what scripts are needed
- Improves understanding

### 5. Maintainability
- Update both frontmatter and package.yaml
- Validation ensures consistency
- Clear error messages

---

## Trade-offs

### Pros
- ✅ Handles multi-dependency problem (shared utilities)
- ✅ Self-documenting (visible in command files)
- ✅ Validated (consistency enforced)
- ✅ Reference counting (install if ANY command needs it)
- ✅ Experimental support (via package.yaml)
- ✅ Clean installations (no unused scripts)

### Cons
- ❌ Must update TWO places (frontmatter + package.yaml)
- ❌ Validation overhead (check consistency)
- ❌ Existing commands need Scripts field added
- ❌ Requires schema update (scripts field required)

**Mitigation**: Validation catches inconsistencies, preventing drift. The dual declaration is worth the maintenance cost for the benefits gained.

---

## Implementation Plan

### Phase 1: Schema and Template Updates (1 hour)
1. Update package.schema.yaml - Make scripts field REQUIRED in command entries
2. Update command.template.md - Add **Scripts**: field (required)
3. Update package.template.yaml - Add scripts array example in commands

### Phase 2: Installation Logic (2-3 hours)
1. Update acp.install.sh - Selective script copying based on package.yaml
2. Update acp.package-install.sh - Read scripts from package.yaml, apply reference counting
3. Update acp.package-update.sh - Update scripts based on command installation

### Phase 3: Validation (1 hour)
1. Update acp.package-validate.sh - Add scripts consistency validation
2. Check frontmatter ↔ package.yaml match
3. Verify scripts exist in scripts section

### Phase 4: Existing Commands (1-2 hours)
1. Add **Scripts**: field to all existing ACP commands
2. Create/update package.yaml for ACP core
3. List all scripts with dependencies

### Phase 5: Testing (1 hour)
1. Test selective installation (only needed scripts)
2. Test experimental filtering (scripts respect flag)
3. Test reference counting (shared utilities)
4. Test validation (catches inconsistencies)

---

## Examples

### Example 1: Command with Direct Script

**Command Frontmatter**:
```markdown
**Scripts**: firebase.deploy.sh, acp.common.sh
```

**package.yaml**:
```yaml
commands:
  - name: firebase.deploy.md
    scripts:
      - firebase.deploy.sh
      - acp.common.sh
```

**Installation**: Both scripts installed when command installed.

### Example 2: Multiple Commands, Shared Utility

**Command 1**:
```markdown
**Scripts**: acp.project-set.sh, acp.common.sh, acp.yaml-parser.sh
```

**Command 2**:
```markdown
**Scripts**: acp.project-list.sh, acp.common.sh, acp.yaml-parser.sh
```

**Installation**: 
- If both commands installed: All 4 scripts installed (project-set.sh, project-list.sh, common.sh, yaml-parser.sh)
- If only command 1: 3 scripts (project-set.sh, common.sh, yaml-parser.sh)
- Reference counting ensures utilities installed once

### Example 3: Experimental Command

**Command**:
```markdown
**Status**: Experimental
**Scripts**: experimental.sh, acp.common.sh
```

**package.yaml**:
```yaml
commands:
  - name: experimental.md
    experimental: true
    scripts:
      - experimental.sh
      - acp.common.sh

scripts:
  - name: experimental.sh
    experimental: true
  - name: acp.common.sh
    type: utility
    experimental: false
```

**Installation**:
- Without --experimental: Command skipped, experimental.sh skipped, acp.common.sh installed if OTHER commands need it
- With --experimental: Command installed, both scripts installed

---

## Related Documents

- [`agent/tasks/task-65-script-command-binding.md`](../tasks/task-65-script-command-binding.md) - Implementation task
- [`agent/schemas/package.schema.yaml`](../schemas/package.schema.yaml) - Package schema
- [`agent/design/local.experimental-features-system.md`](local.experimental-features-system.md) - Experimental features

---

**Status**: Design Specification - Accepted Solution
**Recommendation**: Implement in Task 65
**Priority**: High (affects installation quality across all packages)
