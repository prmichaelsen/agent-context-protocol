# Task 5: Manifest System Implementation

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 6-8 hours  
**Dependencies**: None  
**Status**: Not Started  
**Priority**: High  

---

## Objective

Create the `agent/manifest.yaml` structure and enhance `package-acp.install.sh` to write manifest entries when packages are installed, including package metadata, file versions, and checksums for modification tracking.

---

## Context

The manifest system is the foundation of the package management system. It tracks which packages are installed, their versions, which specific files were installed, and checksums to detect local modifications. This enables smart updates, conflict detection, and team collaboration through version-controlled manifests.

---

## Steps

### 1. Design Manifest Schema

Create the YAML structure for `agent/manifest.yaml`:

```yaml
# agent/manifest.yaml
# Tracks installed ACP packages and their versions

packages:
  <package-name>:
    source: string           # Git URL
    package_version: string  # Semantic version
    commit: string           # Git commit hash
    installed_at: datetime   # ISO 8601
    updated_at: datetime     # ISO 8601
    
    installed:
      patterns:
        - name: string
          version: string
          installed_at: datetime
          modified: boolean
          checksum: string  # sha256:...
      
      commands:
        - name: string
          version: string
          installed_at: datetime
          modified: boolean
          checksum: string
      
      designs:
        - name: string
          version: string
          installed_at: datetime
          modified: boolean
          checksum: string

manifest_version: string  # Format version
last_updated: datetime
```

### 2. Create Manifest Template

Create `agent/manifest.template.yaml`:

```yaml
# agent/manifest.template.yaml
# Template for package manifest

packages: {}

manifest_version: 1.0.0
last_updated: null
```

### 3. Implement Manifest Writing Functions

**✅ COMPLETED**: Created `agent/scripts/acp.common.sh` with shared utilities.  

**Implementation Notes**:
- Using `acp.yaml.sh` parser instead of `yq` (no external dependencies)
- Created POSIX-compliant shared library
- Functions available in `acp.common.sh`:
  - `init_manifest()` - ✅ Implemented
  - `calculate_checksum()` - ✅ Implemented
  - `validate_manifest()` - ✅ Implemented
  - `update_manifest_timestamp()` - ✅ Implemented
  - `package_exists()` - ✅ Implemented

**Still Needed**:
- `add_package_to_manifest()` - Uses `acp.yaml.sh` functions
- `add_file_to_manifest()` - Uses `acp.yaml.sh` functions
- `parse_package_metadata()` - Uses `acp.yaml.sh` functions
- `get_file_version()` - Uses `acp.yaml.sh` functions

**Example using acp.yaml.sh**:
```bash
# Source acp.common.sh and acp.yaml.sh
. "$(dirname "$0")/acp.common.sh"
source_yaml_parser

# Add package to manifest (to be implemented)
add_package_to_manifest() {
  local package_name=$1
  local source_url=$2
  local package_version=$3
  local commit_hash=$4
  local timestamp=$(get_timestamp)
  
  # Use acp.yaml.sh functions instead of yq
  yaml_set "agent/manifest.yaml" "packages.${package_name}.source" "$source_url"
  yaml_set "agent/manifest.yaml" "packages.${package_name}.package_version" "$package_version"
  yaml_set "agent/manifest.yaml" "packages.${package_name}.commit" "$commit_hash"
  yaml_set "agent/manifest.yaml" "packages.${package_name}.installed_at" "$timestamp"
  yaml_set "agent/manifest.yaml" "packages.${package_name}.updated_at" "$timestamp"
  update_manifest_timestamp
}
```

### 4. Parse package.yaml from Repository

**TO BE IMPLEMENTED** in `acp.common.sh` using `acp.yaml.sh`:

```bash
# Parse package.yaml from cloned repository
parse_package_metadata() {
  local repo_dir=$1
  local package_yaml="${repo_dir}/package.yaml"
  
  if [ ! -f "$package_yaml" ]; then
    die "package.yaml not found in repository"
  fi
  
  # Extract metadata using acp.yaml.sh
  PACKAGE_NAME=$(yaml_get "$package_yaml" "name")
  PACKAGE_VERSION=$(yaml_get "$package_yaml" "version")
  PACKAGE_DESCRIPTION=$(yaml_get "$package_yaml" "description")
  
  info "Package: $PACKAGE_NAME"
  info "Version: $PACKAGE_VERSION"
  info "Description: $PACKAGE_DESCRIPTION"
}

# Get file version from package.yaml
# Note: acp.yaml.sh doesn't support array queries, so we'll need to parse differently
get_file_version() {
  local package_yaml=$1
  local file_type=$2  # patterns, commands, designs
  local file_name=$3
  
  # Extract version using grep/awk since acp.yaml.sh doesn't support array queries
  awk "/^  ${file_type}:/,/^  [a-z]/ {
    if (/- name: ${file_name}/) { found=1; next }
    if (found && /version:/) { print \$2; exit }
  }" "$package_yaml"
}
```

### 5. Integrate Manifest Writing into Installation Flow

Update `package-acp.install.sh` main flow:

```bash
# Main installation flow
main() {
  local repo_url=$1
  
  # Initialize manifest
  init_manifest
  
  # Clone repository
  clone_repository "$repo_url"
  
  # Parse package metadata
  parse_package_metadata "temp-repo"
  
  # Get commit hash
  local commit_hash=$(cd temp-repo && git rev-parse HEAD)
  
  # Add package to manifest
  add_package_to_manifest "$PACKAGE_NAME" "$repo_url" "$PACKAGE_VERSION" "$commit_hash"
  
  # Install files
  for pattern_file in temp-repo/agent/patterns/*.md; do
    local file_name=$(basename "$pattern_file")
    local file_version=$(get_file_version "temp-repo/package.yaml" "patterns" "$file_name")
    
    # Copy file
    cp "$pattern_file" "agent/patterns/"
    
    # Add to manifest
    add_file_to_manifest "$PACKAGE_NAME" "patterns" "$file_name" "$file_version" "agent/patterns/$file_name"
  done
  
  # Repeat for commands and designs
  # ...
  
  # Cleanup
  rm -rf temp-repo
  
  echo "✅ Installation complete!"
  echo "Package $PACKAGE_NAME ($PACKAGE_VERSION) installed"
}
```

### 6. Test Manifest Creation

Test the manifest system:

```bash
# Test 1: Install first package
@acp.package-install https://github.com/test/acp-test.git

# Verify:
# - agent/manifest.yaml created
# - Package entry added
# - Files tracked with versions
# - Checksums calculated

# Test 2: Install second package
@acp.package-install https://github.com/test/acp-test2.git

# Verify:
# - Manifest updated (not overwritten)
# - Second package added
# - First package still present

# Test 3: Reinstall same package
@acp.package-install https://github.com/test/acp-test.git

# Verify:
# - Conflict detected
# - User prompted
# - Manifest updated if overwritten
```

### 7. Implement Manifest Validation

**✅ COMPLETED**: Implemented in `agent/scripts/acp.common.sh`.  

**Implementation Notes**:
- `validate_manifest()` function available in `acp.common.sh`
- Uses `acp.yaml.sh` parser for validation
- Checks required fields (manifest_version, package metadata)
- Returns 0 if valid, 1 if invalid

See [`agent/scripts/acp.common.sh`](../scripts/acp.common.sh) for implementation.

### 8. Document Manifest Format

Update `commands/acp.package-install.md` to document manifest:

```markdown
## Manifest Tracking

When you install a package, `@acp.package-install` creates or updates `agent/manifest.yaml` to track:

- Package source (GitHub URL)
- Package version
- Git commit hash
- Installation timestamp
- Installed files with individual versions
- File checksums for modification detection

This enables:
- Smart updates (only changed files)
- Conflict detection (modified files)
- Team collaboration (commit manifest to git)
- Reproducible setups (install from manifest)
```

---

## Verification

- [ ] `agent/manifest.yaml` created on first install
- [ ] Manifest has correct structure (packages, manifest_version, last_updated)
- [ ] Package metadata tracked (source, version, commit, timestamps)
- [ ] Files tracked with name, version, checksum
- [ ] Checksums calculated correctly (SHA-256)
- [ ] Multiple packages can be tracked in same manifest
- [ ] Manifest validation works
- [ ] Reinstalling package updates manifest (not duplicates)
- [ ] Documentation updated
- [ ] No errors during installation

---

## Files to Create

1. `agent/manifest.template.yaml` - Manifest template
2. Functions in `scripts/package-acp.install.sh`:
   - `init_manifest()`
   - `calculate_checksum()`
   - `add_package_to_manifest()`
   - `add_file_to_manifest()`
   - `parse_package_metadata()`
   - `get_file_version()`
   - `validate_manifest()`

---

## Files to Modify

1. `scripts/package-acp.install.sh` - Add manifest writing
2. `commands/acp.package-install.md` - Document manifest

---

## Testing Checklist

- [ ] Install package creates manifest
- [ ] Manifest has correct YAML structure
- [ ] Package metadata is accurate
- [ ] File versions extracted from package.yaml
- [ ] Checksums calculated correctly
- [ ] Second package installation updates manifest
- [ ] Reinstalling package updates (not duplicates)
- [ ] Manifest validation catches errors
- [ ] Works with packages that have no package.yaml (graceful degradation)

---

## Common Issues

### Issue 1: acp.yaml.sh limitations
**Issue**: acp.yaml.sh doesn't support complex array queries  
**Solution**: Use awk/grep for array parsing (see `get_file_version()` implementation)  

### Issue 2: Checksum mismatch on Windows
**Issue**: Line ending differences (CRLF vs LF)  
**Solution**: Normalize line endings before checksum calculation  

### Issue 3: Manifest becomes invalid YAML
**Issue**: Manual edits or script errors corrupt manifest  
**Solution**: Use `validate_manifest()` before operations, keep backups  

### Issue 4: acp.common.sh not found
**Issue**: Script can't find acp.common.sh  
**Solution**: Ensure acp.common.sh is in same directory, use `. "$(dirname "$0")/acp.common.sh"`  

---

## Related Tasks

- Task 6: Selective Installation (uses manifest)
- Task 7: Update System (reads manifest)
- Task 8: Package List (reads manifest)

---

**Status**: Ready to implement  
**Priority**: High (foundation for all other tasks)  
**Estimated Effort**: 6-8 hours  
