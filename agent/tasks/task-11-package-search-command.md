# Task 11: Package Search Command

**Milestone**: [M3 - ACP Package Management System](../milestones/milestone-3-acp-package-management.md)  
**Estimated Time**: 6-8 hours  
**Dependencies**: None  
**Status**: Not Started  
**Priority**: High  

---

## Objective

Implement `@acp.package-search` command to discover ACP packages on GitHub using the GitHub API, with support for keyword search, tag filtering, and sorting by stars or update date.

---

## Context

Package discovery is essential for ecosystem growth. Users need to find packages without manually browsing GitHub. The search command uses GitHub's API to find repositories tagged with `acp-package` and fetches their metadata to display comprehensive results.

---

## Steps

### 1. Create Search Script

Create `scripts/package-search.sh`:

```bash
#!/bin/bash
# Package search script

QUERY=$1
TAG=""
USER=""
ORG=""
SORT="stars"
LIMIT=10

# Parse options
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --tag) TAG=$2; shift 2 ;;
    --user) USER=$2; shift 2 ;;
    --org) ORG=$2; shift 2 ;;
    --sort) SORT=$2; shift 2 ;;
    --limit) LIMIT=$2; shift 2 ;;
    *) shift ;;
  esac
done

# Build search query
SEARCH_QUERY="${QUERY}+topic:acp-package"

if [ -n "$TAG" ]; then
  SEARCH_QUERY="${SEARCH_QUERY}+topic:${TAG}"
fi

if [ -n "$USER" ]; then
  SEARCH_QUERY="${SEARCH_QUERY}+user:${USER}"
fi

if [ -n "$ORG" ]; then
  SEARCH_QUERY="${SEARCH_QUERY}+org:${ORG}"
fi

# Search GitHub
echo "🔍 Searching for ACP packages..."
echo ""

response=$(curl -s -H "Accept: application/vnd.github+json" \
  "https://api.github.com/search/repositories?q=${SEARCH_QUERY}&sort=${SORT}&per_page=${LIMIT}")

# Check for errors
if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
  error_message=$(echo "$response" | jq -r '.message')
  echo "Error: $error_message"
  exit 1
fi

# Get result count
total_count=$(echo "$response" | jq -r '.total_count')

if [ "$total_count" == "0" ]; then
  echo "No packages found matching '$QUERY'"
  exit 0
fi

echo "📦 Found $total_count package(s) matching '$QUERY':"
echo ""

# Process each result
echo "$response" | jq -c '.items[]' | while read -r item; do
  name=$(echo "$item" | jq -r '.name')
  full_name=$(echo "$item" | jq -r '.full_name')
  description=$(echo "$item" | jq -r '.description // "No description"')
  stars=$(echo "$item" | jq -r '.stargazers_count')
  url=$(echo "$item" | jq -r '.html_url')
  
  # Fetch package.yaml to get version and tags
  package_yaml=$(curl -s "https://raw.githubusercontent.com/${full_name}/main/package.yaml" 2>/dev/null)
  
  if [ -n "$package_yaml" ]; then
    version=$(echo "$package_yaml" | yq eval '.version' - 2>/dev/null)
    tags=$(echo "$package_yaml" | yq eval '.tags | join(", ")' - 2>/dev/null)
  else
    version="unknown"
    tags="none"
  fi
  
  # Display result
  echo "$name ($version) ⭐ $stars"
  echo "  $url"
  echo "  $description"
  echo "  Tags: $tags"
  echo "  Install: @acp.package-install https://github.com/${full_name}.git"
  echo ""
done
```

### 2. Create Command Documentation

Create `commands/acp.package-search.md`:

```markdown
# Command: package-search

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-search` has been invoked.

**Namespace**: acp  
**Version**: 1.0.0  
**Status**: Active  

---

**Purpose**: Discover ACP packages on GitHub  
**Category**: Package Management  
**Frequency**: As Needed  

---

## What This Command Does

Searches GitHub for ACP packages using the GitHub API. Packages must have the `acp-package` topic to be discoverable. Results show package name, version, description, stars, and installation command.

## Syntax

```bash
@acp.package-search <query> [options]

Options:
  --tag <tag>              Filter by additional tag
  --user <username>        Search specific user's repos
  --org <org>              Search specific organization
  --sort <field>           Sort by: stars, updated, name (default: stars)
  --limit <n>              Limit results (default: 10)
```

## Examples

```bash
# Search by keyword
@acp.package-search firebase

# Filter by tag
@acp.package-search oauth --tag authentication

# Search user's packages
@acp.package-search --user prmichaelsen

# Sort by recently updated
@acp.package-search --sort updated --limit 5
```

## Package Discovery Requirements

To be discoverable, packages must:
1. Have `package.yaml` in repository root
2. Include GitHub topic `acp-package`
3. Include descriptive tags in `package.yaml`
4. Have clear description in GitHub repo

---

**Status**: Active  
```

### 3. Handle GitHub API Rate Limits

Add rate limit handling:

```bash
# Check rate limit
check_rate_limit() {
  rate_limit=$(curl -s -H "Accept: application/vnd.github+json" \
    "https://api.github.com/rate_limit" | jq -r '.rate.remaining')
  
  if [ "$rate_limit" -lt 5 ]; then
    echo "⚠️  GitHub API rate limit low: $rate_limit requests remaining"
    echo "Consider setting GITHUB_TOKEN environment variable for higher limits"
  fi
}

# Use token if available
if [ -n "$GITHUB_TOKEN" ]; then
  AUTH_HEADER="-H \"Authorization: Bearer $GITHUB_TOKEN\""
else
  AUTH_HEADER=""
fi
```

### 4. Test Search Command

```bash
# Test basic search
@acp.package-search firebase

# Test with filters
@acp.package-search --tag oauth

# Test with user filter
@acp.package-search --user prmichaelsen

# Test with no results
@acp.package-search nonexistentpackage123

# Test rate limit handling
# (make many requests)
```

---

## Verification

- [ ] Searches GitHub API successfully
- [ ] Displays package name, version, stars
- [ ] Shows description and tags
- [ ] Provides installation command
- [ ] `--tag` filter works
- [ ] `--user` filter works
- [ ] `--org` filter works
- [ ] `--sort` option works
- [ ] `--limit` option works
- [ ] Handles no results gracefully
- [ ] Handles API errors gracefully
- [ ] Rate limit warnings displayed
- [ ] Works without GitHub token (60 req/hour)
- [ ] Works with GitHub token (5000 req/hour)

---

**Status**: Ready to implement  
**Priority**: High (MVP feature)  
**Estimated Effort**: 6-8 hours  
