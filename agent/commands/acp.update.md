# Command: update

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.update` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Scripts**: None

---

**Purpose**: Update progress.yaml with latest project status, task completion, and recent work
**Category**: Documentation
**Frequency**: As Needed

---

## What This Command Does

This command updates `agent/progress.yaml` with the latest project status. It's used after completing work to ensure progress tracking accurately reflects what's been accomplished. The command updates task statuses, milestone progress percentages, recent work entries, and next steps.

Use this command when you've completed tasks, made significant progress, or need to ensure the progress tracking is current. It's particularly useful after finishing a work session or when transitioning between tasks.

Unlike `@acp.sync` which updates documentation based on code changes, `@acp.update` focuses specifically on updating the progress tracking file to reflect completed work and current status.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/progress.yaml` exists
- [ ] Work has been completed that needs to be tracked
- [ ] You know which tasks/milestones to update

---

## Steps

### 1. Read Current Progress

Read `agent/progress.yaml` to understand current state.

**Actions**:
- Open and parse `agent/progress.yaml`
- Note current milestone and its progress
- Identify tasks and their statuses
- Review recent work entries
- Check next steps

**Expected Outcome**: Current progress state understood

### 2. Identify What Changed

Determine what work was completed since last update.

**Actions**:
- Review what tasks were worked on
- Identify completed tasks
- Note any milestone completions
- Determine new blockers or resolved blockers
- Identify what should be in recent work

**Expected Outcome**: Changes to track are identified

### 3. Update Task Statuses

Update individual task statuses and completion dates.

**Actions**:
- Mark completed tasks as `completed`
- Set `completed_date` to today's date (YYYY-MM-DD)
- Update task notes if needed
- Change `in_progress` tasks if no longer active

**Expected Outcome**: Task statuses reflect reality

### 4. Update Milestone Progress

Recalculate and update milestone progress percentages.

**Actions**:
- Count tasks completed vs total tasks
- Calculate progress percentage
- Update `progress` field (0-100)
- Update `tasks_completed` count
- Set `completed` date if milestone finished
- Update milestone status if needed

**Expected Outcome**: Milestone progress is accurate

### 5. Add Recent Work Entry

Add entry to `recent_work` section documenting what was done.

**Actions**:
- Add new entry with today's date
- Write clear description of work completed
- List specific items accomplished (use ✅, 📋, ⚠️ emojis)
- Keep entries concise but informative
- Maintain chronological order (newest first)

**Expected Outcome**: Recent work documented

### 6. Update Next Steps

Refresh the `next_steps` list based on current state.

**Actions**:
- Remove completed items
- Add new next steps based on progress
- Prioritize by importance/urgency
- Keep list focused (3-5 items)
- Be specific and actionable

**Expected Outcome**: Next steps are current

### 7. Update Blockers

Update the `current_blockers` list.

**Actions**:
- Remove resolved blockers
- Add new blockers discovered
- Keep descriptions clear and actionable
- Empty list if no blockers

**Expected Outcome**: Blockers list is accurate

### 8. Save Changes

Write updated progress.yaml back to disk.

**Actions**:
- Ensure YAML formatting is correct
- Preserve structure and indentation
- Save file
- Verify file was written successfully

**Expected Outcome**: progress.yaml updated on disk

---

## Verification

- [ ] progress.yaml file updated successfully
- [ ] Task statuses reflect completed work
- [ ] Milestone progress percentages are accurate
- [ ] Recent work entry added with today's date
- [ ] Next steps list is current and actionable
- [ ] Blockers list is accurate
- [ ] YAML syntax is valid
- [ ] No data was lost or corrupted

---

## Expected Output

### Files Modified
- `agent/progress.yaml` - Updated with latest progress

### Console Output
```
📝 Updating Progress Tracking

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reading current progress...
✓ Current milestone: M2 - Documentation & Utility Commands
✓ Progress: 40% (2/5 tasks completed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updating progress...
✓ Marked task-5 as completed
✓ Updated milestone progress: 40% → 60%
✓ Added recent work entry (2026-02-16)
✓ Updated next steps
✓ No new blockers

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Progress Updated!

Summary:
- Tasks completed: 2 → 3
- Milestone progress: 40% → 60%
- Recent work: Added entry for today
- Next: task-6 - Implement Utility Commands
```

### Status Update
- Task statuses updated
- Milestone progress recalculated
- Recent work documented
- Next steps refreshed

---

## Examples

### Example 1: After Completing a Task

**Context**: Just finished task-3, need to update progress

**Invocation**: `@acp.update`

**Result**: Marks task-3 as completed, updates milestone from 40% to 60%, adds recent work entry, identifies task-4 as next

### Example 2: Mid-Task Progress Update

**Context**: Made significant progress on task-5 but not complete

**Invocation**: `@acp.update`

**Result**: Adds recent work entry documenting progress, updates task notes, keeps task status as in_progress

### Example 3: Milestone Completion

**Context**: Just finished last task in milestone

**Invocation**: `@acp.update`

**Result**: Marks task and milestone as completed, sets completion dates, updates to next milestone, celebrates achievement

---

## Related Commands

- [`@acp.status`](acp.status.md) - View current status before updating
- [`@acp.proceed`](acp.proceed.md) - Automatically updates progress after completing tasks
- [`@acp.sync`](acp.sync.md) - Update documentation based on code changes
- [`@acp.report`](acp.report.md) - Generate comprehensive progress report

---

## Troubleshooting

### Issue 1: YAML syntax error after update

**Symptom**: progress.yaml has syntax errors

**Cause**: Incorrect indentation or formatting

**Solution**: Validate YAML syntax, fix indentation (use 2 spaces), ensure proper structure

### Issue 2: Progress percentages don't match

**Symptom**: Calculated percentage doesn't match tasks completed

**Cause**: Math error or incorrect task count

**Solution**: Recalculate: (tasks_completed / tasks_total) * 100, round to nearest integer

### Issue 3: Recent work entries out of order

**Symptom**: Dates not in chronological order

**Cause**: New entry added in wrong position

**Solution**: Ensure newest entries are first in the list, maintain reverse chronological order

---

## Security Considerations

### File Access
- **Reads**: `agent/progress.yaml`
- **Writes**: `agent/progress.yaml` (updates progress tracking)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access any secrets or credentials
- **Credentials**: Does not access any credentials

---

## Notes

- This command only updates progress.yaml, not other documentation
- Use `@acp.sync` to update design docs and other documentation
- Progress percentages should be integers (0-100)
- Recent work entries should be concise but informative
- Keep next steps list focused (3-5 items maximum)
- Update frequently to maintain accurate tracking
- Can be run multiple times per day as needed

---

**Namespace**: acp
**Command**: update
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.1.0+
**Author**: ACP Project
