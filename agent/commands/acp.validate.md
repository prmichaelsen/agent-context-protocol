# Command: validate

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.validate` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.validate` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document.

**Namespace**: acp  
**Version**: 2.1.0  
**Created**: 2026-02-16  
**Last Updated**: 2026-03-17  
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

### 0. Display Command Header

```
⚡ @acp.validate
  Validate all ACP documents for structure, consistency, correctness, and namespace conventions

  Related:
    @acp.package-validate  Package-specific validation
    @acp.sync              Sync documentation with code
    @acp.update            Update progress tracking
    @acp.report            Generate report with validation results
    @acp.init              Can include validation during init
```

This step is informational only — do not wait for user input.

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

Check task document structure and self-containment.

**Actions**:
- Read all files in `agent/tasks/`
- Verify required sections (Objective, Steps, Verification)
- Check naming convention (task-N-name.md)
- Validate milestone references
- Verify verification items are checkboxes
- Check for proper formatting
- Run **Self-Containment Probes** on every task with marker `status:` of `draft`, `in_progress`, or `not_started` (skip tasks marked `complete` — retroactive probing is noise)

**Expected Outcome**: Task docs are structurally valid AND incomplete tasks have verified self-containment  

#### 5.1. Self-Containment Probes

The Self-Contained Task Principle requires every relevant design excerpt, spec requirement, and clarification decision to be inlined verbatim in the task body so sub-agents have all the context they need without opening other files. These probes confirm the task actually did the inlining.

All three probes are **reading-comprehension checks**: you (as validate's executing agent) read the task file and the referenced files, then judge whether the claimed content is meaningfully reflected in the task body. No fingerprints, no thresholds — you compare.

All findings are **soft warnings**. They never hard-fail validate; they appear in the Self-Containment section of Step 12's report and the user decides whether each is deliberate scoping or missed inlining.

**Probe 1 — Spec inlining**

For each incomplete task with `@acp.meta.task` marker fields `spec:` + `covers:`:

1. Read the spec file from `spec:`.
2. Locate each `R<N>` listed in `covers:`.
3. For each R-ID: does the task body reflect R<N>'s substance — its MUST/SHOULD language, its constraint, its short description — somewhere in Steps, Context, or a `## Spec Coverage` section? A `- [ ] R<N>: <description>` line counts. So does a paraphrase that captures the constraint.
4. For each R-ID that is NOT reflected in the body, emit a finding:
   ```
   ⚠️ <task_path>  (<status>)
      Probe 1 (spec): covers: <R-ID> but <R-ID>'s text not reflected in body
      → Inline from <spec_path> under Spec Coverage
   ```

Deferral phrasing (e.g., "R11 deferred to task-19", "R13 scoped out — handled by milestone M11") is NOT a finding — recognize it and skip.

**Probe 2 — Design inlining**

For each incomplete task with `**Design Reference**: [name](path) | None` resolving to a real file:

1. Read the design file. Locate every D-ID in it (look for `\*\*D\d+[:\s*]` bold-prefix form or `### D\d+:` heading form).
2. Three sub-cases:
   - **Design has D-IDs AND task marker has `incorporates:` listing some of them**: for each D-ID in `incorporates:`, confirm that D-ID's atomic unit (the decision text, code snippet, schema, algorithm, interface, rule, or diagram) is reflected verbatim or faithfully paraphrased in the task body. Flag specific missing D-IDs with their short title:
     ```
     ⚠️ <task_path>  (<status>)
        Probe 2 (design): incorporates: <D-ID> but <D-ID> (<short title>) not found in body
        → Inline from <design_path>
     ```
   - **Design has D-IDs but task marker has no `incorporates:` field**: soft-warn:
     ```
     ⚠️ <task_path>  (<status>)
        Probe 2 (design): design <design_path> has D<min>..D<max> but task
        marker has no `incorporates:` field.
        → Add `incorporates:` for relevant D-IDs, or justify the omission in the task body
          (e.g., "scoped-out: D2-D4 handled by task-19")
     ```
   - **Design has no D-IDs (legacy, pre-v5.41)**: fall back to a holistic judgment: "does the task body contain substantive content from the design?" Scan for atomic units in the design (fenced code blocks, definition lists, key invariants in the Implementation / Solution / Edge Cases / Interfaces sections) that appear uncovered. Flag with a snippet:
     ```
     ⚠️ <task_path>  (<status>)
        Probe 2 (design, legacy): design <design_path> has no D-IDs and task
        body doesn't reflect substantive design content.
        Missing likely: <snippet from unreflected section>
        → Consider backfilling D-IDs in the design (run @acp.sync), then claim
          specific D-IDs in this task's `incorporates:` field
     ```

Deferral phrasing is NOT a finding, as in Probe 1.

**Probe 3 — Clarification inlining**

Invoke:
```sh
./agent/scripts/acp.meta-scan.sh --kind clarification agent/clarifications/
```

For each clarification block with `resolves:` matching the task's path AND `resolved: true`:

1. Read the clarification file. Identify the resolved decisions (typically in the answers, resolutions, or a "Resolved Decisions" subsection).
2. For each resolved decision, check the task body reflects it — either in Steps, Context, or Key Design Decisions.
3. For each unreflected decision, emit a finding:
   ```
   ⚠️ <task_path>  (<status>)
      Probe 3 (clarification): <clarification_path> resolved
      '<short summary of decision>' but not inlined in task
      → Inline the decision under Steps or Key Design Decisions
   ```

#### Self-Containment vs structural validation

Structural findings (missing `## Verification`, malformed milestone link, etc.) remain **errors** that fail validate.

Self-containment findings are **warnings** that do NOT fail validate. If a task has only self-containment warnings and no structural errors, the overall status in Step 12 is "passed with warnings."

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

### 8. Validate Artifact Documents

Check artifact document structure and staleness.

**Actions**:
- Read all files in `agent/artifacts/` matching `research-*.md`, `glossary-*.md`, `reference-*.md`
- **Validate metadata block**:
  - Verify required fields exist: Type, Created, Last Verified, Status, Confidence, Category, Sources
  - Check Type is one of: research, glossary, reference
  - Validate Created format (YYYY-MM-DD)
  - Validate Last Verified format (YYYY-MM-DD)
  - Check Status is one of: Active, Stale, Deprecated, WIP
  - Validate Confidence format (High/Medium/Low or score/10)
  - ERROR if any required field missing
- **Validate file naming**:
  - Check format: `{type}-{N}-{title}.md`
  - Verify N is a number
  - ERROR if naming doesn't match pattern
- **Check staleness**:
  - Calculate days since Last Verified
  - WARN if Last Verified > 180 days (6 months) and Status is Active
  - WARN if Status is Stale but Last Verified is recent (< 30 days)
- **Validate research artifacts**:
  - Verify Executive Summary exists
  - Check Key Findings section has citations
  - Verify Sources & References section exists
  - WARN if no sources cited
- **Validate glossary artifacts**:
  - Check for category tables structure
  - Verify Alphabetical Index exists
  - Check Total Terms metadata field matches actual term count
  - WARN if mismatch
- **Validate reference artifacts**:
  - Check for Command-First Principle Check section
  - Verify Purpose section exists
  - Check Content section has appropriate structure for reference type
  - WARN if missing command-first check explanation

**Output format**:
```
📚 Artifact Validation:
  ✓ agent/artifacts/research-1-graphql-federation.md (Active, Last Verified: 2026-03-17)
  ⚠️ agent/artifacts/research-2-redis-persistence.md (Active, Last Verified: 2025-09-20, STALE: 180+ days)
  ✓ agent/artifacts/glossary-1-core-terminology.md (Active, 15 terms)
  ✓ agent/artifacts/reference-1-environment-variables.md (Active, command-first check documented)
  ⚠️ agent/artifacts/reference-2-troubleshooting.md (Stale status but Last Verified: 2026-03-10, recent)

  Summary: 5 artifacts validated, 2 warnings
  - 2 potentially stale artifacts (Last Verified > 6 months)
  - 1 status mismatch (marked Stale but recently verified)
```

**Expected Outcome**: Artifact docs are valid, staleness warnings issued  

### 9. Validate Namespace Conventions

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

### 10. Validate Key File Index

Check index files in `agent/index/` for schema correctness and referential integrity.

**Actions**:
- Check that `agent/index/` directory exists (warn if missing)
- For each `*.yaml` file in `agent/index/` (skip `*.template.yaml`):
  - Verify filename follows `{namespace}.{qualifier}.yaml` naming
  - Parse the index entries under the top-level key
  - For each entry, verify required fields present: `path`, `weight`, `kind`, `description`, `rationale`, `applies`
  - Validate `weight` is a number in range 0.0-1.0
  - Validate `kind` is one of: `pattern`, `command`, `design`, `note`, `directive`
    - `requirements` is accepted as a deprecated alias for `design` (warn: "use `design` instead")
    - `artifact` is also accepted for backward compatibility
  - Validate path/kind consistency:
    - If `path` is `null`: `kind` must be `note` or `directive`
    - If `path` is a string: `kind` must be `pattern`, `command`, or `design`
    - For `path: null` entries, `description` must be non-empty (it IS the content)
  - Validate `applies` values use fully qualified command names (contain a dot, e.g. `acp.proceed`)
  - For entries where `path` is a string: check that the path actually exists in the project
  - Warn on missing paths (file may have been moved or deleted)
  - Skip path existence check for `path: null` entries
- Check total indexed entries across all files (warn if > 20)
- Check per-namespace entry count (warn if > 10)

**Output format**:
```
📑 Index Validation:
  ✓ agent/index/local.main.yaml (5 entries, all valid)
  ⚠️ agent/index/core-sdk.main.yaml: path not found: agent/patterns/core-sdk.deleted.md
  ✓ Total: 8 entries across 2 namespaces (within limits)
```

**Expected Outcome**: Index files validated for schema and referential integrity  

### 11. Check Cross-References

Validate links between documents.

**Actions**:
- Extract all internal links from documents
- Verify linked files exist
- Check milestone → task references
- Verify task → milestone back-references
- Validate command → command links
- Note any broken links

**Expected Outcome**: All links are valid  

### 12. Generate Validation Report

Summarize validation results.

**Actions**:
- Count total documents validated
- List any errors found (structural issues — these fail validate)
- List any warnings, including a dedicated **Self-Containment** section populated by Step 5.1 probes
- Provide recommendations
- Suggest fixes for issues
- Compute overall status:
  - **Passed** — no errors, no warnings
  - **Passed with warnings** — no errors, but at least one warning (including self-containment)
  - **Failed** — at least one structural error

Self-containment warnings do NOT fail validate; they appear as warnings. The author decides whether each warning is deliberate scoping or missed inlining.

**Expected Outcome**: Validation report generated with structural results AND self-containment findings clearly separated.  

**Report format**:

```
Validation Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall: <Passed | Passed with warnings | Failed>

Structural:
  ✓ 12 design documents valid
  ✓ 34 task documents valid (structural)
  ...
  <any ERROR findings>

Self-Containment (incomplete tasks only):
  ⚠️ agent/tasks/milestone-7/task-2-session-freshness-injector.md  (not_started)
     - Probe 1 (spec): covers: R31 but R31's text not reflected in body
       → Inline from agent/specs/local.freshness.md under Spec Coverage

  ⚠️ agent/tasks/milestone-10/task-4-character-grading.md  (in_progress)
     - Probe 2 (design): Design agent/design/local.gamification.md has D1..D8
       but task marker has no `incorporates:` field.
       → Add `incorporates:` for relevant D-IDs or justify the omission
     - Probe 3 (clarification): clarification-12-grading.md resolved
       'Karl uses fluency-weighted formula' but not inlined in task body

Cross-References:
  <any broken links or cross-ref issues>
```

---

## Verification

- [ ] All required directories exist
- [ ] progress.yaml is valid YAML
- [ ] progress.yaml has all required fields
- [ ] All design documents are well-formed
- [ ] All milestone documents are valid
- [ ] All task documents are valid (structural)
- [ ] Self-Containment probes ran for every incomplete task (draft / in_progress / not_started)
- [ ] Probe findings appear in Step 12 report as warnings (not errors)
- [ ] All pattern documents are valid
- [ ] All command documents are valid
- [ ] All artifact documents are valid
- [ ] Artifact metadata blocks complete
- [ ] Artifact staleness checked (Last Verified dates)
- [ ] Artifact file naming validated
- [ ] Namespace conventions validated
- [ ] Reserved names checked
- [ ] Key file index validated (schema, paths, limits, artifact kind supported)
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
