# Task 47: Progress Time Tracking

**Milestone**: Future Enhancement
**Estimated Time**: 2-3 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Add `actual_hours` field to task entries in progress.yaml to track actual time spent implementing tasks, enabling benchmarking of estimated vs actual work time.

---

## Context

Currently, progress.yaml tracks `estimated_hours` for each task, but doesn't capture actual time spent. This makes it impossible to:
- Benchmark estimate accuracy
- Improve future estimates
- Understand actual project velocity
- Identify tasks that consistently take longer than estimated

**Solution**: Add `actual_hours` field to task entries.

**Benefits**:
- Better estimate accuracy over time
- Data-driven planning
- Identify estimation patterns
- Improve project management

---

## Steps

### 1. Update progress.template.yaml

Add `actual_hours` field to task template:

**File**: `agent/progress.template.yaml`

**Change**:
```yaml
tasks:
  milestone_1:
    - id: task-1
      name: Task Name
      status: not_started | in_progress | completed
      file: agent/tasks/task-1-name.md
      estimated_hours: N
      actual_hours: null  # ← Add this field
      completed_date: YYYY-MM-DD | null
      notes: |
        Task notes
```

**Verification**:
- Field added to template
- Default value is `null`
- Field documented

### 2. Update AGENT.md Documentation

Update progress.yaml structure documentation:

**File**: `AGENT.md`

**Location**: Line ~293 (Progress Tracking section)

**Change**:
```yaml
tasks:
  milestone_1:
    - id: task-1
      name: Task Name
      status: not_started | in_progress | completed
      file: agent/tasks/task-1-name.md
      estimated_hours: N
      actual_hours: N  # Actual time spent (null until completed)
      completed_date: YYYY-MM-DD | null
      notes: |
        Task notes
```

**Verification**:
- Documentation updated
- Field explained
- Example shows usage

### 3. Update @acp.proceed Command

Update `@acp.proceed` to prompt for actual hours when marking task complete:

**File**: `agent/commands/acp.proceed.md`

**Location**: Step 4 (Update Progress Tracking)

**Addition**:
```markdown
### 4. Update Progress Tracking

**Only after implementing**, update `agent/progress.yaml`:
- Mark task as `completed` (if done) or `in_progress` (if partial)
- Add completion date (if done)
- **Prompt for actual hours spent**: "How many hours did this task take? (estimated: X hours)"
- Update `actual_hours` field with user's response
- Update milestone progress percentage
- Add `recent_work` entry describing what was IMPLEMENTED
- Update `next_steps`
```

**Verification**:
- Command updated
- Prompts for actual hours
- Field updated in progress.yaml

### 4. Update @acp.status Command

Update `@acp.status` to show estimate vs actual comparison:

**File**: `agent/commands/acp.status.md`

**Addition**: Add section showing estimate accuracy:
```markdown
## Estimate Accuracy (Completed Tasks)

| Task | Estimated | Actual | Variance |
|------|-----------|--------|----------|
| Task 25 | 2-3h | 2.5h | ✅ On target |
| Task 26 | 2-3h | 4h | ⚠️  +33% over |
| Task 27 | 2-3h | 2h | ✅ Under estimate |

Average variance: +15% (tasks take slightly longer than estimated)
```

**Verification**:
- Status command shows estimate accuracy
- Variance calculated
- Helpful insights provided

### 5. Create Analysis Utility (Optional)

Create optional script to analyze estimate accuracy:

**File**: `agent/scripts/acp.estimate-analysis.sh`

**Features**:
- Calculate average variance
- Identify patterns (which types of tasks are underestimated)
- Generate recommendations for future estimates
- Export data for visualization

**Verification**:
- Script created
- Analysis is accurate
- Recommendations are helpful

### 6. Update Existing Tasks (Optional)

Optionally add `actual_hours: null` to all existing task entries:

**Actions**:
- Read progress.yaml
- For each task entry, add `actual_hours: null` if missing
- Save progress.yaml

**Note**: This is optional - field can be added incrementally as tasks complete.

**Verification**:
- Field added to existing tasks
- YAML remains valid
- No data loss

---

## Verification

- [ ] `actual_hours` field added to progress.template.yaml
- [ ] AGENT.md documentation updated
- [ ] @acp.proceed prompts for actual hours
- [ ] @acp.status shows estimate accuracy
- [ ] (Optional) Analysis script created
- [ ] (Optional) Existing tasks updated
- [ ] All documentation updated
- [ ] YAML structure remains valid

---

## Expected Output

### Files Modified
- `agent/progress.template.yaml` - Added actual_hours field
- `AGENT.md` - Updated progress.yaml documentation
- `agent/commands/acp.proceed.md` - Added actual hours prompt
- `agent/commands/acp.status.md` - Added estimate accuracy section

### Files Created (Optional)
- `agent/scripts/acp.estimate-analysis.sh` - Analysis utility

### progress.yaml Example
```yaml
tasks:
  milestone_5:
    - id: task-29
      name: Global ACP Auto-Initialization
      status: completed
      file: agent/tasks/task-29-global-acp-auto-initialization.md
      estimated_hours: 1-2
      actual_hours: 1.5  # ← New field
      completed_date: 2026-02-22
      notes: |
        Auto-initialization complete!
```

---

## Common Issues and Solutions

### Issue 1: Forgot to track actual hours

**Symptom**: Task completed but actual_hours is null

**Solution**: Estimate retroactively or leave as null. Going forward, @acp.proceed will prompt.

### Issue 2: Estimate is a range (e.g., "2-3 hours")

**Symptom**: Can't calculate variance with range

**Solution**: Use midpoint for calculations (2-3h → 2.5h average)

### Issue 3: Task took much longer than estimated

**Symptom**: Large variance (e.g., estimated 2h, actual 8h)

**Solution**: This is valuable data! Document why in task notes. Use for future estimates.

---

## Resources

- [progress.template.yaml](../progress.template.yaml): Progress tracking template
- [@acp.proceed](../commands/acp.proceed.md): Task execution command
- [@acp.status](../commands/acp.status.md): Status display command

---

## Notes

- Field is optional - can be null
- Useful for improving estimate accuracy over time
- Helps identify which types of tasks are consistently underestimated
- Data can be used for project planning and velocity calculations
- Consider adding to milestone entries as well (milestone actual_weeks)
- This is a progressive enhancement - doesn't break existing functionality
- Backward compatible - old progress.yaml files work without this field

---

**Next Task**: None (future enhancement)
**Related Design Docs**: None
**Estimated Completion Date**: TBD
