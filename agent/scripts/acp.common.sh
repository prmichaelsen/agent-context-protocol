#!/bin/sh
# Common utilities for ACP scripts
# POSIX-compliant for maximum portability

# Initialize colors using tput (more reliable than ANSI codes)
init_colors() {
    if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        BOLD=$(tput bold)
        NC=$(tput sgr0)
    else
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        BOLD=''
        NC=''
    fi
}

# Calculate file checksum (SHA-256)
# Usage: calculate_checksum "path/to/file"
# Returns: checksum string (without "sha256:" prefix)
calculate_checksum() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    sha256sum "$file" 2>/dev/null | cut -d' ' -f1
}

# Get current timestamp in ISO 8601 format (UTC)
# Usage: timestamp=$(get_timestamp)
# Returns: YYYY-MM-DDTHH:MM:SSZ
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Validate URL format
# Usage: if validate_url "$url"; then ...
# Returns: 0 if valid, 1 if invalid
validate_url() {
    local url="$1"
    case "$url" in
        http://*|https://*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get script directory (portable way)
# Usage: script_dir=$(get_script_dir)
get_script_dir() {
    # Get the directory of the calling script
    dirname "$0"
}

# Source YAML parser
# Usage: source_yaml_parser
source_yaml_parser() {
    local script_dir
    script_dir=$(get_script_dir)
    if [ -f "${script_dir}/acp.yaml-parser.sh" ]; then
        . "${script_dir}/acp.yaml-parser.sh"
    else
        echo "${RED}Error: acp.yaml-parser.sh not found${NC}" >&2
        return 1
    fi
}

# Initialize manifest file if it doesn't exist
# Usage: init_manifest
init_manifest() {
    if [ ! -f "agent/manifest.yaml" ]; then
        cat > agent/manifest.yaml << 'EOF'
# ACP Package Manifest
# Tracks installed packages and their versions

packages: {}

manifest_version: 1.0.0
last_updated: null
EOF
        echo "${GREEN}✓${NC} Created agent/manifest.yaml"
    fi
}

# Validate manifest structure
# Usage: if validate_manifest; then ...
# Returns: 0 if valid, 1 if invalid
validate_manifest() {
    local manifest="agent/manifest.yaml"
    
    if [ ! -f "$manifest" ]; then
        echo "${RED}Error: Manifest not found${NC}" >&2
        return 1
    fi
    
    # Source YAML parser if not already loaded
    if ! command -v yaml_get >/dev/null 2>&1; then
        source_yaml_parser || return 1
    fi
    
    # Check required fields
    local manifest_version
    manifest_version=$(yaml_get "$manifest" "manifest_version" 2>/dev/null)
    
    if [ -z "$manifest_version" ] || [ "$manifest_version" = "null" ]; then
        echo "${RED}Error: manifest_version missing${NC}" >&2
        return 1
    fi
    
    echo "${GREEN}✓${NC} Manifest valid"
    return 0
}

# Update manifest last_updated timestamp
# Usage: update_manifest_timestamp
update_manifest_timestamp() {
    local manifest="agent/manifest.yaml"
    local timestamp
    timestamp=$(get_timestamp)
    
    # Update timestamp using sed
    sed -i "s/^last_updated: .*/last_updated: $timestamp/" "$manifest"
}

# Check if package exists in manifest
# Usage: if package_exists "package-name" ["manifest-path"]; then ...
# Returns: 0 if exists, 1 if not
package_exists() {
    local package_name="$1"
    local manifest="${2:-agent/manifest.yaml}"
    
    # Source YAML parser if not already loaded
    if ! command -v yaml_has_key >/dev/null 2>&1; then
        source_yaml_parser || return 1
    fi
    
    yaml_has_key "$manifest" "packages.${package_name}.source"
}

# ============================================================================
# Global Manifest Functions
# ============================================================================

# Get global manifest path
# Usage: manifest_path=$(get_global_manifest_path)
# Returns: Path to global manifest
get_global_manifest_path() {
    echo "$HOME/.acp/agent/manifest.yaml"
}

# Check if global manifest exists
# Usage: if global_manifest_exists; then ...
# Returns: 0 if exists, 1 if not
global_manifest_exists() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    [ -f "$manifest_path" ]
}

# Initialize global manifest if it doesn't exist
# Usage: init_global_manifest
init_global_manifest() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ -f "$manifest_path" ]; then
        return 0
    fi
    
    # Create ~/.acp directory if needed
    mkdir -p "$HOME/.acp/packages"
    mkdir -p "$HOME/.acp/projects"
    
    # Create manifest
    local timestamp
    timestamp=$(get_timestamp)
    
    cat > "$manifest_path" << EOF
# Global ACP Package Manifest
# This file tracks all globally installed ACP packages

version: 1.0.0
updated: $timestamp

packages: {}
EOF
    
    success "Initialized global manifest at $manifest_path"
}

# Read global manifest (returns full content)
# Usage: content=$(read_global_manifest)
read_global_manifest() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        echo "Error: Global manifest not found at $manifest_path" >&2
        return 1
    fi
    
    cat "$manifest_path"
}

# Update global manifest timestamp
# Usage: update_global_manifest_timestamp
update_global_manifest_timestamp() {
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        echo "Error: Global manifest not found" >&2
        return 1
    fi
    
    # Update timestamp using sed
    local timestamp
    timestamp=$(get_timestamp)
    sed -i "s/^updated: .*/updated: $timestamp/" "$manifest_path"
}

# Check if package exists in global manifest
# Usage: if global_package_exists "package-name"; then ...
# Returns: 0 if exists, 1 if not
global_package_exists() {
    local package_name="$1"
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        return 1
    fi
    
    # Check if package exists in manifest
    grep -q "^  $package_name:" "$manifest_path"
}

# Get global package location
# Usage: location=$(get_global_package_location "package-name")
# Returns: Package installation path
get_global_package_location() {
    local package_name="$1"
    local manifest_path
    manifest_path=$(get_global_manifest_path)
    
    if [ ! -f "$manifest_path" ]; then
        return 1
    fi
    
    # Extract location using awk
    awk -v pkg="$package_name" '
        $0 ~ "^  " pkg ":" { in_package=1; next }
        in_package && /^    location:/ { print $2; exit }
        /^  [a-z]/ && in_package { exit }
    ' "$manifest_path"
}

# Initialize global ACP infrastructure if it doesn't exist
# This function is idempotent - safe to call multiple times
# Usage: init_global_acp
# Returns: 0 on success, 1 on failure
init_global_acp() {
    local global_dir="$HOME/.acp"
    
    # Check if already initialized
    if [ -d "$global_dir/agent" ] && [ -f "$global_dir/AGENT.md" ]; then
        return 0  # Already initialized, nothing to do
    fi
    
    echo "${BLUE}Initializing global ACP infrastructure at ~/.acp/...${NC}"
    echo ""
    
    # Create ~/.acp directory
    mkdir -p "$global_dir"
    
    # Get the directory where this script is located
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Run standard ACP installation in ~/.acp/
    # This installs all templates, scripts, and schemas
    if [ -f "$script_dir/acp.install.sh" ]; then
        # Use local install script
        (
            cd "$global_dir" || exit 1
            bash "$script_dir/acp.install.sh"
        ) || {
            echo "${RED}Error: Failed to initialize global ACP infrastructure${NC}" >&2
            return 1
        }
    else
        # Fallback: Download from repository
        (
            cd "$global_dir" || exit 1
            curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash
        ) || {
            echo "${RED}Error: Failed to initialize global ACP infrastructure${NC}" >&2
            return 1
        }
    fi
    
    # Create additional global directories
    mkdir -p "$global_dir/projects"
    
    # Initialize global manifest if it doesn't exist
    if [ ! -f "$global_dir/agent/manifest.yaml" ]; then
        init_global_manifest
    fi
    
    # Append global installation notes to AGENT.md
    if [ -f "$global_dir/AGENT.md" ] && ! grep -q "## Global Installation" "$global_dir/AGENT.md"; then
        cat >> "$global_dir/AGENT.md" << 'EOF'

---

## Global Installation

This is a global ACP installation located at `~/.acp/`.

### Purpose

This installation provides:
- **Global packages** in `~/.acp/agent/` - Packages installed with `@acp.package-install --global`
- **Project workspace** in `~/.acp/projects/` - Optional location for package development
- **Global manifest** in `~/.acp/agent/manifest.yaml` - Tracks globally installed packages
- **Templates and scripts** in `~/.acp/agent/` - All ACP templates and utilities

### Usage

**Install packages globally**:
```bash
@acp.package-install --global https://github.com/user/acp-package.git
```

**Create packages**:
```bash
cd ~/.acp/projects
@acp.package-create
```

**List global packages**:
```bash
@acp.package-list --global
```

### Discovery

Agents can discover globally installed packages by reading `~/.acp/agent/manifest.yaml`. Local packages always take precedence over global packages.
EOF
    fi
    
    echo ""
    echo "${GREEN}✓ Global ACP infrastructure initialized${NC}"
    echo ""
    echo "Location: $global_dir"
    echo "Templates: $global_dir/agent/"
    echo "Projects: $global_dir/projects/"
    echo ""
}

# Print error message and exit
# Usage: die "Error message"
die() {
    echo "${RED}Error: $1${NC}" >&2
    exit 1
}

# Print warning message
# Usage: warn "Warning message"
warn() {
    echo "${YELLOW}Warning: $1${NC}" >&2
}

# Print success message
# Usage: success "Success message"
success() {
    echo "${GREEN}✓${NC} $1"
}

# Print info message
# Usage: info "Info message"
info() {
    echo "${BLUE}ℹ${NC} $1"
}

# Remove deprecated script files (from versions < 2.0.0)
# Usage: cleanup_deprecated_scripts
cleanup_deprecated_scripts() {
    local deprecated_scripts=(
        "check-for-updates.sh"
        "common.sh"
        "install.sh"
        "package-install.sh"
        "uninstall.sh"
        "update.sh"
        "version.sh"
        "yaml.sh"
    )
    
    local removed_count=0
    for script in "${deprecated_scripts[@]}"; do
        if [ -f "agent/scripts/$script" ]; then
            rm "agent/scripts/$script"
            warn "Removed deprecated script: $script"
            removed_count=$((removed_count + 1))
        fi
    done
    
    if [ $removed_count -gt 0 ]; then
        success "Cleaned up $removed_count deprecated script(s)"
    fi
}

# Parse package.yaml from repository
# Usage: parse_package_metadata "repo_dir"
# Sets global variables: PACKAGE_NAME, PACKAGE_VERSION, PACKAGE_DESCRIPTION
parse_package_metadata() {
    local repo_dir="$1"
    local package_yaml="${repo_dir}/package.yaml"
    
    if [ ! -f "$package_yaml" ]; then
        warn "package.yaml not found in repository"
        PACKAGE_NAME="unknown"
        PACKAGE_VERSION="0.0.0"
        PACKAGE_DESCRIPTION="No description"
        return 1
    fi
    
    # Source YAML parser if not already loaded
    if ! command -v yaml_get >/dev/null 2>&1; then
        source_yaml_parser || return 1
    fi
    
    # Extract metadata
    PACKAGE_NAME=$(yaml_get "$package_yaml" "name" 2>/dev/null || echo "unknown")
    PACKAGE_VERSION=$(yaml_get "$package_yaml" "version" 2>/dev/null || echo "0.0.0")
    PACKAGE_DESCRIPTION=$(yaml_get "$package_yaml" "description" 2>/dev/null || echo "No description")
    
    info "Package: $PACKAGE_NAME"
    info "Version: $PACKAGE_VERSION"
    info "Description: $PACKAGE_DESCRIPTION"
    
    return 0
}

# Get file version from package.yaml
# Usage: get_file_version "package.yaml" "patterns" "filename.md"
# Returns: version string or "0.0.0" if not found
get_file_version() {
    local package_yaml="$1"
    local file_type="$2"
    local file_name="$3"
    
    if [ ! -f "$package_yaml" ]; then
        echo "0.0.0"
        return 1
    fi
    
    # Use awk to parse YAML array (acp.yaml.sh doesn't support array queries)
    local version
    version=$(awk -v type="$file_type" -v name="$file_name" '
        BEGIN { in_section=0; in_item=0 }
        /^  [a-z_]+:/ { in_section=0 }
        $0 ~ "^  " type ":" { in_section=1; next }
        in_section && /^    - name:/ {
            if ($3 == name) { in_item=1 }
            else { in_item=0 }
            next
        }
        in_section && in_item && /^      version:/ {
            print $2
            exit
        }
    ' "$package_yaml")
    
    if [ -z "$version" ]; then
        echo "0.0.0"
    else
        echo "$version"
    fi
}

# Add package to manifest
# Usage: add_package_to_manifest "package_name" "source_url" "version" "commit_hash"
add_package_to_manifest() {
    local package_name="$1"
    local source_url="$2"
    local package_version="$3"
    local commit_hash="$4"
    local timestamp
    timestamp=$(get_timestamp)
    
    local manifest="agent/manifest.yaml"
    
    # Add package metadata using direct YAML appending (new parser doesn't support yaml_set for new keys)
    # Check if package already exists
    if grep -q "^  ${package_name}:" "$manifest" 2>/dev/null; then
        # Update existing package
        sed -i "/^  ${package_name}:/,/^  [a-z]/ {
            s|source: .*|source: $source_url|
            s|package_version: .*|package_version: $package_version|
            s|commit: .*|commit: $commit_hash|
            s|updated_at: .*|updated_at: $timestamp|
        }" "$manifest"
    else
        # Add new package entry
        # Find the packages: line and append after it
        awk -v pkg="$package_name" -v src="$source_url" -v ver="$package_version" -v commit="$commit_hash" -v ts="$timestamp" '
            /^packages:/ {
                print
                if ($2 == "{}") {
                    # Empty packages, replace line
                    next
                }
                print "  " pkg ":"
                print "    source: " src
                print "    package_version: " ver
                print "    commit: " commit
                print "    installed_at: " ts
                print "    updated_at: " ts
                print "    files:"
                print "      patterns: []"
                print "      commands: []"
                print "      designs: []"
                next
            }
            { print }
        ' "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"
    fi
    
    # Update manifest timestamp
    update_manifest_timestamp
    
    success "Added package $package_name to manifest"
}

# Add file to manifest
# Usage: add_file_to_manifest "package_name" "file_type" "filename" "version" "file_path"
# file_type: patterns, commands, designs
add_file_to_manifest() {
    local package_name="$1"
    local file_type="$2"
    local filename="$3"
    local file_version="$4"
    local file_path="$5"
    local timestamp
    timestamp=$(get_timestamp)
    
    local manifest="agent/manifest.yaml"
    
    # Calculate checksum
    local checksum
    checksum=$(calculate_checksum "$file_path")
    
    if [ $? -ne 0 ]; then
        warn "Failed to calculate checksum for $filename"
        checksum="unknown"
    fi
    
    # Source YAML parser
    if ! command -v yaml_parse >/dev/null 2>&1; then
        source_yaml_parser || return 1
    fi
    
    # Convert empty arrays [] to proper format first (workaround for parser limitation)
    sed -i "s/^      ${file_type}: \\[\\]$/      ${file_type}:/" "$manifest"
    
    # Parse manifest
    yaml_parse "$manifest"
    
    # Append object to array
    local obj_node
    obj_node=$(yaml_array_append_object ".packages.${package_name}.files.${file_type}")
    
    # Set object fields
    yaml_object_set "$obj_node" "name" "$filename" >/dev/null
    yaml_object_set "$obj_node" "version" "$file_version" >/dev/null
    yaml_object_set "$obj_node" "installed_at" "$timestamp" >/dev/null
    yaml_object_set "$obj_node" "modified" "false" >/dev/null
    yaml_object_set "$obj_node" "checksum" "sha256:$checksum" >/dev/null
    
    # Write back
    yaml_write "$manifest"
    
    return 0
}

# Get package commit hash from git repository
# Usage: get_commit_hash "repo_dir"
# Returns: commit hash
get_commit_hash() {
    local repo_dir="$1"
    
    if [ ! -d "$repo_dir/.git" ]; then
        echo "unknown"
        return 1
    fi
    
    (cd "$repo_dir" && git rev-parse HEAD 2>/dev/null) || echo "unknown"
}

# Compare semantic versions
# Usage: compare_versions "1.2.3" "1.3.0"
# Returns: "newer" if remote > current, "same" if equal, "older" if remote < current
compare_versions() {
    local current="$1"
    local remote="$2"
    
    if [ "$current" = "$remote" ]; then
        echo "same"
        return 0
    fi
    
    # Use sort -V for version comparison
    local older
    older=$(printf '%s\n%s\n' "$current" "$remote" | sort -V | head -n1)
    
    if [ "$older" = "$current" ]; then
        echo "newer"
    else
        echo "older"
    fi
}

# Check if file was modified locally
# Usage: is_file_modified "package_name" "file_type" "filename"
# Returns: 0 if modified, 1 if not modified
is_file_modified() {
    local package_name="$1"
    local file_type="$2"
    local file_name="$3"
    local manifest="agent/manifest.yaml"
    
    # Get stored checksum from manifest
    local stored_checksum
    stored_checksum=$(awk -v pkg="$package_name" -v type="$file_type" -v name="$file_name" '
        BEGIN { in_pkg=0; in_type=0; in_file=0 }
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ && !/^    / { in_pkg=0 }
        in_pkg && $0 ~ "^      " type ":" { in_type=1; next }
        in_type && /^      [a-z]/ && !/^        / { in_type=0 }
        in_type && /^        - name:/ {
            if ($3 == name) { in_file=1 }
            else { in_file=0 }
            next
        }
        in_file && /^          checksum:/ {
            gsub(/sha256:/, "", $2)
            print $2
            exit
        }
    ' "$manifest")
    
    if [ -z "$stored_checksum" ]; then
        warn "No checksum found in manifest for $file_type/$file_name"
        return 1
    fi
    
    # Calculate current checksum
    local current_checksum
    current_checksum=$(calculate_checksum "agent/${file_type}/${file_name}")
    
    if [ "$stored_checksum" != "$current_checksum" ]; then
        return 0  # Modified
    else
        return 1  # Not modified
    fi
}

# Update file entry in manifest
# Usage: update_file_in_manifest "package_name" "file_type" "filename" "new_version" "new_checksum"
update_file_in_manifest() {
    local package_name="$1"
    local file_type="$2"
    local file_name="$3"
    local new_version="$4"
    local new_checksum="$5"
    local timestamp
    timestamp=$(get_timestamp)
    
    local manifest="agent/manifest.yaml"
    
    # Update using awk to modify in place
    # This is complex with acp.yaml.sh, so we'll use a temp file approach
    local temp_file
    temp_file=$(mktemp)
    
    awk -v pkg="$package_name" -v type="$file_type" -v name="$file_name" \
        -v ver="$new_version" -v chk="sha256:$new_checksum" -v ts="$timestamp" '
        BEGIN { in_pkg=0; in_type=0; in_file=0 }
        $0 ~ "^  " pkg ":" { in_pkg=1; print; next }
        in_pkg && /^  [a-z]/ && !/^    / { in_pkg=0; print; next }
        in_pkg && $0 ~ "^      " type ":" { in_type=1; print; next }
        in_type && /^      [a-z]/ && !/^        / { in_type=0; print; next }
        in_type && /^        - name:/ {
            if ($3 == name) { in_file=1 }
            else { in_file=0 }
            print
            next
        }
        in_file && /^          version:/ {
            print "          version: " ver
            next
        }
        in_file && /^          checksum:/ {
            print "          checksum: " chk
            next
        }
        in_file && /^          modified:/ {
            print "          modified: false"
            next
        }
        { print }
    ' "$manifest" > "$temp_file"
    
    mv "$temp_file" "$manifest"
}

# ============================================================================
# Dependency Checking Functions
# ============================================================================

# Detect project package manager
# Usage: detect_package_manager
# Returns: npm, pip, cargo, go, or unknown
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

# Check npm dependency
# Usage: check_npm_dependency "dep_name" "required_version"
# Returns: installed version or "not-installed"
check_npm_dependency() {
    local dep_name="$1"
    local required_version="$2"
    
    if [ ! -f "package.json" ]; then
        echo "not-installed"
        return 1
    fi
    
    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        warn "jq not found, skipping npm dependency check"
        echo "unknown"
        return 0
    fi
    
    # Get installed version
    local installed_version
    installed_version=$(jq -r ".dependencies.\"${dep_name}\" // .devDependencies.\"${dep_name}\" // \"not-installed\"" package.json 2>/dev/null)
    
    if [ "$installed_version" = "not-installed" ] || [ "$installed_version" = "null" ]; then
        echo "not-installed"
        return 1
    fi
    
    # Remove ^ ~ >= etc for display
    installed_version=$(echo "$installed_version" | sed 's/[\^~>=<]//g')
    
    echo "$installed_version"
    return 0
}

# Check pip dependency
# Usage: check_pip_dependency "dep_name" "required_version"
# Returns: installed version or "not-installed"
check_pip_dependency() {
    local dep_name="$1"
    local required_version="$2"
    
    # Check requirements.txt
    if [ -f "requirements.txt" ]; then
        local version
        version=$(grep "^${dep_name}" requirements.txt 2>/dev/null | cut -d'=' -f2 | head -n1)
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Check pyproject.toml
    if [ -f "pyproject.toml" ]; then
        local version
        version=$(grep "${dep_name}" pyproject.toml 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -n1)
        if [ -n "$version" ]; then
            echo "$version"
            return 0
        fi
    fi
    
    echo "not-installed"
    return 1
}

# Check cargo dependency
# Usage: check_cargo_dependency "dep_name" "required_version"
# Returns: installed version or "not-installed"
check_cargo_dependency() {
    local dep_name="$1"
    local required_version="$2"
    
    if [ ! -f "Cargo.toml" ]; then
        echo "not-installed"
        return 1
    fi
    
    local version
    version=$(grep "^${dep_name}" Cargo.toml 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -n1)
    
    if [ -n "$version" ]; then
        echo "$version"
        return 0
    fi
    
    echo "not-installed"
    return 1
}

# Check go dependency
# Usage: check_go_dependency "dep_name" "required_version"
# Returns: installed version or "not-installed"
check_go_dependency() {
    local dep_name="$1"
    local required_version="$2"
    
    if [ ! -f "go.mod" ]; then
        echo "not-installed"
        return 1
    fi
    
    local version
    version=$(grep "${dep_name}" go.mod 2>/dev/null | grep -oP 'v\d+\.\d+\.\d+' | sed 's/^v//' | head -n1)
    
    if [ -n "$version" ]; then
        echo "$version"
        return 0
    fi
    
    echo "not-installed"
    return 1
}

# Validate project dependencies
# Usage: validate_project_dependencies "package_yaml_path"
# Returns: 0 if valid or user confirms, 1 if invalid and user cancels
validate_project_dependencies() {
    local package_yaml="$1"
    local package_manager
    package_manager=$(detect_package_manager)
    
    if [ "$package_manager" = "unknown" ]; then
        info "No package manager detected, skipping dependency check"
        return 0
    fi
    
    echo ""
    echo "${BLUE}Checking project dependencies ($package_manager)...${NC}"
    echo ""
    
    # Source YAML parser if not already loaded
    if ! command -v yaml_get >/dev/null 2>&1; then
        source_yaml_parser || return 1
    fi
    
    # Check if requires section exists
    local has_requires
    has_requires=$(grep -c "^requires:" "$package_yaml" 2>/dev/null || echo "0")
    
    if [ "$has_requires" -eq 0 ]; then
        success "No project dependencies required"
        return 0
    fi
    
    # Check if package manager section exists
    local has_pm_section
    has_pm_section=$(grep -c "^  ${package_manager}:" "$package_yaml" 2>/dev/null || echo "0")
    
    if [ "$has_pm_section" -eq 0 ]; then
        success "No ${package_manager} dependencies required"
        return 0
    fi
    
    local has_incompatible=false
    local dep_count=0
    
    # Parse dependencies using awk
    while IFS=: read -r dep_name required_version; do
        # Skip empty lines and section headers
        [ -z "$dep_name" ] && continue
        [[ "$dep_name" =~ ^[[:space:]]*$ ]] && continue
        [[ "$dep_name" =~ ^requires ]] && continue
        [[ "$dep_name" =~ ^[[:space:]]*${package_manager} ]] && continue
        
        # Clean up whitespace
        dep_name=$(echo "$dep_name" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        required_version=$(echo "$required_version" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | tr -d "'")
        
        # Skip if not a dependency line
        [[ ! "$dep_name" =~ ^[a-zA-Z0-9@/_-]+$ ]] && continue
        
        dep_count=$((dep_count + 1))
        
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
            go)
                installed_version=$(check_go_dependency "$dep_name" "$required_version")
                ;;
        esac
        
        if [ "$installed_version" = "not-installed" ]; then
            echo "  ${RED}✗${NC} $dep_name: not installed (requires $required_version)"
            has_incompatible=true
        elif [ "$installed_version" = "unknown" ]; then
            echo "  ${YELLOW}?${NC} $dep_name: unable to verify (requires $required_version)"
        else
            echo "  ${GREEN}✓${NC} $dep_name: $installed_version (requires $required_version)"
        fi
    done < <(awk -v pm="$package_manager" '
        BEGIN { in_requires=0; in_pm=0 }
        /^requires:/ { in_requires=1; next }
        in_requires && /^[a-z]/ && !/^  / { in_requires=0 }
        in_requires && $0 ~ "^  " pm ":" { in_pm=1; next }
        in_pm && /^  [a-z]/ && !/^    / { in_pm=0 }
        in_pm && /^    [a-zA-Z0-9@/_-]+:/ {
            print $0
        }
    ' "$package_yaml")
    
    echo ""
    
    if [ "$dep_count" -eq 0 ]; then
        success "No ${package_manager} dependencies required"
        return 0
    fi
    
    if [ "$has_incompatible" = true ]; then
        echo "${YELLOW}⚠️  Some dependencies are missing or incompatible${NC}"
        echo ""
        echo "Recommendation:"
        echo "  Install missing dependencies before using this package"
        echo "  The package patterns may not work correctly without them"
        echo ""
        
        # Only prompt if not in auto-confirm mode
        if [ "${SKIP_CONFIRM:-false}" != "true" ]; then
            read -p "Continue installation anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        else
            warn "Auto-confirm enabled, continuing despite missing dependencies"
        fi
    else
        success "All dependencies satisfied"
    fi
    
    return 0
}

# ============================================================================
# Namespace Utilities
# ============================================================================

# Check if current directory is an ACP package
# Usage: if is_acp_package; then ...
# Returns: 0 if package.yaml exists, 1 otherwise
is_acp_package() {
    [ -f "package.yaml" ]
}

# Infer package namespace from multiple sources
# Usage: namespace=$(infer_namespace)
# Returns: namespace string or empty if can't infer
# Priority: 1) package.yaml, 2) directory name, 3) git remote
infer_namespace() {
    local namespace=""
    
    # Priority 1: Read from package.yaml
    if [ -f "package.yaml" ]; then
        namespace=$(yaml_get "package.yaml" "name" 2>/dev/null)
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

# Validate namespace format and check reserved names
# Usage: if validate_namespace "firebase"; then ...
# Returns: 0 if valid, 1 if invalid
validate_namespace() {
    local namespace="$1"
    
    if [ -z "$namespace" ]; then
        echo "${RED}Error: Namespace cannot be empty${NC}" >&2
        return 1
    fi
    
    # Check format (lowercase, alphanumeric, hyphens)
    if ! echo "$namespace" | grep -qE '^[a-z0-9-]+$'; then
        echo "${RED}Error: Namespace must be lowercase, alphanumeric, and hyphens only${NC}" >&2
        return 1
    fi
    
    # Check reserved names
    case "$namespace" in
        acp|local|core|system|global)
            echo "${RED}Error: Namespace '$namespace' is reserved${NC}" >&2
            return 1
            ;;
    esac
    
    return 0
}

# Get namespace for file creation (context-aware)
# Usage: namespace=$(get_namespace_for_file)
# Returns: package namespace or "local" for non-packages
get_namespace_for_file() {
    if is_acp_package; then
        local namespace=$(infer_namespace)
        if [ -n "$namespace" ]; then
            echo "$namespace"
            return 0
        else
            # In package but can't infer, ask user
            read -p "Package namespace: " namespace
            if validate_namespace "$namespace"; then
                echo "$namespace"
                return 0
            else
                return 1
            fi
        fi
    else
        # Not a package, use local namespace
        echo "local"
        return 0
    fi
}

# Validate namespace consistency across sources
# Usage: if validate_namespace_consistency; then ...
# Returns: 0 if consistent, 1 if conflicts found
validate_namespace_consistency() {
    if ! is_acp_package; then
        return 0  # Not a package, no consistency to check
    fi
    
    local from_yaml=$(yaml_get "package.yaml" "name" 2>/dev/null)
    local from_dir=$(basename "$PWD" | sed 's/^acp-//')
    local from_remote=""
    
    if git remote get-url origin >/dev/null 2>&1; then
        local remote_url=$(git remote get-url origin)
        if [[ "$remote_url" =~ acp-([a-z0-9-]+)(\.git)?$ ]]; then
            from_remote="${BASH_REMATCH[1]}"
        fi
    fi
    
    # Check for conflicts
    local has_conflict=false
    
    if [ -n "$from_yaml" ] && [ -n "$from_dir" ] && [ "$from_yaml" != "$from_dir" ]; then
        echo "${YELLOW}Warning: Namespace mismatch${NC}" >&2
        echo "  package.yaml: $from_yaml" >&2
        echo "  directory: $from_dir" >&2
        has_conflict=true
    fi
    
    if [ -n "$from_yaml" ] && [ -n "$from_remote" ] && [ "$from_yaml" != "$from_remote" ]; then
        echo "${YELLOW}Warning: Namespace mismatch${NC}" >&2
        echo "  package.yaml: $from_yaml" >&2
        echo "  git remote: $from_remote" >&2
        has_conflict=true
    fi
    
    if [ "$has_conflict" = true ]; then
        return 1
    fi
    
    return 0
}

# ============================================================================
# README Update Utilities
# ============================================================================

# Update README.md contents section from package.yaml
# Usage: update_readme_contents
# Returns: 0 if successful, 1 if error
update_readme_contents() {
    local readme="README.md"
    local package_yaml="package.yaml"
    
    if [ ! -f "$readme" ]; then
        echo "${YELLOW}Warning: README.md not found${NC}" >&2
        return 1
    fi
    
    if [ ! -f "$package_yaml" ]; then
        echo "${YELLOW}Warning: package.yaml not found${NC}" >&2
        return 1
    fi
    
    # Generate contents section
    local contents=$(generate_contents_section)
    
    # Check if markers exist
    if ! grep -q "<!-- ACP_AUTO_UPDATE_START:CONTENTS -->" "$readme"; then
        echo "${YELLOW}Warning: README.md missing auto-update markers${NC}" >&2
        return 1
    fi
    
    # Replace section between markers using awk
    awk -v contents="$contents" '
        /<!-- ACP_AUTO_UPDATE_START:CONTENTS -->/ {
            print
            print contents
            skip=1
            next
        }
        /<!-- ACP_AUTO_UPDATE_END:CONTENTS -->/ {
            skip=0
        }
        !skip
    ' "$readme" > "${readme}.tmp"
    
    mv "${readme}.tmp" "$readme"
    echo "${GREEN}✓${NC} Updated README.md contents section"
    return 0
}

# Generate contents section from package.yaml
# Usage: contents=$(generate_contents_section)
# Returns: Formatted markdown content list
generate_contents_section() {
    local package_yaml="package.yaml"
    
    # Parse and format contents using awk
    awk '
        BEGIN { section="" }
        
        /^  commands:/ { section="commands"; print "### Commands"; next }
        /^  patterns:/ { section="patterns"; print ""; print "### Patterns"; next }
        /^  designs:/ { section="designs"; print ""; print "### Designs"; next }
        
        section != "" && /^    - name:/ {
            gsub(/^    - name: /, "")
            name = $0
            getline
            if (/^      version:/) {
                getline
                if (/^      description:/) {
                    gsub(/^      description: /, "")
                    desc = $0
                    print "- `" name "` - " desc
                } else {
                    print "- `" name "`"
                }
            }
        }
        
        /^[a-z]/ && !/^  / { section="" }
    ' "$package_yaml"
}

# Add file to README contents (updates entire section)
# Usage: add_file_to_readme "patterns" "firebase.my-pattern.md" "Description"
add_file_to_readme() {
    local type="$1"
    local filename="$2"
    local description="$3"
    
    # Simply update entire contents section
    update_readme_contents
}

# ============================================================================
# Display Functions
# ============================================================================

# Display available ACP commands
# Usage: display_available_commands
display_available_commands() {
    echo "${BLUE}ACP Commands Available:${NC}"
    echo ""
    echo "  ${GREEN}@acp.init${NC}                       - Initialize agent context (start here!)"
    echo "  ${GREEN}@acp.proceed${NC}                    - Continue with next task"
    echo "  ${GREEN}@acp.status${NC}                     - Display project status"
    echo "  ${GREEN}@acp.update${NC}                     - Update progress tracking"
    echo "  ${GREEN}@acp.sync${NC}                       - Sync documentation with code"
    echo "  ${GREEN}@acp.validate${NC}                   - Validate ACP documents"
    echo "  ${GREEN}@acp.report${NC}                     - Generate project report"
    echo "  ${GREEN}@acp.version-check${NC}              - Show current ACP version"
    echo "  ${GREEN}@acp.version-check-for-updates${NC}  - Check for ACP updates"
    echo "  ${GREEN}@acp.version-update${NC}             - Update ACP to latest version"
    echo ""
    echo "${BLUE}Package Management Commands:${NC}"
    echo ""
    echo "  ${GREEN}@acp.package-install${NC}            - Install ACP packages from GitHub"
    echo "  ${GREEN}@acp.package-list${NC}               - List installed packages"
    echo "  ${GREEN}@acp.package-update${NC}             - Update installed packages"
    echo "  ${GREEN}@acp.package-remove${NC}             - Remove installed packages"
    echo "  ${GREEN}@acp.package-info${NC}               - Show package details"
    echo "  ${GREEN}@acp.package-search${NC}             - Search for packages on GitHub"
    echo ""
    echo "${BLUE}Git Commands Available:${NC}"
    echo ""
    echo "  ${GREEN}@git.init${NC}                       - Initialize git repository with smart .gitignore"
    echo "  ${GREEN}@git.commit${NC}                     - Intelligent version-aware git commit"
}

# ============================================================================
# Pre-Commit Hook System
# ============================================================================

# Install pre-commit hook for package validation
# Usage: install_precommit_hook
# Returns: 0 on success, 1 on failure
install_precommit_hook() {
    local hook_file=".git/hooks/pre-commit"
    
    # Check if .git directory exists
    if [ ! -d ".git" ]; then
        echo "${RED}Error: Not a git repository${NC}" >&2
        return 1
    fi
    
    # Create hooks directory if it doesn't exist
    mkdir -p ".git/hooks"
    
    # Check if hook already exists
    if [ -f "$hook_file" ]; then
        echo "${YELLOW}⚠  Pre-commit hook already exists${NC}"
        echo "   Backing up to pre-commit.backup"
        cp "$hook_file" "${hook_file}.backup"
    fi
    
    # Create hook from template
    cat > "$hook_file" << 'EOF'
#!/bin/sh
# ACP Package Pre-Commit Hook
# Validates package.yaml before allowing commit

# Colors for output
if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    NC=$(tput sgr0)
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Check if package.yaml exists
if [ ! -f "package.yaml" ]; then
    # Not a package directory, skip validation
    exit 0
fi

# Check if validation script exists
if [ ! -f "agent/scripts/acp.yaml-validate.sh" ]; then
    echo "${YELLOW}Warning: acp.yaml-validate.sh not found, skipping validation${NC}"
    exit 0
fi

# Check if schema exists
if [ ! -f "agent/schemas/package.schema.yaml" ]; then
    echo "${YELLOW}Warning: package.schema.yaml not found, skipping validation${NC}"
    exit 0
fi

# Validate package.yaml by running the script directly (not sourcing)
echo "Validating package.yaml..."
if ! ./agent/scripts/acp.yaml-validate.sh "package.yaml" "agent/schemas/package.schema.yaml" 2>/dev/null; then
    echo ""
    echo "${RED}✗ Pre-commit validation failed${NC}"
    echo ""
    echo "package.yaml has validation errors."
    echo "Please fix the errors and try again."
    echo ""
    echo "To see detailed errors, run:"
    echo "  ./agent/scripts/acp.yaml-validate.sh package.yaml agent/schemas/package.schema.yaml"
    echo ""
    exit 1
fi

echo "${GREEN}✓${NC} package.yaml is valid"

# Future enhancements (documented for reference):
# - Namespace consistency checking across all files
# - CHANGELOG.md validation for version changes
# - File existence verification (all files in package.yaml exist)
# - README.md structure validation
# - Prevent commits to non-release branches

exit 0
EOF
    
    # Make executable
    chmod +x "$hook_file"
    
    echo "${GREEN}✓${NC} Installed pre-commit hook"
    return 0
}
