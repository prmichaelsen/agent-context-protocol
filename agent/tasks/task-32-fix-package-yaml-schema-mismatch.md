# Task 32: Fix package.yaml Schema Mismatch and Add Template

**Milestone**: Future Enhancement  
**Estimated Time**: 4-6 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Enhance the YAML parser to support nested objects and array indexing (e.g., `contents.commands[0].name`), fix validation to use the enhanced parser, and create a `package.template.yaml` file to guide package creators.

---

## Context

**Root Cause Discovered**: The YAML parser (`acp.yaml.sh`) doesn't support array indexing or nested objects!  

**Current Limitation**:
- yaml-parser library says: "Arrays are not supported"
- Can't read `contents.commands[0].name`
- File existence check (lines 125, 143, 161 in acp.package-validate.sh) doesn't work
- Reports "All 0 files in contents exist"

**Why Object Format**:
- Enables tracking entity names and their specifically installed versions
- More structured and extensible for future enhancements
- Consistent with manifest.yaml format

**The Fix**:
1. Enhance YAML parser to support nested objects generically
2. Support array indexing: `array[0].field`
3. Support nested paths: `parent.child.array[0].field`
4. Update validation to use enhanced parser
5. Create package.template.yaml showing correct format

---

## Steps

### 1. Verify Scripts Use Object Format

Confirm that scripts expect object format with `.name` field:

**Actions**:
- Check `contents.patterns` usage in acp.package-validate.sh
- Check `contents.commands` usage in acp.package-install.sh
- Check `contents.designs` usage in acp.package-info.sh
- Confirm all scripts expect `{name: "file.md"}` format

**Expected Outcome**: Confirmed scripts use object format  

### 2. Create package.template.yaml

Create template showing correct format:

**File**: `agent/package.template.yaml`  

**Content**:
```yaml
# package.yaml Template
# This file defines an ACP package for distribution

name: package-name
version: 1.0.0
description: Package description (10-200 characters)
author: Author Name
license: MIT
homepage: https://github.com/user/package-name
repository: https://github.com/user/package-name.git

# Release configuration
release:
  branch: main

# Package contents
# List files that will be installed when users install this package
contents:
  patterns:
    - name: namespace.pattern-name.md
  
  commands:
    - name: namespace.command-name.md
  
  designs:
    - name: namespace.design-name.md

# Compatibility requirements
requires:
  acp: ">=2.8.0"

# Tags for package discovery
tags:
  - tag1
  - tag2
```

**Expected Outcome**: Template created with correct format  

### 3. Update Schema Documentation

Update `agent/schemas/package.schema.yaml` to match actual usage:

**If scripts expect objects**:
```yaml
contents:
  type: object
  fields:
    patterns:
      type: array
      item_type: object
      item_fields:
        name:
          type: string
          required: true
```

**If scripts expect simple strings**:
- Update scripts to handle simple strings
- Keep schema as-is

**Expected Outcome**: Schema matches implementation  

### 4. Update acp.package-create.sh

Generate package.yaml with correct format:

```bash
cat > package.yaml << EOF
contents:
  patterns:
    - name: ${namespace}.example-pattern.md
  commands: []
  designs: []
EOF
```

**Expected Outcome**: Generated package.yaml uses correct format  

### 5. Update Installation Scripts

Ensure all scripts handle the format consistently:

**Scripts to check**:
- acp.package-validate.sh
- acp.package-install.sh
- acp.package-info.sh
- acp.package-update.sh

**Expected Outcome**: All scripts use same format  

### 6. Update Documentation

Update command documentation to show correct format:

**Files to update**:
- agent/commands/acp.package-create.md
- agent/design/acp-package-management-system.md
- agent/design/acp-package-development-system.md

**Expected Outcome**: Documentation shows correct format  

### 7. Test with Real Package

Test the corrected format:

**Actions**:
- Create test package with correct format
- Run validation - should read files correctly
- Run installation - should install correctly
- Verify no false warnings

**Expected Outcome**: Format works correctly across all scripts  

---

## Verification

- [ ] Investigated current format usage in all scripts
- [ ] Created package.template.yaml with correct format
- [ ] Updated schema to match implementation
- [ ] Updated acp.package-create.sh to generate correct format
- [ ] Verified all scripts handle format consistently
- [ ] Updated documentation
- [ ] Tested with real package
- [ ] No validation errors with correct format
- [ ] Files read and installed correctly

---

## Expected Output

### Files Created
- `agent/package.template.yaml` - Template showing correct format

### Files Modified
- `agent/schemas/package.schema.yaml` - Updated to match scripts
- `agent/scripts/acp.package-create.sh` - Generate correct format
- `agent/commands/acp.package-create.md` - Document format
- Design documents - Update format examples

### Correct package.yaml Format

```yaml
name: my-package
version: 1.0.0

contents:
  patterns:
    - name: my-package.pattern1.md
    - name: my-package.pattern2.md
  commands:
    - name: my-package.command1.md
  designs: []
```

---

## Common Issues and Solutions

### Issue 1: Scripts still can't read contents

**Symptom**: Validation reports 0 files  

**Solution**: Verify YAML parser can handle the format. Test with acp.yaml.sh directly.  

### Issue 2: Format breaks existing packages

**Symptom**: Old packages stop working  

**Solution**: Add backward compatibility - support both simple strings and objects.  

---

## Resources

- [Package Schema](../schemas/package.schema.yaml)
- [Package Validation Script](../scripts/acp.package-validate.sh)
- [Package Installation Script](../scripts/acp.package-install.sh)

---

## Notes

- This is a critical bug affecting all package creators
- Schema and implementation must match
- Template provides single source of truth
- Backward compatibility may be needed
- All scripts must be updated consistently

---

**Next Task**: TBD  
**Estimated Completion Date**: TBD  
