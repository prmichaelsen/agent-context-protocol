# Task 33: Track ACP Core Commands in manifest.yaml

**Milestone**: Future Enhancement  
**Estimated Time**: 1-2 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Update `acp.install.sh` to track core ACP commands in `manifest.yaml` as the "acp-core" package, so package validation doesn't flag them as unlisted files.

---

## Context

When ACP is installed via `acp.install.sh`, core commands (like `git.commit.md`, `git.init.md`, and all `acp.*.md` commands) are copied to `agent/commands/`, but they're not tracked in `manifest.yaml`.

**Problem**:
- ❌ Core commands not tracked in manifest
- ❌ Package validation warns about "unlisted files"
- ❌ Can't tell which files came from ACP core vs. packages
- ❌ No version tracking for core commands

**Solution**: Track core ACP installation as "acp-core" package in manifest.yaml  

---

## Steps

### 1. Update acp.install.sh to Create manifest.yaml

Add manifest creation/update after file installation:

```bash
# After copying all files

# Create manifest.yaml to track core ACP installation
echo "Creating manifest..."

# Get ACP version from AGENT.md
ACP_VERSION=$(grep "^\*\*Version\*\*:" AGENT.md | sed 's/.*: //')
INSTALL_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# List installed core files
CORE_COMMANDS=$(ls agent/commands/acp.*.md agent/commands/git.*.md 2>/dev/null | xargs -n1 basename | sed 's/^/        - name: /')
CORE_PATTERNS=$(ls agent/patterns/*.template.md 2>/dev/null | xargs -n1 basename | sed 's/^/        - name: /')
CORE_DESIGNS=$(ls agent/design/*.template.md 2>/dev/null | xargs -n1 basename | sed 's/^/        - name: /')

# Create manifest
cat > agent/manifest.yaml << EOF
# ACP Package Manifest
# Tracks installed packages and their versions

packages:
  acp-core:
    source: https://github.com/prmichaelsen/agent-context-protocol.git
    package_version: ${ACP_VERSION}
    installed_at: ${INSTALL_DATE}
    updated_at: ${INSTALL_DATE}
    files:
      commands:
${CORE_COMMANDS}
      patterns:
${CORE_PATTERNS}
      designs:
${CORE_DESIGNS}

manifest_version: 1.0.0
last_updated: ${INSTALL_DATE}
EOF

echo "✓ Created manifest.yaml (tracking acp-core installation)"
```

**Expected Outcome**: manifest.yaml created with acp-core package  

### 2. Update acp.version-update.sh

Update manifest when ACP is updated:

```bash
# After updating files

# Update acp-core version in manifest
if [ -f "agent/manifest.yaml" ]; then
  NEW_VERSION=$(grep "^\*\*Version\*\*:" AGENT.md | sed 's/.*: //')
  UPDATE_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Update version and timestamp using sed
  sed -i "s/package_version: .*/package_version: ${NEW_VERSION}/" agent/manifest.yaml
  sed -i "s/updated_at: .*/updated_at: ${UPDATE_DATE}/" agent/manifest.yaml
  sed -i "s/last_updated: .*/last_updated: ${UPDATE_DATE}/" agent/manifest.yaml
  
  echo "✓ Updated acp-core version in manifest.yaml"
fi
```

**Expected Outcome**: manifest updated when ACP is updated  

### 3. Update acp.package-validate.sh

Check manifest when validating unlisted files:

```bash
# In validate_unlisted_files()

# Get files from manifest (all packages)
manifest_files=""
if [ -f "agent/manifest.yaml" ]; then
  # Extract all filenames from all packages in manifest
  manifest_files=$(awk '
    /^  [a-z].*:$/ { in_package=1; next }
    in_package && /^    files:/ { in_files=1; next }
    in_files && /^      (commands|patterns|designs):/ { in_section=1; next }
    in_section && /^        - name:/ {
      sub(/^[[:space:]]*- name:[[:space:]]*/, "")
      print $0
    }
    /^  [a-z]/ && in_package { in_package=0; in_files=0; in_section=0 }
  ' agent/manifest.yaml)
fi

# When checking for unlisted files, skip files in manifest
for file in agent/commands/*.md; do
  filename=$(basename "$file")
  
  # Skip if in manifest
  if echo "$manifest_files" | grep -q "^${filename}$"; then
    continue
  fi
  
  # Check if in package.yaml contents
  # ...
done
```

**Expected Outcome**: Validation skips files tracked in manifest  

### 4. Test with Fresh Installation

Test the complete workflow:

**Actions**:
- Create test directory
- Run `./agent/scripts/acp.install.sh`
- Verify `agent/manifest.yaml` exists
- Verify acp-core package is listed
- Verify core commands are tracked
- Run `@acp.package-validate`
- Verify no warnings about core commands

**Expected Outcome**: Core commands properly tracked, no false warnings  

---

## Verification

- [ ] acp.install.sh creates manifest.yaml with acp-core package
- [ ] All core commands listed in manifest
- [ ] All core patterns listed in manifest
- [ ] All core designs listed in manifest
- [ ] acp.version-update.sh updates acp-core version
- [ ] acp.package-validate.sh checks manifest for files
- [ ] No false warnings about core commands
- [ ] Tested with fresh installation
- [ ] manifest.yaml format is correct

---

## Expected Output

### Files Modified
- `agent/scripts/acp.install.sh` - Add manifest creation
- `agent/scripts/acp.version-update.sh` - Update manifest on update
- `agent/scripts/acp.package-validate.sh` - Check manifest for files

### Example manifest.yaml After Installation

```yaml
packages:
  acp-core:
    source: https://github.com/prmichaelsen/agent-context-protocol.git
    package_version: 3.3.0
    installed_at: 2026-02-21T06:00:00Z
    updated_at: 2026-02-21T06:00:00Z
    files:
      commands:
        - name: git.commit.md
        - name: git.init.md
        - name: acp.init.md
        - name: acp.proceed.md
        # ... all core commands
      patterns:
        - name: bootstrap.template.md
        - name: pattern.template.md
      designs:
        - name: design.template.md

manifest_version: 1.0.0
last_updated: 2026-02-21T06:00:00Z
```

---

## Common Issues and Solutions

### Issue 1: manifest.yaml already exists

**Symptom**: Error creating manifest  

**Solution**: Check if manifest exists, update instead of create. Merge acp-core entry with existing packages.  

### Issue 2: Version extraction fails

**Symptom**: Can't read ACP version from AGENT.md  

**Solution**: Verify AGENT.md exists and has Version field. Use fallback version if needed.  

### Issue 3: File list generation fails

**Symptom**: No files listed in manifest  

**Solution**: Verify files exist before listing. Handle empty directories gracefully.  

---

## Resources

- [ACP Install Script](../scripts/acp.install.sh)
- [ACP Update Script](../scripts/acp.version-update.sh)
- [Package Validation Script](../scripts/acp.package-validate.sh)
- [Manifest Template](../manifest.template.yaml)

---

## Notes

- acp-core is a special package name for core ACP installation
- Treated like any other package in manifest
- Updated when ACP is updated
- Enables proper dependency tracking
- Fixes false positive validation warnings

---

**Next Task**: TBD  
**Estimated Completion Date**: TBD  
