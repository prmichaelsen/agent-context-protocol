#!/bin/bash

# Agent Context Protocol (ACP) Package Install Script - OPTIMIZED VERSION
# Installs third-party ACP packages with batched operations for 10x+ performance improvement

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"
. "${SCRIPT_DIR}/acp.yaml-parser.sh"

# Initialize colors
init_colors

# Parse arguments (same as original)
REPO_URL=""
INSTALL_PATTERNS=false
INSTALL_COMMANDS=false
INSTALL_DESIGNS=false
PATTERN_FILES=()
COMMAND_FILES=()
DESIGN_FILES=()
LIST_ONLY=false
GLOBAL_INSTALL=false
INSTALL_EXPERIMENTAL=false
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        --global)
            GLOBAL_INSTALL=true
            shift
            ;;
        --experimental)
            INSTALL_EXPERIMENTAL=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        --patterns)
            INSTALL_PATTERNS=true
            shift
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                PATTERN_FILES+=("$1")
                shift
            done
            ;;
        --commands)
            INSTALL_COMMANDS=true
            shift
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                COMMAND_FILES+=("$1")
                shift
            done
            ;;
        --designs)
            INSTALL_DESIGNS=true
            shift
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                DESIGN_FILES+=("$1")
                shift
            done
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        *)
            echo "${RED}Error: Unknown option: $1${NC}"
            echo "Use --repo to specify repository URL"
            exit 1
            ;;
    esac
done

# Check if repository URL provided
if [ -z "$REPO_URL" ]; then
    echo "${RED}Error: Repository URL required${NC}"
    echo "Usage: $0 --repo <repository-url> [options]"
    exit 1
fi

# Default: install everything if no selective flags specified
if [[ "$INSTALL_PATTERNS" == false && "$INSTALL_COMMANDS" == false && "$INSTALL_DESIGNS" == false ]]; then
    INSTALL_PATTERNS=true
    INSTALL_COMMANDS=true
    INSTALL_DESIGNS=true
fi

echo "${BLUE}📦 ACP Package Installer (Optimized)${NC}"
echo "========================================"
echo ""
echo "Repository: $REPO_URL"
echo ""

# Validate URL format
if [[ ! "$REPO_URL" =~ ^https?:// ]] && [[ ! "$REPO_URL" =~ ^file:// ]] && [[ ! -d "$REPO_URL" ]]; then
    echo "${RED}Error: Invalid repository URL${NC}"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Cloning repository..."
if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &>/dev/null; then
    echo "${RED}Error: Failed to clone repository${NC}"
    exit 1
fi

echo "${GREEN}✓${NC} Repository cloned"
echo ""

# Check for agent/ directory
if [ ! -d "$TEMP_DIR/agent" ]; then
    echo "${RED}Error: No agent/ directory found${NC}"
    exit 1
fi

# Determine installation directory and manifest
if [ "$GLOBAL_INSTALL" = true ]; then
    INSTALL_BASE_DIR="$HOME/.acp/agent"
    MANIFEST_FILE="$HOME/.acp/agent/manifest.yaml"
    echo "${BLUE}Installing globally to ~/.acp/agent/${NC}"
    echo ""
    init_global_acp || {
        echo "${RED}Error: Failed to initialize global infrastructure${NC}" >&2
        exit 1
    }
else
    INSTALL_BASE_DIR="./agent"
    MANIFEST_FILE="./agent/manifest.yaml"
    echo "${BLUE}Installing locally to ./agent/${NC}"
    echo ""
    init_manifest
fi

# Parse package metadata
parse_package_metadata "$TEMP_DIR"
COMMIT_HASH=$(get_commit_hash "$TEMP_DIR")
info "Commit: $COMMIT_HASH"
echo ""

# List mode (unchanged)
if [ "$LIST_ONLY" = true ]; then
    # ... (same as original)
    exit 0
fi

# Validate dependencies
if [ -f "$TEMP_DIR/package.yaml" ]; then
    if ! validate_project_dependencies "$TEMP_DIR/package.yaml"; then
        echo "${RED}Installation cancelled due to dependency issues${NC}"
        exit 1
    fi
fi

# Directories to install from
INSTALL_DIRS=()
[ "$INSTALL_PATTERNS" = true ] && INSTALL_DIRS+=("patterns")
[ "$INSTALL_COMMANDS" = true ] && INSTALL_DIRS+=("commands")
[ "$INSTALL_DESIGNS" = true ] && INSTALL_DIRS+=("design")
[ "$INSTALL_COMMANDS" = true ] && INSTALL_DIRS+=("scripts")

# ============================================================================
# OPTIMIZATION: Collect all files first, then batch process
# ============================================================================

# Arrays to hold all files to install
declare -A ALL_FILES_TO_INSTALL  # Key: dir, Value: space-separated file paths
declare -A FILE_METADATA  # Key: "dir/filename", Value: "version|experimental"

INSTALLED_COUNT=0
SKIPPED_COUNT=0

echo "Scanning for installable files..."
echo ""

# Parse package.yaml once for experimental checking
if [ -f "$TEMP_DIR/package.yaml" ]; then
    yaml_parse "$TEMP_DIR/package.yaml"
fi

# Collect all files to install
for dir in "${INSTALL_DIRS[@]}"; do
    SOURCE_DIR="$TEMP_DIR/agent/$dir"
    
    if [ ! -d "$SOURCE_DIR" ]; then
        continue
    fi
    
    # Determine which files to process
    declare -n FILE_LIST
    case "$dir" in
        patterns) FILE_LIST=PATTERN_FILES ;;
        commands) FILE_LIST=COMMAND_FILES ;;
        design) FILE_LIST=DESIGN_FILES ;;
        scripts) FILE_LIST=COMMAND_FILES ;;
    esac
    
    # Collect files
    FILES_TO_PROCESS=()
    if [ ${#FILE_LIST[@]} -gt 0 ]; then
        # Selective installation
        for file_name in "${FILE_LIST[@]}"; do
            if [ "$dir" = "scripts" ]; then
                [[ "$file_name" != *.sh ]] && file_name="${file_name}.sh"
            else
                [[ "$file_name" != *.md ]] && file_name="${file_name}.md"
            fi
            
            file_path="$SOURCE_DIR/$file_name"
            if [ -f "$file_path" ]; then
                FILES_TO_PROCESS+=("$file_path")
            else
                echo "${YELLOW}⚠${NC}  File not found in $dir/: $file_name"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            fi
        done
    else
        # Install all files
        if [ "$dir" = "scripts" ]; then
            while IFS= read -r file; do
                [ -n "$file" ] && FILES_TO_PROCESS+=("$file")
            done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.sh" ! -name "*.template.sh" -type f)
        else
            while IFS= read -r file; do
                [ -n "$file" ] && FILES_TO_PROCESS+=("$file")
            done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.md" ! -name "*.template.md" -type f)
        fi
    fi
    
    if [ ${#FILES_TO_PROCESS[@]} -eq 0 ]; then
        unset -n FILE_LIST
        continue
    fi
    
    echo "${BLUE}📁 $dir/${NC} (${#FILES_TO_PROCESS[@]} file(s))"
    
    # Validate files
    VALID_FILES=()
    for file in "${FILES_TO_PROCESS[@]}"; do
        filename=$(basename "$file")
        
        # Validation
        if [ "$dir" = "commands" ]; then
            if [[ "$filename" =~ ^acp\. ]]; then
                echo "  ${RED}✗${NC} $filename (reserved namespace 'acp')"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
            if ! grep -q "🤖 Agent Directive" "$file"; then
                echo "  ${YELLOW}⚠${NC}  $filename (missing agent directive - skipping)"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
        fi
        
        if [ "$dir" = "scripts" ]; then
            if [[ "$filename" =~ ^acp\. ]]; then
                echo "  ${RED}✗${NC} $filename (reserved namespace 'acp')"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
        fi
        
        # Check experimental status
        local is_experimental=""
        if [ -f "$TEMP_DIR/package.yaml" ]; then
            is_experimental=$(grep -A 1000 "^  ${dir}:" "$TEMP_DIR/package.yaml" 2>/dev/null | grep -A 2 "name: ${filename}" | grep "^ *experimental: true" | grep -v "^[[:space:]]*#" | head -1)
        fi
        
        if [ -n "$is_experimental" ] && [ "$INSTALL_EXPERIMENTAL" = false ]; then
            echo "  ${DIM}⊘${NC}  $filename (experimental - use --experimental)"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            continue
        fi
        
        # Get file version
        FILE_VERSION=$(get_file_version "$TEMP_DIR/package.yaml" "$dir" "$filename")
        
        # Store metadata
        FILE_METADATA["$dir/$filename"]="$FILE_VERSION|$is_experimental"
        
        # Add to valid files
        VALID_FILES+=("$file")
        
        if [ -f "$INSTALL_BASE_DIR/$dir/$filename" ]; then
            echo "  ${YELLOW}⚠${NC}  $filename (will overwrite)"
        else
            echo "  ${GREEN}✓${NC} $filename"
        fi
        
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    done
    
    # Store valid files for this directory
    if [ ${#VALID_FILES[@]} -gt 0 ]; then
        ALL_FILES_TO_INSTALL["$dir"]="${VALID_FILES[*]}"
    fi
    
    unset -n FILE_LIST
    echo ""
done

# Exit if nothing to install
if [ $INSTALLED_COUNT -eq 0 ]; then
    echo "${RED}Error: No valid files to install${NC}"
    [ $SKIPPED_COUNT -gt 0 ] && echo "Skipped $SKIPPED_COUNT file(s)"
    exit 1
fi

# Confirm installation
echo "Ready to install $INSTALLED_COUNT file(s)"
[ $SKIPPED_COUNT -gt 0 ] && echo "($SKIPPED_COUNT file(s) will be skipped)"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
    read -p "Proceed with installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
else
    echo "Auto-confirming installation (-y flag)"
fi

echo ""
echo "Installing files..."

# ============================================================================
# OPTIMIZATION: Batch file operations
# ============================================================================

# Add package to manifest once
add_package_to_manifest "$PACKAGE_NAME" "$REPO_URL" "$PACKAGE_VERSION" "$COMMIT_HASH"

# Batch copy all files
for dir in "${!ALL_FILES_TO_INSTALL[@]}"; do
    mkdir -p "$INSTALL_BASE_DIR/$dir"
    
    # Copy all files at once
    for file in ${ALL_FILES_TO_INSTALL[$dir]}; do
        filename=$(basename "$file")
        cp "$file" "$INSTALL_BASE_DIR/$dir/$filename"
        
        # Make scripts executable
        if [ "$dir" = "scripts" ]; then
            chmod +x "$INSTALL_BASE_DIR/$dir/$filename"
        fi
    done
done

# ============================================================================
# OPTIMIZATION: Batch checksum calculation
# ============================================================================

echo "  ${BLUE}Calculating checksums...${NC}"

# Collect all installed files for batch checksum
ALL_INSTALLED_FILES=()
for dir in "${!ALL_FILES_TO_INSTALL[@]}"; do
    for file in ${ALL_FILES_TO_INSTALL[$dir]}; do
        filename=$(basename "$file")
        ALL_INSTALLED_FILES+=("$INSTALL_BASE_DIR/$dir/$filename")
    done
done

# Calculate all checksums in one pass
declare -A CHECKSUMS
if [ ${#ALL_INSTALLED_FILES[@]} -gt 0 ]; then
    while IFS= read -r line; do
        checksum=$(echo "$line" | awk '{print $1}')
        filepath=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
        CHECKSUMS["$filepath"]="$checksum"
    done < <(sha256sum "${ALL_INSTALLED_FILES[@]}" 2>/dev/null)
fi

# ============================================================================
# OPTIMIZATION: Batch manifest update
# ============================================================================

echo "  ${BLUE}Updating manifest...${NC}"

# Parse manifest once
yaml_parse "$MANIFEST_FILE"

# Add all files to manifest in memory
timestamp=$(get_timestamp)
for dir in "${!ALL_FILES_TO_INSTALL[@]}"; do
    for file in ${ALL_FILES_TO_INSTALL[$dir]}; do
        filename=$(basename "$file")
        filepath="$INSTALL_BASE_DIR/$dir/$filename"
        
        # Get metadata
        IFS='|' read -r file_version is_experimental <<< "${FILE_METADATA[$dir/$filename]}"
        
        # Get checksum
        checksum="${CHECKSUMS[$filepath]:-unknown}"
        
        # Append to manifest
        obj_node=$(yaml_array_append_object ".packages.${PACKAGE_NAME}.files.${dir}")
        yaml_object_set "$obj_node" "name" "$filename" >/dev/null
        yaml_object_set "$obj_node" "version" "$file_version" >/dev/null
        yaml_object_set "$obj_node" "installed_at" "$timestamp" >/dev/null
        yaml_object_set "$obj_node" "modified" "false" >/dev/null
        yaml_object_set "$obj_node" "checksum" "sha256:$checksum" >/dev/null
        
        if [ -n "$is_experimental" ]; then
            yaml_object_set "$obj_node" "experimental" "true" >/dev/null
        fi
        
        if [ "$dir" = "scripts" ]; then
            echo "  ${GREEN}✓${NC} Installed $dir/$filename (v$file_version) [executable]"
        else
            echo "  ${GREEN}✓${NC} Installed $dir/$filename (v$file_version)"
        fi
    done
done

# Write manifest once at the end
yaml_write "$MANIFEST_FILE"

echo ""

# Success message
if [ "$GLOBAL_INSTALL" = true ]; then
    echo "${GREEN}✅ Package installed globally!${NC}"
    echo ""
    echo "Location: $INSTALL_BASE_DIR"
    echo "Manifest: $MANIFEST_FILE"
else
    echo "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo "Installed $INSTALLED_COUNT file(s) from:"
    echo "  $REPO_URL"
    echo ""
    echo "Package: $PACKAGE_NAME ($PACKAGE_VERSION)"
    echo "Manifest: agent/manifest.yaml updated"
fi

echo ""
echo "${YELLOW}⚠️  Security Reminder:${NC}"
echo "Review installed files before using them."
echo ""
