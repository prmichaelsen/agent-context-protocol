# Command: package-validate

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-validate` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.package-validate` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Scripts**: acp.package-validate.sh, acp.common.sh, acp.yaml-parser.sh, acp.yaml-validate.sh

---

**Purpose**: Comprehensive package validation with shell and LLM checks, auto-fix, and test installation
**Category**: Maintenance
**Frequency**: As Needed

---

## What This Command Does

This command performs comprehensive validation of an ACP package to ensure it's ready for publishing. It combines shell-based structural validation (files, YAML, git) with LLM-based content quality validation, tests the package by installing it to a temporary directory, checks remote repository availability, and offers auto-fix capabilities for common issues.

Use this command before publishing a package, after making significant changes, or when preparing a release. It catches issues early and provides actionable fixes, ensuring package quality and preventing broken installations for users.

Unlike `@acp.validate` which validates general ACP documentation, `@acp.package-validate` is specifically designed for package authors and includes package-specific checks like namespace consistency, remote availability, and test installation.

---

## Prerequisites

- [ ] You are in an ACP package directory (package.yaml exists)
- [ ] Git repository initialized
- [ ] Git remote configured
- [ ] All package files created and documented

---

## Steps

### 1. Detect Package Context

Verify this is a package directory.

**Actions**:
- Check if package.yaml exists in current directory
- If not found, report error: "Not a package directory. package.yaml not found."
- If found, proceed with validation

**Expected Outcome**: Package context confirmed

### 2. Shell-Based Validation

Run structural validation checks that don't require LLM.

**Actions**:
- **YAML Validation**: Run `./agent/scripts/acp.yaml-validate.sh package.yaml`
  - Validates package.yaml structure against schema
  - Checks required fields (name, version, description, author, license, repository)
  - Validates version format (semver: X.Y.Z)
  - Checks reserved names (acp, local, core, system, global)
  - Validates repository URL format
- **File Existence**: Check all files listed in package.yaml contents exist
  - Verify patterns/ files exist
  - Verify commands/ files exist
  - Verify designs/ files exist
  - Report missing files
- **Unlisted Files**: Check for agent/ files not in package.yaml
  - Find all .md files in agent/patterns/, agent/commands/, agent/designs/
  - Compare with package.yaml contents
  - Report unlisted files
- **Namespace Consistency**: Validate filenames use package namespace
  - Extract namespace from package.yaml name field
  - **Only validates files listed in package.yaml contents**
  - Skips files not in contents (e.g., installed dependencies tracked in manifest.yaml)
  - Check all command files in contents start with {namespace}.
  - Check all pattern files in contents start with {namespace}. (if package uses namespaced patterns)
  - Report files without namespace prefix
  - **Note**: Files in your repository but not in package.yaml contents are skipped (this is normal for installed dependencies)
- **Git Repository**: Validate git setup
  - Check `.git/` directory exists
  - Check git remote configured: `git remote -v`
  - Extract remote URL
  - Verify remote URL matches package.yaml repository field
  - Report git issues
- **README.md**: Check README exists and has required sections
  - Verify README.md exists
  - Check for "What's Included" section
  - Check for "Installation" section
  - Check for "License" section
  - Report missing sections

**Expected Outcome**: Shell validation complete with error/warning list

### 3. LLM-Based Validation

Run content quality checks that require LLM analysis.

**Actions**:
- **Documentation Completeness**: Check all documents have complete sections
  - Read each pattern, command, design file
  - Verify all template sections filled in
  - Check for placeholder text (e.g., "[Description]", "TODO")
  - Verify examples are complete and realistic
  - Report incomplete documentation
- **Content Quality**: Analyze documentation clarity
  - Check descriptions are clear and helpful
  - Verify steps are actionable and specific
  - Ensure examples are realistic
  - Validate code examples are syntactically correct
  - Report quality issues
- **Namespace Consistency (Content)**: Check file content uses correct namespace
  - Read command files
  - Check invocation examples use correct namespace (@{namespace}-{command})
  - Check related command links use correct namespace
  - Report namespace inconsistencies
- **README Structure**: Validate README.md follows package structure
  - Check overview is clear
  - Verify installation instructions are correct
  - Check "What's Included" section matches package.yaml
  - Verify namespace convention documented
  - Report README issues

**Expected Outcome**: LLM validation complete with quality assessment

### 4. Test Installation

Install package to temporary directory to verify it works.

**Actions**:
- Create temporary directory: `/tmp/acp-validate-test-{timestamp}/`
- Initialize minimal ACP structure in temp directory:
  - Create agent/patterns/, agent/commands/, agent/designs/
  - Create minimal agent/manifest.yaml
- Run package installation:
  - Execute: `./agent/scripts/acp.package-install.sh {current-directory} --yes`
  - Capture installation output
  - Check for errors
- Verify installation:
  - Check files were copied to temp directory
  - Verify manifest.yaml updated
  - Check file count matches expected
- Cleanup:
  - Remove temporary directory
  - Report test results

**Expected Outcome**: Test installation succeeded or failed with details

### 5. Remote Availability Check

Verify package is accessible from remote repository.

**Actions**:
- Extract repository URL from package.yaml
- Check if remote repository exists:
  - Try: `git ls-remote {repository-url} HEAD`
  - If succeeds: Remote is accessible
  - If fails: Remote not accessible or doesn't exist
- Report remote status

**Expected Outcome**: Remote availability confirmed

### 6. Generate Validation Report

Compile all validation results into comprehensive report.

**Actions**:
- Count total checks performed
- List all errors found (categorized)
- List all warnings found (categorized)
- Calculate validation score (% of checks passed)
- Determine overall status: PASS, PASS WITH WARNINGS, or FAIL
- Format report for display

**Expected Outcome**: Comprehensive validation report ready

### 7. Offer Auto-Fix

If issues found, offer to fix them automatically.

**Actions**:
- Identify fixable issues:
  - Missing files in package.yaml → Add them
  - Unlisted files → Add to package.yaml
  - Missing namespace prefix → Add prefix to filenames
  - Missing README sections → Add sections
  - Missing git remote → Prompt for URL and add
  - Incomplete documentation → Prompt for missing information
- Present fix options:
  - "Fix all issues automatically" (batch mode)
  - "Fix issues one by one" (interactive mode)
  - "Show me what would be fixed" (dry-run mode)
  - "Skip auto-fix" (manual mode)
- If user chooses fix:
  - Apply fixes based on mode
  - Re-run validation
  - Report results

**Expected Outcome**: Issues fixed or user declined

### 8. Display Final Report

Show validation results to user.

**Actions**:
- Display formatted report in chat
- Show validation score
- List remaining issues (if any)
- Provide recommendations
- Suggest next steps

**Expected Outcome**: User informed of validation status

---

## Verification

- [ ] Package context detected (package.yaml exists)
- [ ] Shell validation completed (YAML, files, namespace, git, README)
- [ ] LLM validation completed (content quality, completeness)
- [ ] Test installation attempted
- [ ] Remote availability checked
- [ ] Validation report generated
- [ ] Auto-fix offered (if issues found)
- [ ] Final report displayed
- [ ] No validation errors remain OR user acknowledged remaining issues

---

## Expected Output

### Files Modified

**If auto-fix used**:
- `package.yaml` - Added missing files to contents section
- `README.md` - Added missing sections
- `agent/commands/*.md` - Added namespace prefixes (if needed)
- `agent/patterns/*.md` - Added namespace prefixes (if needed)
- `.git/config` - Added remote (if missing)

**If auto-fix not used**:
- None (validation is read-only)

### Console Output

```
🔍 ACP Package Validation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Package: firebase (v1.2.0)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 Shell Validation

✅ YAML Structure
  ✓ package.yaml is valid YAML
  ✓ All required fields present
  ✓ Version format valid (1.2.0)
  ✓ Repository URL valid
  ✓ No reserved names used

✅ File Existence
  ✓ All 6 files in contents exist
  ✓ patterns/firebase.user-scoped-collections.md ✓
  ✓ patterns/firebase.security-rules.md ✓
  ✓ commands/firebase.init.md ✓
  ✓ commands/firebase.migrate.md ✓
  ✓ designs/firebase.architecture.md ✓
  ✓ designs/firebase.integration.md ✓

⚠️  Unlisted Files
  ⚠️  Found 1 file not in package.yaml:
      - patterns/firebase.queries.md (not listed in contents)

✅ Namespace Consistency
  ✓ All command files use 'firebase' namespace
  ✓ All pattern files use 'firebase' namespace

✅ Experimental Features
  ✓ experimental-command.md: Experimental marking consistent
  ✓ All experimental features marked consistently

✅ Git Repository
  ✓ Git repository initialized
  ✓ Remote configured: https://github.com/user/acp-firebase.git
  ✓ Remote URL matches package.yaml

✅ README.md
  ✓ README.md exists
  ✓ Has "What's Included" section
  ✓ Has "Installation" section
  ✓ Has "License" section

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 LLM Validation

✅ Documentation Completeness
  ✓ All patterns have complete sections
  ✓ All commands have complete sections
  ✓ All designs have complete sections
  ✓ No placeholder text found

✅ Content Quality
  ✓ Descriptions are clear and helpful
  ✓ Steps are actionable and specific
  ✓ Examples are realistic and complete
  ✓ Code examples are syntactically correct

✅ Namespace Consistency (Content)
  ✓ Command invocations use correct namespace
  ✓ Related command links use correct namespace

✅ README Structure
  ✓ Overview is clear
  ✓ Installation instructions correct
  ✓ "What's Included" matches package.yaml
  ✓ Namespace convention documented

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🧪 Test Installation

✓ Created test directory: /tmp/acp-validate-test-1708478400/
✓ Initialized minimal ACP structure
✓ Installed package from current directory
✓ Verified 6 files copied successfully
✓ Verified manifest.yaml updated
✓ Cleaned up test directory

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌐 Remote Availability

✓ Remote repository accessible
✓ URL: https://github.com/user/acp-firebase.git
✓ Latest commit: a1b2c3d4

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Validation Summary

Total Checks: 32
Passed: 31
Warnings: 1
Errors: 0

Overall Status: ✅ PASS WITH WARNINGS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Issues Found

Warnings (1):
  1. Unlisted file: patterns/firebase.queries.md
     → This file exists but is not listed in package.yaml contents

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 Auto-Fix Available

I can fix these issues automatically:
  1. Add firebase.queries.md to package.yaml contents

Options:
  1. Fix all issues automatically (recommended)
  2. Fix issues one by one (interactive)
  3. Show what would be fixed (dry-run)
  4. Skip auto-fix (manual)

Choose option (1-4): 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 Applying Fixes

✓ Added patterns/firebase.queries.md to package.yaml
✓ Updated package.yaml

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 Re-running Validation

✅ All checks passed!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Package Validation Complete!

Your package is ready to publish.

Recommendations:
  - Run @acp.package-publish to publish this package
  - Consider adding more examples to patterns
  - Update CHANGELOG.md before publishing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Status Update

- Validation completed
- Issues fixed (if auto-fix used)
- Package ready or needs manual fixes

---

## Examples

### Example 1: Pre-Publish Validation

**Context**: About to publish package, want to ensure it's valid

**Invocation**: `@acp.package-validate`

**Result**: Runs all checks, finds 2 issues (missing file in package.yaml, incomplete README), offers auto-fix, fixes issues, re-validates, confirms package is ready

### Example 2: After Adding New Files

**Context**: Added 3 new patterns, want to verify package is still valid

**Invocation**: `@acp.package-validate`

**Result**: Validates package, finds new files not listed in package.yaml, offers to add them, updates package.yaml, confirms all checks pass

### Example 3: Validation Failure

**Context**: Package has multiple issues

**Invocation**: `@acp.package-validate`

**Result**: Finds 5 errors (missing git remote, invalid version format, namespace inconsistencies, incomplete docs, missing README sections), offers step-by-step fixes, guides through fixing each issue

### Example 4: Clean Package

**Context**: Well-maintained package, routine validation

**Invocation**: `@acp.package-validate`

**Result**: All 32 checks pass, no warnings, no errors, confirms package is ready to publish

---

## Related Commands

- [`@acp.validate`](acp.validate.md) - General ACP documentation validation (not package-specific)
- [`@acp.package-publish`](acp.package-publish.md) - Publish package (runs validation first)
- [`@acp.pattern-create`](acp.pattern-create.md) - Create patterns (auto-updates package.yaml)
- [`@acp.command-create`](acp.command-create.md) - Create commands (auto-updates package.yaml)
- [`@acp.design-create`](acp.design-create.md) - Create designs (auto-updates package.yaml)

---

## Troubleshooting

### Issue 1: Not a package directory

**Symptom**: Error "package.yaml not found"

**Cause**: Running command in non-package directory

**Solution**: Navigate to package directory, or create package with `@acp.package-create`

### Issue 2: YAML validation fails

**Symptom**: Multiple YAML structure errors

**Cause**: Invalid YAML syntax or missing required fields

**Solution**: Fix YAML syntax (check indentation, quotes), add missing required fields, or use auto-fix

### Issue 3: Test installation fails

**Symptom**: Package installs but test installation reports errors

**Cause**: Files missing, incorrect paths, or installation script issues

**Solution**: Check file paths in package.yaml, verify all files exist, ensure agent/ directory structure is correct

### Issue 4: Remote not accessible

**Symptom**: Remote availability check fails

**Cause**: Repository doesn't exist, URL incorrect, or network issues

**Solution**: Verify repository URL in package.yaml, check git remote configuration, ensure repository is public or you have access

### Issue 5: Namespace inconsistencies

**Symptom**: Files don't use package namespace

**Cause**: Files created manually without namespace prefix

**Solution**: Use auto-fix to add namespace prefixes, or rename files manually to include namespace

---

## Security Considerations

### File Access
- **Reads**: `package.yaml`, all files in `agent/` directory, `README.md`, `.git/config`
- **Writes**: Only if auto-fix used: `package.yaml`, `README.md`, files being renamed
- **Executes**: `./agent/scripts/acp.yaml-validate.sh`, `./agent/scripts/acp.package-install.sh` (for test), `git` commands

### Network Access
- **APIs**: None
- **Repositories**: Checks remote repository accessibility via `git ls-remote`

### Sensitive Data
- **Secrets**: Never reads `.env` files or credential files
- **Credentials**: Does not access credentials (git operations use existing auth)

---

## Notes

- This command is designed for package authors, not package users
- Validation is comprehensive and may take 1-2 minutes for large packages
- Auto-fix is safe and non-destructive (creates backups)
- Test installation uses temporary directory (automatically cleaned up)
- Remote check requires network access
- LLM validation requires agent context (won't work in pure shell)
- Run this before every publish to ensure quality
- Validation score helps track package quality over time
- Consider running in CI/CD pipeline for automated quality checks

---

**Namespace**: acp
**Command**: package-validate
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 2.0.0+
**Author**: ACP Project
