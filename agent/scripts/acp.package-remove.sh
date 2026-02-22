#!/bin/bash

# Agent Context Protocol (ACP) Package Remove Script
# Removes installed ACP packages and updates manifest

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Parse arguments
PACKAGE_NAME=""
AUTO_CONFIRM=false
KEEP_MODIFIED=false
GLOBAL_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_MODE=true
            shift
            ;;
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        --keep-modified)
            KEEP_MODIFIED=true
            shift
            ;;
        *)
            PACKAGE_NAME="$1"
            shift
            ;;
    esac
done

# Check if package name provided
if [ -z "$PACKAGE_NAME" ]; then
    echo "${RED}Error: Package name required${NC}"
    echo "Usage: $0 [options] <package-name>"
    echo ""
    echo "Options:"
    echo "  --global, -g       Remove global package"
    echo "  -y, --yes          Skip confirmation prompts"
    echo "  --keep-modified    Keep locally modified files"
    echo ""
    echo "Example: $0 firebase"
    echo "Example: $0 --global firebase"
    echo "Example: $0 --keep-modified firebase"
    exit 1
fi

echo "${BLUE}📦 ACP Package Remover${NC}"
echo "========================================"
echo ""

# Determine manifest file based on mode
if [ "$GLOBAL_MODE" = true ]; then
    MANIFEST_FILE="$HOME/.acp/manifest.yaml"
    echo "${BLUE}Removing global package: $PACKAGE_NAME${NC}"
    echo ""
else
    MANIFEST_FILE="./agent/manifest.yaml"
    echo "${BLUE}Removing package: $PACKAGE_NAME${NC}"
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

# Check if package is installed
if ! package_exists "$PACKAGE_NAME"; then
    die "Package not installed: $PACKAGE_NAME"
fi

# Get package info
version=$(awk -v pkg="$PACKAGE_NAME" '
    $0 ~ "^  " pkg ":" { in_pkg=1; next }
    in_pkg && /^  [a-z]/ { in_pkg=0 }
    in_pkg && /^    package_version:/ { print $2; exit }
' "$MANIFEST_FILE")

echo "Package: ${GREEN}$PACKAGE_NAME${NC} ($version)"
echo ""

# Get installed files
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

# Count files (handle empty strings properly)
if [ -n "$patterns_files" ]; then
    patterns_count=$(echo "$patterns_files" | wc -l)
else
    patterns_count=0
fi

if [ -n "$commands_files" ]; then
    commands_count=$(echo "$commands_files" | wc -l)
else
    commands_count=0
fi

if [ -n "$designs_files" ]; then
    designs_count=$(echo "$designs_files" | wc -l)
else
    designs_count=0
fi

total_files=$((patterns_count + commands_count + designs_count))

echo "${YELLOW}⚠️  This will remove:${NC}"
[ "$patterns_count" -gt 0 ] && echo "  - $patterns_count pattern(s)"
[ "$commands_count" -gt 0 ] && echo "  - $commands_count command(s)"
[ "$designs_count" -gt 0 ] && echo "  - $designs_count design(s)"
echo ""
echo "Total: $total_files file(s)"
echo ""

# Check for modified files
modified_files=()
for file in $patterns_files; do
    if is_file_modified "$PACKAGE_NAME" "patterns" "$file"; then
        modified_files+=("patterns/$file")
    fi
done

for file in $commands_files; do
    if is_file_modified "$PACKAGE_NAME" "commands" "$file"; then
        modified_files+=("commands/$file")
    fi
done

for file in $designs_files; do
    if is_file_modified "$PACKAGE_NAME" "design" "$file"; then
        modified_files+=("design/$file")
    fi
done

if [ ${#modified_files[@]} -gt 0 ]; then
    echo "${YELLOW}⚠️  Modified files detected:${NC}"
    for file in "${modified_files[@]}"; do
        echo "  - $file"
    done
    echo ""
    
    if [ "$KEEP_MODIFIED" = true ]; then
        echo "Modified files will be kept (--keep-modified)"
        echo ""
    fi
fi

# Confirm removal
if [ "$AUTO_CONFIRM" = false ]; then
    read -p "Remove package '$PACKAGE_NAME'? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Removal cancelled"
        exit 0
    fi
fi

echo ""
echo "Removing files..."

# Remove files
removed_count=0
kept_count=0

for file in $patterns_files; do
    if printf '%s\n' "${modified_files[@]}" | grep -q "^patterns/$file$" && [ "$KEEP_MODIFIED" = true ]; then
        echo "  ${YELLOW}⊙${NC} Kept patterns/$file (modified)"
        kept_count=$((kept_count + 1))
    else
        if [ -f "agent/patterns/$file" ]; then
            rm "agent/patterns/$file"
            echo "  ${GREEN}✓${NC} Removed patterns/$file"
            removed_count=$((removed_count + 1))
        fi
    fi
done

for file in $commands_files; do
    if printf '%s\n' "${modified_files[@]}" | grep -q "^commands/$file$" && [ "$KEEP_MODIFIED" = true ]; then
        echo "  ${YELLOW}⊙${NC} Kept commands/$file (modified)"
        kept_count=$((kept_count + 1))
    else
        if [ -f "agent/commands/$file" ]; then
            rm "agent/commands/$file"
            echo "  ${GREEN}✓${NC} Removed commands/$file"
            removed_count=$((removed_count + 1))
        fi
    fi
done

for file in $designs_files; do
    if printf '%s\n' "${modified_files[@]}" | grep -q "^design/$file$" && [ "$KEEP_MODIFIED" = true ]; then
        echo "  ${YELLOW}⊙${NC} Kept design/$file (modified)"
        kept_count=$((kept_count + 1))
    else
        if [ -f "agent/design/$file" ]; then
            rm "agent/design/$file"
            echo "  ${GREEN}✓${NC} Removed design/$file"
            removed_count=$((removed_count + 1))
        fi
    fi
done

# Remove package from manifest
echo ""
echo "Updating manifest..."

temp_file=$(mktemp)
awk -v pkg="$PACKAGE_NAME" '
    BEGIN { in_pkg=0; skip=0 }
    $0 ~ "^  " pkg ":" { in_pkg=1; skip=1; next }
    in_pkg && /^  [a-z]/ && /:$/ { in_pkg=0; skip=0 }
    in_pkg { next }
    !skip { print }
' "$MANIFEST_FILE" > "$temp_file"

mv "$temp_file" "$MANIFEST_FILE"

# Update manifest timestamp
update_manifest_timestamp

echo "${GREEN}✓${NC} Manifest updated"
echo ""
echo "${GREEN}✅ Removal complete!${NC}"
echo ""
echo "Removed: $removed_count file(s)"
if [ $kept_count -gt 0 ]; then
    echo "Kept: $kept_count file(s) (modified)"
fi
echo ""
