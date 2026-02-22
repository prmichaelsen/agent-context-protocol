#!/bin/bash

# ACP Package Creator v2.1.0
# Creates a new ACP package with full ACP installation

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Parse command-line arguments
PACKAGE_NAME=""
DESCRIPTION=""
AUTHOR=""
LICENSE="MIT"
HOMEPAGE=""
REPO_URL=""
TAGS_INPUT=""
RELEASE_BRANCH="main"
TARGET_DIR=""

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create a new ACP package with full ACP installation."
    echo ""
    echo "Options:"
    echo "  --name NAME              Package name (required, lowercase, hyphens allowed)"
    echo "  --description DESC       Package description (required)"
    echo "  --author AUTHOR          Author name (required)"
    echo "  --license LICENSE        License (default: MIT)"
    echo "  --homepage URL           Homepage URL (optional)"
    echo "  --repository URL         Git repository URL (required)"
    echo "  --tags TAGS              Comma-separated tags (optional)"
    echo "  --branch BRANCH          Release branch (default: main)"
    echo "  --target-dir DIR         Target directory (default: ~/.acp/projects/acp-NAME)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Modes:"
    echo "  Interactive:    Run without arguments, prompts for all information"
    echo "  Non-interactive: Provide all required arguments (--name, --description, --author, --repository)"
    echo ""
    echo "Examples:"
    echo "  # Interactive mode (prompts for all information)"
    echo "  $0"
    echo ""
    echo "  # Non-interactive mode (all required parameters provided)"
    echo "  $0 --name test-package \\"
    echo "     --description \"Test package for ACP\" \\"
    echo "     --author \"Your Name\" \\"
    echo "     --repository \"https://github.com/user/acp-test-package.git\" \\"
    echo "     --tags \"test,example\""
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            PACKAGE_NAME="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --author)
            AUTHOR="$2"
            shift 2
            ;;
        --license)
            LICENSE="$2"
            shift 2
            ;;
        --homepage)
            HOMEPAGE="$2"
            shift 2
            ;;
        --repository)
            REPO_URL="$2"
            shift 2
            ;;
        --tags)
            TAGS_INPUT="$2"
            shift 2
            ;;
        --branch)
            RELEASE_BRANCH="$2"
            shift 2
            ;;
        --target-dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "${RED}Error: Unknown option: $1${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
done

# Detect if running in non-interactive mode (all required args provided)
NON_INTERACTIVE=false
if [ -n "$PACKAGE_NAME" ] && [ -n "$DESCRIPTION" ] && [ -n "$AUTHOR" ] && [ -n "$REPO_URL" ]; then
    NON_INTERACTIVE=true
fi

echo "${BLUE}📦 ACP Package Creator${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$NON_INTERACTIVE" = false ]; then
    echo "Let's create a new ACP package!"
    echo ""
    
    # Step 1: Gather package information
    echo "${BOLD}Package Information${NC}"
    echo ""
fi

# Package name
if [ -z "$PACKAGE_NAME" ]; then
    read -p "Package name (lowercase, no spaces): " PACKAGE_NAME
fi
if [ -z "$PACKAGE_NAME" ]; then
    echo "${RED}Error: Package name is required${NC}"
    exit 1
fi

# Validate package name (lowercase, alphanumeric, hyphens only)
if ! echo "$PACKAGE_NAME" | grep -qE '^[a-z0-9-]+$'; then
    echo "${RED}Error: Package name must be lowercase letters, numbers, and hyphens only${NC}"
    exit 1
fi

# Check for reserved names
if [ "$PACKAGE_NAME" = "acp" ] || [ "$PACKAGE_NAME" = "local" ] || [ "$PACKAGE_NAME" = "core" ] || [ "$PACKAGE_NAME" = "system" ] || [ "$PACKAGE_NAME" = "global" ]; then
    echo "${RED}Error: Package name '${PACKAGE_NAME}' is reserved${NC}"
    echo "Reserved names: acp, local, core, system, global"
    exit 1
fi

# Description
if [ -z "$DESCRIPTION" ]; then
    read -p "Description: " DESCRIPTION
fi
if [ -z "$DESCRIPTION" ]; then
    echo "${RED}Error: Description is required${NC}"
    exit 1
fi

# Author
if [ -z "$AUTHOR" ]; then
    read -p "Author name: " AUTHOR
fi
if [ -z "$AUTHOR" ]; then
    echo "${RED}Error: Author name is required${NC}"
    exit 1
fi

# License
if [ -z "$LICENSE" ]; then
    LICENSE="MIT"
fi
if [ "$NON_INTERACTIVE" = false ]; then
    read -p "License [MIT]: " LICENSE_INPUT
    LICENSE=${LICENSE_INPUT:-MIT}
fi

# Homepage
if [ "$NON_INTERACTIVE" = false ] && [ -z "$HOMEPAGE" ]; then
    read -p "Homepage URL (optional): " HOMEPAGE
fi

# Repository URL
if [ -z "$REPO_URL" ]; then
    read -p "Repository URL (e.g., https://github.com/username/acp-${PACKAGE_NAME}.git): " REPO_URL
fi
if [ -z "$REPO_URL" ]; then
    echo "${RED}Error: Repository URL is required${NC}"
    exit 1
fi

# Ensure repository URL ends with .git
if [[ ! "$REPO_URL" =~ \.git$ ]]; then
    REPO_URL="${REPO_URL}.git"
    echo "${YELLOW}Note: Added .git suffix to repository URL: ${REPO_URL}${NC}"
fi

# Tags
if [ "$NON_INTERACTIVE" = false ] && [ -z "$TAGS_INPUT" ]; then
    read -p "Tags (comma-separated): " TAGS_INPUT
fi

# Convert tags to array
IFS=',' read -ra TAGS_ARRAY <<< "$TAGS_INPUT"

# Release branch
if [ "$NON_INTERACTIVE" = false ]; then
    read -p "Release branch [main]: " RELEASE_BRANCH_INPUT
    RELEASE_BRANCH=${RELEASE_BRANCH_INPUT:-main}
fi

# Target directory (optional)
# Default: ~/.acp/projects/acp-{package-name}
# Note: ~/.acp/projects/ is for development, ~/.acp/packages/ is for installed packages
DEFAULT_TARGET_DIR="$HOME/.acp/projects/acp-${PACKAGE_NAME}"
if [ "$NON_INTERACTIVE" = false ] && [ -z "$TARGET_DIR" ]; then
    read -p "Target directory [${DEFAULT_TARGET_DIR}]: " TARGET_DIR
fi

# Expand path (handle ~, $HOME, and relative paths)
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$DEFAULT_TARGET_DIR"
else
    # Expand ~ to home directory
    TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
    # Expand $HOME
    TARGET_DIR=$(eval echo "$TARGET_DIR")
    
    # If target ends with / or is a common parent directory, append acp-{package-name}
    # This handles cases like:
    #   ~/.acp/projects/ → ~/.acp/projects/acp-package-name
    #   ~/.acp/projects  → ~/.acp/projects/acp-package-name (parent dir)
    if [[ "$TARGET_DIR" == */ ]] || [[ "$TARGET_DIR" == */projects ]] || [[ "$TARGET_DIR" == */packages ]]; then
        # Remove trailing slash if present
        TARGET_DIR="${TARGET_DIR%/}"
        # Append package name with prefix
        TARGET_DIR="${TARGET_DIR}/acp-${PACKAGE_NAME}"
    fi
fi

echo ""
echo "${GREEN}✓${NC} Package information collected"
echo ""

# Initialize global infrastructure if creating in ~/.acp/projects/
if [[ "$TARGET_DIR" == "$HOME/.acp/projects/"* ]] || [[ "$TARGET_DIR" == ~/.acp/projects/* ]]; then
    init_global_acp || {
        echo "${RED}Error: Failed to initialize global infrastructure${NC}" >&2
        exit 1
    }
fi

# Display summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${BOLD}Creating new ACP package: ${PACKAGE_NAME}${NC}"
echo ""
echo "Package name: ${PACKAGE_NAME}"
echo "Description: ${DESCRIPTION}"
echo "Author: ${AUTHOR}"
echo "License: ${LICENSE}"
echo "Homepage: ${HOMEPAGE}"
echo "Repository: ${REPO_URL}"
echo "Tags: ${TAGS_INPUT}"
echo "Release branch: ${RELEASE_BRANCH}"
echo "Target: ${TARGET_DIR}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 2: Create directory structure
PACKAGE_DIR="${TARGET_DIR}"

# Expand to absolute path if relative
if [[ "$PACKAGE_DIR" != /* ]]; then
    PACKAGE_DIR="$(pwd)/$PACKAGE_DIR"
fi

# Check if directory already exists
if [ -d "$PACKAGE_DIR" ]; then
    echo "${RED}Error: Directory $PACKAGE_DIR already exists${NC}"
    exit 1
fi

echo "${BOLD}Creating Directory Structure${NC}"
echo ""

mkdir -p "$PACKAGE_DIR"

echo "${GREEN}✓${NC} Created directory: $PACKAGE_DIR/"
echo ""

# Step 3: Install full ACP
echo "${BOLD}Installing ACP${NC}"
echo ""

# Change to package directory
cd "$PACKAGE_DIR"

# Run ACP installation script
if [ -f "${SCRIPT_DIR}/acp.install.sh" ]; then
    # Run install script (it will create agent/ structure and install all files)
    bash "${SCRIPT_DIR}/acp.install.sh"
    echo ""
else
    echo "${RED}Error: acp.install.sh not found${NC}"
    exit 1
fi

echo "${GREEN}✓${NC} ACP installed successfully"
echo "${GREEN}✓${NC} All templates and commands available"
echo ""

# Step 3.5: Create local-only directories with .gitkeep files
echo "${BOLD}Creating Local Directories${NC}"
echo ""

# Create clarifications directory with .gitkeep
mkdir -p agent/clarifications
touch agent/clarifications/.gitkeep

# Create feedback directory with .gitkeep
mkdir -p agent/feedback
touch agent/feedback/.gitkeep

# Copy clarification template from ACP installation
if [ -f "${SCRIPT_DIR}/../clarifications/clarification-{N}-{title}.template.md" ]; then
    cp "${SCRIPT_DIR}/../clarifications/clarification-{N}-{title}.template.md" agent/clarifications/
    echo "${GREEN}✓${NC} Created agent/clarifications/ with .gitkeep and template"
else
    echo "${YELLOW}⚠${NC}  Created agent/clarifications/ with .gitkeep (template not found)"
fi

echo "${GREEN}✓${NC} Created agent/feedback/ with .gitkeep"
echo ""

# Step 4: Create package.yaml
echo "${BOLD}Creating package.yaml${NC}"
echo ""

# Convert tags array to YAML list
TAGS_YAML=""
for tag in "${TAGS_ARRAY[@]}"; do
    # Trim whitespace
    tag=$(echo "$tag" | xargs)
    TAGS_YAML="${TAGS_YAML}  - ${tag}\n"
done

# Create package.yaml with release branch configuration
cat > "package.yaml" << EOF
# package.yaml
name: ${PACKAGE_NAME}
version: 1.0.0
description: ${DESCRIPTION}
author: ${AUTHOR}
license: ${LICENSE}
homepage: ${HOMEPAGE}
repository: ${REPO_URL}

# Release configuration
release:
  branch: ${RELEASE_BRANCH}

# Package contents
# Add files here as you create them
# Use @acp.pattern-create, @acp.command-create, @acp.design-create
# These commands automatically update this section
contents:
  patterns: []
  
  commands: []
  
  designs: []

# Compatibility
requires:
  acp: >=2.8.0

# Tags for discovery
tags:
$(echo -e "$TAGS_YAML")
EOF

echo "${GREEN}✓${NC} Created package.yaml"
echo "${GREEN}✓${NC} Configured release branch: ${RELEASE_BRANCH}"
echo ""

# Step 4.5: Create progress.yaml for package development
echo "${BOLD}Creating Progress Tracking${NC}"
echo ""

CURRENT_DATE=$(date +%Y-%m-%d)

cat > "agent/progress.yaml" << EOF
# Package Development Progress Tracking
# ACP Package: ${PACKAGE_NAME}

project:
  name: ${PACKAGE_NAME}
  version: 1.0.0
  type: package
  started: ${CURRENT_DATE}
  status: in_progress
  current_milestone: null
  description: |
    ACP Package: ${DESCRIPTION}

milestones: []

tasks: {}

documentation:
  design_documents: 0
  milestone_documents: 0
  pattern_documents: 0
  task_documents: 0
  command_documents: 0
  last_updated: ${CURRENT_DATE}

progress:
  planning: 0
  implementation: 0
  testing: 0
  documentation: 0
  overall: 0

recent_work:
  - date: ${CURRENT_DATE}
    description: |
      📦 Package Created: ${PACKAGE_NAME}
      Initial package structure created. Ready for content development.
    items:
      - ✅ Created package.yaml with metadata
      - ✅ Installed full ACP (templates, commands, scripts)
      - ✅ Created README.md, LICENSE, CHANGELOG.md
      - ✅ Initialized git repository
      - ✅ Installed pre-commit hook
      - ✅ Created progress.yaml for development tracking
      - 📋 Ready to add content with entity creation commands

next_steps:
  - Add patterns using @acp.pattern-create
  - Add commands using @acp.command-create
  - Add designs using @acp.design-create
  - Create milestones and tasks as needed
  - Validate package with @acp.package-validate
  - Publish with @acp.package-publish

notes:
  - This is an ACP package repository
  - Use entity creation commands to add content
  - Create milestones and tasks as you plan development
  - progress.yaml is for development only (not installed to user projects)

current_blockers: []

team:
  - role: Package Author
    name: ${AUTHOR}
    focus: |
      Developing ${PACKAGE_NAME} package
EOF

echo "${GREEN}✓${NC} Created progress.yaml for package development tracking"
echo ""

# Step 5: Create README.md
echo "${BOLD}Creating Documentation${NC}"
echo ""

cat > "README.md" << EOF
# ACP Package: ${PACKAGE_NAME}

${DESCRIPTION}

> **This package is designed for use with the [Agent Context Protocol](https://github.com/prmichaelsen/agent-context-protocol). Read more about ACP [here](https://github.com/prmichaelsen/agent-context-protocol).**

## Installation

### Quick Start (Bootstrap New Project)

Install ACP and this package in one command:

\`\`\`bash
curl -fsSL ${REPO_URL%.git}/raw/${RELEASE_BRANCH}/agent/scripts/bootstrap.sh | bash
\`\`\`

This will:
1. Install ACP if not already installed
2. Install this package
3. Initialize your project with ACP

### Install Package Only (ACP Already Installed)

If you already have ACP installed in your project:

\`\`\`bash
@acp.package-install ${REPO_URL}
\`\`\`

Or using the installation script:

\`\`\`bash
./agent/scripts/acp.package-install.sh ${REPO_URL}
\`\`\`

## What's Included

<!-- ACP_AUTO_UPDATE_START:CONTENTS -->
### Commands

(No commands yet - use @acp.command-create to add commands)

### Patterns

(No patterns yet - use @acp.pattern-create to add patterns)

### Designs

(No designs yet - use @acp.design-create to add designs)
<!-- ACP_AUTO_UPDATE_END:CONTENTS -->

## Why Use This Package

(Add benefits and use cases here)

## Usage

(Add usage examples here)

## Development

### Setup

1. Clone this repository
2. Make changes
3. Run \`@acp.package-validate\` to validate
4. Run \`@acp.package-publish\` to publish

### Adding New Content

- Use \`@acp.pattern-create\` to create patterns
- Use \`@acp.command-create\` to create commands
- Use \`@acp.design-create\` to create designs

These commands automatically:
- Add namespace prefix to filenames
- Update package.yaml contents section
- Update this README.md

### Testing

Run \`@acp.package-validate\` to validate your package locally.

### Publishing

Run \`@acp.package-publish\` to publish updates. This will:
- Validate the package
- Detect version bump from commits
- Update CHANGELOG.md
- Create git tag
- Push to remote
- Test installation

## Namespace Convention

All files in this package use the \`${PACKAGE_NAME}\` namespace:
- Commands: \`${PACKAGE_NAME}.command-name.md\`
- Patterns: \`${PACKAGE_NAME}.pattern-name.md\`
- Designs: \`${PACKAGE_NAME}.design-name.md\`

## Dependencies

(List any required packages or project dependencies here)

## Local Development Directories

This package includes local-only directories for development workflow:

### Clarifications (\`agent/clarifications/\`)

Use this directory to document questions and clarifications during development:
- Create clarification documents using the template: \`clarification-{N}-{title}.template.md\`
- Document requirements gaps, design questions, and implementation decisions
- **Local by default**: Content files are gitignored, only \`.gitkeep\` is tracked
- **Optional tracking**: Remove patterns from \`.gitignore\` to track specific clarifications

### Feedback (\`agent/feedback/\`)

Use this directory to capture feedback during development:
- Document user feedback, bug reports, and feature requests
- Keep notes about what works and what needs improvement
- **Local by default**: Content files are gitignored, only \`.gitkeep\` is tracked
- **Optional tracking**: Remove patterns from \`.gitignore\` to track specific feedback

### Reports (\`agent/reports/\`)

Session reports and development logs:
- Automatically generated by \`@acp.report\` command
- **Local by default**: Content files are gitignored, only \`.gitkeep\` is tracked
- **Optional tracking**: Remove patterns from \`.gitignore\` to track specific reports

**Note**: These directories follow the same pattern - they exist in the repository structure (via \`.gitkeep\`), but their content is local-only by default. You can choose to track specific files by removing them from \`.gitignore\`.

## Contributing

Contributions are welcome! Please:

1. Follow the existing pattern structure
2. Use entity creation commands (@acp.pattern-create, etc.)
3. Run @acp.package-validate before committing
4. Document your changes in CHANGELOG.md
5. Test installation before submitting

## License

${LICENSE}

## Author

${AUTHOR}
EOF

echo "${GREEN}✓${NC} Created README.md"

# Step 6: Create LICENSE
cat > "LICENSE" << 'EOF'
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

echo "${GREEN}✓${NC} Created LICENSE (MIT)"

# Step 7: Create CHANGELOG.md
CURRENT_DATE=$(date +%Y-%m-%d)

cat > "CHANGELOG.md" << EOF
# Changelog

All notable changes to this package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - ${CURRENT_DATE}

### Added
- Initial release
- Package structure created with full ACP installation
EOF

echo "${GREEN}✓${NC} Created CHANGELOG.md"

# Step 8: Create .gitignore (package-specific)
cat > ".gitignore" << 'EOF'
# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo

# Temporary files
*.tmp
*.log

# Node modules (if applicable)
node_modules/

# Python (if applicable)
__pycache__/
*.pyc
.venv/
venv/

# Build artifacts
dist/
build/

# ACP local files (local by default, tracking optional)
# These directories exist with .gitkeep files, but content is gitignored
agent/clarifications/*.md
!agent/clarifications/*.template.md
agent/feedback/*.md
agent/reports/*.md
EOF

echo "${GREEN}✓${NC} Created .gitignore"
echo ""

# Step 8.5: Create bootstrap.sh script
mkdir -p agent/scripts

cat > "agent/scripts/bootstrap.sh" << 'BOOTSTRAP_EOF'
#!/bin/bash
# Bootstrap script for installing ACP and this package in one command
# Usage: curl -fsSL https://github.com/{owner}/{repo}/raw/{branch}/agent/scripts/bootstrap.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${BOLD}  ACP Package Bootstrap${NC}"
echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if ACP is already installed
if [ ! -f "AGENT.md" ] || [ ! -d "agent" ]; then
    echo "${BLUE}Installing ACP...${NC}"
    echo ""
    
    # Install ACP
    curl -fsSL https://raw.githubusercontent.com/prmichaelsen/agent-context-protocol/mainline/agent/scripts/acp.install.sh | bash
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "${GREEN}✓${NC} ACP installed successfully"
        echo ""
    else
        echo ""
        echo "${RED}✗${NC} ACP installation failed"
        exit 1
    fi
else
    echo "${GREEN}✓${NC} ACP already installed"
    echo ""
fi

# Install this package
BOOTSTRAP_EOF

# Add package-specific installation command
cat >> "agent/scripts/bootstrap.sh" << EOF
echo "\${BLUE}Installing ${PACKAGE_NAME} package...\${NC}"
echo ""

# Install package using acp.package-install.sh
if [ -f "./agent/scripts/acp.package-install.sh" ]; then
    ./agent/scripts/acp.package-install.sh ${REPO_URL}
    
    if [ \$? -eq 0 ]; then
        echo ""
        echo "\${GREEN}✓\${NC} ${PACKAGE_NAME} package installed successfully"
        echo ""
    else
        echo ""
        echo "\${RED}✗\${NC} Package installation failed"
        exit 1
    fi
else
    echo "\${RED}✗\${NC} ACP installation script not found"
    echo "Please ensure ACP is properly installed"
    exit 1
fi

echo ""
echo "\${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo "\${GREEN}✓\${NC} \${BOLD}Bootstrap Complete!\${NC}"
echo "\${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo ""
echo "Your project is now set up with:"
echo "  • ACP (Agent Context Protocol)"
echo "  • ${PACKAGE_NAME} package"
echo ""
echo "Next steps:"
echo "  1. Run: @acp.init"
echo "  2. Start working with your AI agent"
echo ""
EOF

chmod +x agent/scripts/bootstrap.sh

echo "${GREEN}✓${NC} Created agent/scripts/bootstrap.sh"
echo ""

# Step 9: Install pre-commit hook
echo "${BOLD}Installing Pre-Commit Hook${NC}"
echo ""

# Initialize git first (required for hook installation)
git init -q

# Install hook using common.sh function
if install_precommit_hook; then
    echo "${GREEN}✓${NC} Validates package.yaml before commits"
else
    echo "${YELLOW}⚠  Pre-commit hook installation failed (non-critical)${NC}"
fi

echo ""

# Step 10: Create initial commit
echo "${BOLD}Initializing Git Repository${NC}"
echo ""

git add .
git commit -q -m "chore: initialize ACP package with full installation"

echo "${GREEN}✓${NC} Initialized git repository"
echo "${GREEN}✓${NC} Created initial commit"
echo ""

# Step 11: Display success message and next steps
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${GREEN}🎉 Package Created Successfully!${NC}"
echo ""
echo "Your ACP package is ready at: ${BOLD}${PACKAGE_DIR}${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${BOLD}📋 Next Steps:${NC}"
echo ""
echo "1. ${BOLD}Add your content:${NC}"
echo "   ${YELLOW}cd acp-${PACKAGE_NAME}${NC}"
echo "   ${YELLOW}@acp.pattern-create${NC}    # Create patterns"
echo "   ${YELLOW}@acp.command-create${NC}    # Create commands"
echo "   ${YELLOW}@acp.design-create${NC}     # Create designs"
echo ""
echo "   These commands automatically:"
echo "   - Add namespace prefix to filenames"
echo "   - Update package.yaml contents section"
echo "   - Update README.md \"What's Included\" section"
echo ""
echo "2. ${BOLD}Validate your package:${NC}"
echo "   ${YELLOW}@acp.package-validate${NC}"
echo ""
echo "   This checks:"
echo "   - package.yaml structure"
echo "   - File existence and namespace consistency"
echo "   - Git repository setup"
echo "   - README.md structure"
echo ""
echo "3. ${BOLD}Create GitHub repository:${NC}"
echo "   - Go to https://github.com/new"
echo "   - Name: ${YELLOW}acp-${PACKAGE_NAME}${NC}"
echo "   - Description: ${DESCRIPTION}"
echo "   - Create repository (public recommended)"
echo ""
echo "4. ${BOLD}Push to GitHub:${NC}"
echo "   ${YELLOW}cd acp-${PACKAGE_NAME}"
echo "   git remote add origin ${REPO_URL}"
echo "   git branch -M ${RELEASE_BRANCH}"
echo "   git push -u origin ${RELEASE_BRANCH}${NC}"
echo ""
echo "5. ${BOLD}Add GitHub topic for discoverability:${NC}"
echo "   - Go to repository settings"
echo "   - Add topic: ${YELLOW}acp-package${NC} (REQUIRED)"
echo "   - Add other topics: ${TAGS_INPUT}"
echo ""
echo "6. ${BOLD}Publish your first version:${NC}"
echo "   ${YELLOW}cd acp-${PACKAGE_NAME}"
echo "   @acp.package-publish${NC}"
echo ""
echo "   This will:"
echo "   - Validate package"
echo "   - Detect version bump from commits"
echo "   - Update CHANGELOG.md"
echo "   - Create git tag"
echo "   - Push to remote"
echo "   - Test installation"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${BOLD}📚 Resources:${NC}"
echo ""
echo "- Package structure guide: See AGENT.md"
echo "- package.yaml reference: agent/design/acp-package-management-system.md"
echo "- Entity creation: @acp.pattern-create, @acp.command-create, @acp.design-create"
echo "- Validation: @acp.package-validate"
echo "- Publishing: @acp.package-publish"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${GREEN}✅ Package creation complete!${NC}"
echo ""
echo "Your package has:"
echo "  ${GREEN}✓${NC} Full ACP installation (all templates and commands)"
echo "  ${GREEN}✓${NC} Pre-commit hook (validates package.yaml before commits)"
echo "  ${GREEN}✓${NC} Release branch configured (${RELEASE_BRANCH})"
echo "  ${GREEN}✓${NC} Git repository initialized"
echo "  ${GREEN}✓${NC} Bootstrap script (agent/scripts/bootstrap.sh)"
echo "  ${GREEN}✓${NC} Progress tracking (agent/progress.yaml)"
echo ""
echo "${BOLD}💡 Bootstrap Installation:${NC}"
echo ""
echo "Once published, users can install ACP + your package in one command:"
echo ""
echo "  ${YELLOW}curl -fsSL ${REPO_URL%.git}/raw/${RELEASE_BRANCH}/agent/scripts/bootstrap.sh | bash${NC}"
echo ""
echo "This is perfect for bootstrapping new projects!"
echo ""
echo "${BOLD}💡 Progress Tracking:${NC}"
echo ""
echo "Use standard ACP commands to track package development:"
echo "  ${YELLOW}@acp.init${NC}     - Initialize context"
echo "  ${YELLOW}@acp.status${NC}   - Check development status"
echo "  ${YELLOW}@acp.proceed${NC}  - Work on tasks"
echo ""
echo "Create milestones and tasks as you plan development."
echo ""
echo "Ready to add content with @acp.pattern-create, @acp.command-create, @acp.design-create"
echo ""
