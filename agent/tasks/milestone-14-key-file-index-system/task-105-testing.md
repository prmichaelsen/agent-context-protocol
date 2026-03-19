# Task 105: Testing

**Milestone**: [M14 - Key File Index System](../../milestones/milestone-14-key-file-index-system.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: [Task 100](task-100-command-directive-integration.md), [Task 101](task-101-creation-command-integration.md), [Task 102](task-102-acp-index-command.md)  
**Status**: Completed  

---

## Objective

Create comprehensive E2E tests for the key file index system covering index loading, validation, package integration, and the `@acp.index` command.

---

## Context

The key file index system touches many parts of ACP (commands, packages, validation). Tests ensure the index schema is parsed correctly, files are loaded in the right order, and validation catches errors. Following the project's established E2E testing pattern.

---

## Steps

### 1. Create Test Suite

Create `e2e/acp.index.test.sh` following the local.e2e-testing pattern.

### 2. Index Schema Tests

- Valid index file parses correctly
- Missing required fields detected
- Weight out of range (< 0.0, > 1.0) detected
- Invalid kind value detected
- Applies field with unqualified names warned

### 3. Index Loading Tests

- Single index file loads entries
- Multiple index files merge correctly
- `local.*` entries take precedence over package entries
- Entries sorted by weight descending
- Filtering by `applies` field works correctly

### 4. Validation Integration Tests

- `@acp.validate` detects missing file paths in index
- `@acp.validate` warns on missing `agent/index/` directory
- `@acp.validate` warns on exceeding recommended limits
- `@acp.validate` passes on valid index

### 5. Package Integration Tests

- Package with index file installs to `agent/index/`
- Package removal cleans up index file
- Package update refreshes index file

### 6. Edge Case Tests

- Empty index file (no entries)
- Index file with only one entry
- Duplicate paths across namespaces
- File path exists but is empty
- Malformed YAML in index file

---

## Verification

- [ ] E2E test suite created following project testing pattern
- [ ] Schema validation tests pass
- [ ] Index loading and precedence tests pass
- [ ] Validation integration tests pass
- [ ] Package integration tests pass
- [ ] Edge case tests pass
- [ ] All tests run cleanly via `bash e2e/acp.index.test.sh`
