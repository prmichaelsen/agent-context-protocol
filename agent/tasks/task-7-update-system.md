# Task 7: Update System

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 5-7 hours  
**Dependencies**: Task 5 (Manifest System), Task 6 (Selective Installation)  
**Status**: Not Started  
**Priority**: High  

---

## Objective

Implement `@acp.package-update` command to update installed packages to their latest versions, with smart detection of changes, local modifications, and conflict resolution.

---

## Context

Packages evolve over time with bug fixes, new features, and improvements. The update system enables users to get the latest versions while preserving local modifications and handling conflicts intelligently.

---

## Steps

### 1. Create Update Command Script

Create `scripts/package-acp.version-update.sh`:

```bash
#!/bin/bash
# Package update script

PACKAGE_NAME=$1
CHECK_ONLY=false
SKIP_MODIFIED=false
FORCE=false

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    --check) CHECK_ONLY=true; shift ;;
    --skip-modified) SKIP_MODIFIED=true; shift ;;
    --force) FORCE=true; shift ;;
    -y|--yes) AUTO_CONFIRM=true; shift ;;
    *) PACKAGE_NAME=$1; shift ;;
  esac
done

# If no package specified, update all
if [ -z "$PACKAGE_NAME" ]; then
  update_all_packages
else
  update_package "$PACKAGE_NAME"
fi
```

### 2. Implement Version Comparison

```bash
# Compare versions (returns: newer, same, older)
compare_versions() {
  local current=$1
  local remote=$2
  
  # Use sort -V for version comparison
  if [ "$current" == "$remote" ]; then
    echo "same"
  elif [ "$(printf '%s\n' "$current" "$remote" | sort -V | head -n1)" == "$current" ]; then
    echo "newer"
  else
    echo "older"
  fi
}

# Check for updates
check_for_updates() {
  local package_name=$1
  
  # Read current version from manifest
  local current_version=$(yq eval ".packages.${package_name}.package_version" agent/manifest.yaml)
  local source_url=$(yq eval ".packages.${package_name}.source" agent/manifest.yaml)
  
  # Clone repository
  git clone --depth 1 "$source_url" temp-update
  
  # Read remote version
  local remote_version=$(yq eval '.version' temp-update/package.yaml)
  
  # Compare
  local comparison=$(compare_versions "$current_version" "$remote_version")
  
  if [ "$comparison" == "newer" ]; then
    echo "Update available: $current_version → $remote_version"
    return 0
  else
    echo "Up to date: $current_version"
    return 1
  fi
}
```

### 3. Detect Local Modifications

```bash
# Check if file was modified locally
is_file_modified() {
  local package_name=$1
  local file_type=$2
  local file_name=$3
  
  # Get stored checksum from manifest
  local stored_checksum=$(yq eval ".packages.${package_name}.installed.${file_type}[] | select(.name == \"${file_name}\") | .checksum" agent/manifest.yaml | sed 's/sha256://')
  
  # Calculate current checksum
  local current_checksum=$(sha256sum "agent/${file_type}/${file_name}" | cut -d' ' -f1)
  
  if [ "$stored_checksum" != "$current_checksum" ]; then
    return 0  # Modified
  else
    return 1  # Not modified
  fi
}

# Get list of modified files
get_modified_files() {
  local package_name=$1
  local modified_files=()
  
  # Check patterns
  local patterns=$(yq eval ".packages.${package_name}.installed.patterns[].name" agent/manifest.yaml)
  for file in $patterns; do
    if is_file_modified "$package_name" "patterns" "$file"; then
      modified_files+=("patterns/$file")
    fi
  done
  
  # Check commands and designs similarly
  
  echo "${modified_files[@]}"
}
```

### 4. Implement Update Logic

```bash
# Update package
update_package() {
  local package_name=$1
  
  echo "Updating $package_name..."
  
  # Check for updates
  if ! check_for_updates "$package_name"; then
    echo "No updates available"
    return 0
  fi
  
  # Get modified files
  local modified_files=$(get_modified_files "$package_name")
  
  if [ -n "$modified_files" ] && [ "$FORCE" == false ]; then
    echo ""
    echo "⚠️  Modified files detected:"
    for file in $modified_files; do
      echo "  - $file"
    done
    echo ""
    
    if [ "$SKIP_MODIFIED" == true ]; then
      echo "Skipping modified files (--skip-modified)"
    else
      read -p "Overwrite modified files? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled"
        return 1
      fi
    fi
  fi
  
  # Perform update
  perform_update "$package_name" "$modified_files"
}

# Perform the actual update
perform_update() {
  local package_name=$1
  local modified_files=$2
  
  # Clone latest version
  local source_url=$(yq eval ".packages.${package_name}.source" agent/manifest.yaml)
  git clone --depth 1 "$source_url" temp-update
  
  # Update each file
  local updated_count=0
  local skipped_count=0
  
  # Update patterns
  local patterns=$(yq eval ".packages.${package_name}.installed.patterns[].name" agent/manifest.yaml)
  for file in $patterns; do
    if echo "$modified_files" | grep -q "patterns/$file" && [ "$SKIP_MODIFIED" == true ]; then
      echo "⊘ Skipped patterns/$file (modified locally)"
      ((skipped_count++))
      continue
    fi
    
    if [ -f "temp-update/agent/patterns/$file" ]; then
      cp "temp-update/agent/patterns/$file" "agent/patterns/"
      
      # Update manifest
      local new_version=$(get_file_version "temp-update/package.yaml" "patterns" "$file")
      local new_checksum=$(calculate_checksum "agent/patterns/$file")
      
      # Update file entry in manifest
      update_file_in_manifest "$package_name" "patterns" "$file" "$new_version" "$new_checksum"
      
      echo "✓ Updated patterns/$file"
      ((updated_count++))
    fi
  done
  
  # Update package metadata
  local new_version=$(yq eval '.version' temp-update/package.yaml)
  local new_commit=$(cd temp-update && git rev-parse HEAD)
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  yq eval -i ".packages.${package_name}.package_version = \"${new_version}\"" agent/manifest.yaml
  yq eval -i ".packages.${package_name}.commit = \"${new_commit}\"" agent/manifest.yaml
  yq eval -i ".packages.${package_name}.updated_at = \"${timestamp}\"" agent/manifest.yaml
  yq eval -i ".last_updated = \"${timestamp}\"" agent/manifest.yaml
  
  # Cleanup
  rm -rf temp-update
  
  echo ""
  echo "✅ Update complete!"
  echo "Updated: $updated_count file(s)"
  echo "Skipped: $skipped_count file(s)"
}
```

### 5. Test Update Scenarios

```bash
# Test 1: Update with no local changes
@acp.package-update firebase

# Test 2: Update with local modifications
# (modify a file first)
@acp.package-update firebase

# Test 3: Update and skip modified
@acp.package-update firebase --skip-modified

# Test 4: Force update
@acp.package-update firebase --force

# Test 5: Check only
@acp.package-update --check

# Test 6: Update all packages
@acp.package-update
```

---

## Verification

- [ ] `@acp.package-update` detects available updates
- [ ] Version comparison works correctly
- [ ] Local modifications detected via checksum
- [ ] User prompted for modified files
- [ ] `--skip-modified` flag works
- [ ] `--force` flag overwrites without prompting
- [ ] `--check` shows updates without installing
- [ ] Updating without args updates all packages
- [ ] Manifest updated with new versions and checksums
- [ ] Update summary shows what changed

---

**Status**: Ready to implement  
**Priority**: High  
**Estimated Effort**: 5-7 hours  
