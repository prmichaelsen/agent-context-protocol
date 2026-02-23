# Task 61: Schema and Validation Enhancement

**Milestone**: M8 - Experimental Features System
**Estimated Time**: 2-3 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Update the package schema to support the `experimental` field and enhance validation to check consistency between package.yaml and file metadata.

---

## Context

The experimental features system requires:
1. Schema support for optional `experimental: true` field in contents arrays
2. Validation to ensure package.yaml and file metadata stay in sync
3. Clear error messages when marking is inconsistent

This task lays the foundation for the entire experimental features system.

---

## Steps

### 1. Update package.schema.yaml

Add `experimental` field to all content types:

**File**: [`agent/schemas/package.schema.yaml`](../../schemas/package.schema.yaml)

**Changes**:
```yaml
contents:
  type: object
  properties:
    commands:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
            pattern: "^[a-z0-9-]+\\.md$"
          description:
            type: string
          experimental:
            type: boolean
            default: false  # Optional field
        required: [name, description]
    
    patterns:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
          description:
            type: string
          experimental:
            type: boolean
            default: false
        required: [name, description]
    
    designs:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
          description:
            type: string
          experimental:
            type: boolean
            default: false
        required: [name, description]
    
    scripts:
      type: array
      items:
        type: object
        properties:
          name:
            type: string
          description:
            type: string
          experimental:
            type: boolean
            default: false
        required: [name, description]
```

### 2. Add Consistency Validation Function

**File**: [`agent/scripts/acp.package-validate.sh`](../../scripts/acp.package-validate.sh)

**Add new function**:
```bash
validate_experimental_consistency() {
  echo "Validating experimental feature consistency..."
  
  local errors=0
  
  # Check each content type
  for type in commands patterns designs scripts; do
    local count=$(yaml_get "contents.${type} | length")
    
    for ((i=0; i<count; i++)); do
      local file_name=$(yaml_get "contents.${type}[$i].name")
      local is_experimental=$(yaml_get "contents.${type}[$i].experimental")
      
      if [[ "$is_experimental" == "true" ]]; then
        # Check if file has Status: Experimental in metadata
        local file_path="agent/${type}/${file_name}"
        
        if [[ ! -f "$file_path" ]]; then
          continue  # File existence checked elsewhere
        fi
        
        if ! grep -q "^\*\*Status\*\*: Experimental" "$file_path"; then
          echo "  ${RED}✗${NC} ${file_path}: Marked experimental in package.yaml but missing 'Status: Experimental' in file"
          ((errors++))
        fi
      else
        # Check if file has Status: Experimental but not marked in package.yaml
        local file_path="agent/${type}/${file_name}"
        
        if [[ -f "$file_path" ]] && grep -q "^\*\*Status\*\*: Experimental" "$file_path"; then
          echo "  ${RED}✗${NC} ${file_path}: Has 'Status: Experimental' but not marked in package.yaml"
          ((errors++))
        fi
      fi
    done
  done
  
  if [[ $errors -eq 0 ]]; then
    echo "  ${GREEN}✓${NC} Experimental marking is consistent"
  fi
  
  return $errors
}
```

### 3. Integrate into Main Validation Flow

**File**: [`agent/scripts/acp.package-validate.sh`](../../scripts/acp.package-validate.sh)

**Add to main validation**:
```bash
# After existing validation checks
validate_experimental_consistency
EXPERIMENTAL_ERRORS=$?
TOTAL_ERRORS=$((TOTAL_ERRORS + EXPERIMENTAL_ERRORS))
```

### 4. Test Validation

Create test scenarios:

**Test 1**: Consistent marking (should pass)
- package.yaml: `experimental: true`
- File: `**Status**: Experimental`

**Test 2**: Missing file metadata (should fail)
- package.yaml: `experimental: true`
- File: No Status field or `**Status**: Active`

**Test 3**: Missing package.yaml field (should fail)
- package.yaml: No experimental field or `experimental: false`
- File: `**Status**: Experimental`

**Test 4**: Both unmarked (should pass)
- package.yaml: No experimental field
- File: `**Status**: Active`

---

## Verification

- [ ] Schema updated with experimental field for all content types
- [ ] experimental field is optional (defaults to false)
- [ ] validate_experimental_consistency() function added
- [ ] Function integrated into main validation flow
- [ ] Test 1 (consistent marking) passes validation
- [ ] Test 2 (missing file metadata) fails with clear error
- [ ] Test 3 (missing package.yaml field) fails with clear error
- [ ] Test 4 (both unmarked) passes validation
- [ ] Error messages are clear and actionable
- [ ] No syntax errors in validation script

---

## Expected Output

### Console Output (Validation Pass)
```
Validating experimental feature consistency...
  ✓ Experimental marking is consistent
```

### Console Output (Validation Fail)
```
Validating experimental feature consistency...
  ✗ agent/commands/test-command.md: Marked experimental in package.yaml but missing 'Status: Experimental' in file
  ✗ agent/patterns/test-pattern.md: Has 'Status: Experimental' but not marked in package.yaml

Validation failed with 2 errors
```

---

## Notes

- Schema changes are backward compatible (experimental defaults to false)
- Validation checks both directions (package.yaml → file and file → package.yaml)
- Clear error messages help package maintainers fix issues quickly
- This task enables all subsequent experimental features functionality

---

**Next Task**: [Task 62 - Installation Filtering](task-62-installation-filtering.md)
**Related Design**: [`agent/design/local.experimental-features-system.md`](../../design/local.experimental-features-system.md)
