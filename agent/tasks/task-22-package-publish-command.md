# Task 22: @acp.package-publish Command

**Milestone**: [M4 - ACP Package Development System](../milestones/milestone-4-package-development.md)  
**Estimated Time**: 8-10 hours  
**Dependencies**: Task 20 (@acp.package-validate), existing @git.commit  
**Status**: Not Started  

---

## Objective

Implement automated package publishing workflow with validation, version management, CHANGELOG generation, git operations, and post-publish testing.

---

## Context

From clarifications:
- Run @acp.package-validate first
- Detect version bump from Conventional Commits
- LLM generates CHANGELOG entries
- Reuse @git.commit logic
- Create git tags
- Push to remote
- Test installation from remote
- Comprehensive error handling

---

## Steps

### 1. Create Command Documentation

Create agent/commands/acp.package-publish.md with complete publishing workflow.

### 2. Implement Validation Phase

Run @acp.package-validate:
- All non-destructive checks
- Generate report
- Stop if validation fails
- Offer to fix and retry

### 3. Implement Version Detection

Detect version bump from commits:
- Analyze commits since last tag
- Parse Conventional Commits (feat:, fix:, BREAKING CHANGE:)
- Determine bump type (major/minor/patch)
- Show recommendation with reasoning
- User confirms or overrides

### 4. Implement CHANGELOG Generation

Generate CHANGELOG entry:
- LLM analyzes commits
- Groups related changes
- Writes human-readable entries
- Categorizes (Added, Changed, Fixed, etc.)
- Updates CHANGELOG.md

### 5. Implement Git Operations

Execute git workflow:
- Commit changes (via @git.commit logic)
- Create git tag (v{version})
- Push commits and tags to remote

### 6. Implement Post-Publish Testing

Test installation from remote:
- Wait for GitHub processing (5-10 seconds)
- Install to /tmp from remote URL
- Validate installation
- Report success/failure

### 7. Implement Branch Validation

Check current branch:
- Read release.branch from package.yaml
- Default branches: main, master, mainline, release
- Error if not on valid branch

### 8. Test Publishing Workflow

Test end-to-end publishing.

---

## Verification

- [ ] acp.package-publish.md created
- [ ] acp.package-publish.sh implemented
- [ ] Validation phase works
- [ ] Version detection works
- [ ] CHANGELOG generation works
- [ ] Git operations work
- [ ] Post-publish testing works
- [ ] Branch validation works
- [ ] Error handling works
- [ ] All scenarios tested

---

**Next Task**: [Task 23: Rewrite @acp.package-create](task-23-package-create-rewrite.md)  
