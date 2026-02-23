# Task 63: Update Handling for Experimental Features

**Milestone**: M8 - Experimental Features System
**Estimated Time**: 2-3 hours
**Dependencies**: [Task 61 - Schema and Validation](task-61-schema-validation.md), [Task 62 - Installation Filtering](task-62-installation-filtering.md)
**Status**: Not Started

---

## Objective

Enhance the update script to handle experimental features correctly: update already-installed experimental features normally, but skip new experimental features unless `--experimental` flag is provided.

---

## Context

The update behavior for experimental features should be:
1. **Already installed experimental features**: Update them normally (no flag required)
2. **New experimental features**: Skip them unless `--experimental` flag is provided
3. **Graduated features** (experimental → stable): Update them normally

This ensures users who opted into experimental features continue to receive updates, while protecting users who haven't opted in from accidentally getting new experimental features.

---

## Steps

### 1. Add Helper Function to Check Installation Status

**File**: [`agent/scripts/acp.package-update.sh`](../../scripts/acp.package-update.sh)

**Add function**:
```bash
# Check if experimental feature is already installed
is_experimental_installed() {
  local file_name="$1"
  local file_type="$2"
  local package_name="$3"
  
  # Check manifest to see if this file is already installed
  local installed=$(yaml_get "packages.${package_name}.files.${file_type}[?name=='${file_name}'].name")
  
  if [[ -n "$installed" ]]; then
    return 0  # Already installed
  fi
  
  return 1  # Not installed
}
```

### 2. Add Experimental Filtering to Update Logic

**File**: [`agent/scripts/acp.package-update.sh`](../../scripts/acp.package-update.sh)

**Update file processing loops**:
```bash
# Commands
echo "Checking commands for updates..."
for cmd in "${commands[@]}"; do
  local is_experimental=$(yaml_get "contents.commands[?name=='${cmd}'].experimental")
  
  if [[ "$is_experimental" == "true" ]]; then
    if is_experimental_installed "$cmd" "commands" "$PACKAGE_NAME"; then
      # Already installed, update it (no --experimental flag required)
      echo "  ${YELLOW}↻${NC} Updating experimental: ${cmd}"
      # ... update logic
    else
      # Not installed, skip it (would need --experimental on install)
      echo "  ${GRAY}⊘${NC} Skipping new experimental: ${cmd} (use --experimental with install to add)"
      continue
    fi
  else
    # Regular update for non-experimental
    echo "  ${BLUE}↻${NC} Updating: ${cmd}"
    # ... update logic
  fi
done

# Patterns
echo "Checking patterns for updates..."
for pattern in "${patterns[@]}"; do
  local is_experimental=$(yaml_get "contents.patterns[?name=='${pattern}'].experimental")
  
  if [[ "$is_experimental" == "true" ]]; then
    if is_experimental_installed "$pattern" "patterns" "$PACKAGE_NAME"; then
      echo "  ${YELLOW}↻${NC} Updating experimental: ${pattern}"
      # ... update logic
    else
      echo "  ${GRAY}⊘${NC} Skipping new experimental: ${pattern} (use --experimental with install to add)"
      continue
    fi
  else
    echo "  ${BLUE}↻${NC} Updating: ${pattern}"
    # ... update logic
  fi
done

# Designs
echo "Checking designs for updates..."
for design in "${designs[@]}"; do
  local is_experimental=$(yaml_get "contents.designs[?name=='${design}'].experimental")
  
  if [[ "$is_experimental" == "true" ]]; then
    if is_experimental_installed "$design" "designs" "$PACKAGE_NAME"; then
      echo "  ${YELLOW}↻${NC} Updating experimental: ${design}"
      # ... update logic
    else
      echo "  ${GRAY}⊘${NC} Skipping new experimental: ${design} (use --experimental with install to add)"
      continue
    fi
  else
    echo "  ${BLUE}↻${NC} Updating: ${design}"
    # ... update logic
  fi
done

# Scripts
echo "Checking scripts for updates..."
for script in "${scripts[@]}"; do
  local is_experimental=$(yaml_get "contents.scripts[?name=='${script}'].experimental")
  
  if [[ "$is_experimental" == "true" ]]; then
    if is_experimental_installed "$script" "scripts" "$PACKAGE_NAME"; then
      echo "  ${YELLOW}↻${NC} Updating experimental: ${script}"
      # ... update logic
    else
      echo "  ${GRAY}⊘${NC} Skipping new experimental: ${script} (use --experimental with install to add)"
      continue
    fi
  else
    echo "  ${BLUE}↻${NC} Updating: ${script}"
    # ... update logic
  fi
done
```

### 3. Handle Graduated Features

**File**: [`agent/scripts/acp.package-update.sh`](../../scripts/acp.package-update.sh)

**Add graduation detection**:
```bash
# Check if feature graduated from experimental to stable
check_graduation() {
  local file_name="$1"
  local file_type="$2"
  local package_name="$3"
  
  # Check if was experimental in manifest
  local was_experimental=$(yaml_get "packages.${package_name}.files.${file_type}[?name=='${file_name}'].experimental")
  
  # Check if is experimental in new package.yaml
  local is_experimental=$(yaml_get "contents.${file_type}[?name=='${file_name}'].experimental")
  
  if [[ "$was_experimental" == "true" ]] && [[ "$is_experimental" != "true" ]]; then
    echo "  ${GREEN}🎓${NC} Graduated to stable: ${file_name}"
    # Remove experimental flag from manifest
    yaml_set "packages.${package_name}.files.${file_type}[?name=='${file_name}'].experimental" "false"
  fi
}

# Call after updating each file
check_graduation "$cmd" "commands" "$PACKAGE_NAME"
```

### 4. Update Summary Message

**File**: [`agent/scripts/acp.package-update.sh`](../../scripts/acp.package-update.sh)

**Add experimental counts to summary**:
```bash
# Count experimental features
EXPERIMENTAL_UPDATED=0
EXPERIMENTAL_SKIPPED=0
GRADUATED_COUNT=0

# ... count during update loop

echo ""
echo "${GREEN}✓${NC} Update complete!"
echo ""
echo "Updated:"
echo "  • ${COMMANDS_UPDATED} commands"
echo "  • ${PATTERNS_UPDATED} patterns"
echo "  • ${DESIGNS_UPDATED} designs"
echo "  • ${SCRIPTS_UPDATED} scripts"

if [[ $EXPERIMENTAL_UPDATED -gt 0 ]]; then
  echo "  • ${YELLOW}${EXPERIMENTAL_UPDATED} experimental features${NC}"
fi

if [[ $GRADUATED_COUNT -gt 0 ]]; then
  echo "  • ${GREEN}${GRADUATED_COUNT} graduated to stable${NC}"
fi

if [[ $EXPERIMENTAL_SKIPPED -gt 0 ]]; then
  echo ""
  echo "${YELLOW}Note:${NC} ${EXPERIMENTAL_SKIPPED} new experimental features were skipped"
  echo "      Use --experimental with install to add them"
fi
```

---

## Verification

- [ ] is_experimental_installed() function implemented
- [ ] Update logic checks experimental status
- [ ] Already-installed experimental features update normally
- [ ] New experimental features are skipped
- [ ] Clear messages for experimental updates
- [ ] check_graduation() function implemented
- [ ] Graduated features detected and marked
- [ ] Manifest updated when features graduate
- [ ] Summary shows experimental counts
- [ ] No syntax errors in update script
- [ ] Test update scenarios (installed, new, graduated)

---

## Test Scenarios

### Test 1: Update Already-Installed Experimental Feature
```bash
# Setup: Package has experimental-command.md installed
./agent/scripts/acp.package-update.sh test-package

Expected:
  ↻ Updating experimental: experimental-command.md
  ✓ Updated to version 0.2.0
  
  ✓ Update complete!
  Updated:
    • 1 commands
    • 1 experimental features
```

### Test 2: Skip New Experimental Feature
```bash
# Setup: Package adds new experimental-pattern.md (not installed)
./agent/scripts/acp.package-update.sh test-package

Expected:
  ↻ Updating: stable-command.md
  ⊘ Skipping new experimental: experimental-pattern.md (use --experimental with install to add)
  
  ✓ Update complete!
  Updated:
    • 1 commands
  
  Note: 1 new experimental features were skipped
        Use --experimental with install to add them
```

### Test 3: Graduated Feature
```bash
# Setup: experimental-command.md was experimental, now stable
./agent/scripts/acp.package-update.sh test-package

Expected:
  🎓 Graduated to stable: experimental-command.md
  ↻ Updating: experimental-command.md
  ✓ Updated to version 1.0.0
  
  ✓ Update complete!
  Updated:
    • 1 commands
    • 1 graduated to stable
```

---

## Expected Output

### Console Output (Mixed Update)
```
Updating package: test-package

Checking commands for updates...
  ↻ Updating: stable-command.md
  ✓ Updated to version 1.2.0
  
  ↻ Updating experimental: experimental-command.md
  ✓ Updated to version 0.3.0
  
  ⊘ Skipping new experimental: new-experimental-command.md (use --experimental with install to add)

Checking patterns for updates...
  🎓 Graduated to stable: formerly-experimental-pattern.md
  ↻ Updating: formerly-experimental-pattern.md
  ✓ Updated to version 1.0.0

✓ Update complete!

Updated:
  • 3 commands
  • 1 patterns
  • 1 experimental features
  • 1 graduated to stable

Note: 1 new experimental features were skipped
      Use --experimental with install to add them
```

---

## Edge Cases

### Edge Case 1: Feature Removed from Package
- Was installed (experimental or not)
- No longer in package.yaml
- **Behavior**: Keep installed (don't auto-remove)

### Edge Case 2: Feature Becomes Experimental
- Was stable, now marked experimental
- **Behavior**: Update it (already installed, user has it)
- **Note**: This is unusual but supported

### Edge Case 3: All Features Experimental
- Package only has experimental features
- User hasn't opted in
- **Behavior**: No updates applied, clear message

---

## Notes

- Update behavior is based on installation status, not flags
- Once installed, experimental features update like any other feature
- Graduation is automatic (no user action required)
- Clear visual indicators for different update types
- Backward compatible (packages without experimental field work unchanged)
- No --experimental flag needed for updates (only for initial install)

---

**Next Task**: [Task 64 - Documentation and Examples](task-64-documentation.md)
**Related Design**: [`agent/design/local.experimental-features-system.md`](../../design/local.experimental-features-system.md)
