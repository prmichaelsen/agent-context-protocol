# Command: resume

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.resume` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active

---

**Purpose**: Resume work on a project by initializing context, reviewing recent progress, and continuing with the next task
**Category**: Workflow
**Frequency**: Per Session

---

## What This Command Does

This command is a convenient alias that combines three essential workflow commands into one:

1. **Initialize Context** - Loads all project documentation via `@acp.init`
2. **Review Recent Work** - Reads the latest session report to understand what was done
3. **Continue Work** - Proceeds with the current/next task via `@acp.proceed`

**Use this when**: Starting a new session or returning to a project after a break.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/progress.yaml` exists
- [ ] Session reports exist in `agent/reports/` (optional but recommended)

---

## Steps

### 1. Initialize Agent Context

Run the initialization workflow to load complete project context.

**Actions**:
- Execute `@acp.init` workflow
- Check for ACP updates
- Read all agent documentation
- Review key source files
- Update stale documentation
- Refresh progress tracking

**Expected Outcome**: Complete project context loaded

### 2. Read Latest Session Report

Find and read the most recent session report to understand what was accomplished.

**Actions**:
- List files in `agent/reports/` directory
- Find most recent report (by date in filename)
- Read the report file
- Summarize key accomplishments
- Note any blockers or issues mentioned

**Expected Outcome**: Recent work understood

### 3. Proceed with Current/Next Task

Continue work by executing the current or next task.

**Actions**:
- Execute `@acp.proceed` workflow
- Identify current task from progress.yaml
- Read task document
- **START IMPLEMENTING immediately**
- Update progress tracking

**Expected Outcome**: Task implementation in progress

---

## Verification

- [ ] Context initialized successfully
- [ ] Latest report read and summarized
- [ ] Current task identified
- [ ] Implementation started
- [ ] No errors encountered

---

## Expected Output

### Console Output
```
🚀 Resuming Work on Project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Initializing Context (@acp.init)

✓ ACP version check: v3.7.1 (up to date)
✓ Read agent/progress.yaml
✓ Read 6 design documents
✓ Read 5 milestone documents
✓ Read 36 task documents
✓ Reviewed key source files
✓ Documentation is current
✓ Progress tracking updated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 2: Reviewing Recent Work

📋 Latest Report: agent/reports/report-2026-02-21-session-4.md

Recent Accomplishments:
- ✅ Task 34: Generic YAML parser with AST
- ✅ Task 35: YAML parser migration
- ✅ Created E2E test infrastructure
- ✅ Fixed 11 critical bugs in package scripts
- ✅ Created GitHub Pages package browser

Current Status:
- Milestone 5: Global Package Installation (0% complete)
- Next: Task 25 - Global Infrastructure Setup

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 3: Proceeding with Next Task (@acp.proceed)

📋 Current Task: task-25-global-infrastructure

Objective: Create ~/.acp/ directory structure with AGENT.md and manifest.yaml

[Implementation begins...]
```

---

## Examples

### Example 1: Resuming After Break

**Context**: Haven't worked on project in a few days

**Invocation**: `@acp.resume`

**Result**: 
- Loads complete context
- Reviews last 3 sessions of work
- Identifies current task (task-12)
- Starts implementing task-12

### Example 2: Starting New Session

**Context**: Beginning work for the day

**Invocation**: `@acp.resume`

**Result**:
- Initializes context
- Shows yesterday's accomplishments
- Continues with current task

### Example 3: Switching Agents

**Context**: Different AI agent picking up the project

**Invocation**: `@acp.resume`

**Result**:
- Complete onboarding via @acp.init
- Understands recent work from reports
- Ready to contribute immediately

---

## Related Commands

- [`@acp.init`](acp.init.md) - Initialize context only
- [`@acp.proceed`](acp.proceed.md) - Proceed with task only
- [`@acp.status`](acp.status.md) - Check status without proceeding
- [`@acp.report`](acp.report.md) - Generate session report

---

## Troubleshooting

### Issue 1: No reports found

**Symptom**: Warning "No session reports found"

**Cause**: No reports in agent/reports/ directory

**Solution**: This is fine for new projects. The command will skip report review and proceed to task execution.

### Issue 2: Context initialization fails

**Symptom**: Error during @acp.init

**Cause**: Missing agent/ directory or corrupted files

**Solution**: Run `@acp.init` separately to see detailed error, fix issues, then run `@acp.resume` again

### Issue 3: No current task

**Symptom**: Error "No current task found"

**Cause**: All tasks completed or progress.yaml doesn't have current task

**Solution**: Review progress.yaml, create new tasks, or mark a task as in_progress

---

## Notes

- This is a convenience command that chains three workflows
- Equivalent to running: `@acp.init` → read reports → `@acp.proceed`
- Saves time when starting new sessions
- Provides comprehensive context before starting work
- Reports are optional but highly recommended for context
- If no reports exist, command still works (skips report review)

---

**Namespace**: acp
**Command**: resume
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 3.7.0+
**Author**: ACP Project
