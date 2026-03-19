# Task 78: Implement @acp.proceed Autonomous Completion Arguments

**Milestone**: M10 - Command Enhancements  
**Estimated Time**: 8-12 hours  
**Dependencies**: None  
**Status**: Completed  

---

## Objective

Enhance `@acp.proceed` to support autonomous milestone completion via flags and natural language arguments. When invoked with `--complete` (or equivalent), the agent should work through all remaining tasks in the current milestone without stopping, committing after each task via `@git.commit`, and providing a summary report at the end.

---

## Context

Currently `@acp.proceed` advances one task at a time with user interaction between each step. For mature milestones with well-defined tasks, users want the ability to say "just finish the milestone" and have the agent autonomously complete all remaining tasks, committing along the way.

Requirements gathered from clarification-2-proceed-args.md and agent/drafts/proceed-args.md.

---

## Steps

### 1. Add Argument Parsing to @acp.proceed

Update `agent/commands/acp.proceed.md` to recognize both flag-style and natural language arguments:

**Completion flags** (all equivalent):
- `--complete`
- `--finish-milestone`
- `--auto`

**Commit flags** (all equivalent):
- `--commit`
- `--commit-each`
- `--with-commits`

**Other flags**:
- `--dry-run` — show what tasks would be completed without executing

**Natural language** (fuzzy matching):
- `@acp.proceed finish milestone and iteratively commit`
- `@acp.proceed just finish everything`
- `@acp.proceed complete the milestone`

**Flag behavior**:
- `--complete` implies `--commit` (committing is automatic in completion mode)
- `--dry-run` can be combined with `--complete` to preview

### 2. Implement Confirmation Prompt

Before entering autonomous mode, display a confirmation:

```
About to complete N remaining tasks in M{X} - {Milestone Name}:
  1. Task 78: Implement @acp.proceed Autonomous Completion
  2. Task 79: Add Testing Suite
  ...
Proceed? (yes/no)
```

### 3. Implement Autonomous Task Loop

Core autonomous completion loop:

1. Read progress.yaml for remaining tasks in current milestone
2. Select next task based on: progress.yaml order, next steps, priorities, and chat context
3. Execute the task (full @acp.proceed single-task workflow)
4. After task completion, run full `@git.commit` subroutine (version bump, changelog, progress update)
5. Display progress indicator with bar graph between tasks
6. Repeat until milestone complete or blocker encountered

**Task selection**: Based on progress.yaml, next steps, previously defined priorities, and chat context (not strictly lowest-ID-first).  

**Stopping conditions**:
- All tasks in milestone completed (success)
- Agent encounters a blocker it cannot resolve autonomously (halt for user input)
- E2E test failure (halt, require user intervention)
- Task fails partway through (halt, do not commit partial work)

### 4. Implement Git Commit Integration

After each completed task:
1. Update progress.yaml (mark task completed)
2. Update CHANGELOG.md
3. Bump version in AGENT.md
4. Run `@git.commit` subroutine
5. Do NOT push — push only happens at end of entire run

### 5. Implement Progress Indicators

Between each task, display visual progress:

```
████████████░░░░░░░░ 3/5 tasks (60%)
✅ Task 78: Implement Autonomous Completion
✅ Task 79: Add Testing Suite
✅ Task 80: Update Documentation
⏳ Task 81: Integration Tests
⬚ Task 82: Final Review
```

### 6. Implement Dry-Run Mode

When `--dry-run` is used:
- Show the same confirmation prompt with task list
- Show what would be completed
- Exit without executing any tasks

### 7. Implement Summary Report

At the end of an autonomous run, display a summary:

```
═══════════════════════════════════════
  Autonomous Run Complete - M10
═══════════════════════════════════════

  Completed: ████████████████░░░░ 4/5

  ✅ Completed (4):
    • Task 78: Implement Autonomous Completion
    • Task 79: Add Testing Suite
    • Task 80: Update Documentation
    • Task 81: Integration Tests

  ❌ Failed (1):
    • Task 82: Final Review — E2E test failure

  Commits: 4 (not pushed)
  Duration: ~45 minutes

  Next: Run `git push` to push all commits
═══════════════════════════════════════
```

### 8. Handle Interruption

If user interrupts mid-run:
- Agent infers user intent from the interruption context
- If user provides guidance, follow it
- If unclear, ask for clarification

---

## Verification

- [ ] `@acp.proceed --complete` enters autonomous completion mode
- [ ] `@acp.proceed --finish-milestone` works as alias
- [ ] `@acp.proceed --auto` works as alias
- [ ] `@acp.proceed finish milestone` works via natural language
- [ ] `@acp.proceed just finish everything` works via fuzzy matching
- [ ] Confirmation prompt shown before starting autonomous mode
- [ ] Agent commits after each task via full `@git.commit` subroutine
- [ ] Agent does NOT push until end of run
- [ ] `--dry-run` shows task list without executing
- [ ] Progress bar/indicator shown between tasks
- [ ] Agent halts on unresolvable blockers (seeks user input)
- [ ] Agent halts on E2E test failure (requires user intervention)
- [ ] Partial task failures do NOT get committed
- [ ] Summary report displayed at end of run with completion stats
- [ ] `--complete` implies `--commit` behavior

---

## Expected Output

### Files Modified
- `agent/commands/acp.proceed.md` — Enhanced with argument parsing, autonomous mode logic, progress indicators, and summary report sections

### Behavior Changes
- `@acp.proceed` without arguments — unchanged (single-task advance)
- `@acp.proceed --complete` — autonomous milestone completion with per-task commits
- `@acp.proceed --dry-run` — preview mode showing planned tasks

---

## Common Issues and Solutions

### Issue 1: Context window exhaustion during long autonomous runs
**Symptom**: Agent loses context after many tasks  
**Solution**: Each task should be self-contained; re-read progress.yaml and task files at start of each iteration  

### Issue 2: Commit conflicts during autonomous run
**Symptom**: Git commit fails mid-run  
**Solution**: Halt and seek user intervention; do not attempt to auto-resolve  

### Issue 3: Natural language parsing too aggressive
**Symptom**: Agent enters autonomous mode unintentionally  
**Solution**: Always show confirmation prompt before starting; require explicit "yes" to proceed  

---

## Resources

- [Clarification 2](../../clarifications/clarification-2-proceed-args.md): Full Q&A on proceed arguments requirements
- [Draft: proceed-args](../../drafts/proceed-args.md): Original concept document
- [@acp.proceed command](../../commands/acp.proceed.md): Current proceed command implementation
- [@git.commit command](../../commands/git.commit.md): Git commit subroutine (used per-task)

---

## Notes

- This is a command documentation enhancement — `@acp.proceed` is an agent directive (markdown), not a shell script
- The "implementation" is updating the command doc with new sections for argument handling and autonomous mode
- Natural language matching should be generous but always behind a confirmation gate
- No max task limit per run — agent runs until milestone complete or blocker encountered
- `--complete` implies `--commit`; there is no completion mode without commits

---

**Next Task**: TBD  
**Related Design Docs**: agent/clarifications/clarification-2-proceed-args.md  
**Estimated Completion Date**: TBD  
