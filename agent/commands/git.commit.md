# Command: commit

> **🤖 Agent Directive**: If you are reading this file, the command `@git.commit` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: git
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Scripts**: None

---

**Purpose**: Automate version detection, changelog updates, and git commits with proper semantic versioning
**Category**: Version Control
**Frequency**: As Needed

---

## Overview

This command intelligently detects if changes represent a version change, determines the appropriate version bump (major/minor/patch), updates version identifiers across the project, updates CHANGELOG.md, intelligently stages relevant files, and creates a properly formatted git commit.

**Key Feature**: This command automatically determines which files to stage based on the changes detected. You don't need to manually run `git add` - the command analyzes your working directory and stages the appropriate files for the commit.

## When to Use

- After completing a feature, fix, or breaking change
- When you want to commit changes with proper version management
- To ensure CHANGELOG.md stays synchronized with code changes
- To maintain consistent commit message formatting
- When you have unstaged changes that need intelligent staging

## Prerequisites

- [ ] Working directory has changes (staged or unstaged)
- [ ] Understanding of semantic versioning (major.minor.patch)
- [ ] Project uses version identifiers (package.json, AGENT.md, etc.)
- [ ] Git repository initialized

---

## Steps

### 1. Analyze Changes for Version Impact

Review the staged/unstaged changes and determine:

**Major Version (X.0.0)** - Breaking changes:
- API changes that break backward compatibility
- Removal of features or functionality
- Major architectural changes
- Changes that require users to modify their code

**Minor Version (0.X.0)** - New features:
- New features added (backward compatible)
- New commands, tools, or capabilities
- Significant enhancements to existing features
- New optional parameters or configuration

**Patch Version (0.0.X)** - Bug fixes:
- Bug fixes
- Documentation updates
- Performance improvements
- Refactoring without behavior changes
- Minor tweaks and adjustments

**No Version Change** - Non-versioned changes:
- Work in progress
- Experimental changes
- Internal development changes
- Changes that don't affect users

### 2. Detect Version Files

Search for version identifiers in the project:

```bash
# Common version files to check:
- package.json (Node.js projects)
- pyproject.toml or setup.py (Python projects)
- Cargo.toml (Rust projects)
- pom.xml (Java/Maven projects)
- build.gradle (Java/Gradle projects)
- AGENT.md (ACP version)
- version.txt or VERSION file
- Any project-specific version files
```

**Action**: List all files containing version numbers that need updating.

### 3. Calculate New Version

Based on the current version and change type:

```
Current: 1.2.3

Major bump: 2.0.0
Minor bump: 1.3.0
Patch bump: 1.2.4
```

**Action**: Determine the new version number.

### 4. Update Version Files

Update all version identifiers found in step 2:

**Example for package.json**:
```json
{
  "version": "1.3.0"
}
```

**Example for AGENT.md**:
```markdown
**Version**: 1.3.0
```

**Action**: Update all version files with the new version number.

### 5. Update CHANGELOG.md

Add a new entry at the top of CHANGELOG.md following Keep a Changelog format:

```markdown
## [1.3.0] - YYYY-MM-DD

### Added
- New features added in this version

### Changed
- Changes to existing functionality

### Deprecated
- Features marked for removal

### Removed
- Features removed in this version

### Fixed
- Bug fixes

### Security
- Security fixes
```

**Guidelines**:
- Use present tense ("Add feature" not "Added feature")
- Be specific and clear
- Group related changes
- Link to issues/PRs if applicable
- Include breaking changes prominently for major versions

**Action**: Create a new CHANGELOG.md entry with all changes in this commit.

### 6. Generate Commit Message

Use Conventional Commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature (minor version bump)
- `fix`: Bug fix (patch version bump)
- `docs`: Documentation only
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `agent`: Changes to agent/ directory only (designs, tasks, milestones, patterns)
- `version`: Version bump only (no code changes, just version number updates)

**Breaking Changes**:
- Add `BREAKING CHANGE:` in the commit message footer for major version bumps
- Use `feat!:` or `fix!:` syntax to indicate breaking changes

**Template for Version Changes**:
```
<type>(<scope>): <short description>

<detailed description of changes>

Changes:
- Change 1
- Change 2
- Change 3

Completed:
- Task: agent/tasks/task-N-name.md
- Milestone: M1 (if milestone completed)

Tests:
- X tests passing
- Y% code coverage

Documentation:
- Design: <link to design doc or external resource>
- API Docs: <link to generated docs>
- Related: <link to related documentation>

BREAKING CHANGE: <description if major version>
Closes #<issue-number>
Related: <PR-link or issue-link>
Version: X.Y.Z
```

**Example**:
```
feat(commands): add @git.commit command for intelligent version management

Implemented automated version detection and changelog management:
- Detects version impact (major/minor/patch)
- Updates all version files automatically
- Generates CHANGELOG.md entries
- Creates properly formatted commit messages

Changes:
- Added agent/commands/git.commit.md
- Updated AGENT.md with changelog emphasis
- Enhanced version management workflow

Completed:
- Task: agent/tasks/task-1-commands-infrastructure.md
- Milestone: M1 (ACP Commands) - 75% complete

Tests:
- All existing tests passing
- No new tests required (documentation only)

Version: 1.3.0
```

**Action**: Generate a commit message following this template.

### 7. Intelligently Stage Changes

Analyze the working directory and stage relevant files:

**Actions**:
- Review `git status` to see all changes
- Stage version files that were updated (AGENT.md, package.json, etc.)
- Stage CHANGELOG.md
- Stage source files that are part of this commit
- **CRITICAL**: Skip gitignored files - never use `git add -f`
- Optionally exclude unrelated changes (use `git add <specific-files>` instead of `git add -A`)

**Decision Logic**:
- If all changes are related to this commit: `git add -A`
- If some changes are unrelated: `git add <file1> <file2> ...` (specific files only)
- Always include: version files, CHANGELOG.md, and files related to the feature/fix
- **Never force-add gitignored files**: If `git add` fails due to `.gitignore`, acknowledge and skip the file

**Gitignore Handling**:
- ❌ **NEVER** use `git add -f` to force-add gitignored files
- ✅ If a file is gitignored, acknowledge it and skip it
- ✅ Assume gitignored files were intentionally excluded
- ✅ Only commit non-gitignored files

**Example**:
```bash
# If all changes are related:
git add -A

# If only specific files should be committed:
git add AGENT.md CHANGELOG.md agent/commands/git.commit.md

# If git add fails due to .gitignore:
# ❌ DON'T: git add -f ignored-file.txt
# ✅ DO: Acknowledge file is gitignored and skip it
```

**Action**: Intelligently stage files based on what's relevant to this commit, respecting `.gitignore` rules.

### 8. Create Commit

```bash
git commit -m "<generated commit message>"
```

**Action**: Commit with the generated message.

### 9. Display Summary

Show what was done:

```
✓ Version bumped: 1.2.3 → 1.3.0 (minor)
✓ Updated version files:
  - AGENT.md
  - package.json
✓ Updated CHANGELOG.md
✓ Created commit: feat: add new feature
✓ Ready to push

Next steps:
  git push
```

---

## Verification Checklist

After running this command, verify:

- [ ] Version number is correct in all files
- [ ] CHANGELOG.md has a new entry with today's date
- [ ] CHANGELOG.md entry accurately describes changes
- [ ] Commit message follows Conventional Commits format
- [ ] All changes are staged and committed
- [ ] Version bump type is appropriate (major/minor/patch)
- [ ] Breaking changes are clearly documented (if major version)

---

## Examples

### Example 1: New Feature (Minor Version)

**Context**: Added `@git.commit` command

**Detection**:
- New command file created
- New functionality added
- Backward compatible
- **Decision**: Minor version bump (1.2.3 → 1.3.0)

**CHANGELOG.md Entry**:
```markdown
## [1.3.0] - 2026-02-16

### Added
- `@git.commit` command for intelligent version management
- Automated version detection and changelog updates
- Conventional Commits format support
```

**Commit Message**:
```
feat: add @git.commit command for intelligent version management

Implemented automated version detection and changelog management.

Version: 1.3.0
```

### Example 2: Bug Fix (Patch Version)

**Context**: Fixed syntax error in acp.version-update.sh

**Detection**:
- Bug fix only
- No new features
- Backward compatible
- **Decision**: Patch version bump (1.2.3 → 1.2.4)

**CHANGELOG.md Entry**:
```markdown
## [1.2.4] - 2026-02-16

### Fixed
- Syntax error in acp.version-update.sh script
- Script now runs without errors
```

**Commit Message**:
```
fix: resolve syntax error in acp.version-update.sh script

Fixed bash syntax error that prevented update script from running.

Version: 1.2.4
```

### Example 3: Breaking Change (Major Version)

**Context**: Changed command syntax from `AGENT.md: Initialize` to `@acp.init`

**Detection**:
- Breaking change to user interface
- Old syntax no longer works
- Requires user action
- **Decision**: Major version bump (1.2.3 → 2.0.0)

**CHANGELOG.md Entry**:
```markdown
## [2.0.0] - 2026-02-16

### Changed
- **BREAKING**: Command syntax changed from `AGENT.md: Initialize` to `@acp.init`
- All commands now use `@acp.*` format
- Old prompt format no longer supported

### Migration Guide
- Replace `AGENT.md: Initialize` with `@acp.init`
- Replace `AGENT.md: Proceed` with `@acp.proceed`
```

**Commit Message**:
```
feat!: change command syntax to @acp.* format

BREAKING CHANGE: Command syntax has changed from "AGENT.md: Initialize" 
to "@acp.init" format. All commands now use the @acp.* namespace.

Migration:
- AGENT.md: Initialize → @acp.init
- AGENT.md: Proceed → @acp.proceed

Version: 2.0.0
```

### Example 4: No Version Change

**Context**: Work in progress, experimental changes

**Detection**:
- Incomplete feature
- Not ready for release
- Internal development
- **Decision**: No version bump

**Commit Message**:
```
chore: work in progress on new feature

Experimental implementation, not ready for release.
```

---

## Decision Tree

```
Is this a breaking change?
├─ Yes → Major version bump (X.0.0)
└─ No
   ├─ Is this a new feature?
   │  ├─ Yes → Minor version bump (0.X.0)
   │  └─ No
   │     ├─ Is this a bug fix or improvement?
   │     │  ├─ Yes → Patch version bump (0.0.X)
   │     │  └─ No → No version bump
```

---

## Best Practices

1. **Be Honest About Breaking Changes**
   - If it breaks existing functionality, it's a major version
   - Document migration paths clearly

2. **Group Related Changes**
   - Commit related changes together
   - Don't mix features and fixes in one commit

3. **Write Clear CHANGELOG Entries**
   - Focus on user impact, not implementation
   - Include examples for complex changes
   - Link to documentation

4. **Use Conventional Commits**
   - Makes changelog generation easier
   - Enables automated tooling
   - Improves git history readability

5. **Update All Version Files**
   - Don't forget any version identifiers
   - Keep versions synchronized
   - Verify after updating

6. **Review Before Committing**
   - Check CHANGELOG.md accuracy
   - Verify version bump is appropriate
   - Ensure commit message is clear

---

## Troubleshooting

**Problem**: Not sure if change is major or minor
- **Solution**: If in doubt, use minor. Major should only be for clear breaking changes.

**Problem**: Multiple unrelated changes staged
- **Solution**: Unstage and commit separately, or group logically in CHANGELOG.

**Problem**: Forgot to update a version file
- **Solution**: Amend the commit: `git commit --amend`, update files, stage, and amend again.

**Problem**: CHANGELOG.md entry is unclear
- **Solution**: Rewrite focusing on user impact, not technical details.

---

## Related Commands

- [`@acp.version-check`](acp.version-check.md) - Check current version
- [`@acp.version-update`](acp.version-update.md) - Update ACP itself
- [`@acp.status`](acp.status.md) - Check project status before committing

---

## Notes

- This command is for project commits, not ACP updates
- Always review generated changelog entries
- Version bumps should be deliberate and meaningful
- Keep CHANGELOG.md user-focused, not developer-focused
- Use semantic versioning consistently

---

**Status**: Production Ready
**Last Updated**: 2026-02-16
