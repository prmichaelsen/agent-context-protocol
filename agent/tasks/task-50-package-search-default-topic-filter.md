# Task 50: Package Search Default Topic Filter

**Milestone**: M3 - ACP Package Management System
**Estimated Time**: 1 hour
**Dependencies**: Task 11 (Package Search Command)
**Status**: Not Started

---

## Objective

Update `@acp.package-search` to search by `topic:acp-package` by default when no other arguments are provided, ensuring only actual ACP packages are returned and preventing accidental discovery of non-ACP repositories.

---

## Context

Currently, `@acp.package-search` searches for repositories with "acp" in the name, which returns thousands of irrelevant results (ACPI drivers, Android libraries, etc.). 

**The Problem**: The search query `acp-` matches any repository with "acp" in the name, resulting in 11,356+ results where only 3 are actual ACP packages.

**The Solution**: By default, search should filter by `topic:acp-package` to only return repositories that have explicitly added the `acp-package` topic. This is the canonical way to identify ACP packages.

**Definition**: A repository is an ACP package **if and only if** it has the `acp-package` topic added to the GitHub repository.

---

## Steps

### 1. Review Current Search Behavior

Understand the current implementation:

**Actions**:
- Read `agent/scripts/acp.package-search.sh`
- Identify where search query is constructed
- Note current default behavior (searches for "acp-")
- Understand how topic filtering works

**Expected Outcome**: Current implementation understood

### 2. Update Default Search Query

Modify the script to use `topic:acp-package` by default:

**Actions**:
- Change default query from `acp-` to `topic:acp-package`
- Ensure topic filter is applied when no query provided
- Keep existing behavior when explicit query is provided
- Combine user query with topic filter: `{query}+topic:acp-package`

**Implementation**:
```bash
# Current behavior (incorrect):
QUERY="${1:-acp-}"

# New behavior (correct):
QUERY="${1:-}"
if [ -z "$QUERY" ]; then
    # No query provided - search all packages with acp-package topic
    SEARCH_QUERY="topic:acp-package"
else
    # Query provided - combine with topic filter
    SEARCH_QUERY="${QUERY}+topic:acp-package"
fi
```

**Expected Outcome**: Default search uses topic filter

### 3. Update Search Display

Update the informational output to reflect the topic filter:

**Actions**:
- Update "Searching GitHub for:" message
- Show when topic filter is applied
- Make it clear that only acp-package repos are searched

**Example Output**:
```
ℹ Searching GitHub for: topic:acp-package
ℹ Sort by: stars
ℹ Limit: 10
```

Or with query:
```
ℹ Searching GitHub for: firebase+topic:acp-package
ℹ Sort by: stars
ℹ Limit: 10
```

**Expected Outcome**: User understands search is filtered to ACP packages

### 4. Update Command Documentation

Update `agent/commands/acp.package-search.md`:

**Actions**:
- Document that search is filtered to `topic:acp-package` by default
- Explain that this ensures only actual ACP packages are returned
- Update examples to show new behavior
- Add note about package discovery requirements

**Documentation Changes**:
```markdown
## What This Command Does

This command searches GitHub for ACP packages using the GitHub API. 
**By default, it only searches repositories with the `acp-package` topic**, 
ensuring you only see actual ACP packages and not unrelated repositories.

...

## Package Discovery

For packages to be discoverable via `@acp.package-search`:
1. **Required**: Add `acp-package` topic to GitHub repository
2. Include `package.yaml` in repository root
3. Follow ACP package structure
```

**Expected Outcome**: Documentation reflects new behavior

### 5. Test Search Behavior

Verify the changes work correctly:

**Test Cases**:
```bash
# Test 1: No arguments (should return only acp-package repos)
./agent/scripts/acp.package-search.sh

# Expected: 3 results (tanstack-cloudflare, mcp-server-starter, mcp-auth-server-base)
# Not: 11,356 results

# Test 2: With query (should combine query + topic filter)
./agent/scripts/acp.package-search.sh firebase

# Expected: Only acp-package repos matching "firebase"

# Test 3: With --tag filter (should work with topic filter)
./agent/scripts/acp.package-search.sh --tag authentication

# Expected: acp-package repos with "authentication" tag
```

**Expected Outcome**: All test cases pass

### 6. Update Examples

Update command examples to reflect new behavior:

**Actions**:
- Update Example 1 to show default search returns only ACP packages
- Add note about topic filter in each example
- Show expected result counts

**Expected Outcome**: Examples are accurate

---

## Verification

- [ ] Script updated with topic filter logic
- [ ] Default search (no args) returns only acp-package repos
- [ ] Search with query combines query + topic filter
- [ ] Informational output shows topic filter is applied
- [ ] Command documentation updated
- [ ] Examples updated to reflect new behavior
- [ ] All test cases pass
- [ ] No regression in existing functionality

---

## Files to Modify

```
agent/
├── scripts/
│   └── acp.package-search.sh       # Update default query logic
└── commands/
    └── acp.package-search.md       # Update documentation
```

---

## Implementation Notes

### Query Construction Logic

**Current (incorrect)**:
- Default query: `acp-` (matches 11,356 repos)
- With query: `{query}` (no topic filter)

**New (correct)**:
- Default query: `topic:acp-package` (matches only ACP packages)
- With query: `{query}+topic:acp-package` (combines user query with topic filter)

### Backward Compatibility

This is a **breaking change** in behavior but improves usability:
- Old behavior: Returns many irrelevant results
- New behavior: Returns only actual ACP packages
- **Justification**: The old behavior is not useful (too many false positives)

### Topic Filter Enforcement

The `topic:acp-package` filter is **always applied** to ensure quality results. Users cannot disable it because:
1. It's the canonical way to identify ACP packages
2. Without it, search is unusable (too many false positives)
3. Package authors must explicitly add the topic (opt-in)

---

## Testing

### Manual Testing

```bash
# Test default search
./agent/scripts/acp.package-search.sh

# Should return ~3 results (current known ACP packages)
# Should NOT return 11,356 results

# Test with query
./agent/scripts/acp.package-search.sh mcp

# Should return ACP packages related to MCP
# Should NOT return non-ACP repos with "mcp" in name

# Test with filters
./agent/scripts/acp.package-search.sh --user prmichaelsen

# Should return only prmichaelsen's ACP packages
```

### Expected Results

**Before fix**:
- Default search: 11,356 results (mostly irrelevant)
- With query: Still returns non-ACP repos

**After fix**:
- Default search: ~3 results (only ACP packages)
- With query: Only ACP packages matching query

---

## Related Tasks

- Task 11: Package Search Command (original implementation)
- Task 36: Test Untested Package Commands (testing infrastructure)

---

## Success Criteria

- [ ] Default search returns only repos with `acp-package` topic
- [ ] Search results are relevant and useful
- [ ] No more false positives from non-ACP repos
- [ ] Documentation clearly explains topic filter
- [ ] Examples show expected result counts
- [ ] All existing search features still work (--tag, --user, --sort, --limit)

---

**Next Task**: TBD
**Estimated Completion**: 1 hour
**Priority**: High (fixes usability issue)
**Complexity**: Low (simple query modification)
