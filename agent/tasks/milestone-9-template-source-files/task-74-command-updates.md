# Task 74: Command Updates for Templates

**Milestone**: [M9 - Template Source Files Support](../../milestones/milestone-9-template-source-files.md)
**Estimated Time**: 4-5 hours
**Dependencies**: Task 73 (Manifest Tracking)
**Status**: Not Started

---

## Objective

Update all package management commands to support templates: `@acp.package-install`, `@acp.package-update`, `@acp.package-remove`, `@acp.package-validate`, and `@acp.package-list`.

---

## Context

This is Phase 4 of the Template Source Files Support implementation. Command updates ensure templates are fully integrated into the package management workflow with consistent behavior across all operations.

**Design Document**: [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md)

---

## Steps

### 1. Update @acp.package-install Documentation

Add templates section to installation command:

**Actions**:
- Open `agent/commands/acp.package-install.md`
- Add `--templates` flag documentation
- Add `--templates-only` and `--no-templates` flags
- Add variable substitution examples
- Add safety warnings for template installation

**Documentation Additions**:
```markdown
## Installation Modes

### Mode 5: Template Installation

Install template source files (code, configs, etc.):

```bash
# Install all templates
@acp.package-install --repo <url>

# Install only templates
@acp.package-install --templates-only --repo <url>

# Install specific templates
@acp.package-install --templates config/tsconfig.json src/schemas/example.schema.ts --repo <url>

# Skip templates
@acp.package-install --no-templates --repo <url>
```

### Variable Substitution

Templates with variables prompt for values:

```
Template config/package.json.template requires variables:
  Enter PACKAGE_NAME: @myorg/my-core
  Enter PACKAGE_DESCRIPTION: Core library
  Enter AUTHOR_NAME: Your Name
```

### Safety Warnings

⚠️ Templates install to project directories (not agent/):
- May overwrite existing files
- Always prompted before installation
- Conflict detection shows diffs
- Use --list to preview before installing
```

### 2. Update @acp.package-update Script

Add template update logic with conflict detection:

**Actions**:
- Open `agent/scripts/acp.package-update.sh`
- Add template update loop after scripts
- Check for template modifications
- Handle variable changes
- Prompt for conflicts

**Implementation**:
```bash
# In update loop, add template handling
if [ -n "$REMOTE_TEMPLATES" ]; then
    echo ""
    echo "Checking templates..."
    
    for template in $REMOTE_TEMPLATES; do
        local_version=$(get_template_version "$PACKAGE_NAME" "$template")
        remote_version=$(yaml_query ".contents.templates[] | select(.name == \"$template\") | .version")
        
        # Get target path from manifest
        target_path=$(yaml_query ".packages.${PACKAGE_NAME}.installed.templates[] | select(.name == \"$template\") | .target")
        
        # Check if modified
        if is_template_modified "$PACKAGE_NAME" "$template" "$target_path"; then
            echo "${YELLOW}⚠${NC}  $template (modified locally)"
            
            if [ "$SKIP_MODIFIED" = true ]; then
                echo "  Skipped (--skip-modified)"
                continue
            fi
            
            if [ "$FORCE_UPDATE" != true ]; then
                read -p "  Overwrite local changes? (y/N): " confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    echo "  Skipped"
                    continue
                fi
            fi
        fi
        
        # Check version
        if [ "$remote_version" != "$local_version" ]; then
            echo "${GREEN}↑${NC} Updating $template ($local_version → $remote_version)"
            
            # Re-collect variables if template has them
            local has_vars
            has_vars=$(yaml_query ".contents.templates[] | select(.name == \"$template\") | .variables | length")
            
            if [ "$has_vars" -gt 0 ]; then
                # Get stored variables from manifest
                stored_vars=$(yaml_query ".packages.${PACKAGE_NAME}.installed.templates[] | select(.name == \"$template\") | .variables")
                
                echo "  Template has variables. Use stored values? (Y/n): "
                read use_stored
                
                if [[ "$use_stored" =~ ^[Nn]$ ]]; then
                    collect_template_variables "$template" "$i"
                else
                    # Use stored variables
                    TEMPLATE_VARS=()  # Load from stored_vars
                fi
            fi
            
            # Install updated template
            install_template "$template" "$i"
            update_template_in_manifest "$PACKAGE_NAME" "$template" "$remote_version" "$new_checksum"
        fi
    done
fi
```

### 3. Update @acp.package-remove Script

Add template removal logic:

**Actions**:
- Open `agent/scripts/acp.package-remove.sh`
- Add template removal after scripts
- Remove files from target locations
- Update manifest

**Implementation**:
```bash
# Remove templates
if [ -n "$TEMPLATES" ]; then
    echo ""
    echo "Removing templates..."
    
    for template in $TEMPLATES; do
        # Get target path from manifest
        target_path=$(yaml_query ".packages.${PACKAGE_NAME}.installed.templates[] | select(.name == \"$template\") | .target")
        
        if [ -f "$target_path" ]; then
            # Check if modified
            if is_template_modified "$PACKAGE_NAME" "$template" "$target_path"; then
                if [ "$KEEP_MODIFIED" = true ]; then
                    echo "${YELLOW}⊘${NC} Kept (modified): $target_path"
                    continue
                fi
            fi
            
            rm "$target_path"
            echo "${GREEN}✓${NC} Removed: $target_path"
        fi
    done
fi
```

### 4. Update @acp.package-validate Script

Add template validation:

**Actions**:
- Open `agent/scripts/acp.package-validate.sh`
- Add template file existence checking
- Validate target paths are safe
- Check variable declarations
- Verify experimental consistency

**Implementation**:
```bash
# Validate templates section
echo ""
echo "Validating templates..."

TEMPLATE_COUNT=$(yaml_query ".contents.templates | length")

if [ "$TEMPLATE_COUNT" -gt 0 ]; then
    for i in $(seq 0 $((TEMPLATE_COUNT - 1))); do
        name=$(yaml_query ".contents.templates[$i].name")
        target=$(yaml_query ".contents.templates[$i].target")
        
        # Check file exists
        if [ ! -f "templates/$name" ]; then
            error "Template not found: templates/$name"
        fi
        
        # Validate target path
        if [[ "$target" =~ \.\. ]] || [[ "$target" =~ ^/ ]]; then
            error "Invalid target path: $target (must be relative, no ../)"
        fi
        
        # Check experimental consistency
        exp_yaml=$(yaml_query ".contents.templates[$i].experimental")
        exp_file=$(grep "^\*\*Status\*\*: Experimental" "templates/$name")
        
        if [ "$exp_yaml" = "true" ] && [ -z "$exp_file" ]; then
            error "Template $name marked experimental in package.yaml but not in file"
        fi
    done
    
    echo "${GREEN}✓${NC} All $TEMPLATE_COUNT templates valid"
fi
```

### 5. Update @acp.package-list Command

Show templates in package listings:

**Actions**:
- Open `agent/scripts/acp.package-list.sh`
- Add template count to summary
- Show templates in verbose mode
- Mark modified templates

**Implementation**:
```bash
# In package listing, add template count
TEMPLATE_COUNT=$(yaml_query ".packages.${package}.installed.templates | length")
total_files=$((PATTERN_COUNT + COMMAND_COUNT + DESIGN_COUNT + SCRIPT_COUNT + TEMPLATE_COUNT))

echo "  $package ($version) - $total_files files"

# In verbose mode, show templates
if [ "$VERBOSE" = true ]; then
    if [ "$TEMPLATE_COUNT" -gt 0 ]; then
        echo "    Templates ($TEMPLATE_COUNT):"
        for i in $(seq 0 $((TEMPLATE_COUNT - 1))); do
            name=$(yaml_query ".packages.${package}.installed.templates[$i].name")
            target=$(yaml_query ".packages.${package}.installed.templates[$i].target")
            modified=$(yaml_query ".packages.${package}.installed.templates[$i].modified")
            
            if [ "$modified" = "true" ]; then
                echo "      - $name → $target ${YELLOW}[MODIFIED]${NC}"
            else
                echo "      - $name → $target"
            fi
        done
    fi
fi
```

### 6. Update Command Documentation

Update all command documentation files:

**Actions**:
- Update `agent/commands/acp.package-update.md` with template update behavior
- Update `agent/commands/acp.package-remove.md` with template removal
- Update `agent/commands/acp.package-validate.md` with template validation
- Update `agent/commands/acp.package-list.md` with template display
- Add examples for each command

---

## Verification

- [ ] `@acp.package-install` documentation updated with templates
- [ ] `@acp.package-update` script handles template updates
- [ ] `@acp.package-remove` script removes templates
- [ ] `@acp.package-validate` script validates templates
- [ ] `@acp.package-list` script shows templates
- [ ] All command documentation updated
- [ ] Variable substitution documented
- [ ] Safety warnings documented
- [ ] Examples provided for each command
- [ ] No syntax errors in modified scripts

---

## Expected Output

### Updated Commands

All 5 package commands now support templates:
- ✅ `@acp.package-install` - Install templates with variables
- ✅ `@acp.package-update` - Update templates with conflict detection
- ✅ `@acp.package-remove` - Remove templates from target paths
- ✅ `@acp.package-validate` - Validate template declarations
- ✅ `@acp.package-list` - Show installed templates

### Command Examples

```bash
# Install with templates
@acp.package-install --repo https://github.com/user/acp-core-sdk.git

# Update templates
@acp.package-update core-sdk

# List with templates
@acp.package-list --verbose

# Validate templates
@acp.package-validate

# Remove with templates
@acp.package-remove core-sdk
```

---

## Common Issues and Solutions

### Issue 1: Template updates overwrite customizations

**Symptom**: User's template modifications lost during update
**Solution**: Modification detection warns before overwriting, use `--skip-modified` to preserve changes

### Issue 2: Variable values lost during update

**Symptom**: Template re-prompts for variables on update
**Solution**: Stored variables in manifest, offer to reuse stored values

### Issue 3: Template validation too strict

**Symptom**: Valid templates fail validation
**Solution**: Review validation rules, ensure patterns allow common file types and paths

---

## Resources

- [`agent/commands/acp.package-install.md`](../../commands/acp.package-install.md): Install command
- [`agent/scripts/acp.package-update.sh`](../../scripts/acp.package-update.sh): Update script
- [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md): Design document

---

## Notes

- Templates follow same patterns as patterns/commands/designs
- Conflict detection critical for templates (install outside agent/)
- Variable reuse improves UX for updates
- Consider adding `--resubstitute` flag to force variable re-collection
- May want template diff preview before updates

---

**Next Task**: [Task 75: Testing Suite](task-75-testing-suite.md)
**Related Design Docs**: [Template Source Files Support](../../design/local.acp-template-source-files.md)
**Estimated Completion Date**: TBD
