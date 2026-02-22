#!/bin/bash

# Agent Context Protocol (ACP) Package Install Script
# Installs third-party ACP packages (commands, patterns, designs, etc.) from git repositories

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"
. "${SCRIPT_DIR}/acp.yaml-parser.sh"

# Initialize colors
init_colors

# Parse arguments
REPO_URL=""
INSTALL_PATTERNS=false
INSTALL_COMMANDS=false
INSTALL_DESIGNS=false
PATTERN_FILES=()
COMMAND_FILES=()
DESIGN_FILES=()
LIST_ONLY=false
GLOBAL_INSTALL=false

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
        --patterns)
            INSTALL_PATTERNS=true
            shift
            # Collect pattern file names until next flag
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                PATTERN_FILES+=("$1")
                shift
            done
            ;;
        --commands)
            INSTALL_COMMANDS=true
            shift
            # Collect command file names until next flag
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                COMMAND_FILES+=("$1")
                shift
            done
            ;;
        --designs)
            INSTALL_DESIGNS=true
            shift
            # Collect design file names until next flag
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
    echo ""
    echo "Required:"
    echo "  --repo <url>           Repository URL to install from"
    echo ""
    echo "Options:"
    echo "  --global               Install to ~/.acp/packages/ instead of ./agent/"
    echo "  --patterns [files...]  Install patterns (all if no files specified)"
    echo "  --commands [files...]  Install commands (all if no files specified)"
    echo "  --designs [files...]   Install designs (all if no files specified)"
    echo "  --list                 List available files without installing"
    echo ""
    echo "Examples:"
    echo "  $0 https://github.com/example/acp-package.git"
    echo "  $0 --patterns https://github.com/example/acp-package.git"
    echo "  $0 --patterns file1 file2 https://github.com/example/acp-package.git"
    echo "  $0 --list https://github.com/example/acp-package.git"
    exit 1
fi

# Default: install everything if no selective flags specified
if [[ "$INSTALL_PATTERNS" == false && "$INSTALL_COMMANDS" == false && "$INSTALL_DESIGNS" == false ]]; then
    INSTALL_PATTERNS=true
    INSTALL_COMMANDS=true
    INSTALL_DESIGNS=true
fi

echo "${BLUE}📦 ACP Package Installer${NC}"
echo "========================================"
echo ""
echo "Repository: $REPO_URL"
echo ""

# Validate URL format
if [[ ! "$REPO_URL" =~ ^https?:// ]]; then
    echo "${RED}Error: Invalid repository URL${NC}"
    echo "URL must start with http:// or https://"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Cloning repository..."
if ! git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &>/dev/null; then
    echo "${RED}Error: Failed to clone repository${NC}"
    echo "Please check the URL and your internet connection."
    exit 1
fi

echo "${GREEN}✓${NC} Repository cloned"
echo ""

# Check if repository has agent/ directory
if [ ! -d "$TEMP_DIR/agent" ]; then
    echo "${RED}Error: No agent/ directory found${NC}"
    echo "Repository must contain an 'agent/' directory with ACP files"
    exit 1
fi

# Determine installation directory and manifest based on --global flag
if [ "$GLOBAL_INSTALL" = true ]; then
    # Global installation - install directly into ~/.acp/agent/
    INSTALL_BASE_DIR="$HOME/.acp/agent"
    MANIFEST_FILE="$HOME/.acp/agent/manifest.yaml"
    
    echo "${BLUE}Installing globally to ~/.acp/agent/${NC}"
    echo ""
    
    # Initialize global ACP infrastructure (auto-initialization)
    init_global_acp || {
        echo "${RED}Error: Failed to initialize global infrastructure${NC}" >&2
        exit 1
    }
else
    # Local installation (existing behavior)
    INSTALL_BASE_DIR="./agent"
    MANIFEST_FILE="./agent/manifest.yaml"
    
    echo "${BLUE}Installing locally to ./agent/${NC}"
    echo ""
    
    # Initialize local manifest
    init_manifest
fi

# Parse package metadata
parse_package_metadata "$TEMP_DIR"

# Get commit hash
COMMIT_HASH=$(get_commit_hash "$TEMP_DIR")
info "Commit: $COMMIT_HASH"
echo ""

# List mode - show available files and exit
if [ "$LIST_ONLY" = true ]; then
    echo "${BLUE}📁 Available files in package:${NC}"
    echo ""
    
    # List patterns
    if [ -d "$TEMP_DIR/agent/patterns" ]; then
        PATTERN_COUNT=$(find "$TEMP_DIR/agent/patterns" -maxdepth 1 -name "*.md" ! -name "*.template.md" -type f 2>/dev/null | wc -l)
        if [ "$PATTERN_COUNT" -gt 0 ]; then
            echo "${GREEN}Patterns ($PATTERN_COUNT):${NC}"
            find "$TEMP_DIR/agent/patterns" -maxdepth 1 -name "*.md" ! -name "*.template.md" -type f 2>/dev/null | xargs -n1 basename | sed 's/^/  - /'
            echo ""
        fi
    fi
    
    # List commands
    if [ -d "$TEMP_DIR/agent/commands" ]; then
        COMMAND_COUNT=$(find "$TEMP_DIR/agent/commands" -maxdepth 1 -name "*.*.md" ! -name "*.template.md" -type f 2>/dev/null | wc -l)
        if [ "$COMMAND_COUNT" -gt 0 ]; then
            echo "${GREEN}Commands ($COMMAND_COUNT):${NC}"
            find "$TEMP_DIR/agent/commands" -maxdepth 1 -name "*.*.md" ! -name "*.template.md" -type f 2>/dev/null | xargs -n1 basename | sed 's/^/  - /'
            echo ""
        fi
    fi
    
    # List designs
    if [ -d "$TEMP_DIR/agent/design" ]; then
        DESIGN_COUNT=$(find "$TEMP_DIR/agent/design" -maxdepth 1 -name "*.md" ! -name "*.template.md" -type f 2>/dev/null | wc -l)
        if [ "$DESIGN_COUNT" -gt 0 ]; then
            echo "${GREEN}Designs ($DESIGN_COUNT):${NC}"
            find "$TEMP_DIR/agent/design" -maxdepth 1 -name "*.md" ! -name "*.template.md" -type f 2>/dev/null | xargs -n1 basename | sed 's/^/  - /'
            echo ""
        fi
    fi
    
    TOTAL_COUNT=$((PATTERN_COUNT + COMMAND_COUNT + DESIGN_COUNT))
    echo "Total: $TOTAL_COUNT file(s) available"
    echo ""
    echo "To install all files:"
    echo "  $0 $REPO_URL"
    echo ""
    echo "To install specific types:"
    echo "  $0 --patterns $REPO_URL"
    echo "  $0 --commands $REPO_URL"
    echo "  $0 --patterns --commands $REPO_URL"
    echo ""
    echo "To install specific files:"
    echo "  $0 --patterns file1 file2 $REPO_URL"
    
    exit 0
fi

# Validate project dependencies
if [ -f "$TEMP_DIR/package.yaml" ]; then
    if ! validate_project_dependencies "$TEMP_DIR/package.yaml"; then
        echo "${RED}Installation cancelled due to dependency issues${NC}"
        exit 1
    fi
fi

# Directories to install from (based on flags)
INSTALL_DIRS=()
[ "$INSTALL_PATTERNS" = true ] && INSTALL_DIRS+=("patterns")
[ "$INSTALL_COMMANDS" = true ] && INSTALL_DIRS+=("commands")
[ "$INSTALL_DESIGNS" = true ] && INSTALL_DIRS+=("design")
[ "$INSTALL_COMMANDS" = true ] && INSTALL_DIRS+=("scripts")  # Scripts installed with commands

INSTALLED_COUNT=0
SKIPPED_COUNT=0

echo "Scanning for installable files..."
echo ""

# Process each directory
for dir in "${INSTALL_DIRS[@]}"; do
    SOURCE_DIR="$TEMP_DIR/agent/$dir"
    
    if [ ! -d "$SOURCE_DIR" ]; then
        continue
    fi
    
    # Determine which files to process based on selective flags
    declare -n FILE_LIST
    case "$dir" in
        patterns)
            FILE_LIST=PATTERN_FILES
            ;;
        commands)
            FILE_LIST=COMMAND_FILES
            ;;
        design)
            FILE_LIST=DESIGN_FILES
            ;;
        scripts)
            FILE_LIST=COMMAND_FILES  # Scripts use command files list (empty array if no specific files)
            ;;
    esac
    
    # If specific files requested, use those; otherwise find all
    if [ ${#FILE_LIST[@]} -gt 0 ]; then
        # Selective file installation
        FILES_TO_PROCESS=()
        for file_name in "${FILE_LIST[@]}"; do
            # Add appropriate extension if not present
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
        # Install all files from directory
        FILES_TO_PROCESS=()
        if [ "$dir" = "scripts" ]; then
            # For scripts, find .sh files
            while IFS= read -r file; do
                [ -n "$file" ] && FILES_TO_PROCESS+=("$file")
            done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.sh" ! -name "*.template.sh" -type f)
        else
            # For other types, find .md files
            while IFS= read -r file; do
                [ -n "$file" ] && FILES_TO_PROCESS+=("$file")
            done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.md" ! -name "*.template.md" -type f)
        fi
    fi
    
    if [ ${#FILES_TO_PROCESS[@]} -eq 0 ]; then
        continue
    fi
    
    echo "${BLUE}📁 $dir/${NC} (${#FILES_TO_PROCESS[@]} file(s))"
    
    # Validate and list files
    for file in "${FILES_TO_PROCESS[@]}"; do
        filename=$(basename "$file")
        
        # Special validation for commands
        if [ "$dir" = "commands" ]; then
            # Check for reserved 'acp' namespace
            if [[ "$filename" =~ ^acp\. ]]; then
                echo "  ${RED}✗${NC} $filename (reserved namespace 'acp')"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
            
            # Check for agent directive
            if ! grep -q "🤖 Agent Directive" "$file"; then
                echo "  ${YELLOW}⚠${NC}  $filename (missing agent directive - skipping)"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
        fi
        
        # Special validation for scripts
        if [ "$dir" = "scripts" ]; then
            # Check for reserved 'acp' namespace
            if [[ "$filename" =~ ^acp\. ]]; then
                echo "  ${RED}✗${NC} $filename (reserved namespace 'acp')"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
                continue
            fi
            
            # Check for shebang
            if ! head -n1 "$file" | grep -q "^#!/"; then
                echo "  ${YELLOW}⚠${NC}  $filename (missing shebang)"
            fi
        fi
        
        # Check for conflicts
        if [ -f "$INSTALL_BASE_DIR/$dir/$filename" ]; then
            echo "  ${YELLOW}⚠${NC}  $filename (will overwrite existing)"
        else
            echo "  ${GREEN}✓${NC} $filename"
        fi
        
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    done
    
    unset -n FILE_LIST
    echo ""
done

# Exit if nothing to install
if [ $INSTALLED_COUNT -eq 0 ]; then
    echo "${RED}Error: No valid files to install${NC}"
    if [ $SKIPPED_COUNT -gt 0 ]; then
        echo "Skipped $SKIPPED_COUNT file(s) due to validation failures"
    fi
    exit 1
fi

# Confirm installation
echo "Ready to install $INSTALLED_COUNT file(s)"
if [ $SKIPPED_COUNT -gt 0 ]; then
    echo "($SKIPPED_COUNT file(s) will be skipped)"
fi
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

# Add package to manifest
add_package_to_manifest "$PACKAGE_NAME" "$REPO_URL" "$PACKAGE_VERSION" "$COMMIT_HASH"

# Install files (same logic for both global and local)
for dir in "${INSTALL_DIRS[@]}"; do
    SOURCE_DIR="$TEMP_DIR/agent/$dir"
    
    if [ ! -d "$SOURCE_DIR" ]; then
        continue
    fi
    
    # Create target directory
    mkdir -p "$INSTALL_BASE_DIR/$dir"

    # Determine which files to install based on selective flags
    declare -n FILE_LIST
    case "$dir" in
        patterns)
            FILE_LIST=PATTERN_FILES
            ;;
        commands)
            FILE_LIST=COMMAND_FILES
            ;;
        design)
            FILE_LIST=DESIGN_FILES
            ;;
        scripts)
            FILE_LIST=COMMAND_FILES  # Scripts use command files list
            ;;
    esac
    
    # If specific files requested, use those; otherwise find all
    if [ ${#FILE_LIST[@]} -gt 0 ]; then
        # Selective file installation
        FILES_TO_INSTALL=()
        for file_name in "${FILE_LIST[@]}"; do
            # Add appropriate extension if not present
            if [ "$dir" = "scripts" ]; then
                [[ "$file_name" != *.sh ]] && file_name="${file_name}.sh"
            else
                [[ "$file_name" != *.md ]] && file_name="${file_name}.md"
            fi
            
            file_path="$SOURCE_DIR/$file_name"
            if [ -f "$file_path" ]; then
                FILES_TO_INSTALL+=("$file_path")
            fi
        done
    else
        # Install all files from directory
        FILES_TO_INSTALL=()
        if [ "$dir" = "scripts" ]; then
            while IFS= read -r file; do
                [ -n "$file" ] && FILES_TO_INSTALL+=("$file")
            done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.sh" ! -name "*.template.sh" -type f)
        else
            while IFS= read -r file; do
                [ -n "$file" ] && FILES_TO_INSTALL+=("$file")
            done < <(find "$SOURCE_DIR" -maxdepth 1 -name "*.md" ! -name "*.template.md" -type f)
        fi
    fi
    
    for file in "${FILES_TO_INSTALL[@]}"; do
        filename=$(basename "$file")
        
        # Skip invalid files
        if [ "$dir" = "commands" ]; then
            if [[ "$filename" =~ ^acp\. ]] || ! grep -q "🤖 Agent Directive" "$file"; then
                continue
            fi
        fi
        
        # Skip invalid scripts
        if [ "$dir" = "scripts" ]; then
            if [[ "$filename" =~ ^acp\. ]]; then
                continue
            fi
        fi
        
        # Copy file
        cp "$file" "$INSTALL_BASE_DIR/$dir/$filename"
        
        # Make scripts executable
        if [ "$dir" = "scripts" ]; then
            chmod +x "$INSTALL_BASE_DIR/$dir/$filename"
        fi
        
        # Get file version from package.yaml
        FILE_VERSION=$(get_file_version "$TEMP_DIR/package.yaml" "$dir" "$filename")
        
        # Add file to manifest
        add_file_to_manifest "$PACKAGE_NAME" "$dir" "$filename" "$FILE_VERSION" "$INSTALL_BASE_DIR/$dir/$filename"
        
        if [ "$dir" = "scripts" ]; then
            echo "  ${GREEN}✓${NC} Installed $dir/$filename (v$FILE_VERSION) [executable]"
        else
            echo "  ${GREEN}✓${NC} Installed $dir/$filename (v$FILE_VERSION)"
        fi
    done
    
    unset -n FILE_LIST
    echo ""
done

echo ""

# Success message based on installation mode
if [ "$GLOBAL_INSTALL" = true ]; then
    echo "${GREEN}✅ Package installed globally!${NC}"
    echo ""
    echo "Location: $INSTALL_BASE_DIR"
    echo "Manifest: $MANIFEST_FILE"
    echo ""
    echo "Agents can now discover this package by reading ~/.acp/agent/manifest.yaml"
    echo ""
    echo "To use in any project:"
    echo "  1. Run @acp.init to discover global packages"
    echo "  2. Reference commands via @namespace.command"
    echo ""
    echo "To list global packages: @acp.package-list --global"
    echo ""
else
    echo "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo "Installed $INSTALLED_COUNT file(s) from:"
    echo "  $REPO_URL"
    echo ""
    echo "Package: $PACKAGE_NAME ($PACKAGE_VERSION)"
    echo "Manifest: agent/manifest.yaml updated"
    echo ""
fi

# List installed commands
if [ -d "$TEMP_DIR/agent/commands" ]; then
    COMMANDS=$(find "$TEMP_DIR/agent/commands" -maxdepth 1 -name "*.*.md" ! -name "*.template.md" -type f)
    if [ -n "$COMMANDS" ]; then
        echo "Installed commands:"
        while IFS= read -r cmd_file; do
            cmd_name=$(basename "$cmd_file" .md)
            if [[ ! "$cmd_name" =~ ^acp\. ]]; then
                invocation="@${cmd_name}"
                echo "  - $invocation"
            fi
        done <<< "$COMMANDS"
        echo ""
    fi
fi

echo "${YELLOW}⚠️  Security Reminder:${NC}"
echo "Review installed files before using them."
echo "Third-party files can instruct agents to modify files and execute scripts."
echo ""
echo "Next steps:"
echo "  1. Review installed files in agent/ directories"
echo "  2. Test installed commands"
echo "  3. Update progress.yaml with installation notes"
echo ""
