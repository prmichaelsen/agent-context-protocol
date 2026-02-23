# Task 62: Installation Filtering

**Milestone**: M8 - Experimental Features System
**Estimated Time**: 3-4 hours
**Dependencies**: [Task 61 - Schema and Validation](task-61-schema-validation.md)
**Status**: Not Started

---

## Objective

Implement `--experimental` flag in the installation script to filter experimental features during package installation.

---

## Context

With the schema and validation in place, we need to implement the installation filtering logic:
- Without `--experimental`: Skip all features marked `experimental: true`
- With `--experimental`: Install all features including experimental ones
- Track experimental status in manifest for update handling

---

## Steps

### 1. Add --experimental Flag Parsing

**File**: [`agent/scripts/acp.package-install.sh`](../../scripts/acp.package-install.sh)

**Add flag parsing**:
```bash
# Add to argument parsing section
INSTALL_EXPERIMENTAL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --experimental)
      INSTALL_EXPERIMENTAL=true
      shift
      ;;
    # ... existing flags
  esac
done
```

### 2. Implement Filtering Function

**File**: [`agent/scripts/acp.package-install.sh`](../../scripts/acp.package-install.sh)

**Add filtering function**:
```bash
# Check if file should be installed based on experimental status
should_install_file() {
  local file_name="$1"
  local file_type="$2"  # commands, patterns, designs, scripts
  
  # Check if file is marked experimental in package.yaml
  local is_experimental=$(yaml_get "contents.${file_type}[?name=='${file_name}'].experimental")
  
  if [[ "$is_experimental" == "true" ]]; then
    if [[ "$INSTALL_EXPERIMENTAL" == "true" ]]; then
      echo "  ${YELLOW}⚠${NC}  Installing experimental: ${file_name}"
      return 0  # Install it
    else
      echo "  ${GRAY}⊘${NC}  Skipping experimental: ${file_name} (use --experimental to install)"
      return 1  # Skip it
    fi
  fi
  
  return 0  # Install non-experimental files
}
```

### 3. Apply Filter to Installation Logic

**File**: [`agent/scripts/acp.package-install.sh`](../../scripts/acp.package-install.sh)

**Update installation loops**:
```bash
# Commands
if [[ -n "${INSTALL_COMMANDS}" ]]; then
  echo "Installing commands..."
  for cmd in "${commands[@]}"; do
    if should_install_file "$cmd" "commands"; then
      cp "${CLONE_DIR}/agent/commands/${cmd}" "${INSTALL_DIR}/commands/"
      add_file_to_manifest "commands" "$cmd"
      echo "  ${GREEN}✓${NC} Installed: ${cmd}"
    fi
  done
fi

# Patterns
if [[ -n "${INSTALL_PATTERNS}" ]]; then
  echo "Installing patterns..."
  for pattern in "${patterns[@]}"; do
    if should_install_file "$pattern" "patterns"; then
      cp "${CLONE_DIR}/agent/patterns/${pattern}" "${INSTALL_DIR}/patterns/"
      add_file_to_manifest "patterns" "$pattern"
      echo "  ${GREEN}✓${NC} Installed: ${pattern}"
    fi
  done
fi

# Designs
if [[ -n "${INSTALL_DESIGNS}" ]]; then
  echo "Installing designs..."
  for design in "${designs[@]}"; do
    if should_install_file "$design" "designs"; then
      cp "${CLONE_DIR}/agent/design/${design}" "${INSTALL_DIR}/design/"
      add_file_to_manifest "designs" "$design"
      echo "  ${GREEN}✓${NC} Installed: ${design}"
    fi
  done
fi

# Scripts
if [[ -n "${INSTALL_SCRIPTS}" ]]; then
  echo "Installing scripts..."
  for script in "${scripts[@]}"; do
    if should_install_file "$script" "scripts"; then
      cp "${CLONE_DIR}/agent/scripts/${script}" "${INSTALL_DIR}/scripts/"
      chmod +x "${INSTALL_DIR}/scripts/${script}"
      add_file_to_manifest "scripts" "$script"
      echo "  ${GREEN}✓${NC} Installed: ${script}"
    fi
  done
fi
```

### 4. Track Experimental Status in Manifest

**File**: [`agent/scripts/acp.common.sh`](../../scripts/acp.common.sh)

**Update add_file_to_manifest function**:
```bash
add_file_to_manifest() {
  local file_type="$1"
  local file_name="$2"
  local package_name="$3"
  
  # Get file version and checksum
  local version=$(get_file_version "$file_type" "$file_name")
  local checksum=$(calculate_checksum "${INSTALL_DIR}/${file_type}/${file_name}")
  
  # Check if experimental
  local is_experimental=$(yaml_get "contents.${file_type}[?name=='${file_name}'].experimental")
  
  # Add to manifest with experimental flag
  if [[ "$is_experimental" == "true" ]]; then
    yaml_set "packages.${package_name}.files.${file_type}[+]" "{name: \"${file_name}\", version: \"${version}\", checksum: \"${checksum}\", experimental: true}"
  else
    yaml_set "packages.${package_name}.files.${file_type}[+]" "{name: \"${file_name}\", version: \"${version}\", checksum: \"${checksum}\"}"
  fi
}
```

### 5. Update Success Message

**File**: [`agent/scripts/acp.package-install.sh`](../../scripts/acp.package-install.sh)

**Add experimental count to summary**:
```bash
# Count experimental features installed
EXPERIMENTAL_COUNT=0
if [[ "$INSTALL_EXPERIMENTAL" == "true" ]]; then
  for type in commands patterns designs scripts; do
    local count=$(yaml_get "packages.${PACKAGE_NAME}.files.${type}[?experimental==true] | length")
    EXPERIMENTAL_COUNT=$((EXPERIMENTAL_COUNT + count))
  done
fi

echo ""
echo "${GREEN}✓${NC} Package installed successfully!"
echo ""
echo "Installed:"
echo "  • ${COMMANDS_INSTALLED} commands"
echo "  • ${PATTERNS_INSTALLED} patterns"
echo "  • ${DESIGNS_INSTALLED} designs"
echo "  • ${SCRIPTS_INSTALLED} scripts"
if [[ $EXPERIMENTAL_COUNT -gt 0 ]]; then
  echo "  • ${YELLOW}${EXPERIMENTAL_COUNT} experimental features${NC}"
fi
```

---

## Verification

- [ ] --experimental flag parsed correctly
- [ ] should_install_file() function implemented
- [ ] Function checks experimental field in package.yaml
- [ ] Without --experimental: Experimental features skipped
- [ ] With --experimental: Experimental features installed
- [ ] Clear messages for skipped experimental features
- [ ] Manifest tracks experimental status
- [ ] Installation summary shows experimental count
- [ ] No syntax errors in install script
- [ ] Test installation with sample package (with/without flag)

---

## Test Scenarios

### Test 1: Install Without --experimental
```bash
./agent/scripts/acp.package-install.sh --repo https://github.com/user/test-package.git

Expected:
  ✓ Installed: stable-command.md
  ⊘ Skipping experimental: experimental-command.md (use --experimental to install)
  
  ✓ Package installed successfully!
  Installed:
    • 1 commands
    • 0 experimental features
```

### Test 2: Install With --experimental
```bash
./agent/scripts/acp.package-install.sh --repo https://github.com/user/test-package.git --experimental

Expected:
  ✓ Installed: stable-command.md
  ⚠  Installing experimental: experimental-command.md
  
  ✓ Package installed successfully!
  Installed:
    • 2 commands
    • 1 experimental features
```

### Test 3: Manifest Tracking
```bash
# After installation with --experimental
cat agent/manifest.yaml

Expected:
packages:
  test-package:
    files:
      commands:
        - name: stable-command.md
          version: 1.0.0
          checksum: abc123
        - name: experimental-command.md
          version: 0.1.0
          checksum: def456
          experimental: true  # ← Tracked
```

---

## Expected Output

### Console Output (Without --experimental)
```
Installing package: test-package

Installing commands...
  ✓ Installed: stable-command.md
  ⊘ Skipping experimental: experimental-command.md (use --experimental to install)

Installing patterns...
  ✓ Installed: stable-pattern.md
  ⊘ Skipping experimental: experimental-pattern.md (use --experimental to install)

✓ Package installed successfully!

Installed:
  • 1 commands
  • 1 patterns
  • 0 experimental features
```

### Console Output (With --experimental)
```
Installing package: test-package

Installing commands...
  ✓ Installed: stable-command.md
  ⚠  Installing experimental: experimental-command.md

Installing patterns...
  ✓ Installed: stable-pattern.md
  ⚠  Installing experimental: experimental-pattern.md

✓ Package installed successfully!

Installed:
  • 2 commands
  • 2 patterns
  • 2 experimental features
```

---

## Notes

- Filtering happens at installation time, not during file copying
- Experimental status is tracked in manifest for update handling
- Clear visual indicators (⊘ for skipped, ⚠ for experimental)
- Backward compatible (packages without experimental field work unchanged)
- Manifest structure supports experimental field per file

---

**Next Task**: [Task 63 - Update Handling](task-63-update-handling.md)
**Related Design**: [`agent/design/local.experimental-features-system.md`](../../design/local.experimental-features-system.md)
