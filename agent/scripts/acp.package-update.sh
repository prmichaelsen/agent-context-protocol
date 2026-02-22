#!/bin/bash

# Agent Context Protocol (ACP) Package Update Script
# Updates installed ACP packages to their latest versions

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Parse arguments
PACKAGE_NAME=""
CHECK_ONLY=false
SKIP_MODIFIED=false
FORCE=false
AUTO_CONFIRM=false
GLOBAL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_MODE=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --skip-modified)
            SKIP_MODIFIED=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        *)
            PACKAGE_NAME="$1"
            shift
            ;;
    esac
done

# Check for updates for a package
# Usage: check_package_for_updates "package_name"
# Returns: 0 if updates available, 1 if up to date
check_package_for_updates() {
    local package_name="$1"
    
    # Get current version and source from manifest
    local current_version
    current_version=$(awk -v pkg="$package_name" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    package_version:/ { print $2; exit }
    ' "$MANIFEST_FILE")
    
    local source_url
    source_url=$(awk -v pkg="$package_name" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    source:/ { print $2; exit }
    ' "$MANIFEST_FILE")
    
    if [ -z "$current_version" ] || [ -z "$source_url" ]; then
        warn "Could not read package metadata for $package_name"
        return 1
    fi
    
    info "Checking $package_name ($current_version)..."
    
    # Clone repository to temp location
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" RETURN
    
    if ! git clone --depth 1 "$source_url" "$temp_dir" &>/dev/null; then
        warn "Failed to clone repository for $package_name"
        return 1
    fi
    
    # Get remote version
    local remote_version
    if [ -f "$temp_dir/package.yaml" ]; then
        remote_version=$(awk '/^version:/ {print $2; exit}' "$temp_dir/package.yaml")
    else
        warn "No package.yaml found in repository"
        return 1
    fi
    
    # Compare versions
    local comparison
    comparison=$(compare_versions "$current_version" "$remote_version")
    
    if [ "$comparison" = "newer" ]; then
        echo "  ${GREEN}✓${NC} Update available: $current_version → $remote_version"
        return 0
    else
        echo "  ${GREEN}✓${NC} Up to date: $current_version"
        return 1
    fi
}

# Update a package
# Usage: update_package "package_name"
update_package() {
    local package_name="$1"
    
    echo "${BLUE}Updating $package_name...${NC}"
    
    # Get package info from manifest
    local source_url
    source_url=$(awk -v pkg="$package_name" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    source:/ { print $2; exit }
    ' "$MANIFEST_FILE")
    
    # Clone latest version
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" RETURN
    
    if ! git clone --depth 1 "$source_url" "$temp_dir" &>/dev/null; then
        die "Failed to clone repository"
    fi
    
    # Parse new package metadata
    parse_package_metadata "$temp_dir"
    local new_commit
    new_commit=$(get_commit_hash "$temp_dir")
    
    # Get list of installed files from manifest
    local updated_count=0
    local skipped_count=0
    local modified_files=()
    
    # Check for modified files first
    for file_type in patterns commands design; do
        local files
        files=$(awk -v pkg="$package_name" -v type="$file_type" '
            BEGIN { in_pkg=0; in_type=0 }
            $0 ~ "^  " pkg ":" { in_pkg=1; next }
            in_pkg && /^  [a-z]/ { in_pkg=0 }
            in_pkg && $0 ~ "^      " type ":" { in_type=1; next }
            in_type && /^      [a-z]/ { in_type=0 }
            in_type && /^        - name:/ { print $3 }
        ' "$MANIFEST_FILE")
        
        for file_name in $files; do
            if is_file_modified "$package_name" "$file_type" "$file_name"; then
                modified_files+=("$file_type/$file_name")
            fi
        done
    done
    
    # Handle modified files
    if [ ${#modified_files[@]} -gt 0 ] && [ "$FORCE" = false ]; then
        echo ""
        echo "${YELLOW}⚠️  Modified files detected:${NC}"
        for file in "${modified_files[@]}"; do
            echo "  - $file"
        done
        echo ""
        
        if [ "$SKIP_MODIFIED" = true ]; then
            echo "Will skip modified files (--skip-modified)"
        elif [ "$AUTO_CONFIRM" = false ]; then
            read -p "Overwrite modified files? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                SKIP_MODIFIED=true
                echo "Skipping modified files"
            fi
        fi
        echo ""
    fi
    
    # Update files
    for file_type in patterns commands design; do
        local files
        files=$(awk -v pkg="$package_name" -v type="$file_type" '
            BEGIN { in_pkg=0; in_type=0 }
            $0 ~ "^  " pkg ":" { in_pkg=1; next }
            in_pkg && /^  [a-z]/ { in_pkg=0 }
            in_pkg && $0 ~ "^      " type ":" { in_type=1; next }
            in_type && /^      [a-z]/ { in_type=0 }
            in_type && /^        - name:/ { print $3 }
        ' "$MANIFEST_FILE")
        
        for file_name in $files; do
            # Check if file should be skipped
            if [ "$SKIP_MODIFIED" = true ]; then
                if printf '%s\n' "${modified_files[@]}" | grep -q "^${file_type}/${file_name}$"; then
                    echo "  ${YELLOW}⊘${NC} Skipped $file_type/$file_name (modified locally)"
                    ((skipped_count++))
                    continue
                fi
            fi
            
            # Check if file exists in new version
            if [ ! -f "$temp_dir/agent/$file_type/$file_name" ]; then
                warn "File no longer exists in package: $file_type/$file_name"
                ((skipped_count++))
                continue
            fi
            
            # Copy file
            cp "$temp_dir/agent/$file_type/$file_name" "agent/$file_type/"
            
            # Get new version and checksum
            local new_version
            new_version=$(get_file_version "$temp_dir/package.yaml" "$file_type" "$file_name")
            local new_checksum
            new_checksum=$(calculate_checksum "agent/$file_type/$file_name")
            
            # Update manifest
            update_file_in_manifest "$package_name" "$file_type" "$file_name" "$new_version" "$new_checksum"
            
            echo "  ${GREEN}✓${NC} Updated $file_type/$file_name (v$new_version)"
            ((updated_count++))
        done
    done
    
    # Update package metadata in manifest
    local timestamp
    timestamp=$(get_timestamp)
    
    # Update using awk
    local temp_file
    temp_file=$(mktemp)
    
    awk -v pkg="$package_name" -v ver="$PACKAGE_VERSION" -v commit="$new_commit" -v ts="$timestamp" '
        BEGIN { in_pkg=0 }
        $0 ~ "^  " pkg ":" { in_pkg=1; print; next }
        in_pkg && /^  [a-z]/ { in_pkg=0; print; next }
        in_pkg && /^    package_version:/ { print "    package_version: " ver; next }
        in_pkg && /^    commit:/ { print "    commit: " commit; next }
        in_pkg && /^    updated_at:/ { print "    updated_at: " ts; next }
        { print }
    ' "$MANIFEST_FILE" > "$temp_file"
    
    mv "$temp_file" "$MANIFEST_FILE"
    
    # Update manifest timestamp
    update_manifest_timestamp
    
    echo ""
    success "Updated $package_name: $updated_count file(s)"
    if [ $skipped_count -gt 0 ]; then
        echo "  Skipped: $skipped_count file(s)"
    fi
}

# Main script execution
echo "${BLUE}📦 ACP Package Updater${NC}"
echo "========================================"
echo ""

# Determine manifest file based on mode
if [ "$GLOBAL_MODE" = true ]; then
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    echo "${BLUE}Updating global packages...${NC}"
    echo ""
else
    MANIFEST_FILE="./agent/manifest.yaml"
    echo "${BLUE}Updating packages...${NC}"
    echo ""
fi

# Check if manifest exists
if [ ! -f "$MANIFEST_FILE" ]; then
    if [ "$GLOBAL_MODE" = true ]; then
        die "No global manifest found. No global packages installed."
    else
        die "No manifest found. No packages installed."
    fi
fi

# Source YAML parser
source_yaml_parser

# Get list of installed packages
INSTALLED_PACKAGES=$(awk '/^  [a-z]/ && !/^    / && /:$/ {gsub(/:/, ""); print $1}' "$MANIFEST_FILE")

if [ -z "$INSTALLED_PACKAGES" ]; then
    echo "${YELLOW}No packages installed${NC}"
    exit 0
fi

# If no package specified, update all
if [ -z "$PACKAGE_NAME" ]; then
    echo "Checking all packages for updates..."
    echo ""
    
    UPDATES_AVAILABLE=false
    for pkg in $INSTALLED_PACKAGES; do
        if check_package_for_updates "$pkg"; then
            UPDATES_AVAILABLE=true
        fi
    done
    
    if [ "$UPDATES_AVAILABLE" = false ]; then
        echo "${GREEN}✓${NC} All packages are up to date"
        exit 0
    fi
    
    if [ "$CHECK_ONLY" = true ]; then
        echo ""
        echo "To update all packages: $0"
        echo "To update specific package: $0 <package-name>"
        exit 0
    fi
    
    # Update all packages
    echo ""
    if [ "$AUTO_CONFIRM" = false ]; then
        read -p "Update all packages? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Update cancelled"
            exit 0
        fi
    fi
    
    echo ""
    for pkg in $INSTALLED_PACKAGES; do
        update_package "$pkg"
        echo ""
    done
else
    # Update specific package
    if ! echo "$INSTALLED_PACKAGES" | grep -q "^${PACKAGE_NAME}$"; then
        die "Package not installed: $PACKAGE_NAME"
    fi
    
    if check_package_for_updates "$PACKAGE_NAME"; then
        if [ "$CHECK_ONLY" = false ]; then
            echo ""
            update_package "$PACKAGE_NAME"
        fi
    else
        echo "${GREEN}✓${NC} Package is up to date"
    fi
fi

echo ""
echo "${GREEN}✅ Update complete!${NC}"
