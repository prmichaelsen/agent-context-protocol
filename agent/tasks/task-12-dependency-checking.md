# Task 12: Dependency Checking

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 5 (Manifest System)  
**Status**: Not Started  
**Priority**: Medium  

---

## Objective

Implement project dependency compatibility checking to validate that the user's project has compatible versions of required dependencies (npm/pip/cargo packages) before installing ACP packages.

---

## Context

ACP packages often contain patterns specific to certain library versions (e.g., Weaviate v2 vs v3, Firebase Admin SDK v11 vs v12). The dependency checker validates compatibility and warns users about mismatches, preventing confusion from using incompatible patterns.

---

## Steps

### 1. Detect Project Package Manager

Add function to detect package manager:

```bash
# Detect package manager
detect_package_manager() {
  if [ -f "package.json" ]; then
    echo "npm"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "pip"
  elif [ -f "Cargo.toml" ]; then
    echo "cargo"
  elif [ -f "go.mod" ]; then
    echo "go"
  else
    echo "unknown"
  fi
}
```

### 2. Check Installed Dependencies

Add functions to check dependencies:

```bash
# Check npm dependency
check_npm_dependency() {
  local dep_name=$1
  local required_version=$2
  
  if [ ! -f "package.json" ]; then
    return 1
  fi
  
  # Get installed version
  local installed_version=$(jq -r ".dependencies.\"${dep_name}\" // .devDependencies.\"${dep_name}\" // \"not-installed\"" package.json)
  
  if [ "$installed_version" == "not-installed" ]; then
    echo "not-installed"
    return 1
  fi
  
  # Remove ^ ~ >= etc for comparison
  installed_version=$(echo "$installed_version" | sed 's/[\^~>=<]//g')
  
  echo "$installed_version"
  return 0
}

# Check pip dependency
check_pip_dependency() {
  local dep_name=$1
  local required_version=$2
  
  # Check requirements.txt
  if [ -f "requirements.txt" ]; then
    grep "^${dep_name}" requirements.txt | cut -d'=' -f2
    return $?
  fi
  
  # Check pyproject.toml
  if [ -f "pyproject.toml" ]; then
    grep "${dep_name}" pyproject.toml | grep -oP '\d+\.\d+\.\d+'
    return $?
  fi
  
  return 1
}

# Check cargo dependency
check_cargo_dependency() {
  local dep_name=$1
  local required_version=$2
  
  if [ ! -f "Cargo.toml" ]; then
    return 1
  fi
  
  grep "^${dep_name}" Cargo.toml | grep -oP '\d+\.\d+\.\d+'
  return $?
}
```

### 3. Validate Compatibility

Add compatibility validation:

```bash
# Validate project dependencies
validate_project_dependencies() {
  local package_yaml=$1
  local package_manager=$(detect_package_manager)
  
  if [ "$package_manager" == "unknown" ]; then
    echo "⚠️  Could not detect package manager"
    return 0
  fi
  
  echo "Checking project dependencies ($package_manager)..."
  echo ""
  
  # Get required dependencies from package.yaml
  local required_deps=$(yq eval ".requires.${package_manager} | to_entries | .[]" "$package_yaml")
  
  if [ -z "$required_deps" ] || [ "$required_deps" == "null" ]; then
    echo "✓ No project dependencies required"
    return 0
  fi
  
  local has_incompatible=false
  
  # Check each dependency
  while IFS= read -r dep_entry; do
    local dep_name=$(echo "$dep_entry" | yq eval '.key' -)
    local required_version=$(echo "$dep_entry" | yq eval '.value' -)
    
    # Check if installed
    local installed_version=""
    case $package_manager in
      npm)
        installed_version=$(check_npm_dependency "$dep_name" "$required_version")
        ;;
      pip)
        installed_version=$(check_pip_dependency "$dep_name" "$required_version")
        ;;
      cargo)
        installed_version=$(check_cargo_dependency "$dep_name" "$required_version")
        ;;
    esac
    
    if [ -z "$installed_version" ] || [ "$installed_version" == "not-installed" ]; then
      echo "  ✗ $dep_name: not installed (requires $required_version)"
      has_incompatible=true
    else
      # Simple version check (can be enhanced with semver)
      echo "  ✓ $dep_name: $installed_version (requires $required_version)"
    fi
  done <<< "$required_deps"
  
  echo ""
  
  if [ "$has_incompatible" == true ]; then
    echo "⚠️  Some dependencies are missing or incompatible"
    echo ""
    echo "Recommendation:"
    echo "  Install missing dependencies before using this package"
    echo ""
    read -p "Continue installation anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 1
    fi
  fi
  
  return 0
}
```

### 4. Integrate into Installation Flow

Update `scripts/package-acp.install.sh`:

```bash
# In main installation flow, after parsing package.yaml:
if ! validate_project_dependencies "temp-repo/package.yaml"; then
  echo "Installation cancelled due to dependency issues"
  rm -rf temp-repo
  exit 1
fi
```

### 5. Add Semver Validation (Optional Enhancement)

```bash
# Validate semver range (requires semver tool or custom logic)
validate_semver() {
  local installed=$1
  local required=$2
  
  # Simple checks for common patterns
  if [[ $required == ^* ]]; then
    # Caret range: ^1.0.0 allows 1.x.x
    local major=$(echo "$required" | cut -d. -f1 | sed 's/\^//')
    local installed_major=$(echo "$installed" | cut -d. -f1)
    
    if [ "$major" == "$installed_major" ]; then
      return 0
    else
      return 1
    fi
  elif [[ $required == >=* ]]; then
    # Greater than or equal
    required_clean=$(echo "$required" | sed 's/>=//')
    # Use sort -V for version comparison
    if [ "$(printf '%s\n' "$required_clean" "$installed" | sort -V | head -n1)" == "$required_clean" ]; then
      return 0
    else
      return 1
    fi
  fi
  
  # Default: exact match
  if [ "$installed" == "$required" ]; then
    return 0
  else
    return 1
  fi
}
```

### 6. Test Dependency Checking

```bash
# Test 1: Compatible dependencies
# (project has firebase-admin ^12.0.0)
@acp.package-install https://github.com/test/acp-firebase.git
# Should succeed with ✓ marks

# Test 2: Missing dependency
# (project missing weaviate-client)
@acp.package-install https://github.com/test/acp-weaviate.git
# Should warn and prompt

# Test 3: Incompatible version
# (project has weaviate-client 2.x, package requires 3.x)
@acp.package-install https://github.com/test/acp-weaviate-v3.git
# Should warn about version mismatch

# Test 4: No dependencies required
@acp.package-install https://github.com/test/acp-simple.git
# Should skip dependency check
```

---

## Verification

- [ ] Detects package manager (npm/pip/cargo/go)
- [ ] Reads required dependencies from package.yaml
- [ ] Checks if dependencies are installed
- [ ] Validates version compatibility
- [ ] Warns about missing dependencies
- [ ] Warns about incompatible versions
- [ ] Prompts user to continue or cancel
- [ ] Works with multiple package managers
- [ ] Handles projects with no package manager
- [ ] Provides clear recommendations

---

## Files to Create

1. `scripts/package-search.sh` - Search implementation
2. `commands/acp.package-search.md` - Command documentation

---

## Files to Modify

1. `scripts/package-acp.install.sh` - Add dependency checking

---

**Status**: Ready to implement  
**Priority**: Medium  
**Estimated Effort**: 3-4 hours  
