# Task 15: Namespace Utilities

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Add namespace detection, inference, and validation utilities to acp.common.sh. These utilities enable context-aware behavior in entity creation commands and validation.

---

## Context

From clarifications:
- Detect if in package (package.yaml exists) vs project
- Infer namespace from package.yaml, directory name, git remote
- Validate namespace format and reserved names
- Reserved namespaces: @acp, @local

---

## Steps

### 1. Add is_acp_package() Function

Detect if current directory is an ACP package:

**Implementation**:
```bash
# Check if current directory is an ACP package
# Usage: if is_acp_package; then ...
# Returns: 0 if package.yaml exists, 1 otherwise
is_acp_package() {
    [ -f "package.yaml" ]
}
```

**Expected Outcome**: Function detects package directories  

### 2. Add infer_namespace() Function

Infer package namespace from multiple sources:

**Implementation**:
```bash
# Infer package namespace
# Usage: namespace=$(infer_namespace)
# Returns: namespace string or empty if can't infer
infer_namespace() {
    local namespace=""
    
    # Priority 1: Read from package.yaml
    if [ -f "package.yaml" ]; then
        namespace=$(yaml_get "package.yaml" "name")
        if [ -n "$namespace" ]; then
            echo "$namespace"
            return 0
        fi
    fi
    
    # Priority 2: Parse from directory name (acp-{namespace})
    local dir_name=$(basename "$PWD")
    if [[ "$dir_name" =~ ^acp-(.+)$ ]]; then
        namespace="${BASH_REMATCH[1]}"
        echo "$namespace"
        return 0
    fi
    
    # Priority 3: Parse from git remote URL
    if git remote get-url origin >/dev/null 2>&1; then
        local remote_url=$(git remote get-url origin)
        if [[ "$remote_url" =~ acp-([a-z0-9-]+)(\.git)?$ ]]; then
            namespace="${BASH_REMATCH[1]}"
            echo "$namespace"
            return 0
        fi
    fi
    
    # Could not infer
    return 1
}
```

**Expected Outcome**: Function infers namespace from available sources  

### 3. Add validate_namespace() Function

Validate namespace format and check reserved names:

**Implementation**:
```bash
# Validate namespace format
# Usage: if validate_namespace "firebase"; then ...
# Returns: 0 if valid, 1 if invalid
validate_namespace() {
    local namespace="$1"
    
    # Check format (lowercase, alphanumeric, hyphens)
    if ! echo "$namespace" | grep -qE '^[a-z0-9-]+$'; then
        echo "${RED}Error: Namespace must be lowercase, alphanumeric, and hyphens only${NC}" >&2
        return 1
    fi
    
    # Check reserved names
    case "$namespace" in
        acp|local)
            echo "${RED}Error: Namespace '$namespace' is reserved${NC}" >&2
            return 1
            ;;
    esac
    
    return 0
}
```

**Expected Outcome**: Function validates namespace format and reserved names  

### 4. Add get_namespace_for_file() Function

Get appropriate namespace for file creation:

**Implementation**:
```bash
# Get namespace for file creation
# Usage: namespace=$(get_namespace_for_file)
# Returns: package namespace or "local" for non-packages
get_namespace_for_file() {
    if is_acp_package; then
        local namespace=$(infer_namespace)
        if [ -n "$namespace" ]; then
            echo "$namespace"
        else
            # In package but can't infer, ask user
            read -p "Package namespace: " namespace
            if validate_namespace "$namespace"; then
                echo "$namespace"
            else
                return 1
            fi
        fi
    else
        # Not a package, use local namespace
        echo "local"
    fi
}
```

**Expected Outcome**: Function returns appropriate namespace for context  

### 5. Add validate_namespace_consistency() Function

Check if inferred namespace matches package.yaml:

**Implementation**:
```bash
# Validate namespace consistency across sources
# Usage: if validate_namespace_consistency; then ...
# Returns: 0 if consistent, 1 if conflicts found
validate_namespace_consistency() {
    if ! is_acp_package; then
        return 0  # Not a package, no consistency to check
    fi
    
    local from_yaml=$(yaml_get "package.yaml" "name")
    local from_dir=$(basename "$PWD" | sed 's/^acp-//')
    local from_remote=""
    
    if git remote get-url origin >/dev/null 2>&1; then
        local remote_url=$(git remote get-url origin)
        if [[ "$remote_url" =~ acp-([a-z0-9-]+)(\.git)?$ ]]; then
            from_remote="${BASH_REMATCH[1]}"
        fi
    fi
    
    # Check for conflicts
    if [ -n "$from_yaml" ] && [ -n "$from_dir" ] && [ "$from_yaml" != "$from_dir" ]; then
        echo "${YELLOW}Warning: Namespace mismatch${NC}" >&2
        echo "  package.yaml: $from_yaml" >&2
        echo "  directory: $from_dir" >&2
        return 1
    fi
    
    if [ -n "$from_yaml" ] && [ -n "$from_remote" ] && [ "$from_yaml" != "$from_remote" ]; then
        echo "${YELLOW}Warning: Namespace mismatch${NC}" >&2
        echo "  package.yaml: $from_yaml" >&2
        echo "  git remote: $from_remote" >&2
        return 1
    fi
    
    return 0
}
```

**Expected Outcome**: Function detects namespace conflicts  

### 6. Test Namespace Utilities

Test all namespace functions:

**Actions**:
- Test is_acp_package() in package and non-package directories
- Test infer_namespace() with various scenarios
- Test validate_namespace() with valid/invalid names
- Test reserved name rejection
- Test namespace consistency checking

**Expected Outcome**: All functions work correctly  

### 7. Update Documentation

Document namespace utilities:

**Actions**:
- Add function documentation to common.sh
- Update design doc with implementation details
- Add usage examples

**Expected Outcome**: Utilities documented  

---

## Verification

- [ ] agent/schemas/ directory created
- [ ] package.schema.yaml created
- [ ] acp.yaml-validate.sh implemented
- [ ] is_acp_package() function works
- [ ] infer_namespace() function works
- [ ] validate_namespace() function works
- [ ] get_namespace_for_file() function works
- [ ] validate_namespace_consistency() function works
- [ ] All functions tested
- [ ] Documentation updated

---

**Next Task**: [Task 16: README Update Utilities](task-16-readme-update-utilities.md)  
**Related Design Docs**: [ACP Package Development System](../design/acp-package-development-system.md)  
