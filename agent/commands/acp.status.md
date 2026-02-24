# Command: status

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-status` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Scripts**: None

---

**Purpose**: Display current project status including milestone progress, current task, recent work, and next steps
**Category**: Workflow
**Frequency**: As Needed

---

## What This Command Does

This command provides a comprehensive overview of the current project status by reading `agent/progress.yaml` and presenting key information in an organized format. It shows where the project stands, what's been accomplished recently, and what needs to be done next.

Use this command when you need to quickly understand the current state of the project without performing a full initialization. It's ideal for checking progress during a session, before starting new work, or when reporting status to stakeholders.

Unlike `@acp-init` which performs a full context load and updates documentation, `@acp-status` is a read-only operation that simply reports the current state as recorded in progress tracking.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/progress.yaml` exists and is up to date

---

## Steps

### 1. Read Progress Tracking

Read the `agent/progress.yaml` file to get current project state.

**Actions**:
- Open and parse `agent/progress.yaml`
- Extract key information: current milestone, current task, progress percentages
- Note any errors or missing data

**Expected Outcome**: Progress data loaded successfully

### 2. Display Current Milestone

Show the current milestone information.

**Actions**:
- Display milestone ID and name
- Show milestone progress percentage
- Show tasks completed vs total tasks
- Display milestone status (not_started, in_progress, completed)

**Expected Outcome**: User sees current milestone summary

### 3. Display Current Task

Show the current task being worked on.

**Actions**:
- Display task ID and name
- Show task status
- Display task file path
- Show estimated hours and completion date (if completed)

**Expected Outcome**: User sees current task details

### 4. Display Recent Work

List recent work completed.

**Actions**:
- Show recent work entries from `progress.yaml`
- Display dates and descriptions
- Show completed items with checkmarks

**Expected Outcome**: User sees what was recently accomplished

### 5. Display Next Steps

Show what needs to be done next.

**Actions**:
- List next steps from `progress.yaml`
- Prioritize by order in the list
- Highlight any urgent items

**Expected Outcome**: User knows what to work on next

### 6. Display Blockers

Show any current blockers or issues.

**Actions**:
- List current blockers from `progress.yaml`
- Highlight critical blockers
- Note if no blockers exist

**Expected Outcome**: User is aware of any obstacles

---

## Verification

- [ ] `agent/progress.yaml` read successfully
- [ ] Current milestone displayed with progress percentage
- [ ] Current task displayed with status
- [ ] Recent work listed (if any exists)
- [ ] Next steps listed
- [ ] Blockers displayed (or noted as none)
- [ ] Output is clear and well-formatted

---

## Expected Output

### Files Modified
None - this is a read-only command

### Console Output
```
📊 Project Status

Project: example-project (v0.1.0)
Status: in_progress
Started: 2026-01-15

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Current Milestone: M1 - Foundation
Progress: 40% (2/5 tasks completed)
Status: in_progress
Started: 2026-01-15

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Current Task: task-3-implement-core-logic
Status: in_progress
File: agent/tasks/task-3-implement-core-logic.md
Estimated: 4 hours

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Recent Work:
  2026-02-15:
    - ✅ Completed task-2 (database setup)
    - ✅ Updated progress tracking
    - 📋 Started task-3

  2026-02-14:
    - ✅ Completed task-1 (project structure)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Next Steps:
  1. Complete task-3 (implement core logic)
  2. Begin task-4 (add tests)
  3. Review milestone-1 success criteria

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Current Blockers:
  None

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall Progress: 35% complete
```

### Status Update
No status changes - read-only operation

---

## Examples

### Example 1: Checking Status Mid-Session

**Context**: You're in the middle of working and want to see where things stand

**Invocation**: `@acp-status`

**Result**: Displays current milestone (M1, 40% complete), current task (task-3, in progress), recent work (completed task-2 yesterday), and next steps (finish task-3, start task-4)

### Example 2: Starting a New Session

**Context**: Beginning work after a break, want to see project state before diving in

**Invocation**: `@acp-status`

**Result**: Shows you're on milestone 2, 60% through, currently on task-7, with 3 tasks completed this week and 2 blockers to address

### Example 3: Reporting to Stakeholders

**Context**: Need to provide a quick status update

**Invocation**: `@acp-status`

**Result**: Clean, formatted output showing overall progress (65%), current phase (Testing), and upcoming milestones

---

## Related Commands

- [`@acp-init`](acp.init.md) - Use for full context initialization at session start
- [`@acp-proceed`](acp.proceed.md) - Use after checking status to continue with current task
- [`@acp-update`](acp.update.md) - Use to update progress.yaml after completing work
- [`@acp-sync`](acp.sync.md) - Use to sync documentation with code changes

---

## Troubleshooting

### Issue 1: progress.yaml not found

**Symptom**: Error message "Cannot read file: agent/progress.yaml"

**Cause**: Progress tracking file doesn't exist yet

**Solution**: Create progress.yaml from template: `cp agent/progress.template.yaml agent/progress.yaml`, then fill in initial project information

### Issue 2: Empty or incomplete output

**Symptom**: Status shows "No data" or missing sections

**Cause**: progress.yaml is not properly filled out

**Solution**: Review progress.yaml and ensure all required fields are populated (project name, current milestone, current task, etc.)

### Issue 3: Outdated information displayed

**Symptom**: Status shows old task or milestone that's already completed

**Cause**: progress.yaml hasn't been updated after recent work

**Solution**: Run `@acp-update` to refresh progress tracking, or manually update progress.yaml

---

## Security Considerations

### File Access
- **Reads**: `agent/progress.yaml` only
- **Writes**: None (read-only command)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access any secrets or credentials
- **Credentials**: Does not access any credentials

---

## Notes

- This is a read-only command that doesn't modify any files
- For best results, keep `agent/progress.yaml` up to date
- Use `@acp-update` after completing tasks to ensure status is accurate
- Status output is designed to be human-readable and suitable for reports
- Can be run multiple times per session without side effects
- Faster than `@acp-init` since it only reads one file

---

**Namespace**: acp
**Command**: status
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.0.3+
**Author**: ACP Project
