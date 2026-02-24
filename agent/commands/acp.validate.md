# Command: validate

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.validate` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.validate` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document.

**Namespace**: acp
**Version**: 2.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-21
**Status**: Active
**Scripts**: None

---

**Purpose**: Validate all ACP documents for structure, consistency, correctness, and namespace conventions
**Category**: Documentation
**Frequency**: As Needed

---

## What This Command Does

This command validates all ACP documentation to ensure it follows proper structure, maintains consistency, contains no errors, and follows namespace conventions. It checks document formatting, verifies links and references, validates YAML syntax, ensures all required sections are present, validates namespace usage, and checks for reserved name violations.

Use this command before committing documentation changes, after creating new documents, or periodically to ensure documentation quality. It's particularly useful before releases or when onboarding new contributors.

Unlike `@acp.sync` which compares docs to code, `@acp.validate` checks the internal consistency and correctness of the documentation itself. Unlike `@acp.package-validate` which is for package authors, this command validates general ACP project documentation.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] Documentation exists in `agent/` directory
- [ ] You want to verify documentation quality

---

## Steps

### 1. Validate Directory Structure

Check that all required directories and files exist.

**Actions**:
- Verify `agent/` directory exists
- Check for `agent/design/`, `agent/milestones/`, `agent/patterns/`, `agent/tasks/`
- Verify `agent/progress.yaml` exists
- Check for `agent/commands/` directory
- Note any missing directories

**Expected Outcome**: Directory structure validated

### 2. Validate progress.yaml

Check YAML syntax and required fields.

**Actions**:
- Parse `agent/progress.yaml` as YAML
- Verify required fields exist (project, milestones, tasks)
- Check field types (strings, numbers, dates)
- Validate date formats (YYYY-MM-DD)
- Verify progress percentages (0-100)
- Check milestone/task references are consistent
- Validate status values (not_started, in_progress, completed)

**Expected Outcome**: progress.yaml is valid

### 3. Validate Design Documents

Check design document structure and content.

**Actions**:
- Read all files in `agent/design/`
- Verify required sections exist (Overview, Problem, Solution)
- Check for proper markdown formatting
- Validate code blocks have language tags
- Verify dates are in correct format
- Check status values are valid
- Ensure no broken internal links

**Expected Outcome**: Design docs are well-formed

### 4. Validate Milestone Documents

Check milestone document structure.

**Actions**:
- Read all files in `agent/milestones/`
- Verify required sections (Overview, Deliverables, Success Criteria)
- Check naming convention (milestone-N-name.md)
- Validate task references exist
- Verify success criteria are checkboxes
- Check for proper formatting

**Expected Outcome**: Milestone docs are valid

### 5. Validate Task Documents

Check task document structure.

**Actions**:
- Read all files in `agent/tasks/`
- Verify required sections (Objective, Steps, Verification)
- Check naming convention (task-N-name.md)
- Validate milestone references
- Verify verification items are checkboxes
- Check for proper formatting

**Expected Outcome**: Task docs are valid

### 6. Validate Pattern Documents

Check pattern document structure.

**Actions**:
- Read all files in `agent/patterns/`
- Verify required sections (Overview, Implementation, Examples)
- Check code examples are properly formatted
- Validate examples have language tags
- Verify no broken links

**Expected Outcome**: Pattern docs are valid

### 7. Validate Command Documents

Check command document structure.

**Actions**:
- Read all files in `agent/commands/`
- Verify required sections (Purpose, Steps, Verification)
- Check agent directive is present
- Validate namespace and version fields
- Verify examples are complete
- Check related commands links work

**Expected Outcome**: Command docs are valid

### 8. Validate Namespace Conventions

Check namespace usage across all files.

**Actions**:
- **Detect Context**: Check if package.yaml exists
  - If exists: This is a package (use package namespace)
  - If not exists: This is a project (use @local namespace)
- **Command Files**: Validate command filenames
  - In packages: Commands MUST use {namespace}.{command}.md format
  - In projects: Local commands MUST use local.{command}.md format
  - Core ACP commands always use acp.{command}.md format
  - ERROR if files missing proper namespace prefix
- **Pattern Files**: Validate pattern filenames
  - In packages: Patterns MUST use {namespace}.{pattern}.md format
  - In projects: Patterns MUST use local.{pattern}.md format
  - ERROR if patterns missing namespace prefix
  - Exception: Template files (*.template.md) don't need namespace
- **Design Files**: Validate design filenames
  - In packages: Designs MUST use {namespace}.{design}.md format
  - In projects: Designs MUST use local.{design}.md format
  - ERROR if designs missing namespace prefix
  - Exception: Template files (*.template.md) don't need namespace
- **Reserved Names**: Check for reserved namespace usage
  - Reject package names: acp, local, core, system, global
  - Reject command files starting with reserved namespaces (unless core ACP)
  - Reject pattern files starting with reserved namespaces (unless core ACP)
  - ERROR for any violations
- **Consistency**: Verify namespace consistency
  - All commands in package use same namespace
  - All patterns in package use same namespace
  - All designs in package use same namespace
  - Namespace matches package.yaml name field (if package)
  - ERROR for mixing of namespaces

**Expected Outcome**: Namespace conventions validated, errors reported for violations

### 9. Check Cross-References

Validate links between documents.

**Actions**:
- Extract all internal links from documents
- Verify linked files exist
- Check milestone → task references
- Verify task → milestone back-references
- Validate command → command links
- Note any broken links

**Expected Outcome**: All links are valid

### 10. Generate Validation Report

Summarize validation results.

**Actions**:
- Count total documents validated
- List any errors found
- List any warnings
- Provide recommendations
- Suggest fixes for issues

**Expected Outcome**: Validation report generated

---

## Verification

- [ ] All required directories exist
- [ ] progress.yaml is valid YAML
- [ ] progress.yaml has all required fields
- [ ] All design documents are well-formed
- [ ] All milestone documents are valid
- [ ] All task documents are valid
- [ ] All pattern documents are valid
- [ ] All command documents are valid
- [ ] Namespace conventions validated
- [ ] Reserved names checked
- [ ] No broken internal links
- [ ] Validation report generated

---

## Expected Output

### Files Modified
None - this is a read-only validation command

### Console Output
```
✓ Validating ACP Documentation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Directory Structure:
✓ agent/ directory exists
✓ agent/design/ exists (5 files)
✓ agent/milestones/ exists (2 files)
✓ agent/patterns/ exists (3 files)
✓ agent/tasks/ exists (7 files)
✓ agent/commands/ exists (11 files)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

progress.yaml:
✓ Valid YAML syntax
✓ All required fields present
✓ Date formats correct
✓ Progress percentages valid (0-100)
✓ Status values valid
✓ Task/milestone references consistent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Design Documents (5):
✓ All have required sections
✓ Markdown formatting correct
✓ Code blocks properly tagged
⚠️  auth-design.md: Missing "Last Updated" date

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone Documents (2):
✓ All have required sections
✓ Naming convention followed
✓ Task references valid
✓ Success criteria are checkboxes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task Documents (7):
✓ All have required sections
✓ Naming convention followed
✓ Milestone references valid
✓ Verification items are checkboxes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pattern Documents (3):
✓ All have required sections
✓ Code examples properly formatted
✓ No broken links

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Command Documents (11):
✓ All have required sections
✓ Agent directives present
✓ Namespace and version fields valid
✓ Examples complete
✓ Related command links valid

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Namespace Conventions:
✓ Context detected: Project (no package.yaml)
✓ All core ACP commands use 'acp' namespace
✓ Local commands use 'local' namespace
✓ No reserved name violations
✓ Namespace consistency maintained

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cross-References:
✓ All internal links valid
✓ Milestone → task references correct
✓ Task → milestone back-references correct
✓ Command → command links work

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Validation Complete!

Summary:
- Documents validated: 28
- Errors: 0
- Warnings: 1
- Overall: PASS

Warnings:
⚠️  auth-design.md: Missing "Last Updated" date

Recommendations:
- Add "Last Updated" date to auth-design.md
- Consider adding more code examples to patterns
```

### Status Update
- Validation completed
- Issues identified (if any)
- Documentation quality confirmed

---

## Examples

### Example 1: Before Committing Changes

**Context**: Made changes to several docs, want to verify before commit

**Invocation**: `@acp.validate`

**Result**: Validates all docs, finds 2 broken links, reports them, you fix them before committing

### Example 2: After Creating New Documents

**Context**: Created 3 new design documents

**Invocation**: `@acp.validate`

**Result**: Validates new docs, confirms they follow proper structure, identifies missing section in one doc

### Example 3: Periodic Quality Check

**Context**: Monthly documentation review

**Invocation**: `@acp.validate`

**Result**: Validates all 50+ documents, finds minor formatting issues in 3 files, overall quality is good

---

## Related Commands

- [`@acp.package-validate`](acp.package-validate.md) - Package-specific validation (for package authors)
- [`@acp.sync`](acp.sync.md) - Sync documentation with code (different from validation)
- [`@acp.update`](acp.update.md) - Update progress tracking
- [`@acp.report`](acp.report.md) - Generate comprehensive report including validation results
- [`@acp.init`](acp.init.md) - Can include validation as part of initialization

---

## Troubleshooting

### Issue 1: YAML parsing errors

**Symptom**: progress.yaml fails to parse

**Cause**: Invalid YAML syntax (indentation, special characters)

**Solution**: Use YAML validator, check indentation (2 spaces), quote strings with special characters

### Issue 2: Many broken links reported

**Symptom**: Validation finds numerous broken links

**Cause**: Files were moved or renamed

**Solution**: Update links to reflect new file locations, use relative paths, verify files exist

### Issue 3: Validation takes too long

**Symptom**: Command runs for several minutes

**Cause**: Very large project with many documents

**Solution**: This is normal for large projects, consider validating specific directories only, run less frequently

---

## Security Considerations

### File Access
- **Reads**: All files in `agent/` directory
- **Writes**: None (read-only validation)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access secrets or credentials
- **Credentials**: Does not access credentials files

---

## Notes

- This is a read-only command - it doesn't modify files
- Validation should be fast (< 30 seconds for most projects)
- Run before committing documentation changes
- Integrate into CI/CD pipeline if desired
- Warnings are informational, not failures
- Errors should be fixed before proceeding
- Consider running after major documentation updates
- Can be automated as a pre-commit hook

---

**Namespace**: acp
**Command**: validate
**Version**: 2.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 2.0.0+
**Author**: ACP Project
