# Task 13: Pure Bash YAML Library

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: None (MUST be done first)  
**Status**: Not Started  
**Priority**: Critical (Blocking)  

---

## Objective

Integrate or adapt an existing pure bash YAML library to read and write YAML files without external dependencies, ensuring the package management system works on any system with just bash, git, and curl.

---

## Context

The package management system needs to:
1. **Read** `package.yaml` from repositories (simple key-value pairs, arrays, nested objects)
2. **Read/Write** `agent/manifest.yaml` (nested structures, arrays of objects)

Several mature bash YAML libraries exist on GitHub that we can use or adapt.

**Note**: All other tasks (5-12) reference this library and should use its functions instead of direct `yq` calls.  

---

## Steps

### 1. Evaluate Existing Libraries

Research and test these bash YAML libraries:

**Option A: mrbaseman/parse_yaml** ⭐ RECOMMENDED
- URL: https://github.com/mrbaseman/parse_yaml
- License: MIT
- Features: Read YAML, convert to bash variables
- Pros: Simple, well-tested, MIT licensed
- Cons: Read-only (need to add write support)

**Option B: fiftydinar/yaml-parser**
- URL: https://github.com/fiftydinar/yaml-parser
- Features: Read AND write YAML
- Pros: Supports both read and write operations
- Cons: Requires GNU utilities

**Option C: ArtBIT/bash-yaml**
- URL: https://github.com/ArtBIT/bash-yaml
- Features: Simple YAML parser
- Pros: Lightweight
- Cons: Limited features

**Option D: aruehl/shell_yaml_parser**
- URL: https://github.com/aruehl/shell_yaml_parser
- Features: Parse YAML to variables
- Pros: Works with bash/zsh
- Cons: Read-only

### 2. Download and Test Chosen Library

**Recommended**: Use **mrbaseman/parse_yaml** as base and add write functions  

```bash
# Download parse_yaml
curl -s https://raw.githubusercontent.com/mrbaseman/parse_yaml/master/src/parse_acp.yaml.sh > scripts/acp.yaml-read.sh

# Test reading
source scripts/acp.yaml-read.sh
eval $(parse_yaml package.yaml "pkg_")
echo $pkg_version  # Outputs version from package.yaml
```

### 3. Add Write Functions

Create `scripts/yaml-write.sh` to complement the read library:

```bash
#!/bin/bash
# Pure bash YAML parser
# Supports simple YAML structures (no complex nesting, arrays, or multi-line)

# Read YAML value
# Usage: yaml_get file.yaml "path.to.key"
yaml_get() {
  local file=$1
  local path=$2
  
  # Convert dot notation to grep pattern
  # "packages.firebase.version" → search for "version:" under "firebase:" under "packages:"
  
  local keys
  IFS='.' read -ra keys <<< "$path"
  
  local indent=0
  local current_section=""
  local found=false
  
  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ $line =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Calculate indentation
    local line_indent=$(echo "$line" | sed 's/^\([[:space:]]*\).*/\1/' | wc -c)
    line_indent=$((line_indent - 1))
    
    # Extract key and value
    local key=$(echo "$line" | sed 's/^[[:space:]]*\([^:]*\):.*/\1/')
    local value=$(echo "$line" | sed 's/^[[:space:]]*[^:]*:[[:space:]]*\(.*\)/\1/')
    
    # Match path
    if [ "${keys[0]}" == "$key" ]; then
      if [ ${#keys[@]} -eq 1 ]; then
        # Found the value
        echo "$value"
        return 0
      else
        # Need to go deeper
        # Remove first key and search within this section
        # (simplified - full implementation would track nesting)
        found=true
      fi
    fi
  done < "$file"
  
  return 1
}

# Write YAML value
# Usage: yaml_set file.yaml "path.to.key" "value"
yaml_set() {
  local file=$1
  local path=$2
  local value=$3
  
  # For simple cases, use sed
  local key=$(echo "$path" | rev | cut -d. -f1 | rev)
  
  # Find and replace
  sed -i "s/^\([[:space:]]*${key}:[[:space:]]*\).*/\1${value}/" "$file"
}

# Simpler approach: Use awk for YAML parsing
yaml_get_awk() {
  local file=$1
  local key=$2
  
  awk -F': ' -v key="$key" '
    $1 ~ "^[[:space:]]*"key"$" {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
      print $2
      exit
    }
  ' "$file"
}

# Simple YAML reader (for package.yaml - read-only)
yaml_get() {
  local file=$1
  local key=$2
  
  # Handle simple key: value pairs
  grep "^[[:space:]]*${key}:" "$file" | head -n1 | sed "s/^[[:space:]]*${key}:[[:space:]]*//" | sed 's/^["'\'']//' | sed 's/["'\'']$//'
}

# Get array values (tags, etc.)
yaml_get_array() {
  local file=$1
  local key=$2
  
  # Find array section and extract values
  awk "/^${key}:/{flag=1; next} /^[a-zA-Z]/{flag=0} flag && /^[[:space:]]*-/{print}" "$file" | sed 's/^[[:space:]]*-[[:space:]]*//'
}

# Check if key exists
yaml_has_key() {
  local file=$1
  local key=$2
  
  grep -q "^[[:space:]]*${key}:" "$file"
}
```

### 3. Implement Write Functions (For Manifest)

**Recommendation**: Use JSON for manifest instead of YAML  

```bash
# agent/manifest.json (not .yaml)
# Easier to manipulate with jq

# Initialize manifest
json_init_manifest() {
  cat > agent/manifest.json << 'EOF'
{
  "packages": {},
  "manifest_version": "1.0.0",
  "last_updated": null
}
EOF
}

# Add package
json_add_package() {
  local package_name=$1
  local source=$2
  local version=$3
  local commit=$4
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  jq --arg name "$package_name" \
     --arg source "$source" \
     --arg version "$version" \
     --arg commit "$commit" \
     --arg ts "$timestamp" \
     '.packages[$name] = {
       source: $source,
       package_version: $version,
       commit: $commit,
       installed_at: $ts,
       updated_at: $ts,
       installed: {patterns: [], commands: [], designs: []}
     } | .last_updated = $ts' \
     agent/manifest.json > agent/manifest.json.tmp && mv agent/manifest.json.tmp agent/manifest.json
}

# Add file to package
json_add_file() {
  local package_name=$1
  local file_type=$2  # patterns, commands, designs
  local file_name=$3
  local file_version=$4
  local checksum=$5
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  jq --arg pkg "$package_name" \
     --arg type "$file_type" \
     --arg name "$file_name" \
     --arg version "$file_version" \
     --arg checksum "$checksum" \
     --arg ts "$timestamp" \
     '.packages[$pkg].installed[$type] += [{
       name: $name,
       version: $version,
       installed_at: $ts,
       modified: false,
       checksum: $checksum
     }]' \
     agent/manifest.json > agent/manifest.json.tmp && mv agent/manifest.json.tmp agent/manifest.json
}

# Read from manifest
json_get() {
  local path=$1
  jq -r "$path" agent/manifest.json
}
```

### 4. Update All Task Documents

**Tasks to update** (reference yq):
- Task 5: Use `json_*` functions instead of `yq`
- Task 6: Use `json_*` functions
- Task 7: Use `json_*` functions
- Task 8: Use `json_*` functions
- Task 9: Use `json_*` functions
- Task 10: Use `json_*` functions

**Pattern to replace**:
```bash
# OLD (with yq)
yq eval '.packages.firebase.version' agent/manifest.yaml

# NEW (with jq)
jq -r '.packages.firebase.package_version' agent/manifest.json
```

### 5. Create Hybrid Solution

**Final architecture**:
- `package.yaml` in repos - Read with simple bash functions
- `agent/manifest.json` in projects - Read/write with jq

**Dependencies**:
- ✅ bash (always available)
- ✅ git (required for ACP)
- ✅ curl (standard on most systems)
- ✅ jq (widely available, can provide install instructions)

### 6. Add jq Installation Check

```bash
# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed"
  echo ""
  echo "Install jq:"
  echo "  macOS: brew install jq"
  echo "  Ubuntu/Debian: sudo apt-get install jq"
  echo "  CentOS/RHEL: sudo yum install jq"
  echo "  Windows: choco install jq"
  echo ""
  echo "Or download from: https://stedolan.github.io/jq/download/"
  exit 1
fi
```

---

## Verification

- [ ] Can read package.yaml without yq
- [ ] Can read/write manifest without yq
- [ ] Works on systems with only bash, git, curl, jq
- [ ] Handles simple YAML structures
- [ ] Handles quoted values
- [ ] Handles arrays (for tags)
- [ ] Error handling for malformed YAML/JSON

---

## Recommendation

**Use JSON for manifest** (`agent/manifest.json`):
- ✅ jq is more common than yq
- ✅ Easier to parse and manipulate
- ✅ Better bash support
- ✅ Still human-readable (with formatting)

**Keep YAML for packages** (`package.yaml`):
- ✅ Community standard
- ✅ More human-friendly
- ✅ Only need to READ (not write)
- ✅ Simple grep/sed sufficient

---

**Status**: Critical - Should be implemented first  
**Priority**: Critical  
**Estimated Effort**: 4-5 hours  
