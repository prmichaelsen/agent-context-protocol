# Command: audit

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-audit` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-audit NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-03-15
**Last Updated**: 2026-03-15
**Status**: Active
**Scripts**: None

---

**Purpose**: Deep-dive investigation of a subject, producing a structured report in `agent/reports/`
**Category**: Workflow
**Frequency**: As Needed

---

## Arguments

**CLI-Style Arguments**:
- `<subject>` (positional) - The subject to audit (topic, path, keyword, or description)
- `--output <path>` or `-o <path>` - Custom report output path (default: `agent/reports/`)

**Natural Language Arguments**:
- `@acp.audit the install system` - Audit a named subject
- `@acp.audit src/auth/` - Audit a directory
- `@acp.audit everything related to sessions` - Audit by description
- `@acp.audit` - Infer subject from current context

**Argument Mapping**:
The agent infers intent from context:
1. If an explicit subject or path follows the command → audit that
2. If natural language describes a topic → derive subject from description
3. If no arguments → infer from current task, milestone, or recent conversation context
4. If still ambiguous → ask the user

---

## What This Command Does

This command performs a directed, deep investigation of a specific subject and produces a persistent, structured report. The subject can be anything — a feature area, a directory, a codebase pattern, a set of milestones, a refactoring target, or any topic that requires comprehensive understanding.

Unlike `@acp.init` (broad context loading) or `@acp.status` (quick snapshot), `@acp.audit` goes narrow and deep. It reads, analyzes, and cross-references everything relevant to the subject, then captures findings efficiently in a report with tables, code pointers, and key decisions.

Use this when you need a thorough understanding of a subject before acting — refactors, status reports, pattern alignment, scope analysis, or any situation where you need to see the full picture before making decisions.

---

## Prerequisites

- [ ] ACP installed in current directory (`agent/` directory exists)
- [ ] `agent/reports/` directory exists (create if not)

---

## Steps

### 1. Parse Subject

Determine what to audit from the user's invocation.

**Actions**:
- Parse CLI arguments and natural language for the audit subject
- If no subject provided, infer from current conversation context (active task, recent discussion, open files)
- If still unclear, ask the user: "What would you like to audit?"

**Expected Outcome**: A clear subject string identified (e.g., "sessions", "src/auth/", "package install system")

### 2. Determine Next Report Number

Find the next available audit report number.

**Actions**:
- List existing files in `agent/reports/` matching `audit-*`
- Parse the highest number
- Increment by 1

**Expected Outcome**: Next report number determined (e.g., 1 if no prior audits)

### 3. Investigate

Perform the deep dive. The agent uses judgment on scope and depth based on the subject and user instructions.

**Actions**:
- Search the project for everything related to the subject (grep, glob, file reads)
- Include git history analysis — recent commits touching the subject, timeline of changes
- Read discovered files to understand their relationship to the subject
- Note code pointers (file:line references) for key locations
- Capture key decisions found in designs, clarifications, or code comments
- Identify open questions or ambiguities

**Guidance**:
- Cast the net as wide or narrow as the user's instructions imply
- Use judgment on which files to read in full vs. summarize
- Use judgment on whether to note specific functions/line ranges
- Do NOT check for inconsistencies between entities (that's `@acp.validate`)
- The goal is understanding, not validation

**Expected Outcome**: Comprehensive understanding of the subject across the project

### 4. Generate Report

Create a structured report capturing findings efficiently.

**Actions**:
- Create `agent/reports/audit-{N}-{subject-slug}.md`
- Subject slug: kebab-case, derived from subject (e.g., "package install system" → "package-install-system")
- Use tables and structured data over prose
- Use `file_path:line_number` format for code pointers (IDE-clickable)

**Report structure** (adapt sections based on what the investigation found — not all sections required):

```markdown
# Audit Report: {subject}

**Audit**: #{N}
**Date**: {date}
**Subject**: {subject description}

## Summary

{1-2 paragraphs: what was investigated, key takeaways}

## Files Analyzed

| File | Type | Relevance |
|------|------|-----------|
| path/to/file | source/doc/config/test | brief note |

## Key Findings

| Finding | Location | Notes |
|---------|----------|-------|
| {finding} | file:line | {context} |

## Key Decisions

- {decision found in design docs, clarifications, or code}

## Code Pointers

| Location | Description |
|----------|-------------|
| file:line | {what this code does relevant to subject} |

## Git History

| Date | Commit | Summary |
|------|--------|---------|
| {date} | {short hash} | {message} |

## Recommendations

1. {recommendation}
```

**Expected Outcome**: Report file created with structured findings

### 5. Report Success

Display what was produced.

**Output**:
```
Audit Complete!

Report: agent/reports/audit-{N}-{subject-slug}.md
Subject: {subject}
Files analyzed: {count}
Findings: {count}
Code pointers: {count}

Next steps:
- Review the audit report
- Use findings to inform your next action
```

**Expected Outcome**: User knows audit is complete and where to find the report

---

## Verification

- [ ] Subject identified (explicit or inferred)
- [ ] Investigation covered relevant files across the project
- [ ] Report created in `agent/reports/audit-{N}-{subject-slug}.md`
- [ ] Report uses tables and structured data, not walls of prose
- [ ] Code pointers use `file:line` format
- [ ] Git history included where relevant
- [ ] No files modified other than the new report

---

## Expected Output

### Files Created
- `agent/reports/audit-{N}-{subject-slug}.md` - Audit report

### Files Modified
- None (read-only investigation)

### Console Output
```
Audit Complete!

Report: agent/reports/audit-1-sessions-system.md
Subject: sessions system
Files analyzed: 12
Findings: 8
Code pointers: 15
```

---

## Examples

### Example 1: Audit a Feature Area

**Context**: Need to understand the sessions system before making changes

**Invocation**: `@acp.audit sessions`

**Result**: Agent searches for "sessions" across the project, reads the design doc, milestone, tasks, shell script, command file, progress.yaml entries. Produces `agent/reports/audit-1-sessions-system.md` with tables of files, findings, and code pointers.

### Example 2: Audit a Directory

**Context**: Need to understand what's in src/auth/ before a refactor

**Invocation**: `@acp.audit src/auth/`

**Result**: Agent reads all files in src/auth/, traces imports and references from other parts of the codebase, checks git history for recent changes. Produces a report with file inventory, key code pointers, and recommendations.

### Example 3: Audit from Context

**Context**: Currently working on task-37 (Preference Loading Infrastructure), want to understand the full scope

**Invocation**: `@acp.audit`

**Result**: Agent infers "preferences system" from current task context, investigates the design doc, all 8 planned tasks, related clarifications, and any existing code. Produces a report capturing the full scope.

### Example 4: Audit with Natural Language

**Context**: Need to understand how package installation works end-to-end

**Invocation**: `@acp.audit everything related to how packages get installed`

**Result**: Agent searches for install-related code, reads acp.install.sh, package management design, related commands and tasks. Produces a comprehensive report.

---

## Related Commands

- [`@acp.init`](acp.init.md) - Broad context loading (use for session start, not deep dives)
- [`@acp.status`](acp.status.md) - Quick status snapshot (use for "where are we?", not "what is X?")
- [`@acp.validate`](acp.validate.md) - Schema and consistency validation (use for correctness checks, not investigation)

---

## Troubleshooting

### Issue 1: Subject too broad

**Symptom**: Investigation returns hundreds of files, report is unwieldy

**Cause**: Subject like "." or "everything" matches too much

**Solution**: Narrow the subject. Use a more specific topic or path.

### Issue 2: No results found

**Symptom**: Investigation finds nothing related to the subject

**Cause**: Subject doesn't match any files or content in the project

**Solution**: Try different keywords, check spelling, or provide a path instead of a topic.

---

## Security Considerations

### File Access
- **Reads**: Any file in the project (scoped by subject relevance)
- **Writes**: `agent/reports/audit-{N}-{subject-slug}.md` only
- **Executes**: `git log` for history analysis

### Network Access
- **APIs**: None
- **Repositories**: Local git only (no remote operations)

### Sensitive Data
- **Secrets**: Never include secrets or credentials in audit reports
- **Credentials**: If audit discovers credential files, note their existence but do not include contents

---

## Key Design Decisions

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Audit target | Any subject (agent/, src/, ., anything) | Designed for ACP consumers, not ACP itself — must work on any project content |
| Use case | General-purpose (refactors, status, alignment, etc.) | Not limited to impact analysis — any situation requiring deep understanding |
| Investigation scope | Inferred from user instructions | Agent uses judgment; no hardcoded entity types or directories |

### Output

| Decision | Choice | Rationale |
|---|---|---|
| Output mode | Read-only, report to file | Audit investigates and reports; does not modify project files |
| Report location | `agent/reports/audit-{N}-{subject}.md` | Sequence-numbered, not date-based, with subject in filename |
| Report format | Tables and structured data over prose | Draft spec emphasized efficiency; tables are scannable and dense |

### Boundaries

| Decision | Choice | Rationale |
|---|---|---|
| Consistency checking | Not in scope | That's `@acp.validate`'s job — audit is for understanding, not validation |
| Git history | Included | Useful context for understanding a subject's evolution |
| Distinction from init/status | Narrow/deep vs. broad/shallow vs. snapshot | Each command has a distinct purpose; audit's differentiator is depth + persistent report |

---

## Notes

- The agent uses judgment throughout — depth, file reading, code pointer granularity are all context-dependent
- Reports are meant to be efficient and scannable, not exhaustive prose
- Audit reports are standalone files — they are not tracked in progress.yaml
- The `agent/reports/` directory may contain other report types; audit reports are prefixed with `audit-`
- This is a read-only command — it never modifies existing project files

---

**Namespace**: acp
**Command**: audit
**Version**: 1.0.0
**Created**: 2026-03-15
**Last Updated**: 2026-03-15
**Status**: Active
**Compatibility**: ACP 5.21.0+
**Author**: ACP Project
