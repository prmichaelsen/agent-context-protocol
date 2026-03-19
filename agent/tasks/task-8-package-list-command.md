# Task 8: Package List Command

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 5 (Manifest System)  
**Status**: Not Started  
**Priority**: Medium  

---

## Objective

Implement `@acp.package-list` command to display installed packages with their versions, installation dates, and file counts.

---

## Steps

### 1. Create List Script

```bash
#!/bin/bash
# scripts/package-list.sh

VERBOSE=false
OUTDATED=false
MODIFIED=false

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose) VERBOSE=true; shift ;;
    --outdated) OUTDATED=true; shift ;;
    --modified) MODIFIED=true; shift ;;
    *) shift ;;
  esac
done

# Read manifest
if [ ! -f "agent/manifest.yaml" ]; then
  echo "No packages installed"
  exit 0
fi

# List packages
echo "📦 Installed ACP Packages"
echo ""

packages=$(yq eval '.packages | keys | .[]' agent/manifest.yaml)

for package in $packages; do
  # Get package info
  version=$(yq eval ".packages.${package}.package_version" agent/manifest.yaml)
  source=$(yq eval ".packages.${package}.source" agent/manifest.yaml)
  installed_at=$(yq eval ".packages.${package}.installed_at" agent/manifest.yaml)
  
  # Count files
  patterns_count=$(yq eval ".packages.${package}.installed.patterns | length" agent/manifest.yaml)
  commands_count=$(yq eval ".packages.${package}.installed.commands | length" agent/manifest.yaml)
  designs_count=$(yq eval ".packages.${package}.installed.designs | length" agent/manifest.yaml)
  total=$((patterns_count + commands_count + designs_count))
  
  echo "$package ($version) - $total files"
  
  if [ "$VERBOSE" == true ]; then
    echo "  Source: $source"
    echo "  Installed: $installed_at"
    echo "  Files: $patterns_count patterns, $commands_count commands, $designs_count designs"
    echo ""
  fi
done
```

### 2. Create Command Documentation

Create `commands/acp.package-list.md`

### 3. Test List Command

```bash
# Test basic list
@acp.package-list

# Test verbose
@acp.package-list --verbose

# Test filters
@acp.package-list --outdated
@acp.package-list --modified
```

---

## Verification

- [ ] Lists all installed packages
- [ ] Shows version and file count
- [ ] `--verbose` shows detailed information
- [ ] `--outdated` shows only packages with updates
- [ ] `--modified` shows only packages with local changes
- [ ] Works with empty manifest
- [ ] Handles missing manifest gracefully

---

**Status**: Ready to implement  
**Priority**: Medium  
**Estimated Effort**: 2-3 hours  
