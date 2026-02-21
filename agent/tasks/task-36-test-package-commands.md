# Task 36: Test Untested Package Commands

**Milestone**: Future Enhancements
**Estimated Time**: 4-6 hours
**Dependencies**: Tasks 8-12 (Package Commands Implementation)
**Status**: Not Started

---

## Objective

Comprehensively test all package management commands that have not yet been tested: `@acp.package-list`, `@acp.package-update`, `@acp.package-remove`, `@acp.package-info`, `@acp.package-search`, and `@acp.package-create`.

---

## Context

According to user feedback, only four package commands have been tested:
- ✅ `@acp.package-validate` (tested in Task 20)
- ✅ `@acp.package-publish` (tested in Task 22)
- ✅ `@acp.package-install` (tested in Task 6)
- ✅ `@acp.package-create` (tested in Task 23)

The following commands need comprehensive testing:
- ❌ `@acp.package-list` (Task 8) - List installed packages
- ❌ `@acp.package-update` (Task 7) - Update packages
- ❌ `@acp.package-remove` (Task 9) - Remove packages
- ❌ `@acp.package-info` (Task 10) - Show package details
- ❌ `@acp.package-search` (Task 11) - Search for packages

Testing is critical to ensure these commands work correctly in production and handle edge cases gracefully.

---

## Steps

### 1. Test @acp.package-list

Test listing installed packages with various filters:

**Test Cases**:
```bash
# Test 1: List all packages (basic)
./agent/scripts/acp.package-list.sh

# Test 2: List with verbose output
./agent/scripts/acp.package-list.sh --verbose

# Test 3: List outdated packages
./agent/scripts/acp.package-list.sh --outdated

# Test 4: List modified packages
./agent/scripts/acp.package-list.sh --modified

# Test 5: Empty manifest (no packages)
# Create empty manifest, run list, should show "No packages installed"
```

**Expected Results**:
- Shows all installed packages with versions and file counts
- Verbose mode shows detailed file information
- Filters work correctly (outdated, modified)
- Handles empty manifest gracefully
- Color-coded output displays correctly

**Verification**:
- [ ] Basic listing works
- [ ] Verbose mode shows details
- [ ] Outdated filter works
- [ ] Modified filter works
- [ ] Empty manifest handled gracefully
- [ ] Output format matches documentation
- [ ] No errors or warnings

### 2. Test @acp.package-update

Test updating packages with various scenarios:

**Test Cases**:
```bash
# Test 1: Check for updates (dry run)
./agent/scripts/acp.package-update.sh --check

# Test 2: Update specific package
./agent/scripts/acp.package-update.sh test-package

# Test 3: Update all packages
./agent/scripts/acp.package-update.sh

# Test 4: Update with --skip-modified
./agent/scripts/acp.package-update.sh --skip-modified

# Test 5: Update with --force
./agent/scripts/acp.package-update.sh --force

# Test 6: Update with auto-confirm
./agent/scripts/acp.package-update.sh -y

# Test 7: Update when no updates available
# Should show "All packages up to date"

# Test 8: Update with local modifications
# Modify a file, run update, should detect conflict
```

**Expected Results**:
- Check mode shows available updates without installing
- Updates specific package correctly
- Updates all packages when no package specified
- Skip-modified preserves local changes
- Force overwrites local changes
- Auto-confirm skips prompts
- Handles no updates gracefully
- Detects and reports conflicts

**Verification**:
- [ ] Check mode works (no modifications)
- [ ] Specific package update works
- [ ] Update all packages works
- [ ] Skip-modified preserves changes
- [ ] Force overwrites changes
- [ ] Auto-confirm works
- [ ] No updates handled gracefully
- [ ] Conflict detection works
- [ ] Manifest updated correctly
- [ ] No errors or warnings

### 3. Test @acp.package-remove

Test removing packages with various options:

**Test Cases**:
```bash
# Test 1: Remove package (with confirmation)
./agent/scripts/acp.package-remove.sh test-package

# Test 2: Remove with auto-confirm
./agent/scripts/acp.package-remove.sh test-package -y

# Test 3: Remove with --keep-modified
# Modify a file first, then remove with flag
./agent/scripts/acp.package-remove.sh test-package --keep-modified

# Test 4: Remove non-existent package
./agent/scripts/acp.package-remove.sh nonexistent-package

# Test 5: Remove when files already deleted
# Delete files manually, then run remove
```

**Expected Results**:
- Prompts for confirmation before removal
- Auto-confirm skips prompts
- Keep-modified preserves locally changed files
- Handles non-existent packages gracefully
- Handles missing files gracefully
- Removes package from manifest
- Shows removal summary

**Verification**:
- [ ] Confirmation prompt works
- [ ] Auto-confirm works
- [ ] Keep-modified preserves changes
- [ ] Non-existent package handled
- [ ] Missing files handled
- [ ] Manifest updated correctly
- [ ] Files removed successfully
- [ ] Summary shows correct counts
- [ ] No errors or warnings

### 4. Test @acp.package-info

Test displaying package information:

**Test Cases**:
```bash
# Test 1: Show info for installed package
./agent/scripts/acp.package-info.sh test-package

# Test 2: Show info for non-existent package
./agent/scripts/acp.package-info.sh nonexistent-package

# Test 3: Show info with modified files
# Modify a file, run info, should show [MODIFIED] tag

# Test 4: Show info for package with many files
# Should display all files organized by type
```

**Expected Results**:
- Shows package metadata (source, version, commit, dates)
- Lists all installed files with versions
- Highlights modified files with [MODIFIED] tag
- Shows file counts by type
- Handles non-existent packages gracefully
- Color-coded output displays correctly

**Verification**:
- [ ] Package metadata displayed correctly
- [ ] All files listed with versions
- [ ] Modified files highlighted
- [ ] File counts correct
- [ ] Non-existent package handled
- [ ] Output format matches documentation
- [ ] No errors or warnings

### 5. Test @acp.package-search

Test searching for packages on GitHub:

**Test Cases**:
```bash
# Test 1: Search by keyword
./agent/scripts/acp.package-search.sh firebase

# Test 2: Search by tag
./agent/scripts/acp.package-search.sh --tag authentication

# Test 3: Search by user
./agent/scripts/acp.package-search.sh --user prmichaelsen

# Test 4: Search by organization
./agent/scripts/acp.package-search.sh --org someorg

# Test 5: Sort by different fields
./agent/scripts/acp.package-search.sh firebase --sort updated
./agent/scripts/acp.package-search.sh firebase --sort name

# Test 6: Limit results
./agent/scripts/acp.package-search.sh firebase --limit 5

# Test 7: No results found
./agent/scripts/acp.package-search.sh nonexistent-keyword-xyz123
```

**Expected Results**:
- Searches GitHub API successfully
- Fetches package.yaml metadata
- Displays results with stars, description, tags
- Shows installation command for each result
- Sorting works correctly
- Limit works correctly
- Handles no results gracefully
- Handles API rate limits gracefully

**Verification**:
- [ ] Keyword search works
- [ ] Tag filter works
- [ ] User filter works
- [ ] Organization filter works
- [ ] Sorting works (stars, updated, name)
- [ ] Limit works
- [ ] No results handled gracefully
- [ ] API rate limits handled
- [ ] Output format matches documentation
- [ ] No errors or warnings

### 6. Create Test Report

Document all test results:

**Create**: `agent/reports/package-commands-test-report.md`

**Content**:
```markdown
# Package Commands Test Report

**Date**: 2026-02-21
**Tester**: Agent
**Version**: 3.6.0

---

## Test Summary

| Command | Status | Tests Passed | Tests Failed | Notes |
|---------|--------|--------------|--------------|-------|
| package-list | ✅ | 5/5 | 0 | All filters work |
| package-update | ✅ | 8/8 | 0 | Conflict detection works |
| package-remove | ✅ | 5/5 | 0 | Keep-modified works |
| package-info | ✅ | 4/4 | 0 | Modified detection works |
| package-search | ✅ | 7/7 | 0 | GitHub API works |
| package-create | ✅ | 7/7 | 0 | Full workflow works |

**Total**: 36/36 tests passed (100%)

---

## Detailed Results

[Include detailed test results for each command]

---

## Issues Found

[List any issues discovered during testing]

---

## Recommendations

[Suggest improvements or fixes]
```

**Verification**:
- [ ] Test report created
- [ ] All test results documented
- [ ] Issues identified and documented
- [ ] Recommendations provided

---

## Common Issues and Solutions

### Issue 1: Command not found

**Symptom**: Error "command not found" when running script

**Solution**: Ensure script is executable: `chmod +x agent/scripts/acp.package-*.sh`. Or run with bash: `bash agent/scripts/acp.package-*.sh`

### Issue 2: YAML parser errors

**Symptom**: Errors parsing YAML files

**Solution**: Ensure `acp.yaml-parser.sh` is sourced correctly. Check that `source_yaml_parser()` is called in script. Verify YAML files are valid.

### Issue 3: Manifest not found

**Symptom**: Error "manifest.yaml not found"

**Solution**: Initialize manifest first: `./agent/scripts/acp.package-install.sh --repo {url}` to install a package, which will create manifest.

### Issue 4: GitHub API rate limit

**Symptom**: Package search fails with rate limit error

**Solution**: Wait for rate limit to reset (60 requests/hour without auth). Or add GitHub token for higher limits (5000/hour).

---

## Resources

- [Package List Command](../commands/acp.package-list.md): Command documentation
- [Package Update Command](../commands/acp.package-update.md): Command documentation
- [Package Remove Command](../commands/acp.package-remove.md): Command documentation
- [Package Info Command](../commands/acp.package-info.md): Command documentation
- [Package Search Command](../commands/acp.package-search.md): Command documentation
- [Package Create Command](../commands/acp.package-create.md): Command documentation

---

## Notes

- Testing should cover both success and failure scenarios
- Test with real packages when possible
- Document any bugs or issues found
- Create bug fix tasks for any issues discovered
- Consider creating automated test suite for future regression testing
- Some commands require network access (search, update)
- Some commands require user input (create, remove without -y)

---

**Next Task**: TBD
**Related Tasks**: 
- [task-8-package-list-command.md](task-8-package-list-command.md)
- [task-7-update-system.md](task-7-update-system.md)
- [task-9-package-remove-command.md](task-9-package-remove-command.md)
- [task-10-package-info-command.md](task-10-package-info-command.md)
- [task-11-package-search-command.md](task-11-package-search-command.md)
- [task-23-package-create-rewrite.md](task-23-package-create-rewrite.md)
**Estimated Completion Date**: TBD
