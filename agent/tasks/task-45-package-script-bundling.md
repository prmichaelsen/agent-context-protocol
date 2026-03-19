# Task 45: Package Script Bundling Support

**Milestone**: [M5 - Global Package Installation](../milestones/milestone-5-global-package-installation.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 26 (Global Installation), Task 27 (Global Commands)  
**Status**: Not Started  

---

## Objective

Enable ACP packages to bundle and distribute scripts in their contents, with proper namespace enforcement and installation/update support.

---

## Context

Currently, packages can bundle commands, patterns, and designs, but not scripts. Some packages may want to provide utility scripts that can be used by commands or directly by users. This task adds script bundling support to the package system.

Scripts must be properly namespaced (e.g., `firebase.deploy.sh`, `git.hooks.sh`) to prevent conflicts between packages.

---

## Steps

### 1. Update Package Schema

Add scripts to `agent/schemas/package.schema.yaml`:

```yaml
contents:
  scripts:
    description: "Shell scripts provided by this package"
    type: array
    required: false
    items:
      type: object
      properties:
        name:
          type: string
          pattern: "^[a-z0-9-]+\\.[a-z0-9-]+\\.sh$"
          description: "Script filename with namespace (e.g., 'firebase.deploy.sh')"
        version:
          type: string
          pattern: "^[0-9]+\\.[0-9]+\\.[0-9]+$"
        description:
          type: string
```

### 2. Update Package Install Script

Modify `agent/scripts/acp.package-install.sh` to copy scripts:

```bash
# After copying commands, patterns, designs
# Copy scripts if present

if [ -d "$CLONE_DIR/agent/scripts" ]; then
    info "Installing scripts..."
    
    # Get scripts from package.yaml
    local scripts_count=0
    while IFS= read -r script_name; do
        if [ -n "$script_name" ] && [ -f "$CLONE_DIR/agent/scripts/$script_name" ]; then
            # Validate namespace
            local script_namespace=$(echo "$script_name" | cut -d'.' -f1)
            if [ "$script_namespace" != "$PACKAGE_NAME" ]; then
                warn "Script $script_name doesn't match package namespace $PACKAGE_NAME"
            fi
            
            # Copy script
            cp "$CLONE_DIR/agent/scripts/$script_name" "./agent/scripts/"
            chmod +x "./agent/scripts/$script_name"
            
            # Add to manifest
            add_file_to_manifest "$PACKAGE_NAME" "scripts" "$script_name" "$file_version"
            
            scripts_count=$((scripts_count + 1))
        fi
    done < <(yaml_get_array "$CLONE_DIR/package.yaml" "contents.scripts" | while read -r idx; do
        yaml_get_nested "$CLONE_DIR/package.yaml" "contents.scripts[$idx].name"
    done)
    
    if [ $scripts_count -gt 0 ]; then
        success "Installed $scripts_count script(s)"
    fi
fi
```

### 3. Update Package Update Script

Modify `agent/scripts/acp.package-update.sh` to handle scripts:

```bash
# Add scripts to file types to update
for script_file in $scripts_files; do
    local script_path="./agent/scripts/$script_file"
    
    if [ -f "$script_path" ]; then
        # Check if modified
        if is_file_modified "$PACKAGE_NAME" "scripts" "$script_file"; then
            if [ "$SKIP_MODIFIED" = true ]; then
                warn "Skipping modified script: $script_file"
                continue
            elif [ "$FORCE_UPDATE" != true ]; then
                warn "Script modified: $script_file"
                # Prompt for action
            fi
        fi
        
        # Update script
        cp "$temp_dir/agent/scripts/$script_file" "$script_path"
        chmod +x "$script_path"
        update_file_in_manifest "$PACKAGE_NAME" "scripts" "$script_file" "$new_version"
    fi
done
```

### 4. Update Package Validate Script

Modify `agent/scripts/acp.package-validate.sh` to validate scripts:

```bash
# Validate scripts section
info "Validating scripts..."

local scripts_count=0
while IFS= read -r script_name; do
    if [ -n "$script_name" ]; then
        scripts_count=$((scripts_count + 1))
        
        # Check file exists
        if [ ! -f "./agent/scripts/$script_name" ]; then
            error "Script file not found: $script_name"
            ERRORS=$((ERRORS + 1))
        fi
        
        # Check namespace
        local script_namespace=$(echo "$script_name" | cut -d'.' -f1)
        if [ "$script_namespace" != "$package_name" ]; then
            error "Script $script_name doesn't match package namespace $package_name"
            ERRORS=$((ERRORS + 1))
        fi
        
        # Check executable
        if [ -f "./agent/scripts/$script_name" ] && [ ! -x "./agent/scripts/$script_name" ]; then
            warn "Script not executable: $script_name"
            WARNINGS=$((WARNINGS + 1))
        fi
        
        # Check shebang
        if [ -f "./agent/scripts/$script_name" ]; then
            local first_line=$(head -n1 "./agent/scripts/$script_name")
            if [[ ! "$first_line" =~ ^#!/ ]]; then
                warn "Script missing shebang: $script_name"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    fi
done < <(yaml_get_array "./package.yaml" "contents.scripts" | while read -r idx; do
    yaml_get_nested "./package.yaml" "contents.scripts[$idx].name"
done)

if [ $scripts_count -gt 0 ]; then
    success "Validated $scripts_count script(s)"
fi
```

### 5. Update Package List/Info Commands

Add scripts to output:

```bash
# In acp.package-list.sh and acp.package-info.sh
scripts_count=$(awk -v pkg="$package" '
    BEGIN { in_pkg=0; in_scripts=0; count=0 }
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^      scripts:/ { in_scripts=1; next }
    in_scripts && /^      [a-z]/ { in_scripts=0 }
    in_scripts && /^        - name:/ { count++ }
    END { print count }
' "$MANIFEST_FILE")

# Display: "2 commands, 3 patterns, 1 script"
```

### 6. Update Documentation

Update command documentation to mention script support:
- `@acp.package-install` - Scripts are copied and made executable
- `@acp.package-validate` - Scripts are validated for namespace and executability
- `@acp.package-create` - Can include scripts in package

### 7. Test Script Bundling

Create test package with scripts and verify:
- Scripts are copied correctly
- Scripts are executable
- Scripts are namespaced correctly
- Scripts appear in package-list output
- Scripts are validated

---

## Verification

- [ ] Package schema updated with scripts field
- [ ] `@acp.package-install` copies scripts
- [ ] Scripts are made executable (`chmod +x`)
- [ ] `@acp.package-update` updates scripts
- [ ] `@acp.package-validate` validates scripts
- [ ] Scripts validated for namespace consistency
- [ ] Scripts validated for shebang
- [ ] Scripts validated for executability
- [ ] `@acp.package-list` shows script count
- [ ] `@acp.package-info` lists scripts
- [ ] Test package with scripts works correctly
- [ ] Documentation updated

---

## Expected Output

### Package with Scripts

```yaml
# package.yaml
contents:
  scripts:
    - name: firebase.deploy.sh
      version: 1.0.0
      description: Deploy Firebase functions and rules
    - name: firebase.emulator.sh
      version: 1.0.0
      description: Start Firebase emulators
```

### Installation Output

```
Installing package: firebase

✓ Copied 2 commands
✓ Copied 3 patterns
✓ Installed 2 script(s)
  - firebase.deploy.sh (executable)
  - firebase.emulator.sh (executable)

Package installed successfully!
```

---

## Common Issues and Solutions

### Issue 1: Script not executable after install
**Symptom**: Script exists but can't be executed  
**Solution**: Ensure `chmod +x` is called after copying script  

### Issue 2: Namespace mismatch
**Symptom**: Validation fails for script namespace  
**Solution**: Rename script to match package namespace (e.g., `firebase.deploy.sh`)  

### Issue 3: Missing shebang
**Symptom**: Warning about missing shebang  
**Solution**: Add `#!/bin/bash` or `#!/usr/bin/env bash` to top of script  

---

## Resources

- [Package Schema](../schemas/package.schema.yaml) - Schema to update
- [Package Install Script](../scripts/acp.package-install.sh) - Installation logic
- [Package Validate Script](../scripts/acp.package-validate.sh) - Validation logic

---

## Notes

- Scripts must be namespaced (package-name.script-name.sh)
- Scripts are made executable automatically
- Scripts should have proper shebang
- Scripts can be sourced or executed directly
- Consider security implications of bundled scripts

---

**Next Task**: None (enhancement to existing milestone)  
**Related Design Docs**: [Package Management System](../design/acp-package-management-system.md)  
**Estimated Completion Date**: TBD  
