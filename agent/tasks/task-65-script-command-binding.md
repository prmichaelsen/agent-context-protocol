# Task 65: Script-Command Binding and Selective Installation

**Milestone**: [M3 - ACP Package Management System](../../milestones/milestone-3-package-management.md)
**Estimated Time**: 4-6 hours
**Dependencies**: Task 45 (Package Script Bundling), Task 62 (Installation Filtering)
**Status**: Not Started

---

## Objective

Implement selective script installation based on command installation status. Scripts should only be installed when their corresponding commands are installed, preventing clutter from unused scripts in experimental or selectively-installed packages.

---

## Context

Currently, installation scripts copy ALL scripts without checking if their corresponding commands are installed. This creates several issues:

1. **Experimental commands** are skipped, but their scripts are still installed
2. **Selective installation** (e.g., `--commands command1`) installs all scripts, not just needed ones
3. **Script directory clutter** with unused files
4. **No binding** between commands and their required scripts

**Example Problem**:
```bash
# Install only one command
@acp.package-install repo --commands firebase.init

# Result: firebase.init.md installed, but ALL scripts copied
# Including: firebase.deploy.sh, firebase.migrate.sh (unused)
```

**Related Work**:
- Task 45: Scripts ARE in package.yaml schema with experimental support
- Task 62: Experimental filtering works for commands, not scripts
- Design: [`agent/drafts/script-command-binding.draft.md`](../../drafts/script-command-binding.draft.md)

---

## Steps

### 1. Design Script-Command Binding System

Choose and document binding approach:

**Recommended: Hybrid Approach**
- Explicit listing in package.yaml scripts section
- Naming convention fallback (command.md → command.sh)
- Utility scripts explicitly listed

**Actions**:
- Review draft document
- Finalize binding approach
- Document in design document

### 2. Update package.yaml Schema

Enhance scripts section if needed:

**Actions**:
- Review current schema (already supports scripts)
- Add `for_command` field (optional) to explicitly bind scripts
- Update schema documentation

**Example**:
```yaml
contents:
  scripts:
    - name: acp.project-set.sh
      description: Context switching script
      experimental: true
      for_command: acp.project-set.md  # Optional explicit binding
```

### 3. Update acp.install.sh

Modify to selectively copy scripts:

**Actions**:
- Check if package.yaml exists (ACP as package vs direct install)
- If package.yaml: Only copy scripts listed in contents.scripts
- If no package.yaml: Copy all scripts (direct ACP install)
- Apply naming convention fallback for unlisted scripts

**Implementation**:
```bash
if [ -f "$TEMP_DIR/package.yaml" ]; then
  # Package mode - selective installation
  install_scripts_from_package_yaml
else
  # Direct install mode - install all
  cp "$TEMP_DIR/agent/scripts"/*.sh "$TARGET_DIR/agent/scripts/"
fi
```

### 4. Update acp.package-install.sh

Implement script-command binding logic:

**Actions**:
- Read scripts section from package.yaml
- For each script, check if it should be installed:
  - If experimental and no --experimental flag: Skip
  - If bound to command (naming convention): Check if command installed
  - If utility script: Install if any command installed
- Copy only needed scripts
- Track in manifest

**Implementation**:
```bash
# Install scripts from package.yaml
for script in scripts_list; do
  if should_install_script "$script"; then
    install_script "$script"
  fi
done

should_install_script() {
  local script="$1"
  
  # Check experimental
  if is_experimental "$script" && ! has_experimental_flag; then
    return 1  # Skip
  fi
  
  # Check if bound to installed command (naming convention)
  local cmd="${script%.sh}.md"
  if command_exists_in_package "$cmd"; then
    if command_is_installed "$cmd"; then
      return 0  # Install
    else
      return 1  # Skip
    fi
  fi
  
  # Utility script (no matching command) - install if listed in package.yaml
  return 0
}
```

### 5. Update acp.package-update.sh

Apply same logic for updates:

**Actions**:
- Update scripts based on command installation status
- Remove scripts when commands are removed
- Add scripts when commands are added

### 6. Create ACP Core package.yaml

Create package.yaml for ACP core to enable selective installation:

**Actions**:
- Create package.yaml in repository root
- List all commands with experimental marking
- List all scripts with bindings
- Mark experimental commands and scripts

**Location**: `package.yaml` (repository root)

### 7. Test Selective Script Installation

Create E2E tests:

**Test Scenarios**:
- Install command without --experimental → script not installed
- Install command with --experimental → script installed
- Install selective commands → only those scripts installed
- Install utility script → always installed
- Update removes unused scripts

### 8. Update Documentation

Document script-command binding:

**Actions**:
- Update AGENT.md with script binding explanation
- Update package.template.yaml with scripts example
- Update command creation docs to mention script binding
- Update CHANGELOG.md

---

## Verification

- [ ] Binding approach documented in design doc
- [ ] Schema updated (if needed)
- [ ] acp.install.sh updated for selective copying
- [ ] acp.package-install.sh implements binding logic
- [ ] acp.package-update.sh handles script updates
- [ ] ACP core package.yaml created
- [ ] E2E tests created and passing
- [ ] Experimental scripts respected
- [ ] Utility scripts handled correctly
- [ ] Documentation updated
- [ ] No unused scripts installed

---

## Expected Outcome

**Before**:
```bash
@acp.package-install repo --commands firebase.init
# Installs: firebase.init.md + ALL scripts (firebase.*.sh)
```

**After**:
```bash
@acp.package-install repo --commands firebase.init
# Installs: firebase.init.md + firebase.init.sh only
# Utility scripts (firebase.common.sh) installed if listed in package.yaml
```

---

**Next Task**: TBD (depends on milestone priority)
