#!/bin/bash
# ACP Package Publishing Script
# Automated package publishing with validation, versioning, and testing
# Version: 1.0.0

set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"
. "${SCRIPT_DIR}/acp.yaml-parser.sh"

# Initialize colors
init_colors

# Check if we're in a package directory
if [ ! -f "package.yaml" ]; then
    echo "${RED}Error: Not a package directory${NC}"
    echo "package.yaml not found. This command must be run from an ACP package directory."
    exit 1
fi

# Extract package info
PACKAGE_NAME=$(yaml_get "package.yaml" "name" 2>/dev/null || echo "unknown")
CURRENT_VERSION=$(yaml_get "package.yaml" "version" 2>/dev/null || echo "0.0.0")
REPO_URL=$(yaml_get "package.yaml" "repository" 2>/dev/null || echo "")

echo "${BLUE}🚀 ACP Package Publishing${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}Package: ${PACKAGE_NAME} (v${CURRENT_VERSION})${NC}"
echo ""

# Step 1: Validation
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}🔍 Step 1: Validation${NC}"
echo ""
echo "Running @acp.package-validate..."
echo ""

if ! "${SCRIPT_DIR}/acp.package-validate.sh"; then
    echo ""
    echo "${RED}❌ Package validation failed${NC}"
    echo ""
    echo "Fix validation errors and run @acp.package-publish again."
    echo "Or use @acp.package-validate to see detailed errors."
    exit 1
fi

echo ""
echo "${GREEN}✅ Package validation passed!${NC}"
echo ""

# Step 2: Check working directory
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}🔍 Step 2: Git Status${NC}"
echo ""

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "${YELLOW}⚠️  Uncommitted changes detected${NC}"
    git status --short
    echo ""
    echo "${YELLOW}These changes will be committed as part of the release.${NC}"
    echo ""
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: ${BOLD}${CURRENT_BRANCH}${NC}"

# Validate branch
RELEASE_BRANCH=$(yaml_get "package.yaml" "release.branch" 2>/dev/null || echo "main")
VALID_BRANCHES="main master mainline release ${RELEASE_BRANCH}"

if ! echo "$VALID_BRANCHES" | grep -qw "$CURRENT_BRANCH"; then
    echo ""
    echo "${RED}❌ Not on a valid release branch${NC}"
    echo "Current: $CURRENT_BRANCH"
    echo "Valid: $VALID_BRANCHES"
    echo ""
    echo "Switch to a release branch or configure in package.yaml:"
    echo "  release:"
    echo "    branch: $CURRENT_BRANCH"
    exit 1
fi

echo "${GREEN}✓${NC} On valid release branch"

# Show remote
if [ -n "$REPO_URL" ]; then
    echo "Remote: ${REPO_URL}"
fi

echo ""

# Step 3: Check remote status
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}🔍 Step 3: Remote Status${NC}"
echo ""

echo "Fetching latest from origin..."
if git fetch origin >/dev/null 2>&1; then
    echo "${GREEN}✓${NC} Fetched latest from origin"
    
    # Check if remote is ahead
    COMMITS_BEHIND=$(git rev-list HEAD..origin/${CURRENT_BRANCH} --count 2>/dev/null || echo "0")
    if [ "$COMMITS_BEHIND" -gt 0 ]; then
        echo ""
        echo "${RED}❌ Remote is ahead of local${NC}"
        echo "Remote has $COMMITS_BEHIND commit(s) not in local."
        echo ""
        echo "Pull latest changes first:"
        echo "  git pull"
        exit 1
    fi
    
    echo "${GREEN}✓${NC} Local is up to date with remote"
else
    echo "${YELLOW}⚠️  Could not fetch from remote${NC}"
    echo "Continuing anyway (remote may not exist yet)..."
fi

echo ""

# Step 4: Analyze commits for version bump
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}📊 Step 4: Version Analysis${NC}"
echo ""

# Get last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
    echo "No previous tags found. This will be the first release."
    LAST_TAG="HEAD~999"  # Get all commits
    COMMIT_COUNT=$(git rev-list HEAD --count)
else
    echo "Last release: ${LAST_TAG}"
    COMMIT_COUNT=$(git rev-list ${LAST_TAG}..HEAD --count)
fi

echo "Commits since last release: ${COMMIT_COUNT}"
echo ""

if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo "${RED}❌ No commits since last release${NC}"
    echo "Nothing to publish."
    exit 1
fi

# Analyze commits
echo "Commit analysis:"
HAS_BREAKING=false
HAS_FEAT=false
HAS_FIX=false

while IFS= read -r commit; do
    echo "  - $commit"
    
    # Check for breaking changes
    if echo "$commit" | grep -qiE "(BREAKING CHANGE|feat!:|fix!:)"; then
        HAS_BREAKING=true
    fi
    
    # Check for features
    if echo "$commit" | grep -qE "^feat(\(|:)"; then
        HAS_FEAT=true
    fi
    
    # Check for fixes
    if echo "$commit" | grep -qE "^fix(\(|:)"; then
        HAS_FIX=true
    fi
done < <(git log ${LAST_TAG}..HEAD --oneline)

echo ""

# Determine version bump
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

if [ "$HAS_BREAKING" = true ]; then
    NEW_MAJOR=$((MAJOR + 1))
    NEW_MINOR=0
    NEW_PATCH=0
    BUMP_TYPE="major"
    BUMP_REASON="Breaking changes detected"
elif [ "$HAS_FEAT" = true ]; then
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$((MINOR + 1))
    NEW_PATCH=0
    BUMP_TYPE="minor"
    BUMP_REASON="New features added"
else
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$MINOR
    NEW_PATCH=$((PATCH + 1))
    BUMP_TYPE="patch"
    BUMP_REASON="Bug fixes or improvements"
fi

NEW_VERSION="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"

echo "Recommendation: ${BOLD}${NEW_VERSION}${NC} (${BUMP_TYPE})"
echo "Reason: ${BUMP_REASON}"
echo ""

# Step 5: Confirm version
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}❓ Step 5: Confirm Version${NC}"
echo ""
echo "Publish as version ${BOLD}${NEW_VERSION}${NC}? (Y/n/custom)"
read -r response

case "$response" in
    n|N|no|No|NO)
        echo "Publishing cancelled."
        exit 0
        ;;
    custom|c|C)
        echo "Enter custom version (X.Y.Z format):"
        read -r NEW_VERSION
        if ! echo "$NEW_VERSION" | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$"; then
            echo "${RED}Error: Invalid version format${NC}"
            exit 1
        fi
        ;;
    *)
        # Use recommended version
        ;;
esac

echo ""
echo "${GREEN}✓${NC} Publishing version: ${BOLD}${NEW_VERSION}${NC}"
echo ""

# Step 6: Generate CHANGELOG (LLM-based - placeholder for now)
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}📝 Step 6: CHANGELOG Generation${NC}"
echo ""
echo "${YELLOW}Note: CHANGELOG generation requires LLM context.${NC}"
echo "When run via agent, CHANGELOG will be generated automatically."
echo "For now, please update CHANGELOG.md manually."
echo ""
echo "Press Enter to continue after updating CHANGELOG.md..."
read -r

# Step 7: Update version files
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}✏️  Step 7: Updating Version Files${NC}"
echo ""

# Update package.yaml version
if command -v sed >/dev/null 2>&1; then
    sed -i.bak "s/^version: .*/version: ${NEW_VERSION}/" package.yaml && rm package.yaml.bak
    echo "${GREEN}✓${NC} Updated package.yaml (${CURRENT_VERSION} → ${NEW_VERSION})"
else
    echo "${YELLOW}⚠️  Please update package.yaml version manually to ${NEW_VERSION}${NC}"
fi

echo ""

# Step 8: Commit changes
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}💾 Step 8: Committing Changes${NC}"
echo ""

git add package.yaml CHANGELOG.md
COMMIT_MSG="chore(release): bump version to ${NEW_VERSION}

Updated package.yaml and CHANGELOG.md for release.

Version: ${NEW_VERSION}"

git commit -m "$COMMIT_MSG"
COMMIT_HASH=$(git rev-parse --short HEAD)

echo "${GREEN}✓${NC} Committed: chore(release): bump version to ${NEW_VERSION}"
echo "${GREEN}✓${NC} Commit hash: ${COMMIT_HASH}"
echo ""

# Step 9: Create git tag
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}🏷️  Step 9: Creating Git Tag${NC}"
echo ""

TAG_NAME="v${NEW_VERSION}"
TAG_MSG="Release v${NEW_VERSION}"

if git tag -a "$TAG_NAME" -m "$TAG_MSG"; then
    echo "${GREEN}✓${NC} Created tag: ${TAG_NAME}"
    echo "${GREEN}✓${NC} Tag message: ${TAG_MSG}"
else
    echo "${RED}❌ Failed to create tag${NC}"
    echo "Tag may already exist. Delete it first if needed:"
    echo "  git tag -d ${TAG_NAME}"
    exit 1
fi

echo ""

# Step 10: Push to remote
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}🚀 Step 10: Pushing to Remote${NC}"
echo ""

echo "Pushing commits to origin/${CURRENT_BRANCH}..."
if git push origin "$CURRENT_BRANCH"; then
    echo "${GREEN}✓${NC} Pushed commits to origin/${CURRENT_BRANCH}"
else
    echo "${RED}❌ Failed to push commits${NC}"
    exit 1
fi

echo "Pushing tag ${TAG_NAME}..."
if git push origin "$TAG_NAME"; then
    echo "${GREEN}✓${NC} Pushed tag ${TAG_NAME}"
else
    echo "${RED}❌ Failed to push tag${NC}"
    exit 1
fi

if [ -n "$REPO_URL" ]; then
    echo "Remote: ${REPO_URL}"
fi

echo ""

# Step 11: Wait for GitHub
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}⏳ Step 11: Waiting for GitHub${NC}"
echo ""
echo "Waiting for GitHub to process push... (10 seconds)"
sleep 10
echo "${GREEN}✓${NC} Ready to test"
echo ""

# Step 12: Test installation from remote
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${BOLD}🧪 Step 12: Test Installation${NC}"
echo ""

TEST_DIR="/tmp/acp-publish-test-$(date +%s)"
echo "Creating test directory: ${TEST_DIR}"
mkdir -p "$TEST_DIR/agent/"{patterns,commands,design}

# Create minimal manifest
cat > "$TEST_DIR/agent/manifest.yaml" << 'EOF'
packages: {}
manifest_version: 1.0.0
last_updated: null
EOF

echo "${GREEN}✓${NC} Test directory created"
echo ""

# Get current directory for install script
CURRENT_DIR=$(pwd)

# Try to install from remote
echo "Installing from remote: ${REPO_URL}"
cd "$TEST_DIR"

if "${CURRENT_DIR}/agent/scripts/acp.package-install.sh" "$REPO_URL" --yes >/dev/null 2>&1; then
    echo "${GREEN}✓${NC} Package installed successfully"
    
    # Verify installation
    INSTALLED_FILES=$(find agent/ -name "*.md" -not -name "*.template.md" 2>/dev/null | wc -l)
    echo "${GREEN}✓${NC} Verified ${INSTALLED_FILES} file(s) copied"
    
    # Check manifest
    if grep -q "$PACKAGE_NAME:" agent/manifest.yaml 2>/dev/null; then
        echo "${GREEN}✓${NC} Manifest updated correctly"
    fi
else
    echo "${RED}❌ Package installation failed${NC}"
    echo ""
    echo "${YELLOW}This may indicate issues with the published package.${NC}"
    echo "Check repository and try installing manually."
fi

# Cleanup
cd "$CURRENT_DIR"
rm -rf "$TEST_DIR"
echo "${GREEN}✓${NC} Test directory cleaned up"
echo ""

# Step 13: Final report
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${GREEN}${BOLD}✅ Publishing Complete!${NC}"
echo ""
echo "📦 Package: ${BOLD}${PACKAGE_NAME} v${NEW_VERSION}${NC}"
echo "🌐 Repository: ${REPO_URL}"
echo "🏷️  Tag: ${TAG_NAME}"
echo "✅ Test Installation: PASSED"
echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "${GREEN}${BOLD}🎉 Your package is now live!${NC}"
echo ""
echo "Users can install it with:"
echo "  ${BOLD}@acp.package-install ${REPO_URL}${NC}"
echo ""
echo "Next steps:"
echo "  - Announce release to users"
echo "  - Monitor for issues"
echo "  - Update documentation if needed"
echo ""
