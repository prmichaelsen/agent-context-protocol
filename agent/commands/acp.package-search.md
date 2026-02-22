# Command: package-search

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-search` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-18
**Status**: Active

---

**Purpose**: Discover ACP packages on GitHub using the GitHub API
**Category**: Package Discovery
**Frequency**: As Needed

---

## What This Command Does

This command searches GitHub for ACP packages using the GitHub API. **By default, it only searches repositories with the `acp-package` topic**, ensuring you only see actual ACP packages and not unrelated repositories.

It fetches `package.yaml` metadata from each result and displays comprehensive information including version, description, tags, stars, and installation commands.

Use this command when you want to discover available ACP packages, find packages for specific technologies (via tags), or browse community-created patterns and commands.

---

## Prerequisites

- [ ] Internet connection available
- [ ] `curl` command available
- [ ] `agent/scripts/acp.package-search.sh` exists
- [ ] Optional: `GITHUB_TOKEN` environment variable for higher rate limits

---

## Steps

### 1. Run Package Search Script

Execute the search script with your query.

**Actions**:
- Run `./agent/scripts/acp.package-search.sh` with search terms:
  ```bash
  # Search by keyword
  ./agent/scripts/acp.package-search.sh firebase
  
  # Filter by tag
  ./agent/scripts/acp.package-search.sh oauth --tag authentication
  
  # Search specific user's packages
  ./agent/scripts/acp.package-search.sh --user prmichaelsen
  
  # Sort by recently updated
  ./agent/scripts/acp.package-search.sh --sort updated --limit 5
  ```

**Expected Outcome**: Search results displayed

### 2. Review Search Results

Analyze the displayed packages.

**Actions**:
- Review package names and versions
- Read descriptions
- Check star counts (popularity indicator)
- Note tags (technology indicators)
- Identify relevant packages for your project

**Expected Outcome**: Suitable packages identified

### 3. Install Selected Package

Use the provided installation command.

**Actions**:
- Copy installation command from search results
- Run `@acp.package-install <url>` with the package URL
- Follow installation prompts

**Expected Outcome**: Package installed successfully

---

## Syntax

```bash
./agent/scripts/acp.package-search.sh [query] [options]

Options:
  --tag <tag>              Filter by additional tag
  --user <username>        Search specific user's repos
  --org <org>              Search specific organization
  --sort <field>           Sort by: stars, updated, name (default: stars)
  --limit <n>              Limit results (default: 10, max: 100)
```

---

## Verification

- [ ] Script executed successfully
- [ ] GitHub API queried successfully
- [ ] Results displayed with all metadata
- [ ] Package versions shown
- [ ] Tags displayed
- [ ] Star counts shown
- [ ] Installation commands provided
- [ ] Filters work correctly
- [ ] Handles no results gracefully
- [ ] Handles API errors gracefully

---

## Expected Output

### Files Modified
None - this is a read-only command

### Console Output
```
🔍 ACP Package Search
========================================

ℹ Searching GitHub for: firebase+topic:acp-package
ℹ Sort by: stars
ℹ Limit: 10

📦 Found 3 package(s)

1. firebase (1.2.0) ⭐ 45
   https://github.com/prmichaelsen/acp-firebase
   Firebase patterns and utilities for ACP projects
   Tags: firebase, firestore, database, backend
   Install: ./agent/scripts/acp.package-install.sh https://github.com/prmichaelsen/acp-firebase.git

2. firebase-v11 (1.0.0) ⭐ 12
   https://github.com/otheruser/acp-firebase-v11
   Firebase patterns for v11 Admin SDK
   Tags: firebase, firebase-v11, legacy
   Install: ./agent/scripts/acp.package-install.sh https://github.com/otheruser/acp-firebase-v11.git

3. fullstack (2.0.0) ⭐ 89
   https://github.com/community/acp-fullstack
   Complete fullstack patterns including Firebase
   Tags: firebase, cloudflare, tanstack, fullstack
   Install: ./agent/scripts/acp.package-install.sh https://github.com/community/acp-fullstack.git

Showing 3 of 3 result(s)

To install a package:
  ./agent/scripts/acp.package-install.sh <repository-url>
```

---

## Examples

### Example 1: Search by Keyword

**Context**: Looking for Firebase-related packages

**Invocation**: `@acp.package-search firebase`

**Result**: Shows 3 packages with firebase in name/description/tags, sorted by stars

### Example 2: Filter by Tag

**Context**: Need OAuth authentication patterns

**Invocation**: `@acp.package-search oauth --tag authentication`

**Result**: Shows packages tagged with both "oauth" and "authentication"

### Example 3: Browse User's Packages

**Context**: Want to see all packages from specific author

**Invocation**: `@acp.package-search --user prmichaelsen`

**Result**: Shows all acp-package repos from prmichaelsen

### Example 4: Find Recent Packages

**Context**: Want to see recently updated packages

**Invocation**: `@acp.package-search --sort updated --limit 5`

**Result**: Shows 5 most recently updated packages

### Example 5: No Results

**Context**: Search for non-existent package

**Invocation**: `@acp.package-search nonexistent123`

**Result**: "No packages found matching your search", suggests trying broader terms

---

## Related Commands

- [`@acp.package-install`](acp.package-install.md) - Install discovered packages
- [`@acp.package-list`](acp.package-list.md) - List installed packages
- [`@acp.package-info`](acp.package-info.md) - Show package details

---

## GitHub API Details

### Rate Limits
- **Without token**: 60 requests/hour
- **With token**: 5,000 requests/hour

### Setting GitHub Token
```bash
export GITHUB_TOKEN="your_github_token"
```

### API Endpoints Used
- `GET /search/repositories` - Search repos by topic
- `GET /repos/{owner}/{repo}/contents/package.yaml` - Fetch metadata

---

## Package Discovery Requirements

For packages to be discoverable via `@acp.package-search`:

1. **GitHub Topic** (REQUIRED): Add `acp-package` topic to repository
   - This is the canonical way to identify ACP packages
   - Without this topic, packages will NOT appear in search results
2. **package.yaml**: Include in repository root with:
   ```yaml
   name: package-name
   version: 1.0.0
   description: Clear description
   tags:
     - tag1
     - tag2
   ```
3. **Clear Description**: Add description to GitHub repository
4. **ACP Structure**: Follow standard `agent/` directory structure

**Note**: The `topic:acp-package` filter is always applied to ensure search results contain only actual ACP packages, not unrelated repositories with "acp" in the name.

---

## Troubleshooting

### Issue 1: No results found

**Symptom**: "No packages found"

**Cause**: No packages match search criteria

**Solution**: Try broader search terms, remove filters, check spelling

### Issue 2: API rate limit exceeded

**Symptom**: "API rate limit exceeded" error

**Cause**: Made too many requests (60/hour without token)

**Solution**: Wait for rate limit reset, or set GITHUB_TOKEN for higher limits

### Issue 3: Package.yaml not found

**Symptom**: Version shows "unknown"

**Cause**: Package doesn't have package.yaml in root

**Solution**: This is informational only, package can still be installed

### Issue 4: Slow response

**Symptom**: Search takes long time

**Cause**: Fetching package.yaml for each result

**Solution**: This is normal, reduce --limit for faster results

---

## Notes

- Requires internet connection
- Uses GitHub API (no authentication required for basic use)
- Fetches package.yaml for each result (adds latency)
- Results cached by GitHub (may not show very recent packages)
- Set GITHUB_TOKEN for higher rate limits
- Packages must have `acp-package` topic to be discoverable

---

**Namespace**: acp
**Command**: package-search
**Version**: 1.0.0
**Created**: 2026-02-18
**Last Updated**: 2026-02-18
**Status**: Active
**Compatibility**: ACP 2.0.0+
**Author**: ACP Project
