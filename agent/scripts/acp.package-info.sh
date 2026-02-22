#!/bin/bash

# Agent Context Protocol (ACP) Package Info Script
# Shows detailed information about an installed package

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Parse arguments
GLOBAL_MODE=false
PACKAGE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_MODE=true
            shift
            ;;
        *)
            PACKAGE_NAME="$1"
            shift
            ;;
    esac
done

if [ -z "$PACKAGE_NAME" ]; then
    echo "${RED}Error: Package name required${NC}"
    echo "Usage: $0 [--global] <package-name>"
    echo ""
    echo "Example: $0 firebase"
    echo "Example: $0 --global firebase"
    echo ""
    echo "To see installed packages: ./agent/scripts/acp.package-list.sh [--global]"
    exit 1
fi

# Determine manifest file based on mode
if [ "$GLOBAL_MODE" = true ]; then
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    echo "${BLUE}📦 Global Package Information:${NC}"
else
    MANIFEST_FILE="./agent/manifest.yaml"
    echo "${BLUE}📦 Package Information:${NC}"
fi
echo ""

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

# Check if package is installed
if ! package_exists "$PACKAGE_NAME" "$MANIFEST_FILE"; then
    die "Package not installed: $PACKAGE_NAME"
fi

# Get package metadata
version=$(awk -v pkg="$PACKAGE_NAME" '
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^    package_version:/ { print $2; exit }
' "$MANIFEST_FILE")

source_url=$(awk -v pkg="$PACKAGE_NAME" '
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^    source:/ { print $2; exit }
' "$MANIFEST_FILE")

commit_hash=$(awk -v pkg="$PACKAGE_NAME" '
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^    commit:/ { print $2; exit }
' "$MANIFEST_FILE")

installed_at=$(awk -v pkg="$PACKAGE_NAME" '
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^    installed_at:/ { print $2; exit }
' "$MANIFEST_FILE")

updated_at=$(awk -v pkg="$PACKAGE_NAME" '
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^    updated_at:/ { print $2; exit }
' "$MANIFEST_FILE")

# Get location for global packages
location=""
if [ "$GLOBAL_MODE" = true ]; then
    location=$(awk -v pkg="$PACKAGE_NAME" '
        $0 ~ "^  " pkg ":" { in_pkg=1; next }
        in_pkg && /^  [a-z]/ { in_pkg=0 }
        in_pkg && /^    location:/ { print $2; exit }
    ' "$MANIFEST_FILE")
fi

# Display header
echo "${BLUE}📦 $PACKAGE_NAME${NC} (${GREEN}$version${NC})"
echo ""
if [ "$GLOBAL_MODE" = true ] && [ -n "$location" ]; then
    echo "${BLUE}Location:${NC} $location"
fi
echo "${BLUE}Source:${NC} $source_url"
echo "${BLUE}Commit:${NC} $commit_hash"
echo "${BLUE}Installed:${NC} $installed_at"
if [ "$installed_at" != "$updated_at" ]; then
    echo "${BLUE}Updated:${NC} $updated_at"
fi
echo ""

# Get installed files by type
patterns_files=$(awk -v pkg="$PACKAGE_NAME" '
    BEGIN { in_pkg=0; in_patterns=0 }
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^      patterns:/ { in_patterns=1; next }
    in_patterns && /^      [a-z]/ { in_patterns=0 }
    in_patterns && /^        - name:/ { print $3 }
' "$MANIFEST_FILE")

commands_files=$(awk -v pkg="$PACKAGE_NAME" '
    BEGIN { in_pkg=0; in_commands=0 }
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^      commands:/ { in_commands=1; next }
    in_commands && /^      [a-z]/ { in_commands=0 }
    in_commands && /^        - name:/ { print $3 }
' "$MANIFEST_FILE")

designs_files=$(awk -v pkg="$PACKAGE_NAME" '
    BEGIN { in_pkg=0; in_designs=0 }
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^      designs:/ { in_designs=1; next }
    in_designs && /^      [a-z]/ { in_designs=0 }
    in_designs && /^        - name:/ { print $3 }
' "$MANIFEST_FILE")

# Count files
patterns_count=$(echo "$patterns_files" | grep -c . || echo 0)
commands_count=$(echo "$commands_files" | grep -c . || echo 0)
designs_count=$(echo "$designs_files" | grep -c . || echo 0)
total_files=$((patterns_count + commands_count + designs_count))

echo "${BLUE}Contents:${NC}"
echo ""

# Display patterns
if [ "$patterns_count" -gt 0 ]; then
    echo "  ${GREEN}Patterns ($patterns_count):${NC}"
    for file in $patterns_files; do
        file_version=$(awk -v pkg="$PACKAGE_NAME" -v name="$file" '
            BEGIN { in_pkg=0; in_patterns=0; in_file=0 }
            $0 ~ "^  " pkg ":" { in_pkg=1; next }
            in_pkg && /^  [a-z]/ { in_pkg=0 }
            in_pkg && /^      patterns:/ { in_patterns=1; next }
            in_patterns && /^      [a-z]/ { in_patterns=0 }
            in_patterns && /^        - name:/ {
                if ($3 == name) { in_file=1 }
                else { in_file=0 }
                next
            }
            in_file && /^          version:/ { print $2; exit }
        ' "$MANIFEST_FILE")
        
        # Check if modified
        if is_file_modified "$PACKAGE_NAME" "patterns" "$file"; then
            echo "    - $file (v$file_version) ${YELLOW}[MODIFIED]${NC}"
        else
            echo "    - $file (v$file_version)"
        fi
    done
    echo ""
fi

# Display commands
if [ "$commands_count" -gt 0 ]; then
    echo "  ${GREEN}Commands ($commands_count):${NC}"
    for file in $commands_files; do
        file_version=$(awk -v pkg="$PACKAGE_NAME" -v name="$file" '
            BEGIN { in_pkg=0; in_commands=0; in_file=0 }
            $0 ~ "^  " pkg ":" { in_pkg=1; next }
            in_pkg && /^  [a-z]/ { in_pkg=0 }
            in_pkg && /^      commands:/ { in_commands=1; next }
            in_commands && /^      [a-z]/ { in_commands=0 }
            in_commands && /^        - name:/ {
                if ($3 == name) { in_file=1 }
                else { in_file=0 }
                next
            }
            in_file && /^          version:/ { print $2; exit }
        ' "$MANIFEST_FILE")
        
        # Check if modified
        if is_file_modified "$PACKAGE_NAME" "commands" "$file"; then
            echo "    - $file (v$file_version) ${YELLOW}[MODIFIED]${NC}"
        else
            echo "    - $file (v$file_version)"
        fi
    done
    echo ""
fi

# Display designs
if [ "$designs_count" -gt 0 ]; then
    echo "  ${GREEN}Designs ($designs_count):${NC}"
    for file in $designs_files; do
        file_version=$(awk -v pkg="$PACKAGE_NAME" -v name="$file" '
            BEGIN { in_pkg=0; in_designs=0; in_file=0 }
            $0 ~ "^  " pkg ":" { in_pkg=1; next }
            in_pkg && /^  [a-z]/ { in_pkg=0 }
            in_pkg && /^      designs:/ { in_designs=1; next }
            in_designs && /^      [a-z]/ { in_designs=0 }
            in_designs && /^        - name:/ {
                if ($3 == name) { in_file=1 }
                else { in_file=0 }
                next
            }
            in_file && /^          version:/ { print $2; exit }
        ' "$MANIFEST_FILE")
        
        # Check if modified
        if is_file_modified "$PACKAGE_NAME" "design" "$file"; then
            echo "    - $file (v$file_version) ${YELLOW}[MODIFIED]${NC}"
        else
            echo "    - $file (v$file_version)"
        fi
    done
    echo ""
fi

# Count modified files
modified_count=0
for file in $patterns_files; do
    if is_file_modified "$PACKAGE_NAME" "patterns" "$file"; then
        ((modified_count++))
    fi
done
for file in $commands_files; do
    if is_file_modified "$PACKAGE_NAME" "commands" "$file"; then
        ((modified_count++))
    fi
done
for file in $designs_files; do
    if is_file_modified "$PACKAGE_NAME" "design" "$file"; then
        ((modified_count++))
    fi
done

if [ $modified_count -gt 0 ]; then
    echo "${YELLOW}Modified Files: $modified_count${NC}"
    echo ""
fi

echo "Total Files: $total_files"
echo ""
