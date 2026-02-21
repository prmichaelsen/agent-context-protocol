#!/bin/bash

# Agent Context Protocol (ACP) Package Search Script
# Search for ACP packages on GitHub using the GitHub API

# Note: set -e disabled because while loop runs in subshell
# and some commands may return non-zero without being errors
# set -e

# Source common utilities
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.common.sh"

# Initialize colors
init_colors

# Parse arguments
QUERY=""
TAG=""
USER=""
ORG=""
SORT="stars"
LIMIT=10

while [[ $# -gt 0 ]]; do
    case $1 in
        --tag)
            TAG="$2"
            shift 2
            ;;
        --user)
            USER="$2"
            shift 2
            ;;
        --org)
            ORG="$2"
            shift 2
            ;;
        --sort)
            SORT="$2"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

echo "${BLUE}🔍 ACP Package Search${NC}"
echo "========================================"
echo ""

# Build search query
# Search for repos with "acp-" prefix (convention for ACP packages)
if [ -n "$QUERY" ]; then
    SEARCH_QUERY="acp-${QUERY}"
else
    SEARCH_QUERY="acp-"
fi

if [ -n "$TAG" ]; then
    SEARCH_QUERY="$SEARCH_QUERY+topic:$TAG"
fi

if [ -n "$USER" ]; then
    SEARCH_QUERY="$SEARCH_QUERY+user:$USER"
fi

if [ -n "$ORG" ]; then
    SEARCH_QUERY="$SEARCH_QUERY+org:$ORG"
fi

info "Searching GitHub for: $SEARCH_QUERY"
info "Sort by: $SORT"
info "Limit: $LIMIT"
echo ""

# Search GitHub repositories
GITHUB_API="https://api.github.com/search/repositories"
SEARCH_URL="${GITHUB_API}?q=${SEARCH_QUERY}&sort=${SORT}&per_page=${LIMIT}"

# Make API request
RESPONSE=$(curl -s -H "Accept: application/vnd.github+json" "$SEARCH_URL")

# Check for API errors
if echo "$RESPONSE" | grep -q '"message"'; then
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    die "GitHub API error: $ERROR_MSG"
fi

# Parse results (handle spaces in JSON)
TOTAL_COUNT=$(echo "$RESPONSE" | grep -o '"total_count"[: ]*[0-9]*' | grep -o '[0-9]*$')

if [ -z "$TOTAL_COUNT" ] || [ "$TOTAL_COUNT" -eq 0 ]; then
    echo "${YELLOW}No packages found matching your search${NC}"
    echo ""
    echo "Try:"
    echo "  - Broader search terms"
    echo "  - Different tags"
    echo "  - Removing filters"
    exit 0
fi

echo "${GREEN}📦 Found $TOTAL_COUNT package(s)${NC}"
echo ""

# Parse and display each result
REPO_COUNT=0

echo "$RESPONSE" | grep -o '"full_name": "[^"]*"' | cut -d'"' -f4 | while read -r full_name; do
    REPO_COUNT=$((REPO_COUNT + 1))
    
    # Extract repo info from response
    REPO_DATA=$(echo "$RESPONSE" | grep -A 20 "\"full_name\":\"$full_name\"")
    
    DESCRIPTION=$(echo "$REPO_DATA" | grep -o '"description"[: ]*"[^"]*"' | head -1 | sed 's/"description"[: ]*"//' | sed 's/"$//')
    STARS=$(echo "$REPO_DATA" | grep -o '"stargazers_count"[: ]*[0-9]*' | head -1 | grep -o '[0-9]*$')
    URL="https://github.com/$full_name"
    
    # Fetch package.yaml to get version and tags
    PACKAGE_YAML_URL="https://raw.githubusercontent.com/$full_name/main/package.yaml"
    PACKAGE_YAML=$(curl -s "$PACKAGE_YAML_URL" 2>/dev/null)
    
    if [ -n "$PACKAGE_YAML" ]; then
        VERSION=$(echo "$PACKAGE_YAML" | awk '/^version:/ {print $2; exit}')
        PACKAGE_NAME=$(echo "$PACKAGE_YAML" | awk '/^name:/ {print $2; exit}')
        TAGS=$(echo "$PACKAGE_YAML" | awk '/^tags:/,/^[a-z]/ {if (/^  - /) {gsub(/^  - /, ""); print}}' | tr '\n' ', ' | sed 's/,$//')
    else
        VERSION="unknown"
        PACKAGE_NAME=$(echo "$full_name" | cut -d'/' -f2)
        TAGS=""
    fi
    
    # Display result
    echo "${GREEN}$REPO_COUNT. $PACKAGE_NAME${NC} (${BLUE}$VERSION${NC}) ⭐ $STARS"
    echo "   $URL"
    if [ -n "$DESCRIPTION" ] && [ "$DESCRIPTION" != "null" ]; then
        echo "   $DESCRIPTION"
    fi
    if [ -n "$TAGS" ]; then
        echo "   Tags: $TAGS"
    fi
    echo "   Install: ./agent/scripts/acp.package-install.sh $URL.git"
    echo ""
done

echo "Showing $REPO_COUNT of $TOTAL_COUNT result(s)"
echo ""
echo "To install a package:"
echo "  ./agent/scripts/acp.package-install.sh <repository-url>"
echo ""
