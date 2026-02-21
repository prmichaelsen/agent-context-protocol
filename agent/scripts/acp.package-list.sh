#!/bin/bash

# Agent Context Protocol (ACP) Package List Script
# Lists installed ACP packages with their versions and details

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Parse arguments
VERBOSE=false
OUTDATED=false
MODIFIED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --outdated)
            OUTDATED=true
            shift
            ;;
        --modified)
            MODIFIED=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Check if manifest exists
if [ ! -f "agent/manifest.yaml" ]; then
    echo "${YELLOW}No packages installed${NC}"
    echo ""
    echo "To install a package:"
    echo "  ./agent/scripts/acp.package-install.sh <repository-url>"
    exit 0
fi

# Source YAML parser
source_yaml_parser

# Get list of installed packages
INSTALLED_PACKAGES=$(awk '/^  [a-z]/ && !/^    / && /:$/ {gsub(/:/, ""); print $1}' agent/manifest.yaml)

if [ -z "$INSTALLED_PACKAGES" ]; then
    echo "${YELLOW}No packages installed${NC}"
    exit 0
fi

echo "${BLUE}📦 Installed ACP Packages${NC}"
echo ""

PACKAGE_COUNT=0
DISPLAYED_COUNT=0

for package in $INSTALLED_PACKAGES; do
    PACKAGE_COUNT=$((PACKAGE_COUNT + 1))
    
    # Get package info from manifest
    version=$(awk -v pkg="$package" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    package_version:/ { print $2; exit }
    ' agent/manifest.yaml)
    
    source_url=$(awk -v pkg="$package" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    source:/ { print $2; exit }
    ' agent/manifest.yaml)
    
    installed_at=$(awk -v pkg="$package" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    installed_at:/ { print $2; exit }
    ' agent/manifest.yaml)
    
    updated_at=$(awk -v pkg="$package" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    updated_at:/ { print $2; exit }
    ' agent/manifest.yaml)
    
    # Count files
    patterns_count=$(awk -v pkg="$package" '
        BEGIN { in_pkg=0; in_patterns=0; count=0 }
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^      patterns:/ { in_patterns=1; next }
        in_patterns && /^      [a-z]/ { in_patterns=0 }
        in_patterns && /^        - name:/ { count++ }
        END { print count }
    ' agent/manifest.yaml)
    
    commands_count=$(awk -v pkg="$package" '
        BEGIN { in_pkg=0; in_commands=0; count=0 }
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^      commands:/ { in_commands=1; next }
        in_commands && /^      [a-z]/ { in_commands=0 }
        in_commands && /^        - name:/ { count++ }
        END { print count }
    ' agent/manifest.yaml)
    
    designs_count=$(awk -v pkg="$package" '
        BEGIN { in_pkg=0; in_designs=0; count=0 }
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^      designs:/ { in_designs=1; next }
        in_designs && /^      [a-z]/ { in_designs=0 }
        in_designs && /^        - name:/ { count++ }
        END { print count }
    ' agent/manifest.yaml)
    
    total_files=$((patterns_count + commands_count + designs_count))
    
    # Check if package has updates (for --outdated filter)
    has_updates=false
    if [ "$OUTDATED" = true ]; then
        # Create temp dir for checking
        temp_dir=$(mktemp -d)
        trap "rm -rf $temp_dir" RETURN
        
        if git clone --depth 1 "$source_url" "$temp_dir" &>/dev/null 2>&1; then
            if [ -f "$temp_dir/package.yaml" ]; then
                remote_version=$(awk '/^version:/ {print $2; exit}' "$temp_dir/package.yaml")
                comparison=$(compare_versions "$version" "$remote_version")
                if [ "$comparison" = "newer" ]; then
                    has_updates=true
                fi
            fi
        fi
        
        rm -rf "$temp_dir"
        
        # Skip if no updates and filtering for outdated
        if [ "$has_updates" = false ]; then
            continue
        fi
    fi
    
    # Check if package has modified files (for --modified filter)
    has_modified=false
    if [ "$MODIFIED" = true ]; then
        for file_type in patterns commands design; do
            files=$(awk -v pkg="$package" -v type="$file_type" '
                BEGIN { in_pkg=0; in_type=0 }
                $0 ~ "^  " pkg ":" { in_pkg=1; next }
                in_pkg && /^  [a-z]/ { in_pkg=0 }
                in_pkg && $0 ~ "^      " type ":" { in_type=1; next }
                in_type && /^      [a-z]/ { in_type=0 }
                in_type && /^        - name:/ { print $3 }
            ' agent/manifest.yaml)
            
            for file_name in $files; do
                if is_file_modified "$package" "$file_type" "$file_name"; then
                    has_modified=true
                    break 2
                fi
            done
        done
        
        # Skip if no modifications and filtering for modified
        if [ "$has_modified" = false ]; then
            continue
        fi
    fi
    DISPLAYED_COUNT=$((DISPLAYED_COUNT + 1))
    
    
    # Display package info
    echo "${GREEN}$package${NC} ($version) - $total_files file(s)"
    
    if [ "$VERBOSE" = true ]; then
        echo "  ${BLUE}Source:${NC} $source_url"
        echo "  ${BLUE}Installed:${NC} $installed_at"
        if [ "$installed_at" != "$updated_at" ]; then
            echo "  ${BLUE}Updated:${NC} $updated_at"
        fi
        echo "  ${BLUE}Files:${NC}"
        [ "$patterns_count" -gt 0 ] && echo "    - $patterns_count pattern(s)"
        [ "$commands_count" -gt 0 ] && echo "    - $commands_count command(s)"
        [ "$designs_count" -gt 0 ] && echo "    - $designs_count design(s)"
        
        # Show modified files if any
        if [ "$has_modified" = true ]; then
            echo "  ${YELLOW}Modified files:${NC}"
            for file_type in patterns commands design; do
                files=$(awk -v pkg="$package" -v type="$file_type" '
                    BEGIN { in_pkg=0; in_type=0 }
                    $0 ~ "^  " pkg ":" { in_pkg=1; next }
                    in_pkg && /^  [a-z]/ { in_pkg=0 }
                    in_pkg && $0 ~ "^      " type ":" { in_type=1; next }
                    in_type && /^      [a-z]/ { in_type=0 }
                    in_type && /^        - name:/ { print $3 }
                ' agent/manifest.yaml)
                
                for file_name in $files; do
                    if is_file_modified "$package" "$file_type" "$file_name"; then
                        echo "    - $file_type/$file_name"
                    fi
                done
            done
        fi
        
        # Show update status if checking outdated
        if [ "$has_updates" = true ]; then
            echo "  ${GREEN}Update available${NC}"
        fi
        
        echo ""
    fi
done

echo ""
echo "Total: $DISPLAYED_COUNT of $PACKAGE_COUNT package(s)"

if [ "$OUTDATED" = true ] && [ $DISPLAYED_COUNT -eq 0 ]; then
    echo "${GREEN}✓${NC} All packages are up to date"
fi

if [ "$MODIFIED" = true ] && [ $DISPLAYED_COUNT -eq 0 ]; then
    echo "${GREEN}✓${NC} No packages have local modifications"
fi
