# Task 67: Script-Command Binding - Validation Logic

**Milestone**: [M3 - ACP Package Management System](../../milestones/milestone-3-package-management.md)  
**Estimated Time**: 1-2 hours  
**Dependencies**: Task 65 (Schema and Templates), Task 66 (Installation Logic)  
**Status**: Not Started  

---

## Objective

Implement validation logic in acp.package-validate.sh to ensure script declarations in command frontmatter match package.yaml, and all declared scripts exist in the scripts section.

---

## Context

This is Phase 3 of the script-command binding system. With installation logic in place (Task 66), this task adds validation to catch inconsistencies.

**Design Document**: [`agent/design/local.script-command-binding.md`](../../design/local.script-command-binding.md)  

---

## Steps

### 1. Add validate_script_dependencies() Function

Create validation function in acp.package-validate.sh:

**Actions**:
- Add new validation function after existing validations
- Parse command files for **Scripts**: field
- Compare with package.yaml scripts arrays
- Check all scripts exist in scripts section

**Implementation**:
```bash
validate_script_dependencies() {
  echo "Validating script-command bindings..."
  
  local errors=0
  
  # Get all commands from package.yaml
  local commands=$(yaml_get_nested "contents.commands" | jq -r '.[].name' 2>/dev/null)
  
  for cmd in $commands; do
    local cmd_file="agent/commands/$cmd"
    
    if [ ! -f "$cmd_file" ]; then
      continue  # File existence checked elsewhere
    fi
    
    # Get scripts from frontmatter
    local frontmatter_scripts=$(grep "^\*\*Scripts\*\*:" "$cmd_file" | \
      awk -F': ' '{print $2}' | tr ',' '\n' | tr -d ' ' | sort)
    
    # Get scripts from package.yaml
    local yaml_scripts=$(yaml_get_nested "contents.commands" | \
      jq -r ".[] | select(.name==\"$cmd\") | .scripts[]" 2>/dev/null | sort)
    
    # Compare
    if [ "$frontmatter_scripts" != "$yaml_scripts" ]; then
      echo "  ❌ $cmd: Scripts mismatch between frontmatter and package.yaml"
      echo "     Frontmatter: $(echo $frontmatter_scripts | tr '\n' ', ')"
      echo "     package.yaml: $(echo $yaml_scripts | tr '\n' ', ')"
      ((errors++))
    fi
    
    # Verify all scripts exist in scripts section
    for script in $frontmatter_scripts; do
      local script_exists=$(yaml_get_nested "contents.scripts" | \
        jq -r ".[] | select(.name==\"$script\") | .name" 2>/dev/null)
      
      if [ -z "$script_exists" ]; then
        echo "  ❌ $cmd declares $script, but it's not in scripts section"
        ((errors++))
      fi
    done
  done
  
  if [ $errors -eq 0 ]; then
    echo "  ✓ Script-command bindings are consistent"
  fi
  
  return $errors
}
```

### 2. Integrate into Main Validation Flow

Add to main validation sequence:

**Actions**:
- Call validate_script_dependencies() in main validation
- Add to validation score calculation
- Include in final report

### 3. Add Auto-Fix Suggestions

Provide fixable suggestions for common issues:

**Actions**:
- If frontmatter missing Scripts field: Suggest adding it
- If package.yaml missing scripts array: Suggest adding it
- If mismatch: Show diff and suggest which to update

### 4. Test Validation

Create test scenarios:

**Actions**:
- Test with matching declarations (should pass)
- Test with frontmatter missing (should error)
- Test with package.yaml missing (should error)
- Test with mismatch (should error with clear message)
- Test with missing script in scripts section (should error)

---

## Verification

- [ ] validate_script_dependencies() function created
- [ ] Integrated into main validation flow
- [ ] Checks frontmatter ↔ package.yaml consistency
- [ ] Verifies scripts exist in scripts section
- [ ] Clear error messages with suggestions
- [ ] Auto-fix suggestions provided
- [ ] Test scenarios pass
- [ ] No syntax errors

---

## Expected Outcome

**Validation Output**:
```
Validating script-command bindings...
  ✓ acp.project-set.md: Scripts match (3 scripts)
  ✓ acp.project-list.md: Scripts match (3 scripts)
  ❌ firebase.deploy.md: Scripts mismatch
     Frontmatter: firebase.deploy.sh, acp.common.sh
     package.yaml: firebase.deploy.sh
  ❌ firebase.init.md: Missing Scripts field in frontmatter

Fixable Issues:
  - Add Scripts field to firebase.init.md frontmatter
  - Add acp.common.sh to firebase.deploy.md scripts array in package.yaml
```

---

**Next Task**: Task 68 - Update Existing Commands with Scripts Field  
