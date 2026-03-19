# Task 9: Package Remove Command

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 5 (Manifest System)  
**Status**: Not Started  
**Priority**: Medium  

---

## Objective

Implement `@acp.package-remove` command to remove installed packages, delete their files, and update the manifest accordingly, with options to keep locally modified files.

---

## Context

Users need the ability to remove packages they no longer need. The removal process should clean up all installed files, update the manifest, and optionally preserve files that were modified locally.

---

## Steps

### 1. Create Remove Script

Create `scripts/package-remove.sh`:

```bash
#!/bin/bash
# Package remove script

PACKAGE_NAME=$1
AUTO_CONFIRM=false
KEEP_MODIFIED=false
BACKUP=false

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes) AUTO_CONFIRM=true; shift ;;
    --keep-modified) KEEP_MODIFIED=true; shift ;;
    --backup) BACKUP=true; shift ;;
    *) PACKAGE_NAME=$1; shift ;;
  esac
done

if [ -z "$PACKAGE_NAME" ]; then
  echo "Error: Package name required"
  echo "Usage: @acp.package-remove <package-name> [options]"
  exit 1
fi

# Check if package is installed
if ! yq eval ".packages | has(\"${PACKAGE_NAME}\")" agent/manifest.yaml | grep -q "true"; then
  echo "Error: Package '$PACKAGE_NAME' is not installed"
  exit 1
fi

# Get installed files
patterns=$(yq eval ".packages.${PACKAGE_NAME}.installed.patterns[].name" agent/manifest.yaml)
commands=$(yq eval ".packages.${PACKAGE_NAME}.installed.commands[].name" agent/manifest.yaml)
designs=$(yq eval ".packages.${PACKAGE_NAME}.installed.designs[].name" agent/manifest.yaml)

# Count files
patterns_count=$(echo "$patterns" | wc -w)
commands_count=$(echo "$commands" | wc -w)
designs_count=$(echo "$designs" | wc -w)
total=$((patterns_count + commands_count + designs_count))

# Show what will be removed
echo "⚠️  This will remove:"
echo "  - $patterns_count pattern(s)"
echo "  - $commands_count command(s)"
echo "  - $designs_count design(s)"
echo ""

# Check for modified files
modified_files=()
for file in $patterns; do
  if is_file_modified "$PACKAGE_NAME" "patterns" "$file"; then
    modified_files+=("patterns/$file")
  fi
done
# Check commands and designs similarly...

if [ ${#modified_files[@]} -gt 0 ]; then
  echo "⚠️  Modified files:"
  for file in "${modified_files[@]}"; do
    echo "  - $file"
  done
  echo ""
  
  if [ "$KEEP_MODIFIED" == true ]; then
    echo "Modified files will be kept (--keep-modified)"
  fi
fi

# Confirm removal
if [ "$AUTO_CONFIRM" == false ]; then
  read -p "Continue? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Removal cancelled"
    exit 0
  fi
fi

# Create backup if requested
if [ "$BACKUP" == true ]; then
  backup_dir="agent/.backup/${PACKAGE_NAME}-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"
  
  for file in $patterns; do
    cp "agent/patterns/$file" "$backup_dir/" 2>/dev/null
  done
  # Backup commands and designs similarly...
  
  echo "✓ Backup created: $backup_dir"
fi

# Remove files
removed_count=0
kept_count=0

for file in $patterns; do
  if echo "${modified_files[@]}" | grep -q "patterns/$file" && [ "$KEEP_MODIFIED" == true ]; then
    echo "⊙ Kept patterns/$file (modified)"
    ((kept_count++))
  else
    rm "agent/patterns/$file"
    echo "✓ Removed patterns/$file"
    ((removed_count++))
  fi
done

# Remove commands and designs similarly...

# Remove package from manifest
yq eval -i "del(.packages.${PACKAGE_NAME})" agent/manifest.yaml
yq eval -i ".last_updated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" agent/manifest.yaml

echo ""
echo "✅ Removal complete!"
echo "Removed: $removed_count file(s)"
if [ $kept_count -gt 0 ]; then
  echo "Kept: $kept_count file(s) (modified)"
fi
```

### 2. Create Command Documentation

Create `commands/acp.package-remove.md`

### 3. Test Remove Scenarios

```bash
# Test 1: Remove package
@acp.package-remove firebase

# Test 2: Remove with auto-confirm
@acp.package-remove firebase -y

# Test 3: Keep modified files
@acp.package-remove firebase --keep-modified

# Test 4: Create backup
@acp.package-remove firebase --backup
```

---

## Verification

- [ ] Removes all package files
- [ ] Updates manifest (removes package entry)
- [ ] Prompts for confirmation
- [ ] `-y` flag skips confirmation
- [ ] `--keep-modified` preserves modified files
- [ ] `--backup` creates backup before removal
- [ ] Shows summary of what was removed
- [ ] Handles non-existent packages gracefully

---

**Status**: Ready to implement  
**Priority**: Medium  
**Estimated Effort**: 3-4 hours  
