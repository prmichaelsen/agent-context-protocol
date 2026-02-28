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
INSTALL_FILES=false
PATTERN_FILES=()
COMMAND_FILES=()
DESIGN_FILES=()
FILE_FILES=()
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
            while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                PATTERN_FILES+=("$1")
                shift
            done
            ;;
        --commands)
            INSTALL_COMMANDS=true
            shift
            while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                COMMAND_FILES+=("$1")
                shift
            done
            ;;
        --designs)
            INSTALL_DESIGNS=true
            shift
            while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                DESIGN_FILES+=("$1")
                shift
            done
            ;;
        --files)
            INSTALL_FILES=true
            shift
            while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                FILE_FILES+=("$1")
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
if [[ "$INSTALL_PATTERNS" == false && "$INSTALL_COMMANDS" == false && "$INSTALL_DESIGNS" == false && "$INSTALL_FILES" == false ]]; then
    INSTALL_PATTERNS=true
    INSTALL_COMMANDS=true
    INSTALL_DESIGNS=true
    INSTALL_FILES=true
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
if [ -d "$REPO_URL" ]; then
    # Local directory - copy contents instead of clone
    cp -r "$REPO_URL"/* "$TEMP_DIR/" 2>/dev/null || cp -r "$REPO_URL"/.[!.]* "$TEMP_DIR/" 2>/dev/null || true
    echo "${GREEN}✓${NC} Local directory copied"
elif ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &>/dev/null; then
    echo "${RED}Error: Failed to clone repository${NC}"
    exit 1
else
    echo "${GREEN}✓${NC} Repository cloned"
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
[ "$INSTALL_FILES" = true ] && INSTALL_DIRS+=("files")

# Mapping from dir names to manifest keys (dir → manifest key)
declare -A MANIFEST_KEYS=(
    ["patterns"]="patterns"
    ["commands"]="commands"
    ["design"]="designs"
    ["scripts"]="scripts"
    ["files"]="files"
)

# ============================================================================
# OPTIMIZATION: Collect all files first, then batch process
# ============================================================================

# Arrays to hold all files to install
declare -A ALL_FILES_TO_INSTALL  # Key: dir, Value: space-separated file paths
declare -A FILE_METADATA  # Key: "dir/filename", Value: "version|experimental"

# Track installed commands for script-command binding resolution
INSTALLED_COMMANDS=()

INSTALLED_COUNT=0
SKIPPED_COUNT=0

# Template file metadata (populated during scanning when contents.files exists)
declare -A FILE_TARGETS    # Key: "files/relpath", Value: target directory path
declare -A FILE_VARS       # Key: "files/relpath", Value: "VAR1,VAR2,..."
declare -A COLLECTED_VARS  # Key: "VARNAME", Value: user-provided value
HAS_FILE_METADATA=false

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
        files) FILE_LIST=FILE_FILES ;;
    esac

    # Collect files
    FILES_TO_PROCESS=()
    if [ ${#FILE_LIST[@]} -gt 0 ]; then
        # Selective installation
        for file_name in "${FILE_LIST[@]}"; do
            if [ "$dir" = "scripts" ]; then
                [[ "$file_name" != *.sh ]] && file_name="${file_name}.sh"
            elif [ "$dir" != "files" ]; then
                [[ "$file_name" != *.md ]] && file_name="${file_name}.md"
            fi

            file_path="$SOURCE_DIR/$file_name"
            if [ -f "$file_path" ]; then
                FILES_TO_PROCESS+=("$file_path")

                # For selective files, also collect metadata from package.yaml
                if [ "$dir" = "files" ] && [ -f "$TEMP_DIR/package.yaml" ]; then
                    _sel_idx=0
                    while true; do
                        _sel_name=$(yaml_query ".contents.files[$_sel_idx].name" 2>/dev/null || echo "")
                        [ -z "$_sel_name" ] || [ "$_sel_name" = "null" ] && break
                        if [ "$_sel_name" = "$file_name" ]; then
                            HAS_FILE_METADATA=true
                            _sel_target=$(yaml_query ".contents.files[$_sel_idx].target" 2>/dev/null || echo "")
                            [ -n "$_sel_target" ] && [ "$_sel_target" != "null" ] && FILE_TARGETS["files/$file_name"]="$_sel_target"
                            _sel_var_idx=0
                            _sel_vars=""
                            while true; do
                                _sel_var=$(yaml_query ".contents.files[$_sel_idx].variables[$_sel_var_idx]" 2>/dev/null || echo "")
                                [ -z "$_sel_var" ] || [ "$_sel_var" = "null" ] && break
                                [ -n "$_sel_vars" ] && _sel_vars="$_sel_vars,$_sel_var" || _sel_vars="$_sel_var"
                                _sel_var_idx=$((_sel_var_idx + 1))
                            done
                            [ -n "$_sel_vars" ] && FILE_VARS["files/$file_name"]="$_sel_vars"
                            break
                        fi
                        _sel_idx=$((_sel_idx + 1))
                    done
                fi
            else
                echo "${YELLOW}⚠${NC}  File not found in $dir/: $file_name"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            fi
        done
    else
        # Install all files
        if [ "$dir" = "files" ]; then
            # Check if package.yaml has contents.files metadata
            _first_file=$(yaml_query ".contents.files[0].name" 2>/dev/null || echo "")
            if [ -f "$TEMP_DIR/package.yaml" ] && [ -n "$_first_file" ] && [ "$_first_file" != "null" ]; then
                # Use package.yaml contents.files as source of truth
                HAS_FILE_METADATA=true
                _file_idx=0
                while true; do
                    _fname=$(yaml_query ".contents.files[$_file_idx].name" 2>/dev/null || echo "")
                    [ -z "$_fname" ] || [ "$_fname" = "null" ] && break

                    if [ -f "$SOURCE_DIR/$_fname" ]; then
                        FILES_TO_PROCESS+=("$SOURCE_DIR/$_fname")

                        # Store target metadata
                        _target=$(yaml_query ".contents.files[$_file_idx].target" 2>/dev/null || echo "")
                        [ -n "$_target" ] && [ "$_target" != "null" ] && FILE_TARGETS["files/$_fname"]="$_target"

                        # Collect variable names
                        _var_idx=0
                        _vars=""
                        while true; do
                            _var=$(yaml_query ".contents.files[$_file_idx].variables[$_var_idx]" 2>/dev/null || echo "")
                            [ -z "$_var" ] || [ "$_var" = "null" ] && break
                            [ -n "$_vars" ] && _vars="$_vars,$_var" || _vars="$_var"
                            _var_idx=$((_var_idx + 1))
                        done
                        [ -n "$_vars" ] && FILE_VARS["files/$_fname"]="$_vars"
                    else
                        echo "  ${YELLOW}⚠${NC}  Declared in package.yaml but not found: agent/files/$_fname"
                        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                    fi

                    _file_idx=$((_file_idx + 1))
                done
            else
                # Fallback: recursive scan (backward compat for packages without contents.files)
                while IFS= read -r file; do
                    [ -n "$file" ] && FILES_TO_PROCESS+=("$file")
                done < <(find "$SOURCE_DIR" -type f)
            fi
        elif [ "$dir" = "scripts" ]; then
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
    
    if [ "$dir" = "files" ] && [ "$HAS_FILE_METADATA" = false ]; then
        echo "${BLUE}📁 $dir/${NC} (${#FILES_TO_PROCESS[@]} file(s)) → installs to ./"
    else
        echo "${BLUE}📁 $dir/${NC} (${#FILES_TO_PROCESS[@]} file(s))"
    fi
    
    # Validate files
    VALID_FILES=()
    for file in "${FILES_TO_PROCESS[@]}"; do
        # For files/ dir, use relative path from SOURCE_DIR; otherwise basename
        if [ "$dir" = "files" ]; then
            filename="${file#$SOURCE_DIR/}"
        else
            filename=$(basename "$file")
        fi

        # Validation (not applied to files/ directory)
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
        is_experimental=""
        if [ -f "$TEMP_DIR/package.yaml" ]; then
            if [ "$dir" = "files" ] && [ "$HAS_FILE_METADATA" = false ]; then
                : # No per-file experimental marking without metadata
            elif [ "$dir" = "files" ]; then
                # Files entries have more fields (name, description, target, required, experimental)
                # so need a wider context window (-A 6) to catch experimental: true
                is_experimental=$(grep -A 1000 "^  ${dir}:" "$TEMP_DIR/package.yaml" 2>/dev/null | grep -A 6 "name: ${filename}" | grep "^ *experimental: true" | grep -v "^[[:space:]]*#" | head -1)
            else
                is_experimental=$(grep -A 1000 "^  ${dir}:" "$TEMP_DIR/package.yaml" 2>/dev/null | grep -A 2 "name: ${filename}" | grep "^ *experimental: true" | grep -v "^[[:space:]]*#" | head -1)
            fi
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

        # Determine target path for overwrite check
        if [ "$dir" = "files" ] && [ "$HAS_FILE_METADATA" = true ]; then
            _file_target="${FILE_TARGETS[files/$filename]:-./}"
            _bname=$(basename "$filename")
            _bname="${_bname%.template}"
            target_path="${_file_target}${_bname}"
        elif [ "$dir" = "files" ]; then
            target_path="./$filename"
        else
            target_path="$INSTALL_BASE_DIR/$dir/$filename"
        fi

        # Build display info for files with metadata
        _display_extra=""
        if [ "$dir" = "files" ] && [ "$HAS_FILE_METADATA" = true ]; then
            _file_vars="${FILE_VARS[files/$filename]:-}"
            _display_extra=" → $target_path"
            [ -n "$_file_vars" ] && _display_extra="$_display_extra (variables: $_file_vars)"
        fi

        if [ -f "$target_path" ]; then
            echo "  ${YELLOW}⚠${NC}  $filename${_display_extra} (will overwrite)"
        else
            echo "  ${GREEN}✓${NC} $filename${_display_extra}"
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

# Warn about unrecognized directories in the package
KNOWN_DIRS="patterns commands design scripts files"
if [ -d "$TEMP_DIR/agent" ]; then
    UNRECOGNIZED=()
    while IFS= read -r pkg_dir; do
        dir_name=$(basename "$pkg_dir")
        if ! echo " $KNOWN_DIRS " | grep -q " $dir_name "; then
            UNRECOGNIZED+=("$dir_name")
        fi
    done < <(find "$TEMP_DIR/agent" -mindepth 1 -maxdepth 1 -type d)

    if [ ${#UNRECOGNIZED[@]} -gt 0 ]; then
        echo "${YELLOW}⚠  Unrecognized directories in package (not installed):${NC}"
        for udir in "${UNRECOGNIZED[@]}"; do
            echo "    $udir/"
        done
        echo ""
    fi
fi

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

if [ "$LIST_ONLY" = true ]; then
    echo "${BLUE}(dry run — no files were installed)${NC}"
    exit 0
fi

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

# Collect template variables from user (if any files have variables declared)
if [ ${#FILE_VARS[@]} -gt 0 ]; then
    echo "${BLUE}Collecting template variables...${NC}"

    # Build list of unique variables across all templates
    _all_vars=""
    for _key in "${!FILE_VARS[@]}"; do
        IFS=',' read -ra _var_arr <<< "${FILE_VARS[$_key]}"
        for _var in "${_var_arr[@]}"; do
            if [[ ! ",$_all_vars," =~ ",$_var," ]]; then
                [ -n "$_all_vars" ] && _all_vars="$_all_vars,$_var" || _all_vars="$_var"
            fi
        done
    done

    # Prompt for each unique variable
    IFS=',' read -ra _unique_vars <<< "$_all_vars"
    for _var in "${_unique_vars[@]}"; do
        read -p "  Enter $_var: " _value
        COLLECTED_VARS["$_var"]="$_value"
    done

    echo "${GREEN}✓${NC} Variables collected"
    echo ""
fi

echo "Installing files..."

# ============================================================================
# OPTIMIZATION: Batch file operations
# ============================================================================

# Check if file should be installed based on experimental status
should_install_file() {
    local filename="$1"
    local file_type="$2"  # commands, patterns, designs, scripts

    # If no package.yaml, install everything
    if [ ! -f "$TEMP_DIR/package.yaml" ]; then
        return 0
    fi

    # Check if file is marked experimental in package.yaml
    # Extract only the relevant section, then find the specific entry
    local section=$(grep -A 1000 "^  ${file_type}:" "$TEMP_DIR/package.yaml" 2>/dev/null | grep -B 1000 "^  [a-z]" 2>/dev/null | head -n -1 || true)
    local is_experimental=$(echo "$section" | grep -A 3 "^    - name: ${filename}$" 2>/dev/null | grep "^ *experimental: true" 2>/dev/null | grep -v "^[[:space:]]*#" | head -1 || true)

    if [ -n "$is_experimental" ]; then
        if [ "$INSTALL_EXPERIMENTAL" = true ]; then
            echo "  ${YELLOW}⚠${NC}  Installing experimental: ${filename}"
            return 0  # Install it
        else
            echo "  ${DIM}⊘${NC}  Skipping experimental: ${filename} (use --experimental to install)"
            return 1  # Skip it
        fi
    fi

    return 0  # Install non-experimental files
}

# Add package to manifest once
add_package_to_manifest "$PACKAGE_NAME" "$REPO_URL" "$PACKAGE_VERSION" "$COMMIT_HASH"

# Batch copy all files (skip scripts — handled via script-command binding below)
for dir in "${!ALL_FILES_TO_INSTALL[@]}"; do
    SOURCE_DIR="$TEMP_DIR/agent/$dir"

    # Skip scripts in first pass — install selectively after commands via script-command binding
    if [ "$dir" = "scripts" ]; then
        continue
    fi

    # Copy all files
    for file in ${ALL_FILES_TO_INSTALL[$dir]}; do
        if [ "$dir" = "files" ]; then
            rel_path="${file#$SOURCE_DIR/}"

            if [ "$HAS_FILE_METADATA" = true ]; then
                # Metadata-aware installation: use target path and variable substitution
                _file_target="${FILE_TARGETS[files/$rel_path]:-./}"
                _bname=$(basename "$rel_path")
                _bname="${_bname%.template}"
                _dest="${_file_target}${_bname}"

                # Safety validation: reject paths that escape project root
                if [[ "$_dest" =~ \.\. ]] || [[ "$_dest" =~ ^/ ]]; then
                    echo "  ${RED}✗${NC} Skipping $rel_path (unsafe target: $_dest)"
                    continue
                fi

                mkdir -p "$(dirname "$_dest")"

                # Apply variable substitution if template has variables
                _file_vars="${FILE_VARS[files/$rel_path]:-}"
                if [ -n "$_file_vars" ] && [ ${#COLLECTED_VARS[@]} -gt 0 ]; then
                    cp "$file" "$_dest"
                    IFS=',' read -ra _var_arr <<< "$_file_vars"
                    for _var in "${_var_arr[@]}"; do
                        _value="${COLLECTED_VARS[$_var]:-}"
                        if [ -n "$_value" ]; then
                            _escaped=$(printf '%s\n' "$_value" | sed 's/[&/\]/\\&/g')
                            sed -i "s|{{${_var}}}|${_escaped}|g" "$_dest"
                        fi
                    done
                else
                    cp "$file" "$_dest"
                fi
            else
                # Backward compat: install to project root preserving subdirectory structure
                target_dir="$(dirname "./$rel_path")"
                mkdir -p "$target_dir"
                cp "$file" "./$rel_path"
            fi
        else
            mkdir -p "$INSTALL_BASE_DIR/$dir"
            filename=$(basename "$file")
            cp "$file" "$INSTALL_BASE_DIR/$dir/$filename"
        fi

        # Track installed commands for script dependency resolution
        if [ "$dir" = "commands" ]; then
            filename=$(basename "$file")
            INSTALLED_COMMANDS+=("$filename")
        fi
    done
done

# ============================================================================
# Script-Command Binding: Install scripts based on command dependencies
# ============================================================================

if [ -f "$TEMP_DIR/package.yaml" ] && [ ${#INSTALLED_COMMANDS[@]} -gt 0 ]; then
    echo "Resolving script dependencies..."
    echo "  Installed commands: ${INSTALLED_COMMANDS[@]}"

    # Collect required scripts from installed commands using YAML parser
    REQUIRED_SCRIPTS=()
    for cmd in "${INSTALLED_COMMANDS[@]}"; do
        # Find the command index in the array
        cmd_index=0
        while true; do
            cmd_name=$(yaml_get_nested "$TEMP_DIR/package.yaml" "contents.commands[$cmd_index].name" 2>/dev/null || echo "")
            if [ -z "$cmd_name" ] || [ "$cmd_name" = "null" ]; then
                break
            fi

            if [ "$cmd_name" = "$cmd" ]; then
                # Found the command, now get its scripts
                script_index=0
                while true; do
                    script=$(yaml_get_nested "$TEMP_DIR/package.yaml" "contents.commands[$cmd_index].scripts[$script_index]" 2>/dev/null || echo "")
                    if [ -z "$script" ] || [ "$script" = "null" ]; then
                        break
                    fi

                    # Add to required scripts (with deduplication)
                    already_added=false
                    for existing in "${REQUIRED_SCRIPTS[@]}"; do
                        if [ "$existing" = "$script" ]; then
                            already_added=true
                            break
                        fi
                    done

                    if [ "$already_added" = false ]; then
                        REQUIRED_SCRIPTS+=("$script")
                    fi

                    script_index=$((script_index + 1))
                done
                break
            fi

            cmd_index=$((cmd_index + 1))
        done
    done

    echo "  Found ${#REQUIRED_SCRIPTS[@]} required script(s): ${REQUIRED_SCRIPTS[@]}"

    # Install required scripts and add to ALL_FILES_TO_INSTALL for batch manifest update
    SCRIPT_FILES_LIST=""
    if [ ${#REQUIRED_SCRIPTS[@]} -gt 0 ]; then
        mkdir -p "$INSTALL_BASE_DIR/scripts"
        for script in "${REQUIRED_SCRIPTS[@]}"; do
            script_path="$TEMP_DIR/agent/scripts/$script"

            # Check if script exists
            if [ ! -f "$script_path" ]; then
                echo "  ${RED}✗${NC} Script not found: $script (declared in package.yaml)"
                continue
            fi

            # Check if should install based on experimental status
            if ! should_install_file "$script" "scripts"; then
                continue
            fi

            # Copy script and make executable
            cp "$script_path" "$INSTALL_BASE_DIR/scripts/$script"
            chmod +x "$INSTALL_BASE_DIR/scripts/$script"

            # Get file version and store metadata
            FILE_VERSION=$(get_file_version "$TEMP_DIR/package.yaml" "scripts" "$script")

            # Check experimental status
            is_experimental=""
            if [ -f "$TEMP_DIR/package.yaml" ]; then
                is_experimental=$(grep -A 1000 "^  scripts:" "$TEMP_DIR/package.yaml" 2>/dev/null | grep -A 2 "name: ${script}" | grep "^ *experimental: true" | grep -v "^[[:space:]]*#" | head -1)
            fi
            FILE_METADATA["scripts/$script"]="$FILE_VERSION|$is_experimental"

            # Track for batch processing
            if [ -n "$SCRIPT_FILES_LIST" ]; then
                SCRIPT_FILES_LIST="$SCRIPT_FILES_LIST $script_path"
            else
                SCRIPT_FILES_LIST="$script_path"
            fi
        done
    fi

    # Update ALL_FILES_TO_INSTALL with resolved scripts
    if [ -n "$SCRIPT_FILES_LIST" ]; then
        ALL_FILES_TO_INSTALL["scripts"]="$SCRIPT_FILES_LIST"
    fi
    echo ""
elif [ -d "$TEMP_DIR/agent/scripts" ] && [ -n "${ALL_FILES_TO_INSTALL[scripts]+x}" ]; then
    # Scripts were collected during scan but no package.yaml script-command binding
    # Install all scripts that passed validation (backward compatibility)
    for file in ${ALL_FILES_TO_INSTALL[scripts]}; do
        filename=$(basename "$file")
        mkdir -p "$INSTALL_BASE_DIR/scripts"
        cp "$file" "$INSTALL_BASE_DIR/scripts/$filename"
        chmod +x "$INSTALL_BASE_DIR/scripts/$filename"
    done
fi

# ============================================================================
# OPTIMIZATION: Batch checksum calculation
# ============================================================================

echo "  ${BLUE}Calculating checksums...${NC}"

# Collect all installed files for batch checksum
ALL_INSTALLED_FILES=()
for dir in "${!ALL_FILES_TO_INSTALL[@]}"; do
    SOURCE_DIR="$TEMP_DIR/agent/$dir"
    for file in ${ALL_FILES_TO_INSTALL[$dir]}; do
        if [ "$dir" = "files" ]; then
            rel_path="${file#$SOURCE_DIR/}"
            if [ "$HAS_FILE_METADATA" = true ]; then
                _file_target="${FILE_TARGETS[files/$rel_path]:-./}"
                _bname=$(basename "$rel_path")
                _bname="${_bname%.template}"
                ALL_INSTALLED_FILES+=("${_file_target}${_bname}")
            else
                ALL_INSTALLED_FILES+=("./$rel_path")
            fi
        else
            filename=$(basename "$file")
            ALL_INSTALLED_FILES+=("$INSTALL_BASE_DIR/$dir/$filename")
        fi
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
    SOURCE_DIR="$TEMP_DIR/agent/$dir"
    manifest_key="${MANIFEST_KEYS[$dir]:-$dir}"

    for file in ${ALL_FILES_TO_INSTALL[$dir]}; do
        # Determine filename and installed filepath based on dir type
        if [ "$dir" = "files" ]; then
            filename="${file#$SOURCE_DIR/}"
            if [ "$HAS_FILE_METADATA" = true ]; then
                _file_target="${FILE_TARGETS[files/$filename]:-./}"
                _bname=$(basename "$filename")
                _bname="${_bname%.template}"
                filepath="${_file_target}${_bname}"
            else
                filepath="./$filename"
            fi
        else
            filename=$(basename "$file")
            filepath="$INSTALL_BASE_DIR/$dir/$filename"
        fi

        # Get metadata
        IFS='|' read -r file_version is_experimental <<< "${FILE_METADATA[$dir/$filename]}"

        # Get checksum
        checksum="${CHECKSUMS[$filepath]:-unknown}"

        # Append to manifest using mapped key
        obj_node=$(yaml_array_append_object ".packages.${PACKAGE_NAME}.files.${manifest_key}")
        yaml_object_set "$obj_node" "name" "$filename" >/dev/null
        yaml_object_set "$obj_node" "version" "$file_version" >/dev/null
        yaml_object_set "$obj_node" "installed_at" "$timestamp" >/dev/null
        yaml_object_set "$obj_node" "modified" "false" >/dev/null
        yaml_object_set "$obj_node" "checksum" "sha256:$checksum" >/dev/null

        if [ -n "$is_experimental" ]; then
            yaml_object_set "$obj_node" "experimental" "true" >/dev/null
        fi

        # For files with metadata: store target path and variables
        if [ "$dir" = "files" ] && [ "$HAS_FILE_METADATA" = true ]; then
            yaml_object_set "$obj_node" "target" "$filepath" >/dev/null
            # Store variable values if this file had variables
            _file_vars_manifest="${FILE_VARS[files/$filename]:-}"
            if [ -n "$_file_vars_manifest" ]; then
                # Create nested map node for variables
                _vars_node=$(create_node "map" "variables" "" "$obj_node")
                add_child "$obj_node" "$_vars_node"
                IFS=',' read -ra _var_names <<< "$_file_vars_manifest"
                for _vname in "${_var_names[@]}"; do
                    _vval="${COLLECTED_VARS[$_vname]:-}"
                    if [ -n "$_vval" ]; then
                        yaml_object_set "$_vars_node" "$_vname" "$_vval" >/dev/null
                    fi
                done
            fi
        fi

        if [ "$dir" = "scripts" ]; then
            echo "  ${GREEN}✓${NC} Installed $dir/$filename (v$file_version) [executable]"
        elif [ "$dir" = "files" ]; then
            echo "  ${GREEN}✓${NC} Installed $filename → $filepath"
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
