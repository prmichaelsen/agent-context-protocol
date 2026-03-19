# Task 30: Fix Package Validation for Non-Package Files

**Milestone**: Future Enhancement  
**Estimated Time**: 30 minutes - 1 hour  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Fix `@acp.package-validate` to skip namespace validation for files that exist in the package repository but are NOT listed in `package.yaml` contents.

---

## Context

When developing an ACP package, developers often install other ACP packages (like core ACP commands) into their package repository for development purposes.

**How It Works (Already Correct)**:
1. Package developer runs `@acp.package-install https://github.com/user/acp-git.git`
2. Files like `git.commit.md` are installed to `agent/commands/`
3. These files are tracked in the package's `manifest.yaml`
4. These files are NOT in the package's `package.yaml` contents
5. When users install the package, only files in `contents` are copied ✅
6. The `manifest.yaml` effectively acts as a "dev dependencies" tracker ✅

**Current Problem (Validation Only)**:
- Validation checks ALL files in `agent/commands/`, `agent/patterns/`, `agent/designs/`
- Flags files like `git.commit.md` as namespace violations
- Even though these files are correctly excluded from `package.yaml` contents
- The installation system already works correctly (only installs files in `contents`)

**Root Cause**: Validation doesn't check if files are in `package.yaml` contents before validating namespace.  

**Key Insight**: `manifest.yaml` already acts as the dev dependency tracker! Files in manifest but not in package contents are effectively dev dependencies. No new field needed.  

**Example**:
```
acp-tanstack-cloudflare/
├── package.yaml              # Lists tanstack-cloudflare.* files in contents
├── agent/
│   ├── manifest.yaml         # Tracks git.commit.md (installed dependency)
│   ├── commands/
│   │   ├── git.commit.md     # Installed from acp-git package
│   │   └── tanstack-cloudflare.deploy.md  # Package content
```

Validation currently flags `git.commit.md` as error, but it shouldn't because:
1. It's not in `package.yaml` contents
2. It won't be installed to user projects
3. It's tracked in `manifest.yaml` as an installed dependency

---

## Steps

### 1. Update acp.package-validate.sh Namespace Validation

Modify the namespace validation logic to only check files listed in `package.yaml` contents:

```bash
# Read package.yaml contents
package_patterns=$(./agent/scripts/acp.yaml.sh package.yaml "contents.patterns")
package_commands=$(./agent/scripts/acp.yaml.sh package.yaml "contents.commands")
package_designs=$(./agent/scripts/acp.yaml.sh package.yaml "contents.designs")

# Validate namespace only for files in contents
for file in agent/commands/*.md; do
  filename=$(basename "$file")
  
  # Skip if not in package.yaml contents
  if ! echo "$package_commands" | grep -q "$filename"; then
    echo "  ℹ️  Skipping namespace check (not in package contents): $filename"
    continue
  fi
  
  # Validate namespace for package content files
  if [[ ! "$filename" =~ ^${NAMESPACE}\. ]]; then
    echo "  ❌ Command file missing namespace: $filename (should be ${NAMESPACE}.*.md)"
    ((namespace_errors++))
  fi
done
```

**Expected Outcome**: Only files in `package.yaml` contents are validated for namespace  

### 2. Add Informational Output

When validation encounters files not in contents, show helpful message:

```bash
# Count files not in contents
not_in_contents=0

for file in agent/commands/*.md; do
  filename=$(basename "$file")
  if ! echo "$package_commands" | grep -q "$filename"; then
    ((not_in_contents++))
  fi
done

if [ $not_in_contents -gt 0 ]; then
  echo ""
  echo "ℹ️  Found $not_in_contents file(s) not in package.yaml contents"
  echo "   These files exist in your repository but won't be installed to user projects"
  echo "   This is normal for installed dependencies (tracked in manifest.yaml)"
fi
```

**Expected Outcome**: Users understand why some files are skipped  

### 3. Update Validation Documentation

Update `agent/commands/acp.package-validate.md` to explain:
- Namespace validation only applies to files in `package.yaml` contents
- Files not in contents are skipped (e.g., installed dependencies)
- This is expected behavior for package development

**Expected Outcome**: Documentation clarifies validation behavior  

### 4. Test with Real Package

Test with acp-tanstack-cloudflare package:

**Actions**:
- Ensure `git.commit.md` exists but is NOT in `package.yaml` contents
- Ensure `git.commit.md` IS in `manifest.yaml` (installed dependency)
- Run `@acp.package-validate`
- Should pass without namespace errors for `git.commit.md`
- Should still validate namespace for files IN contents

**Expected Outcome**: Validation passes correctly  

---

## Verification

- [ ] acp.package-validate.sh reads package.yaml contents
- [ ] Namespace validation only checks files in contents
- [ ] Files not in contents are skipped with informational message
- [ ] Validation documentation updated
- [ ] Tested with real package (acp-tanstack-cloudflare)
- [ ] No false positive namespace errors
- [ ] Files in contents still validated correctly
- [ ] Informational output explains skipped files

---

## Expected Output

### Files Modified
- `agent/scripts/acp.package-validate.sh` - Updated namespace validation logic
- `agent/commands/acp.package-validate.md` - Updated documentation

### Example Validation Output

```
Namespace Consistency
  ℹ️  Skipping namespace check (not in package contents): git.commit.md
  ℹ️  Skipping namespace check (not in package contents): git.init.md
  ✓ Command file namespace correct: tanstack-cloudflare.deploy.md
  ✓ Command file namespace correct: tanstack-cloudflare.tail.md
  ✓ All package content files use correct namespace

ℹ️  Found 2 file(s) not in package.yaml contents
   These files exist in your repository but won't be installed to user projects
   This is normal for installed dependencies (tracked in manifest.yaml)
```

---

## Common Issues and Solutions

### Issue 1: Validation still flags installed dependencies

**Symptom**: Namespace errors for files not in contents  

**Solution**: Verify package.yaml contents section is correct. Ensure validation script is reading contents properly.  

### Issue 2: Files in contents not validated

**Symptom**: Namespace errors not caught for package files  

**Solution**: Verify files are listed in package.yaml contents. Check grep pattern matching.  

---

## Resources

- [Package Schema](../schemas/package.schema.yaml)
- [Package Validation Script](../scripts/acp.package-validate.sh)
- [Package Validation Command](../commands/acp.package-validate.md)

---

## Notes

- This is a bug fix, not a new feature
- No changes to package.yaml structure needed
- Validation logic is the only change
- Backward compatible (doesn't break existing packages)
- Fixes false positive namespace violations
- manifest.yaml already acts as the "dev dependency" tracker

---

**Next Task**: TBD  
**Estimated Completion Date**: TBD  
