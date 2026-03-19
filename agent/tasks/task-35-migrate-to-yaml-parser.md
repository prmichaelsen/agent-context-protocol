# Task 35: Migrate Scripts from acp.yaml.sh to acp.yaml-parser.sh

**Milestone**: Future Enhancements  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 34 (Generic YAML Parser)  
**Status**: Not Started  

---

## Objective

Migrate all scripts currently using `acp.yaml.sh` to use the new `acp.yaml-parser.sh` for better performance and consistency. The new parser provides 10-100x faster queries through AST caching and supports generic path expressions.

---

## Context

Task 34 created a new generic YAML parser (`acp.yaml-parser.sh`) with AST-based architecture that is significantly faster and more flexible than the old `acp.yaml.sh`. However, several scripts still use the old parser directly.

**Current State**:
- `acp.yaml-parser.sh` provides backward-compatible functions (`yaml_get()`, `yaml_get_nested()`, `yaml_has_key()`, `yaml_get_array()`)
- `acp.yaml.sh` is still sourced by some scripts
- 29 references to `acp.yaml.sh` found across codebase
- Scripts work but miss performance benefits of new parser

**Benefits of Migration**:
- 10-100x faster for multiple queries (parse once, query many)
- Generic path expressions (`.path.to.field`, `.array[0].field`)
- Better error handling and validation
- Single parser to maintain going forward
- Enables future YAML modification operations

---

## Steps

### 1. Audit Current Usage

Identify all files using `acp.yaml.sh`:

```bash
# Find all references
grep -r "acp\.yaml\.sh" agent/ --include="*.sh" --include="*.md"

# Count references
grep -r "acp\.yaml\.sh" agent/ --include="*.sh" --include="*.md" | wc -l
```

**Files to check**:
- `agent/scripts/acp.common.sh` - Uses `source_yaml_parser()` which sources `acp.yaml-parser.sh`
- `agent/scripts/acp.yaml-validate.sh` - Already migrated in Task 34
- `agent/scripts/acp.package-validate.sh` - Uses yaml functions
- `agent/scripts/acp.package-publish.sh` - Uses yaml functions
- `agent/scripts/acp.common.sh` - Contains `source_yaml_parser()` function
- `agent/commands/acp.sync.md` - References `acp.yaml.sh` in documentation

**Verification**:
- All files using old parser identified
- Usage patterns documented
- Migration complexity assessed

### 2. Update source_yaml_parser() Function

The `source_yaml_parser()` function in `acp.common.sh` already sources `acp.yaml-parser.sh`, so scripts using this function are already using the new parser.

**Verify**:
```bash
# Check source_yaml_parser() implementation
grep -A 10 "source_yaml_parser()" agent/scripts/acp.common.sh
```

**Expected**: Function sources `acp.yaml-parser.sh` (not `acp.yaml.sh`)  

**Verification**:
- `source_yaml_parser()` sources correct parser
- All scripts using this function get new parser
- No changes needed to scripts using `source_yaml_parser()`

### 3. Update Direct References

Update any scripts that directly source `acp.yaml.sh`:

**Search for**:
```bash
grep -n "acp\.yaml\.sh" agent/scripts/*.sh
```

**Replace**:
```bash
# Old
. "${SCRIPT_DIR}/acp.yaml.sh"

# New
. "${SCRIPT_DIR}/acp.yaml-parser.sh"
```

**Verification**:
- No direct references to `acp.yaml.sh` remain
- All scripts source `acp.yaml-parser.sh` or use `source_yaml_parser()`
- Scripts still execute without errors

### 4. Update Documentation References

Update documentation that mentions `acp.yaml.sh`:

**Files to update**:
- `agent/commands/acp.sync.md` - Update references to use `acp.yaml-parser.sh`
- Any design documents mentioning the old parser
- Task documents referencing YAML parser

**Changes**:
```markdown
# Old
Compare documented tools (e.g., yq) with actual tools (e.g., acp.yaml.sh)

# New
Compare documented tools (e.g., yq) with actual tools (e.g., acp.yaml-parser.sh)
```

**Verification**:
- All documentation references updated
- No mentions of old parser remain
- Documentation accurately reflects current implementation

### 5. Verify Backward Compatibility

Ensure all existing yaml function calls still work:

**Test each function**:
```bash
# Source new parser
source agent/scripts/acp.yaml-parser.sh

# Test yaml_get
yaml_get "package.yaml" "name"

# Test yaml_get_nested
yaml_get_nested "package.yaml" "contents.commands[0].name"

# Test yaml_has_key
yaml_has_key "package.yaml" "name" && echo "✓ Key exists"

# Test yaml_get_array
yaml_get_array "package.yaml" "contents.commands"

# Test yaml_set
yaml_set ".name" "new-value"
yaml_write "package.yaml"
```

**Verification**:
- All backward-compatible functions work
- No breaking changes to existing scripts
- Function signatures unchanged
- Return values match expectations

### 6. Test All Package Commands

Run each package command to ensure they work with new parser:

```bash
# Test package-validate (already tested in Task 20)
./agent/scripts/acp.package-validate.sh

# Test package-publish (already tested in Task 22)
./agent/scripts/acp.package-publish.sh

# Test package-install (already tested in Task 6)
./agent/scripts/acp.package-install.sh --list --repo https://github.com/example/repo.git

# Test other commands (to be tested in Task 36)
./agent/scripts/acp.package-list.sh
./agent/scripts/acp.package-update.sh --check
./agent/scripts/acp.package-remove.sh --help
./agent/scripts/acp.package-info.sh test-package
./agent/scripts/acp.package-search.sh firebase
```

**Verification**:
- All commands execute without errors
- YAML parsing works correctly
- No performance regressions
- Output is correct and complete

### 7. Consider Deprecating acp.yaml.sh

Decide whether to keep or remove `acp.yaml.sh`:

**Option A: Keep for Backward Compatibility**
- Keep file but add deprecation notice
- Update to be a thin wrapper around `acp.yaml-parser.sh`
- Maintain for 1-2 versions before removal

**Option B: Remove Immediately**
- Delete `acp.yaml.sh` file
- All scripts now use `acp.yaml-parser.sh`
- Clean break, simpler codebase

**Recommendation**: Option A (keep with deprecation notice)  

**If keeping**:
```bash
#!/bin/sh
# DEPRECATED: This file is deprecated. Use acp.yaml-parser.sh instead.
# This file is kept for backward compatibility and will be removed in a future version.

# Source new parser
SCRIPT_DIR="$(dirname "$0")"
. "${SCRIPT_DIR}/acp.yaml-parser.sh"

# All functions now provided by acp.yaml-parser.sh
```

**Verification**:
- Decision documented
- Deprecation notice added if keeping
- CHANGELOG.md updated with deprecation notice

### 8. Update CHANGELOG.md

Document the migration in CHANGELOG:

**Add to next version**:
```markdown
### Changed

**YAML Parser Migration**:
- All scripts now use `acp.yaml-parser.sh` (AST-based parser)
- `acp.yaml.sh` deprecated (kept for backward compatibility)
- 10-100x performance improvement for multiple queries
- Generic path expressions supported: `.path.to.field`, `.array[0].field`

### Deprecated

- `acp.yaml.sh` - Use `acp.yaml-parser.sh` instead (will be removed in v4.0.0)
```

**Verification**:
- CHANGELOG.md updated
- Migration documented
- Deprecation timeline specified

---

## Verification

- [ ] All files using `acp.yaml.sh` identified (29 references found)
- [ ] `source_yaml_parser()` verified to source correct parser
- [ ] No direct references to `acp.yaml.sh` in scripts (or updated)
- [ ] Documentation references updated
- [ ] Backward compatibility verified (all functions work)
- [ ] All package commands tested with new parser
- [ ] Deprecation strategy decided and implemented
- [ ] CHANGELOG.md updated with migration notes
- [ ] No errors during migration
- [ ] Performance improvements confirmed

---

## Expected Output

### Files Modified
- `agent/commands/acp.sync.md` - Updated references to new parser
- `agent/scripts/acp.yaml.sh` - Added deprecation notice (if keeping)
- `CHANGELOG.md` - Added migration notes

### Console Output
```
🔄 Migrating to acp.yaml-parser.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Auditing current usage...
  Found 29 references to acp.yaml.sh
  
✓ Verifying source_yaml_parser()...
  Already sources acp.yaml-parser.sh ✓
  
✓ Checking direct references...
  No direct references found ✓
  
✓ Updating documentation...
  Updated agent/commands/acp.sync.md
  
✓ Testing backward compatibility...
  yaml_get() ✓
  yaml_get_nested() ✓
  yaml_has_key() ✓
  yaml_get_array() ✓
  yaml_set() ✓
  
✓ Testing package commands...
  All commands work correctly ✓
  
✓ Adding deprecation notice...
  Updated acp.yaml.sh with deprecation notice
  
✓ Updating CHANGELOG.md...
  Migration documented

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Migration Complete!

All scripts now use acp.yaml-parser.sh
Performance: 10-100x faster for multiple queries
Backward compatibility: 100% maintained
```

---

## Common Issues and Solutions

### Issue 1: Function not found after migration

**Symptom**: Error "yaml_get: command not found"  

**Solution**: Ensure `acp.yaml-parser.sh` is sourced. Check that `source_yaml_parser()` is called or parser is sourced directly.  

### Issue 2: Different output format

**Symptom**: Script output changed after migration  

**Solution**: New parser should be backward compatible. Check if script relies on specific output format. May need to adjust parsing logic.  

### Issue 3: Performance regression

**Symptom**: Scripts slower after migration  

**Solution**: This should not happen - new parser is faster. If it does, check that parser is being used correctly (parse once, query many times).  

---

## Resources

- [YAML Parser Design](../design/yaml-parser-design.md): Complete AST specification
- [acp.yaml-parser.sh](../scripts/acp.yaml-parser.sh): New parser implementation
- [acp.yaml.sh](../scripts/acp.yaml.sh): Old parser (to be deprecated)
- [Task 34: Build Generic YAML Parser](task-34-build-generic-yaml-parser.md): Parser creation task

---

## Notes

- Migration is mostly documentation updates (scripts already use new parser via `source_yaml_parser()`)
- Old parser (`acp.yaml.sh`) kept for backward compatibility with deprecation notice
- New parser provides same API, so no code changes needed in most scripts
- Performance improvements are automatic once migration complete
- Consider removing `acp.yaml.sh` in v4.0.0 (breaking change)

---

**Next Task**: [task-36-test-package-commands.md](task-36-test-package-commands.md)  
**Related Tasks**: [task-34-build-generic-yaml-parser.md](task-34-build-generic-yaml-parser.md)  
**Estimated Completion Date**: TBD  
