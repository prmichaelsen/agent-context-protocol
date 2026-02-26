# Task 72: Template Installation System

**Milestone**: [M9 - Template Source Files Support](../../milestones/milestone-9-template-source-files.md)
**Estimated Time**: 6-8 hours
**Dependencies**: Task 71 (Schema Extension)
**Status**: Not Started

---

## Objective

Implement template installation logic in `acp.package-install.sh` including template scanning, selective installation flags, variable substitution, target path handling, and conflict detection.

---

## Context

This is Phase 2 of the Template Source Files Support implementation. The installation system enables users to install template files from packages to their project directories with variable substitution and safety checks.

**Design Document**: [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md)

---

## Steps

### 1. Add Template Scanning

Scan templates/ directory in cloned package:

**Actions**:
- Add template scanning after existing directory scanning
- Use `find` to locate all files in `templates/` directory
- Parse template metadata from `package.yaml`
- Build list of available templates

**Implementation**:
```bash
# In acp.package-install.sh, after existing scanning

# Scan templates directory
if [ -d "$TEMP_DIR/templates" ]; then
    echo "Scanning templates..."
    
    # Get template count from package.yaml
    TEMPLATE_COUNT=$(yaml_query ".contents.templates | length")
    
    if [ "$TEMPLATE_COUNT" -gt 0 ]; then
        echo "  Found $TEMPLATE_COUNT template(s)"
        
        # List templates if in list mode
        if [ "$LIST_ONLY" = true ]; then
            echo ""
            echo "📁 templates/ ($TEMPLATE_COUNT files)"
            for i in $(seq 0 $((TEMPLATE_COUNT - 1))); do
                name=$(yaml_query ".contents.templates[$i].name")
                desc=$(yaml_query ".contents.templates[$i].description")
                required=$(yaml_query ".contents.templates[$i].required")
                vars=$(yaml_query ".contents.templates[$i].variables[]")
                
                if [ "$required" = "true" ]; then
                    echo "  ✓ $name (required)"
                else
                    echo "  ✓ $name"
                fi
                
                if [ -n "$vars" ]; then
                    echo "    Variables: $vars"
                fi
            done
        fi
    fi
fi
```

### 2. Add Installation Flags

Add command-line flags for template control:

**Actions**:
- Add `--templates [files...]` flag for selective installation
- Add `--templates-only` flag to install only templates
- Add `--no-templates` flag to skip templates
- Update argument parsing logic

**Implementation**:
```bash
# Add to argument parsing section
INSTALL_TEMPLATES=false
TEMPLATE_FILES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --templates)
            INSTALL_TEMPLATES=true
            shift
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                TEMPLATE_FILES+=("$1")
                shift
            done
            ;;
        --templates-only)
            INSTALL_TEMPLATES=true
            INSTALL_PATTERNS=false
            INSTALL_COMMANDS=false
            INSTALL_DESIGNS=false
            shift
            ;;
        --no-templates)
            INSTALL_TEMPLATES=false
            shift
            ;;
        # ... existing cases ...
    esac
done

# Default: install templates if no selective flags
if [[ "$INSTALL_PATTERNS" == false && "$INSTALL_COMMANDS" == false && 
      "$INSTALL_DESIGNS" == false && "$INSTALL_TEMPLATES" == false ]]; then
    INSTALL_TEMPLATES=true
fi
```

### 3. Implement Variable Substitution

Collect variables and substitute in templates:

**Actions**:
- Parse variables array from package.yaml
- Prompt user for variable values
- Validate variable format (UPPER_SNAKE_CASE)
- Perform substitution using sed
- Handle missing variables gracefully

**Implementation**:
```bash
# Function to collect variables for template
collect_template_variables() {
    local template_name="$1"
    local template_index="$2"
    
    # Get variables array from package.yaml
    local vars
    vars=$(yaml_query ".contents.templates[$template_index].variables[]")
    
    if [ -z "$vars" ]; then
        return 0
    fi
    
    echo ""
    echo "${YELLOW}Template $template_name requires variables:${NC}"
    
    # Collect each variable
    declare -gA TEMPLATE_VARS
    for var in $vars; do
        read -p "  Enter $var: " value
        TEMPLATE_VARS["$var"]="$value"
    done
    
    echo "${GREEN}✓${NC} Variables collected"
}

# Function to substitute variables in template
substitute_variables() {
    local template_file="$1"
    local output_file="$2"
    
    # Copy template to output
    cp "$template_file" "$output_file"
    
    # Substitute each variable
    for var in "${!TEMPLATE_VARS[@]}"; do
        value="${TEMPLATE_VARS[$var]}"
        # Escape special characters in value
        value=$(echo "$value" | sed 's/[&/\]/\\&/g')
        # Substitute {{VARIABLE}} with value
        sed -i "s/{{$var}}/$value/g" "$output_file"
    done
}
```

### 4. Implement Target Path Handling

Install templates to specified target paths:

**Actions**:
- Parse target path from package.yaml
- Validate target path is safe (no ../, no absolute)
- Create target directories if needed
- Check for existing files (conflict detection)
- Copy template to target location

**Implementation**:
```bash
# Function to validate target path
validate_target_path() {
    local target="$1"
    
    # Check for dangerous patterns
    if [[ "$target" =~ \.\. ]] || [[ "$target" =~ ^/ ]]; then
        echo "${RED}Error: Invalid target path: $target${NC}" >&2
        echo "Target must be relative and not escape project root" >&2
        return 1
    fi
    
    return 0
}

# Function to install template
install_template() {
    local template_name="$1"
    local template_index="$2"
    local source_file="$TEMP_DIR/templates/$template_name"
    
    # Get target path
    local target
    target=$(yaml_query ".contents.templates[$template_index].target")
    
    # Validate target
    if ! validate_target_path "$target"; then
        return 1
    fi
    
    # Determine output path
    local filename
    filename=$(basename "$template_name")
    local output_path="${target}${filename}"
    
    # Remove .template extension if present
    output_path="${output_path%.template}"
    
    # Check for conflicts
    if [ -f "$output_path" ]; then
        echo "${YELLOW}⚠${NC}  File exists: $output_path"
        read -p "Overwrite? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "  Skipped"
            return 0
        fi
    fi
    
    # Create target directory
    mkdir -p "$(dirname "$output_path")"
    
    # Check if template has variables
    local has_vars
    has_vars=$(yaml_query ".contents.templates[$template_index].variables | length")
    
    if [ "$has_vars" -gt 0 ]; then
        # Collect variables and substitute
        collect_template_variables "$template_name" "$template_index"
        substitute_variables "$source_file" "$output_path"
    else
        # Direct copy
        cp "$source_file" "$output_path"
    fi
    
    echo "${GREEN}✓${NC} Installed: $output_path"
}
```

### 5. Integrate with Existing Installation Flow

Add template installation to main installation loop:

**Actions**:
- Add templates to `INSTALL_DIRS` array
- Process templates after scripts
- Apply experimental filtering
- Track installed templates for manifest

**Implementation**:
```bash
# Add to installation directories
if [ "$INSTALL_TEMPLATES" = true ]; then
    INSTALL_DIRS+=("templates")
fi

# In installation loop, add template handling
for dir in "${INSTALL_DIRS[@]}"; do
    if [ "$dir" = "templates" ]; then
        # Special handling for templates
        TEMPLATE_COUNT=$(yaml_query ".contents.templates | length")
        
        for i in $(seq 0 $((TEMPLATE_COUNT - 1))); do
            template_name=$(yaml_query ".contents.templates[$i].name")
            
            # Check if should install (experimental filtering)
            if should_install_file "templates" "$i"; then
                install_template "$template_name" "$i"
                INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
            else
                echo "${BLUE}⊘${NC} Skipped (experimental): $template_name"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            fi
        done
    else
        # Existing handling for patterns/commands/designs/scripts
        # ...
    fi
done
```

### 6. Add Safety Warnings

Warn users about template installation:

**Actions**:
- Add warning before template installation
- Explain that templates install outside agent/ directory
- Show target paths clearly
- Require confirmation for first-time template install

**Implementation**:
```bash
# Before template installation
if [ "$INSTALL_TEMPLATES" = true ] && [ "$TEMPLATE_COUNT" -gt 0 ]; then
    echo ""
    echo "${YELLOW}⚠  Template Installation Warning${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Templates will be installed to project directories (not agent/):"
    
    for i in $(seq 0 $((TEMPLATE_COUNT - 1))); do
        name=$(yaml_query ".contents.templates[$i].name")
        target=$(yaml_query ".contents.templates[$i].target")
        echo "  • $name → $target"
    done
    
    echo ""
    echo "This may overwrite existing files. Review carefully."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if [ "$SKIP_CONFIRM" != true ]; then
        read -p "Continue with template installation? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Template installation cancelled"
            INSTALL_TEMPLATES=false
        fi
    fi
fi
```

---

## Verification

- [ ] Template scanning implemented and working
- [ ] `--templates` flag enables selective installation
- [ ] `--templates-only` flag works correctly
- [ ] `--no-templates` flag skips templates
- [ ] Variable collection prompts user correctly
- [ ] Variable substitution replaces {{PLACEHOLDERS}}
- [ ] Target path validation prevents dangerous paths
- [ ] Target directories created automatically
- [ ] Conflict detection warns before overwrites
- [ ] Safety warnings displayed before installation
- [ ] Templates respect experimental flag
- [ ] Installation integrates with existing flow
- [ ] No syntax errors in modified script

---

## Expected Output

### Installation with Templates

```
📦 ACP Package Installer
========================================

Repository: https://github.com/user/acp-core-sdk.git

Cloning repository...
✓ Repository cloned

Package: core-sdk (1.0.0)
Description: Patterns for creating reusable core libraries
Commit: abc123

Scanning for installable files...
  Found 2 pattern(s)
  Found 1 command(s)
  Found 8 template(s)

⚠  Template Installation Warning
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Templates will be installed to project directories (not agent/):
  • config/tsconfig.json → ./
  • config/package.json.template → ./
  • src/schemas/example.schema.ts → src/schemas/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Continue with template installation? (y/N): y

Template config/package.json.template requires variables:
  Enter PACKAGE_NAME: @myorg/my-core
  Enter PACKAGE_DESCRIPTION: Core business logic library
  Enter AUTHOR_NAME: Patrick Michaelsen
✓ Variables collected

Installing files...
  ✓ patterns/core-library-extraction.md
  ✓ commands/core-sdk.init.md
  ✓ templates/config/tsconfig.json → ./tsconfig.json
  ✓ templates/config/package.json.template → ./package.json
  ✓ templates/src/schemas/example.schema.ts → src/schemas/example.schema.ts

✓ Installed 5 files
✓ Updated agent/manifest.yaml

Installation complete!
```

---

## Common Issues and Solutions

### Issue 1: Template file not found

**Symptom**: Error "Template not found: templates/config/file.json"
**Solution**: Verify template exists in package repository, check package.yaml declaration matches actual file path

### Issue 2: Variable substitution incomplete

**Symptom**: `{{VARIABLE}}` placeholders remain in installed file
**Solution**: Ensure all declared variables were collected, check sed substitution logic, verify variable names match exactly

### Issue 3: Permission denied creating target directory

**Symptom**: mkdir fails with permission error
**Solution**: Check user has write permissions to target location, validate target path is within project

### Issue 4: Conflict detection not working

**Symptom**: Files overwritten without warning
**Solution**: Verify conflict check runs before copy, ensure `SKIP_CONFIRM` flag respected

---

## Resources

- [`agent/scripts/acp.package-install.sh`](../../scripts/acp.package-install.sh): Installation script
- [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md): Design document
- [`agent/scripts/acp.common.sh`](../../scripts/acp.common.sh): Shared utilities

---

## Notes

- Templates install to project root, not agent/ directory
- Variable substitution uses `{{VARIABLE}}` format
- Target paths must be relative and safe
- Conflict detection critical for safety
- Experimental templates follow same filtering as commands/patterns
- Consider adding `--dry-run` flag for testing
- May want to add template preview before installation

---

**Next Task**: [Task 73: Manifest Tracking](task-73-manifest-tracking.md)
**Related Design Docs**: [Template Source Files Support](../../design/local.acp-template-source-files.md)
**Estimated Completion Date**: TBD
