# Task 10: Package Info Command

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 5 (Manifest System)  
**Status**: Not Started  
**Priority**: Low  

---

## Objective

Implement `@acp.package-info` command to display detailed information about an installed package, including all files, versions, modification status, and metadata.

---

## Context

Users need a way to inspect package details, see which files are installed, check for local modifications, and view package metadata. This command provides comprehensive package information for troubleshooting and verification.

---

## Steps

### 1. Create Info Script

Create `scripts/package-info.sh`:

```bash
#!/bin/bash
# Package info script

PACKAGE_NAME=$1

if [ -z "$PACKAGE_NAME" ]; then
  echo "Error: Package name required"
  echo "Usage: @acp.package-info <package-name>"
  exit 1
fi

# Check if package is installed
if ! yq eval ".packages | has(\"${PACKAGE_NAME}\")" agent/manifest.yaml | grep -q "true"; then
  echo "Error: Package '$PACKAGE_NAME' is not installed"
  exit 1
fi

# Get package metadata
source=$(yq eval ".packages.${PACKAGE_NAME}.source" agent/manifest.yaml)
version=$(yq eval ".packages.${PACKAGE_NAME}.package_version" agent/manifest.yaml)
commit=$(yq eval ".packages.${PACKAGE_NAME}.commit" agent/manifest.yaml)
installed_at=$(yq eval ".packages.${PACKAGE_NAME}.installed_at" agent/manifest.yaml)
updated_at=$(yq eval ".packages.${PACKAGE_NAME}.updated_at" agent/manifest.yaml)

# Display header
echo "📦 $PACKAGE_NAME ($version)"
echo ""
echo "Source: $source"
echo "Commit: $commit"
echo "Installed: $installed_at"
echo "Updated: $updated_at"
echo ""

# Fetch description from package.yaml if available
description=$(curl -s "https://raw.githubusercontent.com/${source#https://github.com/}/main/package.yaml" | yq eval '.description' -)
if [ -n "$description" ] && [ "$description" != "null" ]; then
  echo "Description:"
  echo "  $description"
  echo ""
fi

# List installed files
echo "Contents:"
echo ""

# Patterns
patterns=$(yq eval ".packages.${PACKAGE_NAME}.installed.patterns" agent/manifest.yaml)
if [ "$patterns" != "null" ]; then
  patterns_count=$(yq eval ".packages.${PACKAGE_NAME}.installed.patterns | length" agent/manifest.yaml)
  echo "  Patterns ($patterns_count):"
  
  for i in $(seq 0 $((patterns_count - 1))); do
    name=$(yq eval ".packages.${PACKAGE_NAME}.installed.patterns[$i].name" agent/manifest.yaml)
    version=$(yq eval ".packages.${PACKAGE_NAME}.installed.patterns[$i].version" agent/manifest.yaml)
    modified=$(yq eval ".packages.${PACKAGE_NAME}.installed.patterns[$i].modified" agent/manifest.yaml)
    
    if [ "$modified" == "true" ]; then
      echo "    - $name (v$version) [MODIFIED]"
    else
      echo "    - $name (v$version)"
    fi
  done
  echo ""
fi

# Commands
commands=$(yq eval ".packages.${PACKAGE_NAME}.installed.commands" agent/manifest.yaml)
if [ "$commands" != "null" ]; then
  commands_count=$(yq eval ".packages.${PACKAGE_NAME}.installed.commands | length" agent/manifest.yaml)
  echo "  Commands ($commands_count):"
  
  for i in $(seq 0 $((commands_count - 1))); do
    name=$(yq eval ".packages.${PACKAGE_NAME}.installed.commands[$i].name" agent/manifest.yaml)
    version=$(yq eval ".packages.${PACKAGE_NAME}.installed.commands[$i].version" agent/manifest.yaml)
    modified=$(yq eval ".packages.${PACKAGE_NAME}.installed.commands[$i].modified" agent/manifest.yaml)
    
    if [ "$modified" == "true" ]; then
      echo "    - $name (v$version) [MODIFIED]"
    else
      echo "    - $name (v$version)"
    fi
  done
  echo ""
fi

# Designs
designs=$(yq eval ".packages.${PACKAGE_NAME}.installed.designs" agent/manifest.yaml)
if [ "$designs" != "null" ]; then
  designs_count=$(yq eval ".packages.${PACKAGE_NAME}.installed.designs | length" agent/manifest.yaml)
  echo "  Designs ($designs_count):"
  
  for i in $(seq 0 $((designs_count - 1))); do
    name=$(yq eval ".packages.${PACKAGE_NAME}.installed.designs[$i].name" agent/manifest.yaml)
    version=$(yq eval ".packages.${PACKAGE_NAME}.installed.designs[$i].version" agent/manifest.yaml)
    modified=$(yq eval ".packages.${PACKAGE_NAME}.installed.designs[$i].modified" agent/manifest.yaml)
    
    if [ "$modified" == "true" ]; then
      echo "    - $name (v$version) [MODIFIED]"
    else
      echo "    - $name (v$version)"
    fi
  done
  echo ""
fi

# Count modified files
modified_count=$(yq eval ".packages.${PACKAGE_NAME}.installed | .. | select(has(\"modified\")) | select(.modified == true)" agent/manifest.yaml | grep "modified: true" | wc -l)

if [ $modified_count -gt 0 ]; then
  echo "Modified Files: $modified_count"
fi
```

### 2. Create Command Documentation

Create `commands/acp.package-info.md`

### 3. Test Info Command

```bash
# Test with installed package
@acp.package-info firebase

# Test with non-existent package
@acp.package-info nonexistent

# Test with modified files
# (modify a file first)
@acp.package-info firebase
```

---

## Verification

- [ ] Shows package metadata (source, version, commit, dates)
- [ ] Lists all installed files with versions
- [ ] Indicates modified files with [MODIFIED] tag
- [ ] Shows file counts by type
- [ ] Fetches description from remote package.yaml
- [ ] Handles non-existent packages gracefully
- [ ] Handles packages with no files
- [ ] Output is well-formatted and readable

---

**Status**: Ready to implement  
**Priority**: Low  
**Estimated Effort**: 2-3 hours  
