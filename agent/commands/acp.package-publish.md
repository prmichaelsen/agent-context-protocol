# Command: package-publish

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.package-publish` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.package-publish` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Scripts**: acp.package-publish.sh, acp.common.sh, acp.yaml-parser.sh

---

**Purpose**: Automated package publishing with validation, version detection, CHANGELOG generation, and testing
**Category**: Maintenance
**Frequency**: As Needed

---

## What This Command Does

This command automates the complete package publishing workflow from validation through testing. It validates the package, detects the appropriate version bump from commit history using Conventional Commits, generates CHANGELOG entries with LLM assistance, commits changes, creates git tags, pushes to remote, and tests the published package by installing it from the remote repository.

Use this command when you're ready to publish a new version of your package. It ensures quality through comprehensive validation, maintains proper version history, automates tedious tasks like CHANGELOG updates, and verifies the package works after publishing.

Unlike manual publishing which is error-prone and time-consuming, this command provides a reliable, repeatable workflow that catches issues before they reach users.

---

## Prerequisites

- [ ] You are in an ACP package directory (package.yaml exists)
- [ ] All changes committed or ready to commit
- [ ] Git repository initialized with remote configured
- [ ] On a valid release branch (main, master, mainline, release, or configured branch)
- [ ] Package passes validation (@acp.package-validate)

---

## Steps

### 1. Run Non-Destructive Validation

Validate package before making any changes.

**Actions**:
- Run `@acp.package-validate` command
- Capture validation results
- If validation fails:
  - Display comprehensive error report
  - Offer to fix issues automatically
  - Stop publishing workflow
  - Return to validation after fixes
- If validation passes:
  - Display success message
  - Proceed to next step

**Expected Outcome**: Package validated successfully or user fixes issues

### 2. Check Working Directory Status

Verify git state is clean or has only version-related changes.

**Actions**:
- Run `git status --porcelain`
- Check for uncommitted changes
- If changes exist:
  - Check if they're version-related (package.yaml, CHANGELOG.md)
  - If yes: These will be committed as part of publish
  - If no: Error - commit or stash changes first
- Check current branch: `git branch --show-current`
- Validate branch against release branches:
  - Default: main, master, mainline, release
  - Custom: Check package.yaml release.branch or release.branches
  - If not on release branch: Error with branch name

**Expected Outcome**: Working directory ready for publishing

### 3. Check Remote Status

Ensure local is in sync with remote.

**Actions**:
- Fetch latest from remote: `git fetch origin`
- Check if remote is ahead: `git rev-list HEAD..origin/$(git branch --show-current) --count`
- If remote is ahead:
  - Error: "Remote has commits not in local. Pull first: git pull"
  - Stop publishing workflow
- If local is ahead or in sync:
  - Proceed to next step

**Expected Outcome**: Local is up to date with remote

### 4. Analyze Commits for Version Bump

Detect version bump type from commit history.

**Actions**:
- Get last version tag: `git describe --tags --abbrev=0` or read from package.yaml
- Get commits since last tag: `git log <last-tag>..HEAD --oneline`
- Analyze commit messages using Conventional Commits:
  - Look for `feat!:` or `BREAKING CHANGE:` → Major bump
  - Look for `feat:` → Minor bump
  - Look for `fix:`, `docs:`, `chore:`, etc. → Patch bump
- Calculate new version:
  - Current: Read from package.yaml version field
  - New: Apply bump (major/minor/patch)
- Display recommendation with reasoning:
  ```
  Current version: 1.2.3
  Commits since last release: 5
    - feat: add new pattern (minor)
    - fix: correct typo (patch)
    - docs: update README (patch)
  
  Recommended: 1.3.0 (minor - new features added)
  ```

**Expected Outcome**: Version bump recommendation generated

### 5. Confirm Version Bump

Ask user to confirm or override version bump.

**Actions**:
- Display recommended version with reasoning
- Ask user: "Publish as version X.Y.Z? (Y/n/custom)"
- If Y: Use recommended version
- If n: Cancel publishing
- If custom: Prompt for version number and validate format
- Validate new version > current version

**Expected Outcome**: User confirms version number

### 6. Commit Version Changes Using @git.commit

Use the @git.commit command to handle version bump and CHANGELOG.

**Actions**:
- Invoke `@git.commit` command (reuse existing logic)
- @git.commit will:
  - Detect this is a version change (package.yaml modified)
  - Determine version bump type (already determined in Step 4)
  - Update package.yaml version field
  - Generate and update CHANGELOG.md entry
  - Stage relevant files intelligently
  - Create properly formatted commit
- Display commit results

**Expected Outcome**: Version changes committed via @git.commit

**Note**: This step delegates to [`@git.commit`](git.commit.md) which handles:
- Version file updates
- CHANGELOG.md generation and updates
- Intelligent file staging
- Commit message formatting
- All version management logic

This ensures consistency with project-level version management and avoids duplicating logic.

### 7. Create Git Tag

Tag the release commit.

**Actions**:
- Create annotated tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
- Display tag created
- Show tag details: `git show vX.Y.Z --no-patch`

**Expected Outcome**: Git tag created

### 8. Push to Remote

Push commits and tags to remote repository.

**Actions**:
- Push commits: `git push origin <current-branch>`
- Push tags: `git push origin vX.Y.Z`
- Display push results
- Show remote URL

**Expected Outcome**: Changes pushed to remote

### 9. Wait for GitHub Processing

Give GitHub time to process the push.

**Actions**:
- Wait 5-10 seconds
- Display: "Waiting for GitHub to process push..."

**Expected Outcome**: GitHub has processed the push

### 10. Test Installation from Remote

Verify package can be installed from remote.

**Actions**:
- Create temp directory: `/tmp/acp-publish-test-{timestamp}/`
- Initialize minimal ACP structure
- Install package from remote:
  ```bash
  ./agent/scripts/acp.package-install.sh <remote-repo-url> --yes
  ```
- Verify installation succeeded
- Check files were copied
- Check manifest updated
- Cleanup temp directory
- Report test results

**Expected Outcome**: Package installs successfully from remote

### 11. Generate Final Report

Display comprehensive publishing report.

**Actions**:
- Show publishing summary:
  - Version published: X.Y.Z
  - Commits included: N
  - Files updated: package.yaml, CHANGELOG.md
  - Tag created: vX.Y.Z
  - Remote: <repository-url>
  - Test installation: PASSED
- Show next steps:
  - Package is live at <repository-url>
  - Users can install with: @acp.package-install <url>
  - Consider announcing release
  - Monitor for issues

**Expected Outcome**: User informed of successful publish

---

## Verification

- [ ] Package validated successfully
- [ ] Working directory clean or only version changes
- [ ] On valid release branch
- [ ] Remote is not ahead of local
- [ ] Version bump detected and confirmed
- [ ] @git.commit executed successfully (handles CHANGELOG and version files)
- [ ] Git tag created
- [ ] Pushed to remote successfully
- [ ] Test installation passed
- [ ] Final report displayed

---

## Expected Output

### Files Modified

- `package.yaml` - Version updated
- `CHANGELOG.md` - New release entry added
- `.git/` - New commit and tag created

### Console Output

```
🚀 ACP Package Publishing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Package: firebase (v1.2.3)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Step 1: Validation

Running @acp.package-validate...

✅ Package validation passed!
  - 32 checks passed
  - 0 errors
  - 0 warnings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Step 2: Git Status

✓ Working directory clean
✓ Current branch: main (valid release branch)
✓ Remote: https://github.com/user/acp-firebase.git

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 Step 3: Remote Status

✓ Fetched latest from origin
✓ Local is up to date with remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Step 4: Version Analysis

Current version: 1.2.3
Commits since v1.2.3: 5

Commit analysis:
  - feat: add pagination pattern (minor)
  - fix: correct typo in security rules (patch)
  - docs: update README examples (patch)
  - feat: add transaction pattern (minor)
  - chore: update dependencies (patch)

Recommendation: 1.3.0 (minor)
Reason: New features added (2 feat commits)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❓ Publish as version 1.3.0? (Y/n/custom): Y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💾 Step 6: Committing via @git.commit

Running @git.commit command...

✓ Detected version change (minor bump)
✓ Updated package.yaml (1.2.3 → 1.3.0)
✓ Generated CHANGELOG.md entry
✓ Staged: package.yaml, CHANGELOG.md
✓ Committed: chore(release): bump version to 1.3.0
✓ Commit hash: a1b2c3d

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏷️  Step 7: Creating Git Tag

✓ Created tag: v1.3.0
✓ Tag message: Release v1.3.0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚀 Step 10: Pushing to Remote

✓ Pushed commits to origin/main
✓ Pushed tag v1.3.0
✓ Remote: https://github.com/user/acp-firebase.git

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⏳ Step 11: Waiting for GitHub

Waiting for GitHub to process push... (5 seconds)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🧪 Step 12: Test Installation

Creating test directory...
Installing from remote: https://github.com/user/acp-firebase.git

✓ Package installed successfully
✓ Verified 6 files copied
✓ Manifest updated correctly
✓ Test directory cleaned up

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Publishing Complete!

📦 Package: firebase v1.3.0
🌐 Repository: https://github.com/user/acp-firebase.git
🏷️  Tag: v1.3.0
✅ Test Installation: PASSED

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 Your package is now live!

Users can install it with:
  @acp.package-install https://github.com/user/acp-firebase.git

Next steps:
  - Announce release to users
  - Monitor for issues
  - Update documentation if needed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Status Update

- Package published successfully
- Version X.Y.Z live on GitHub
- Test installation verified

---

## Examples

### Example 1: Publishing New Feature Release

**Context**: Added 2 new patterns, ready to publish

**Invocation**: `@acp.package-publish`

**Result**: Validates package, detects minor version bump (1.2.3 → 1.3.0), generates CHANGELOG, commits, tags, pushes, tests installation, confirms success

### Example 2: Publishing Bug Fix

**Context**: Fixed typo in documentation

**Invocation**: `@acp.package-publish`

**Result**: Validates, detects patch bump (1.2.3 → 1.2.4), generates CHANGELOG, publishes, tests, confirms success

### Example 3: Validation Failure

**Context**: Package has issues

**Invocation**: `@acp.package-publish`

**Result**: Validation fails with 3 errors, offers auto-fix, user fixes issues, re-runs validation, then proceeds with publishing

### Example 4: Wrong Branch

**Context**: On feature branch instead of main

**Invocation**: `@acp.package-publish`

**Result**: Detects wrong branch, reports error: "Not on release branch. Current: feature/new-pattern, Expected: main, master, mainline, or release", stops publishing

### Example 5: Remote Ahead

**Context**: Remote has commits not pulled locally

**Invocation**: `@acp.package-publish`

**Result**: Detects remote ahead, reports error: "Remote has 2 commits not in local. Run: git pull", stops publishing

---

## Related Commands

- [`@acp.package-validate`](acp.package-validate.md) - Validate package before publishing (run automatically)
- [`@git.commit`](git.commit.md) - Commit changes with version management
- [`@acp.package-create`](acp.package-create.md) - Create new package
- [`@acp.pattern-create`](acp.pattern-create.md) - Add patterns to package
- [`@acp.command-create`](acp.command-create.md) - Add commands to package

---

## Troubleshooting

### Issue 1: Validation fails

**Symptom**: Package validation reports errors

**Cause**: Package has structural or content issues

**Solution**: Use auto-fix to resolve issues, or fix manually, then run `@acp.package-publish` again

### Issue 2: Not on release branch

**Symptom**: Error "Not on release branch"

**Cause**: Current branch is not configured as release branch

**Solution**: Switch to release branch (`git checkout main`), or configure current branch in package.yaml release.branch field

### Issue 3: Remote ahead of local

**Symptom**: Error "Remote has commits not in local"

**Cause**: Someone else pushed to remote

**Solution**: Pull latest changes (`git pull`), resolve conflicts if any, then run `@acp.package-publish` again

### Issue 4: Test installation fails

**Symptom**: Package publishes but test installation fails

**Cause**: Package structure issues or installation script problems

**Solution**: Check package structure, verify all files exist, ensure package.yaml is correct, fix issues and publish patch version

### Issue 5: No commits since last tag

**Symptom**: Error "No commits since last release"

**Cause**: Nothing to publish

**Solution**: Make changes, commit them, then run `@acp.package-publish`

### Issue 6: Version already exists

**Symptom**: Error "Tag vX.Y.Z already exists"

**Cause**: Version was already published

**Solution**: Choose different version number, or delete existing tag if it was a mistake: `git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z`

---

## Security Considerations

### File Access
- **Reads**: `package.yaml`, `CHANGELOG.md`, all files in `agent/` directory, `.git/config`
- **Writes**: `package.yaml` (version), `CHANGELOG.md` (new entry)
- **Executes**: `git` commands (fetch, commit, tag, push), `./agent/scripts/acp.package-validate.sh`, `./agent/scripts/acp.package-install.sh` (for test)

### Network Access
- **APIs**: None directly (git operations may use GitHub)
- **Repositories**: Pushes to remote repository, installs from remote for testing

### Sensitive Data
- **Secrets**: Never reads `.env` files or credential files
- **Credentials**: Uses existing git credentials (SSH keys or tokens)

---

## Notes

- This command is for package authors, not package users
- Publishing is a multi-step process that takes 1-2 minutes
- All steps are validated before destructive operations
- Validation runs first to catch issues early
- Version detection uses Conventional Commits (recommended)
- CHANGELOG generation requires LLM (uses commit analysis)
- Test installation verifies package works after publishing
- Can be cancelled at any confirmation prompt
- Failed test installation does not rollback (version is already pushed)
- Consider running `@acp.package-validate` first to preview issues
- Branch validation ensures you're publishing from correct branch
- Remote check prevents overwriting others' work

---

**Namespace**: acp
**Command**: package-publish
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 2.0.0+
**Author**: ACP Project
