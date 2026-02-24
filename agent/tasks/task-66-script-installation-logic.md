# Task 66: Script-Command Binding - Installation Logic

**Milestone**: [M3 - ACP Package Management System](../../milestones/milestone-3-package-management.md)
**Estimated Time**: 2-3 hours
**Dependencies**: Task 65 (Schema and Templates)
**Status**: Not Started

---

## Objective

Implement selective script installation logic in acp.install.sh and acp.package-install.sh. Scripts are only installed when their corresponding commands are installed, using reference counting for shared utilities.

---

## Context

This is Phase 2 of the script-command binding system. With schemas and templates updated in Task 65, this task implements the actual installation logic.

**Design Document**: [`agent/design/local.script-command-binding.md`](../../design/local.script-command-binding.md)

---

## Steps

### 1. Update acp.install.sh

Implement selective script copying for package mode:

**Actions**:
- Check if package.yaml exists in source
- If package.yaml: Read commands being installed, collect their script dependencies
- If no package.yaml: Copy all scripts (direct ACP install)
- Use reference counting for shared utilities

**Implementation**:
```bash
if [ -f "$TEMP_DIR/package.yaml" ]; then
  # Package mode - selective installation
  # Read scripts from installed commands
  required_scripts=()
  for cmd in installed_commands; do
    cmd_scripts=$(yaml_get "contents.commands[?name=='$cmd'].scripts[]")
    for script in $cmd_scripts; do
      if ! in_array "$script" "${required_scripts[@]}"; then
        required_scripts+=("$script")
      fi
    done
  done
  
  # Install only required scripts
  for script in "${required_scripts[@]}"; do
    cp "$TEMP_DIR/agent/scripts/$script" "$TARGET_DIR/agent/scripts/"
  done
else
  # Direct install - copy all
  cp "$TEMP_DIR/agent/scripts"/*.sh "$TARGET_DIR/agent/scripts/"
fi
```

### 2. Update acp.package-install.sh

Implement script-command binding with experimental filtering:

**Actions**:
- After installing commands, collect required scripts
- Read scripts array from package.yaml for each installed command
- Deduplicate (reference counting)
- Check experimental status from package.yaml scripts section
- Install only required, non-experimental (or with --experimental) scripts

**Implementation**:
```bash
# After command installation, collect required scripts
required_scripts=()

for cmd in installed_commands; do
  # Read scripts from package.yaml
  cmd_scripts=$(yaml_get_nested "contents.commands" | \
    jq -r ".[] | select(.name==\"$cmd\") | .scripts[]" 2>/dev/null || echo "")
  
  for script in $cmd_scripts; do
    if ! in_array "$script" "${required_scripts[@]}"; then
      required_scripts+=("$script")
    fi
  done
done

# Install required scripts
for script in "${required_scripts[@]}"; do
  if should_install_script "$script"; then
    install_script "$script"
  fi
done
```

### 3. Implement should_install_script()

Create helper function for script installation decisions:

**Actions**:
- Check experimental status from package.yaml scripts section
- Return true if should install, false otherwise

**Implementation**:
```bash
should_install_script() {
  local script="$1"
  
  # Check if script is experimental
  local is_experimental=$(yaml_get_nested "contents.scripts" | \
    jq -r ".[] | select(.name==\"$script\") | .experimental" 2>/dev/null || echo "false")
  
  if [ "$is_experimental" = "true" ] && [ "$INSTALL_EXPERIMENTAL" != "true" ]; then
    echo "  ⊘ Skipping experimental script: $script"
    return 1
  fi
  
  return 0
}
```

### 4. Test Installation Logic

Verify scripts are installed correctly:

**Actions**:
- Test with experimental commands
- Test with selective installation
- Test reference counting (shared utilities)
- Verify no unused scripts installed

---

## Verification

- [ ] acp.install.sh updated for selective copying
- [ ] acp.package-install.sh reads scripts from package.yaml
- [ ] should_install_script() implemented
- [ ] Reference counting works (utilities installed once)
- [ ] Experimental scripts respected
- [ ] No unused scripts installed
- [ ] Shared utilities (acp.common.sh) handled correctly
- [ ] No syntax errors

---

## Expected Outcome

**Before**:
```bash
@acp.package-install repo --commands firebase.init
# Installs: firebase.init.md + ALL scripts
```

**After**:
```bash
@acp.package-install repo --commands firebase.init
# Installs: firebase.init.md + firebase.init.sh + acp.common.sh (if needed)
# Skips: firebase.deploy.sh, firebase.migrate.sh (unused)
```

---

**Next Task**: Task 67 - Script-Command Binding Validation
