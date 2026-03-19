# Task 41: Package Preference Support

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)  
**Estimated Time**: 4-5 hours  
**Dependencies**: Task 37 (Preference Loading), Task 40 (Management Commands)  
**Status**: Not Started  

---

## Objective

Enable ACP packages to define their own configurables and provide preset configurations, integrating preference support into the package installation and creation workflows.

---

## Context

Third-party packages need a standard way to expose configuration options. By supporting package-specific configurables and preferences, we enable:
- Package authors to define configurable behaviors
- Users to customize package behavior without modifying code
- Preset configurations for common use cases
- Consistent configuration experience across all packages

---

## Steps

### 1. Update Package Schema

Add configurables to `agent/schemas/package.schema.yaml`:

```yaml
contents:
  configurables:
    description: "Configurable preference definitions for this package"
    type: array
    required: false
    items:
      type: object
      properties:
        name:
          type: string
          pattern: "^[a-z0-9-]+\\.configurables\\.yaml$"
          description: "Configurable filename (e.g., 'my-package.configurables.yaml')"
```

### 2. Update @acp.package-install

Modify `agent/scripts/acp.package-install.sh` to copy configurables:

```bash
# After copying commands, patterns, designs
# Copy configurables if present

if [ -d "$CLONE_DIR/agent/configurables" ]; then
  info "Installing configurables..."
  
  # Copy to project configurables
  mkdir -p "./agent/configurables"
  cp -r "$CLONE_DIR/agent/configurables/"*.yaml "./agent/configurables/" 2>/dev/null || true
  
  # Also copy to user-level for global access
  if [ "$INSTALL_MODE" = "global" ]; then
    mkdir -p "$HOME/.acp/agent/configurables"
    cp -r "$CLONE_DIR/agent/configurables/"*.yaml "$HOME/.acp/agent/configurables/" 2>/dev/null || true
  fi
  
  success "Configurables installed"
fi

# Copy preset preferences if present
if [ -d "$CLONE_DIR/agent/preferences" ]; then
  info "Installing preset preferences..."
  
  mkdir -p "./agent/preferences"
  cp -r "$CLONE_DIR/agent/preferences/"*.yaml "./agent/preferences/" 2>/dev/null || true
  
  success "Preset preferences installed"
fi
```

### 3. Update @acp.package-create

Modify `agent/scripts/acp.package-create.sh` to create configurables template:

```bash
# After creating package.yaml
# Create configurables template

info "Creating configurables template..."

cat > "$TARGET_DIR/agent/configurables/${PACKAGE_NAME}.configurables.yaml" << EOF
# ${PACKAGE_NAME} Configurables
# Define available preferences for this package
# Version: 1.0.0

${PACKAGE_NAME}:
  # Example preference
  example:
    setting:
      id: 'example.setting'
      description: Example preference description
      default: 'default_value'
      type: string
      options:
        - name: option1
          description: First option
          value: option1
        - name: option2
          description: Second option
          value: option2

# Add your package-specific preferences here
# Follow the structure above for each preference
EOF

success "Configurables template created"
```

### 4. Create Example Package Preset

Create example preset in package template:

```bash
# Create example preset preference file

cat > "$TARGET_DIR/agent/preferences/${PACKAGE_NAME}.example-preset.yaml" << EOF
# ${PACKAGE_NAME} Example Preset
# Preset configuration for common use case
# Usage: @{package-command} --preset ${PACKAGE_NAME}.example-preset

${PACKAGE_NAME}:
  example.setting: 'option1'
  # Add more preset values here

# Presets provide pre-configured preference sets for common workflows
# Users can create their own presets or use provided ones
EOF
```

### 5. Update Package Documentation

Add configurables section to package README template:

```markdown
## Configuration

This package supports preferences through the ACP preferences system.

### Available Preferences

See `agent/configurables/${PACKAGE_NAME}.configurables.yaml` for all available preferences.

### Preset Configurations

This package provides the following presets:
- `${PACKAGE_NAME}.example-preset` - Example preset description

Usage:
```bash
@{package-command} --preset ${PACKAGE_NAME}.example-preset
```

### Custom Preferences

Set preferences at any level:
```bash
# User-level
@acp.preferences-set ${PACKAGE_NAME} example.setting option2 --user

# Project-level
@acp.preferences-set ${PACKAGE_NAME} example.setting option2 --project
```
```

### 6. Update Package Validation

Modify `agent/scripts/acp.package-validate.sh` to validate configurables:

```bash
# Add validation step for configurables

validate_configurables() {
  local package_name="$1"
  local configurable_file="./agent/configurables/${package_name}.configurables.yaml"
  
  if [ ! -f "$configurable_file" ]; then
    # Configurables are optional
    return 0
  fi
  
  info "Validating configurables..."
  
  # Check YAML syntax
  yaml_parse "$configurable_file" > /dev/null || {
    error "Invalid YAML in configurables"
    return 1
  }
  
  # Check required fields for each preference
  # - id matches path
  # - description present
  # - default present
  # - type present (if applicable)
  # - options present (for string types)
  
  success "Configurables valid"
}
```

### 7. Test Package Preferences

Create test package with preferences:

```bash
# Create test package
@acp.package-create test-preferences-package

# Add configurables
# Add preset
# Install package
# Test preference loading
```

---

## Verification

- [ ] Package schema updated with configurables field
- [ ] `@acp.package-install` copies configurables
- [ ] `@acp.package-install` copies preset preferences
- [ ] `@acp.package-create` creates configurables template
- [ ] `@acp.package-create` creates example preset
- [ ] Package README template includes configuration section
- [ ] `@acp.package-validate` validates configurables
- [ ] Test package created with preferences
- [ ] Package preferences load correctly
- [ ] Preset configurations work
- [ ] Documentation updated

---

## Expected Output

### Files Modified
- `agent/schemas/package.schema.yaml` - Added configurables field
- `agent/scripts/acp.package-install.sh` - Copy configurables and presets
- `agent/scripts/acp.package-create.sh` - Create configurables template
- `agent/scripts/acp.package-validate.sh` - Validate configurables

### Package Structure (Enhanced)
```
package-name/
├── agent/
│   ├── configurables/
│   │   └── package-name.configurables.yaml  # NEW
│   ├── preferences/
│   │   ├── package-name.default.yaml        # NEW (optional)
│   │   └── package-name.preset-name.yaml   # NEW (optional)
│   ├── commands/
│   ├── patterns/
│   └── design/
└── package.yaml
```

---

## Common Issues and Solutions

### Issue 1: Configurables not installed
**Symptom**: Package configurables not found after installation  
**Solution**: Ensure package.yaml lists configurables in contents array  

### Issue 2: Preset not loading
**Symptom**: `--preset` flag doesn't apply preferences  
**Solution**: Check preset filename matches namespace (e.g., `package-name.preset.yaml`)  

### Issue 3: Namespace conflicts
**Symptom**: Package preferences override ACP core preferences  
**Solution**: Namespace isolation prevents this - each package has its own namespace  

---

## Resources

- [Design Document](../design/acp-preferences-system.md) - Package preference patterns
- [Package Schema](../schemas/package.schema.yaml) - Schema to update
- [Package Install Script](../scripts/acp.package-install.sh) - Installation logic

---

## Notes

- Configurables are optional for packages (not all packages need preferences)
- Presets are optional (packages can provide them for convenience)
- Package configurables installed to both project and user-level (for global packages)
- Namespace isolation prevents conflicts between packages
- Package authors should document their configurables in README

---

**Next Task**: [Task 42: Preset Configuration System](task-42-preset-configuration-system.md)  
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md), [Package Management System](../design/acp-package-management-system.md)  
**Estimated Completion Date**: TBD  
