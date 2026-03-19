# Task 73: Manifest Tracking for Templates

**Milestone**: [M9 - Template Source Files Support](../../milestones/milestone-9-template-source-files.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 72 (Installation System)  
**Status**: Not Started  

---

## Objective

Extend `agent/manifest.yaml` structure and `acp.common.sh` functions to track installed templates with versions, target paths, checksums, and variable values.

---

## Context

This is Phase 3 of the Template Source Files Support implementation. Manifest tracking enables version control, modification detection, and smart updates for installed templates.

**Design Document**: [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md)  

---

## Steps

### 1. Extend Manifest Structure

Update manifest template to include templates section:

**Actions**:
- Open `agent/manifest.template.yaml`
- Add templates array to installed section
- Define template metadata fields
- Add examples

**Structure**:
```yaml
packages:
  example-package:
    source: https://github.com/user/example.git
    package_version: 1.0.0
    installed:
      patterns: [...]
      commands: [...]
      designs: [...]
      scripts: [...]
      templates:  # NEW
        - name: config/tsconfig.json
          version: 1.0.0
          installed_at: 2026-02-26T10:00:00Z
          target: ./tsconfig.json
          modified: false
          checksum: sha256:abc123...
          variables: {}  # Empty if no variables
        
        - name: config/package.json.template
          version: 1.0.0
          installed_at: 2026-02-26T10:00:00Z
          target: ./package.json
          modified: false
          checksum: sha256:def456...
          variables:
            PACKAGE_NAME: "@myorg/my-core"
            AUTHOR_NAME: "Patrick Michaelsen"
```

### 2. Add Template Manifest Functions

Add functions to `acp.common.sh` for template tracking:

**Actions**:
- Add `add_template_to_manifest()` function
- Add `get_template_version()` function
- Add `is_template_modified()` function
- Add `update_template_in_manifest()` function

**Implementation**:
```bash
# Add template to manifest
# Usage: add_template_to_manifest "package-name" "template-name" "version" "target" "checksum" "variables-json"
add_template_to_manifest() {
    local package_name="$1"
    local template_name="$2"
    local version="$3"
    local target="$4"
    local checksum="$5"
    local variables_json="${6:-{}}"
    local timestamp
    timestamp=$(get_timestamp)
    
    # Build template entry
    local entry="
        - name: $template_name
          version: $version
          installed_at: $timestamp
          target: $target
          modified: false
          checksum: $checksum
          variables: $variables_json"
    
    # Append to manifest (implementation depends on yaml_write capabilities)
    # For now, use sed-based approach similar to other manifest functions
}

# Get template version from manifest
# Usage: version=$(get_template_version "package-name" "template-name")
get_template_version() {
    local package_name="$1"
    local template_name="$2"
    
    yaml_query ".packages.${package_name}.installed.templates[] | select(.name == \"$template_name\") | .version"
}

# Check if template modified
# Usage: if is_template_modified "package-name" "template-name" "target-path"; then ...
is_template_modified() {
    local package_name="$1"
    local template_name="$2"
    local target_path="$3"
    
    # Get stored checksum
    local stored_checksum
    stored_checksum=$(yaml_query ".packages.${package_name}.installed.templates[] | select(.name == \"$template_name\") | .checksum")
    
    # Calculate current checksum
    local current_checksum
    current_checksum=$(calculate_checksum "$target_path")
    
    # Compare
    [ "$stored_checksum" != "$current_checksum" ]
}

# Update template in manifest
# Usage: update_template_in_manifest "package-name" "template-name" "new-version" "new-checksum"
update_template_in_manifest() {
    local package_name="$1"
    local template_name="$2"
    local new_version="$3"
    local new_checksum="$4"
    local timestamp
    timestamp=$(get_timestamp)
    
    # Update version, checksum, and timestamp
    # Implementation depends on yaml_set capabilities
}
```

### 3. Integrate with Installation Script

Call manifest functions during template installation:

**Actions**:
- Update `install_template()` to call `add_template_to_manifest()`
- Pass all required metadata
- Handle variable values correctly
- Update manifest after all templates installed

**Implementation**:
```bash
# In install_template() function, after successful copy
local checksum
checksum=$(calculate_checksum "$output_path")

# Build variables JSON
local vars_json="{}"
if [ ${#TEMPLATE_VARS[@]} -gt 0 ]; then
    vars_json="{"
    for var in "${!TEMPLATE_VARS[@]}"; do
        value="${TEMPLATE_VARS[$var]}"
        vars_json+="\"$var\": \"$value\", "
    done
    vars_json="${vars_json%, }}"  # Remove trailing comma
fi

# Add to manifest
add_template_to_manifest "$PACKAGE_NAME" "$template_name" "$version" "$output_path" "$checksum" "$vars_json"
```

### 4. Update Batch Operations

Integrate templates into optimized batch operations:

**Actions**:
- Add templates to batch checksum calculation
- Add templates to batch manifest updates
- Ensure templates tracked in `FILE_METADATA` array
- Update `INSTALLED_COUNT` correctly

**Implementation**:
```bash
# In batch operations section
if [ "$INSTALL_TEMPLATES" = true ]; then
    # Collect template files for batch processing
    for i in $(seq 0 $((TEMPLATE_COUNT - 1))); do
        template_name=$(yaml_query ".contents.templates[$i].name")
        target=$(yaml_query ".contents.templates[$i].target")
        
        if should_install_file "templates" "$i"; then
            # Add to batch arrays
            ALL_FILES_TO_INSTALL["templates"]+="$template_name "
            FILE_METADATA["templates/$template_name"]="$version|$experimental|$target"
        fi
    done
fi
```

### 5. Test Manifest Tracking

Verify templates tracked correctly:

**Actions**:
- Install package with templates
- Check manifest.yaml contains templates section
- Verify all metadata fields present
- Test modification detection
- Test version tracking

```bash
# Test manifest tracking
./agent/scripts/acp.package-install.sh --repo /path/to/test-package

# Check manifest
cat agent/manifest.yaml | grep -A 10 "templates:"

# Modify template and check detection
echo "// modified" >> ./tsconfig.json
# Should detect as modified
```

---

## Verification

- [ ] Manifest template structure defined
- [ ] `add_template_to_manifest()` function implemented
- [ ] `get_template_version()` function implemented
- [ ] `is_template_modified()` function implemented
- [ ] `update_template_in_manifest()` function implemented
- [ ] Functions integrated into installation script
- [ ] Templates tracked with all metadata (name, version, target, checksum, variables)
- [ ] Variable values stored in manifest
- [ ] Batch operations include templates
- [ ] Modification detection works correctly
- [ ] No syntax errors in modified scripts

---

## Expected Output

### Manifest with Templates

```yaml
packages:
  core-sdk:
    source: https://github.com/user/acp-core-sdk.git
    package_version: 1.0.0
    commit: abc123def
    installed_at: 2026-02-26T10:00:00Z
    updated_at: 2026-02-26T10:00:00Z
    
    installed:
      patterns:
        - name: core-library-extraction.md
          version: 1.0.0
          # ...
      
      commands:
        - name: core-sdk.init.md
          version: 1.0.0
          # ...
      
      templates:
        - name: config/tsconfig.json
          version: 1.0.0
          installed_at: 2026-02-26T10:00:00Z
          target: ./tsconfig.json
          modified: false
          checksum: sha256:abc123...
          variables: {}
        
        - name: config/package.json.template
          version: 1.0.0
          installed_at: 2026-02-26T10:00:00Z
          target: ./package.json
          modified: false
          checksum: sha256:def456...
          variables:
            PACKAGE_NAME: "@myorg/my-core"
            PACKAGE_DESCRIPTION: "Core business logic"
            AUTHOR_NAME: "Patrick Michaelsen"
```

---

## Common Issues and Solutions

### Issue 1: Variables JSON malformed

**Symptom**: Manifest contains invalid JSON in variables field  
**Solution**: Properly escape quotes and special characters, validate JSON before writing  

### Issue 2: Checksum mismatch after substitution

**Symptom**: Stored checksum doesn't match file after variable substitution  
**Solution**: Calculate checksum AFTER substitution, not before  

### Issue 3: Target path not stored correctly

**Symptom**: Manifest shows wrong target path  
**Solution**: Store actual installed path (after .template removal), not source path  

---

## Resources

- [`agent/manifest.template.yaml`](../../manifest.template.yaml): Manifest structure
- [`agent/scripts/acp.common.sh`](../../scripts/acp.common.sh): Shared utilities
- [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md): Design document

---

## Notes

- Variable values stored for reproducibility and updates
- Checksums calculated after variable substitution
- Target paths stored as installed (not source paths)
- Modification detection works same as patterns/commands
- Consider adding template-specific metadata (original_name if .template removed)

---

**Next Task**: [Task 74: Command Updates](task-74-command-updates.md)  
**Related Design Docs**: [Template Source Files Support](../../design/local.acp-template-source-files.md)  
**Estimated Completion Date**: TBD  
