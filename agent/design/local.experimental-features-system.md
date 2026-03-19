# Experimental Features System

**Concept**: System for marking and managing experimental features that require explicit opt-in via --experimental flag  
**Created**: 2026-02-23  
**Status**: Design Specification  

---

## Overview

This design document describes a system for marking commands, patterns, designs, and scripts as "experimental" to exclude them from standard installations and updates. Experimental features require explicit opt-in via the `--experimental` flag, allowing package maintainers to ship bleeding-edge features without affecting stable installations.

The system uses dual marking (package.yaml + file metadata) to ensure consistency and provide both installation control and clear documentation.

---

## Problem Statement

Currently, all features in a package are installed by default. This creates several challenges:

1. **No way to ship experimental features** - Package maintainers cannot include work-in-progress or experimental features without forcing them on all users
2. **Risk of breaking stable installations** - Experimental features might break or change frequently, affecting production users
3. **No clear documentation** - Users cannot easily identify which features are stable vs experimental
4. **All-or-nothing installation** - Users must either install everything or manually exclude files

**Consequences of not solving**:
- Package maintainers hesitate to include experimental features
- Users accidentally rely on unstable features
- No clear path for graduating features from experimental to stable
- Reduced innovation in the ACP ecosystem

---

## Solution

Implement a dual-marking system where experimental features are marked in both:

1. **package.yaml** - `experimental: true` field in contents arrays (installation control)
2. **File metadata** - `**Status**: Experimental` in file frontmatter (documentation)

**Installation behavior**:
- **Without `--experimental`**: Skip all features marked `experimental: true`
- **With `--experimental`**: Install all features including experimental ones
- **Updates**: If experimental features are already installed, update them normally (no flag required)

**Scope**: Applies to:  
- Commands (`agent/commands/*.md`)
- Patterns (`agent/patterns/*.md`)
- Designs (`agent/design/*.md`)
- Scripts (`agent/scripts/*.sh`)

**Not in scope** (for now):
- Tasks and milestones (internal development artifacts)
- Listing experimental features before installation (future enhancement)

---

## Implementation

### 1. package.yaml Schema Enhancement

Add optional `experimental` boolean field to content objects:

```yaml
contents:
  commands:
    - name: stable-command.md
      description: A stable command
      # experimental field omitted = false (default)
    
    - name: experimental-command.md
      description: An experimental command
      experimental: true  # Requires --experimental flag
  
  patterns:
    - name: stable-pattern.md
      description: A stable pattern
    
    - name: experimental-pattern.md
      description: An experimental pattern
      experimental: true
  
  designs:
    - name: stable-design.md
      description: A stable design
    
    - name: experimental-design.md
      description: An experimental design
      experimental: true
  
  scripts:
    - name: stable-script.sh
      description: A stable script
    
    - name: experimental-script.sh
      description: An experimental script
      experimental: true
```

**Default behavior**: If `experimental` field is omitted, it defaults to `false` (stable).  

### 2. File Metadata Enhancement

Add `**Status**: Experimental` to file frontmatter for experimental features:

**Command example**:
```markdown
# Command: experimental-feature

> **🤖 Agent Directive**: ...

**Namespace**: mypackage  
**Version**: 0.1.0  
**Created**: 2026-02-23  
**Last Updated**: 2026-02-23  
**Status**: Experimental  # ← Marks as experimental  

---

**Purpose**: ...  
```

**Pattern example**:
```markdown
# Pattern: Experimental Pattern

**Status**: Experimental  # ← Marks as experimental  
**Created**: 2026-02-23  

---

## Overview
...
```

**Design example**:
```markdown
# Experimental Design

**Concept**: ...  
**Created**: 2026-02-23  
**Status**: Experimental  # ← Marks as experimental (replaces Proposal/Design Specification/Implemented)  

---
```

### 3. Installation Script Changes

Modify `agent/scripts/acp.package-install.sh`:

```bash
# Add --experimental flag parsing
INSTALL_EXPERIMENTAL=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --experimental)
      INSTALL_EXPERIMENTAL=true
      shift
      ;;
    # ... other flags
  esac
done

# Filter function for experimental features
should_install_file() {
  local file_name="$1"
  local file_type="$2"  # commands, patterns, designs, scripts
  
  # Check if file is marked experimental in package.yaml
  local is_experimental=$(yaml_get "contents.${file_type}[?name=='${file_name}'].experimental")
  
  if [[ "$is_experimental" == "true" ]]; then
    if [[ "$INSTALL_EXPERIMENTAL" == "true" ]]; then
      return 0  # Install it
    else
      echo "  ⊘ Skipping experimental: ${file_name}"
      return 1  # Skip it
    fi
  fi
  
  return 0  # Install non-experimental files
}

# Use filter when installing files
for cmd in "${commands[@]}"; do
  if should_install_file "$cmd" "commands"; then
    # Install the command
    cp "${CLONE_DIR}/agent/commands/${cmd}" "${INSTALL_DIR}/commands/"
    # ... rest of installation logic
  fi
done
```

### 4. Update Script Changes

Modify `agent/scripts/acp.package-update.sh`:

```bash
# Check if experimental feature is already installed
is_experimental_installed() {
  local file_name="$1"
  local file_type="$2"
  
  # Check manifest to see if this file is already installed
  local installed=$(yaml_get "packages.${PACKAGE_NAME}.files.${file_type}[?name=='${file_name}'].name")
  
  if [[ -n "$installed" ]]; then
    return 0  # Already installed, update it
  fi
  
  return 1  # Not installed
}

# Update logic
for cmd in "${commands[@]}"; do
  local is_experimental=$(yaml_get "contents.commands[?name=='${cmd}'].experimental")
  
  if [[ "$is_experimental" == "true" ]]; then
    if is_experimental_installed "$cmd" "commands"; then
      # Already installed, update it (no --experimental flag required)
      echo "  ↻ Updating experimental: ${cmd}"
      # ... update logic
    else
      # Not installed, skip it (would need --experimental on install)
      echo "  ⊘ Skipping new experimental: ${cmd} (use --experimental to install)"
      continue
    fi
  else
    # Regular update for non-experimental
    # ... update logic
  fi
done
```

### 5. Validation Script Changes

Modify `agent/scripts/acp.package-validate.sh`:

```bash
# Add consistency check for experimental marking
validate_experimental_consistency() {
  echo "Validating experimental feature consistency..."
  
  local errors=0
  
  # Check each content type
  for type in commands patterns designs scripts; do
    local count=$(yaml_get "contents.${type} | length")
    
    for ((i=0; i<count; i++)); do
      local file_name=$(yaml_get "contents.${type}[$i].name")
      local is_experimental=$(yaml_get "contents.${type}[$i].experimental")
      
      if [[ "$is_experimental" == "true" ]]; then
        # Check if file has Status: Experimental in metadata
        local file_path="agent/${type}/${file_name}"
        
        if [[ ! -f "$file_path" ]]; then
          continue  # File existence checked elsewhere
        fi
        
        if ! grep -q "^\*\*Status\*\*: Experimental" "$file_path"; then
          echo "  ❌ ${file_path}: Marked experimental in package.yaml but missing 'Status: Experimental' in file"
          ((errors++))
        fi
      else
        # Check if file has Status: Experimental but not marked in package.yaml
        local file_path="agent/${type}/${file_name}"
        
        if [[ -f "$file_path" ]] && grep -q "^\*\*Status\*\*: Experimental" "$file_path"; then
          echo "  ❌ ${file_path}: Has 'Status: Experimental' but not marked in package.yaml"
          ((errors++))
        fi
      fi
    done
  done
  
  if [[ $errors -eq 0 ]]; then
    echo "  ✓ Experimental marking is consistent"
  fi
  
  return $errors
}

# Add to main validation flow
validate_experimental_consistency
```

### 6. Schema Update

Update `agent/schemas/package.schema.yaml`:

```yaml
contents:
  type: object
  properties:
    commands:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
            pattern: "^[a-z0-9-]+\\.md$"
          description:
            type: string
          experimental:
            type: boolean
            default: false  # Optional field, defaults to false
        required: [name, description]
    
    patterns:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
            pattern: "^[a-z0-9-]+\\.md$"
          description:
            type: string
          experimental:
            type: boolean
            default: false
        required: [name, description]
    
    # ... similar for designs and scripts
```

---

## Benefits

1. **Safe experimentation** - Package maintainers can ship experimental features without affecting stable users
2. **Clear documentation** - Users can easily identify experimental features via Status field
3. **Gradual rollout** - Features can be tested by early adopters before becoming stable
4. **Backward compatible** - Existing packages work without changes (experimental defaults to false)
5. **Consistent marking** - Validation ensures package.yaml and file metadata stay in sync
6. **Flexible updates** - Once installed, experimental features update normally (no repeated flag)
7. **Ecosystem innovation** - Encourages package maintainers to experiment and iterate

---

## Trade-offs

1. **Additional complexity** - Package maintainers must mark features in two places (mitigated by validation)
2. **Discovery challenge** - Users may not know experimental features exist (future enhancement: --list-experimental)
3. **Graduation process** - No automated way to graduate features from experimental to stable (manual process)
4. **Documentation burden** - Maintainers must document experimental status and risks
5. **Testing complexity** - Must test both with and without --experimental flag

**Mitigation strategies**:
- Validation ensures consistency between package.yaml and file metadata
- Clear documentation in AGENT.md about experimental features
- Future enhancement: `--list-experimental` flag to discover available features
- Template updates to include experimental field examples

---

## Dependencies

- **package.yaml schema** - Must support optional `experimental` boolean field
- **acp.package-install.sh** - Must implement --experimental flag and filtering
- **acp.package-update.sh** - Must handle experimental features correctly
- **acp.package-validate.sh** - Must validate experimental marking consistency
- **YAML parser** - Must support querying experimental field (already supported)

---

## Testing Strategy

### Unit Tests

1. **Installation filtering**:
   - Install without --experimental → experimental features skipped
   - Install with --experimental → experimental features included
   - Verify manifest tracks experimental status

2. **Update behavior**:
   - Update with experimental already installed → updates normally
   - Update with new experimental feature → skips unless --experimental
   - Verify no flag required for updating already-installed experimental features

3. **Validation**:
   - package.yaml has experimental: true, file missing Status: Experimental → error
   - File has Status: Experimental, package.yaml missing experimental: true → error
   - Both marked consistently → pass

### Integration Tests

1. Create test package with mix of stable and experimental features
2. Install without --experimental, verify only stable features installed
3. Install with --experimental, verify all features installed
4. Update package, verify experimental features update correctly
5. Run validation, verify consistency checks work

### Edge Cases

1. Experimental feature with no Status field in file
2. Status: Experimental in file but experimental: false in package.yaml
3. Upgrading from old package format (no experimental field)
4. Removing experimental flag (graduating to stable)

---

## Migration Path

### For Package Maintainers

1. **Add experimental field to package.yaml** for any experimental features
2. **Add Status: Experimental** to file metadata for those features
3. **Run validation** to ensure consistency
4. **Document** which features are experimental in README.md
5. **Test** installation with and without --experimental flag

### For ACP Core

1. **Update schemas** - Add experimental field to package.schema.yaml
2. **Update install script** - Implement --experimental flag and filtering
3. **Update update script** - Handle experimental features correctly
4. **Update validate script** - Add consistency checks
5. **Update documentation** - Document experimental features in AGENT.md and README.md
6. **Update templates** - Add experimental field examples to package.template.yaml

### Backward Compatibility

- Existing packages without `experimental` field work unchanged (defaults to false)
- No breaking changes to existing functionality
- Opt-in system - packages choose when to use experimental marking

---

## Future Considerations

1. **Discovery enhancement** - Add `--list-experimental` flag to show available experimental features before installing
2. **Graduation workflow** - Create `@acp.package-graduate` command to move features from experimental to stable
3. **Deprecation system** - Similar system for marking features as deprecated
4. **Version-based experimental** - Mark features as experimental until specific version (e.g., experimental until v2.0.0)
5. **Experimental warnings** - Show warnings when using experimental features in production
6. **Analytics** - Track usage of experimental features to inform graduation decisions
7. **Auto-graduation** - Automatically graduate features after X months of stability

---

**Status**: Design Specification  
**Recommendation**: Implement in phases:  
1. Phase 1: Schema and validation (Task 1)
2. Phase 2: Installation filtering (Task 2)
3. Phase 3: Update handling (Task 3)
4. Phase 4: Documentation and examples (Task 4)

**Related Documents**:
- [`agent/schemas/package.schema.yaml`](../schemas/package.schema.yaml) - Package schema definition
- [`agent/scripts/acp.package-install.sh`](../scripts/acp.package-install.sh) - Installation script
- [`agent/scripts/acp.package-update.sh`](../scripts/acp.package-update.sh) - Update script
- [`agent/scripts/acp.package-validate.sh`](../scripts/acp.package-validate.sh) - Validation script
