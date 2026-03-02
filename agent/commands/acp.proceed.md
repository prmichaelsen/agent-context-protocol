# Command: proceed

> **🤖 CRITICAL AGENT DIRECTIVE**: You are reading this file because `@acp.proceed` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."
>
> **STEP 0: CHECK FOR ARGUMENTS FIRST.**
> If arguments or natural language follow `@acp.proceed`, detect the mode before doing anything else.
> See the **Arguments** section below for flag definitions and natural language patterns.
>
> **If no arguments (default mode):**
> - YOU MUST IMMEDIATELY BEGIN IMPLEMENTING THE CURRENT OR NEXT TASK.
> - Follow **Steps 1-5** (Single-Task Mode).
>
> **If autonomous arguments detected (`--complete`, `--auto`, `--autonomous`, `--finish-milestone`, or natural language like "finish milestone", "just finish everything", "complete all tasks"):**
> - Follow **Autonomous Mode** section.
> - Do NOT start implementing individual tasks until confirmation is received.
>
> **If `--dry-run` detected:**
> - Follow **Autonomous Mode > Dry-Run** section.
> - Show what would be done, then exit.
>
> **DO NOT** (in any mode):
> - ❌ Provide status reports or summaries instead of action
> - ❌ Ask about session size, cost, or token limits
> - ❌ End with "ready to proceed" or similar passive statements
>
> **This is an ACTION command, not a STATUS command.**

**Namespace**: acp
**Version**: 2.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-28
**Status**: Active
**Scripts**: None

---

**Purpose**: Implement tasks — single-task (default) or autonomous milestone completion (with arguments)
**Category**: Workflow
**Frequency**: As Needed

---

## Arguments

This command supports both CLI-style flags and natural language arguments.

### Completion Flags (all equivalent — trigger autonomous mode)

| Flag | Description |
|------|-------------|
| `--complete` | Complete all remaining tasks in current milestone |
| `--finish-milestone` | Same as `--complete` (explicit name) |
| `--auto` | Same as `--complete` (short form) |
| `--autonomous` | Same as `--complete` (explicit form) |

### Commit Flags (all equivalent — implied by `--complete`)

| Flag | Description |
|------|-------------|
| `--commit` | Run `@git.commit` after each task |
| `--commit-each` | Same as `--commit` (explicit name) |
| `--with-commits` | Same as `--commit` (modifier style) |

**Note**: `--complete` implies `--commit`. There is no autonomous completion mode without per-task commits.

### Other Flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview what tasks would be completed without executing |

### Natural Language (Fuzzy Matching)

The agent should detect autonomous intent from natural language following `@acp.proceed`:

| Example | Detected Mode |
|---------|---------------|
| `@acp.proceed --complete` | Autonomous |
| `@acp.proceed finish milestone` | Autonomous |
| `@acp.proceed finish milestone and iteratively commit` | Autonomous |
| `@acp.proceed just finish everything` | Autonomous |
| `@acp.proceed complete the milestone` | Autonomous |
| `@acp.proceed complete all tasks` | Autonomous |
| `@acp.proceed --dry-run` | Dry-Run |
| `@acp.proceed` | Single-Task (default) |

**Matching rules**:
- Look for keywords: `complete`, `finish`, `auto`, `autonomous`, `all tasks`, `everything`, `milestone`
- Be generous with matching — if the user's intent is clearly "do everything", enter autonomous mode
- When in doubt, **always show the confirmation prompt** before starting autonomous execution
- Never enter autonomous mode silently — the confirmation gate is mandatory

### Flag Combinations

| Combination | Behavior |
|-------------|----------|
| `--complete` | Autonomous completion with per-task commits |
| `--complete --dry-run` | Preview task list, no execution |
| `--dry-run` (alone) | Preview next task only |
| `--commit` (alone) | Single-task mode, commit after completion |
| (no flags) | Single-task mode, no auto-commit |

---

## What This Command Does

**THIS IS AN IMPLEMENTATION COMMAND.**

### Default Mode (No Arguments)

When you invoke `@acp.proceed` without arguments:
1. Find the current/next task
2. **IMMEDIATELY START IMPLEMENTING IT**
3. Write code, create files, make changes
4. Complete the task or make substantial progress
5. Update progress tracking

### Autonomous Mode (With `--complete` or Natural Language)

When you invoke `@acp.proceed --complete` (or equivalent):
1. Scan remaining tasks in current milestone
2. Show confirmation prompt with task list
3. After user confirms, **implement ALL remaining tasks sequentially**
4. After each task: run full `@git.commit` subroutine (version bump, changelog, progress)
5. Display progress indicators between tasks
6. Continue until milestone complete or blocker encountered
7. Display summary report at end

**This is NOT a status command.** Do not confuse this with `@acp.status`. The purpose of `@acp.proceed` is to **DO WORK**, not report on work.

**Forbidden Behaviors** (all modes):
- Providing status summaries without implementation
- Asking about token limits or session size
- Suggesting to "continue later" or "push commits first"
- Ending with "ready to proceed" (you ARE proceeding!)

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/progress.yaml` exists and has current task defined
- [ ] Current task document exists in `agent/tasks/`
- [ ] Context initialized (recommended to run `@acp-init` first)

---

## Steps (Single-Task Mode)

> **These steps apply when `@acp.proceed` is invoked WITHOUT autonomous arguments.**
> If autonomous mode was detected, skip to **Autonomous Mode** section below.

### 🚨 CRITICAL: These are IMPLEMENTATION steps, not planning steps

### 1. Identify Current Task (30 seconds max)

**Actions**:
- Read `agent/progress.yaml`
- Find first task with status `in_progress` or `not_started` in the current milestone
- Read the task document

**DO NOT spend time analyzing or planning. MOVE TO STEP 2 IMMEDIATELY.**

### 1.5. Read Contextual Key Files

Before implementing, load relevant key files from the index.

**Actions**:
- Check if `agent/index/` directory exists
- If exists, scan for all `*.yaml` files (excluding `*.template.yaml`)
- Parse entries, merge across namespaces (`local.*` takes precedence)
- Filter entries where `applies` includes `acp.proceed`
- Sort by weight descending
- Read matching files
- Produce visible output

**Display format**:
```
📑 Reading Key Files (acp.proceed)...
  ✓ agent/patterns/local.e2e-testing.md (weight: 0.8, pattern)
  ✓ agent/patterns/local.tracked-untracked-directories.md (weight: 0.7, pattern)

  2 key files read for acp.proceed context
```

**Note**: If `agent/index/` does not exist, skip silently. Do NOT spend excessive time here — read files quickly and move to implementation.

### 2. START IMPLEMENTING NOW (This is the main step)

**🚨 MANDATORY ACTIONS - DO THESE IMMEDIATELY:**

- **Create files** that the task requires
- **Write code** specified in the task
- **Execute commands** needed for the task
- **Make changes** to existing files
- **Install dependencies** if needed
- **Run tests** if specified
- **Verify functionality** as you go

**DO NOT**:
- ❌ Provide summaries of what you "will" do
- ❌ Ask if the user wants to proceed
- ❌ Mention token limits, costs, or session size
- ❌ Suggest breaking the task into smaller pieces
- ❌ End with "ready to implement" or similar

**YOU ARE IMPLEMENTING. START NOW. NO EXCUSES.**

### 3. Complete the Task or Make Substantial Progress

**Keep working until**:
- ✅ Task is complete, OR
- ✅ You've made substantial progress (50%+ of task done), OR
- ✅ You encounter a genuine blocker that requires user input

**"Substantial progress" means**:
- Multiple files created/modified
- Core functionality implemented
- Verification steps passing
- Clear advancement toward task completion

**NOT substantial**:
- Reading files
- Planning what to do
- Providing status updates
- Asking questions that could be answered by reading docs

### 3.5. Verify All Deliverables Exist

**Before marking a task complete, you MUST verify every expected deliverable:**

1. **Re-read the task document** — specifically the "Expected Output", "Acceptance Criteria", and "Verification" sections
2. **Check file existence** — for every file listed in "Files Created", verify it exists on disk (ls or stat)
3. **Check file content** — for files with specific content requirements (README, docs, configs), verify they contain the required sections
4. **Check modifications** — for every file listed in "Files Modified", verify the expected changes are present
5. **Walk the verification checklist** — go through each checkbox item and confirm it passes

**If ANY deliverable is missing:**
- DO NOT mark the task complete
- DO NOT move to progress update
- Create the missing deliverable first, then re-verify
- Only proceed to Step 4 when ALL deliverables confirmed

**This step is NON-NEGOTIABLE.** A task with passing tests but missing files is NOT complete.

### 4. Update Progress Tracking

**Only after verifying all deliverables**, update `agent/progress.yaml`:
- Mark task as `completed` (if done) or `in_progress` (if partial)
- Add completion date (if done)
- **Ask user for actual hours spent**: "How many hours did this task take? (estimated: X hours)" - Update `actual_hours` field
- Update milestone progress percentage
- Add `recent_work` entry describing what was IMPLEMENTED
- Update `next_steps`

### 5. Report What Was IMPLEMENTED (Not What Will Be Done)

**Provide a completion report showing**:
- What files were created/modified
- What functionality was implemented
- What verification steps passed
- What remains (if task incomplete)

**DO NOT**:
- ❌ End with "ready to continue"
- ❌ Ask if user wants to proceed
- ❌ Suggest next steps without implementing them

---

## Autonomous Mode

> **These steps apply when `@acp.proceed` is invoked WITH `--complete`, `--auto`, `--autonomous`, `--finish-milestone`, or natural language indicating autonomous completion.**
>
> **🚨 CRITICAL**: Do NOT start implementing tasks until the user confirms the plan.

### A1. Scan Remaining Tasks

**Actions**:
- Read `agent/progress.yaml`
- Identify the current milestone (from `current_milestone` field)
- Collect all tasks in that milestone with status `not_started` or `in_progress`
- Read each task document to understand scope
- Order tasks based on: progress.yaml order, next steps, previously defined priorities, and chat context

**Task selection is NOT strictly lowest-ID-first.** Use judgment based on:
- Dependencies between tasks
- Progress.yaml ordering and notes
- Previously defined priorities in milestone or task documents
- Current chat context (user may have indicated preferences)

### A2. Show Confirmation Prompt

**🚨 MANDATORY**: Always show this confirmation before starting autonomous execution. Never skip this step.

Display the following to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Autonomous Completion Mode
  M{X} - {Milestone Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  {N} remaining tasks:

    1. Task {id}: {name} ({estimated_hours})
    2. Task {id}: {name} ({estimated_hours})
    3. Task {id}: {name} ({estimated_hours})
    ...

  After each task:
    - Update progress.yaml, CHANGELOG.md, AGENT.md version
    - Run @git.commit (full subroutine)
    - Display progress bar

  At end of run:
    - Summary report with completion stats
    - Push NOT automatic (you decide when to push)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Proceed? (yes/no)
```

**Wait for user confirmation.** If user says no, exit autonomous mode and fall back to single-task mode or stop.

### A3. Autonomous Task Loop

After user confirms, execute the following loop:

```
FOR each remaining task in planned order:

  1. DISPLAY progress indicator (see A5)

  2. READ task document and key files
     - Re-read progress.yaml at start of each iteration (context freshness)
     - Read contextual key files from agent/index/ (filter by acp.proceed applies)
     - Read the task file

  3. IMPLEMENT the task
     - Follow the same implementation approach as Single-Task Steps 2-3
     - Create files, write code, execute commands
     - Run tests if specified in task
     - Complete the task fully

  4. VERIFY DELIVERABLES
     - Re-read the task's "Expected Output" and "Verification" sections
     - Confirm every file in "Files Created" exists on disk
     - Confirm every file in "Files Modified" has the expected changes
     - Walk each verification checkbox and confirm it passes
     - If anything is missing: create it before proceeding
     - Do NOT skip this step — a task with passing tests but missing files is NOT complete

  5. CHECK for failure
     - If task fails or encounters blocker → HALT (see A8)
     - If E2E tests fail → HALT (see A8)
     - Do NOT commit partial work

  6. UPDATE progress tracking
     - Mark task as completed in progress.yaml
     - Add completion date
     - Update milestone progress percentage
     - Add recent_work entry

  7. RUN @git.commit subroutine
     - Determine version bump (patch for most tasks, minor for features)
     - Update AGENT.md version
     - Update CHANGELOG.md with task completion entry
     - Stage all relevant files
     - Create commit with conventional commit message
     - Do NOT push (push only at end of entire run)

  8. CONTINUE to next task

END FOR
```

### A3.5. Milestone Completion Sweep

**After ALL tasks in the autonomous loop are done, perform a final deliverables audit:**

1. **Re-read each completed task's Expected Output section**
2. **Verify all files exist** — ls/stat every file listed across all tasks
3. **Run the full test suite** one final time
4. **Check for common omissions:**
   - README.md or project documentation
   - Configuration files (.env.example, etc.)
   - Architecture/design documentation if specified
   - Migration guides if specified

**If any deliverable from any task is missing:**
- Create it before generating the Summary Report
- Re-run verification for the affected task
- Only proceed to Summary Report when all tasks' deliverables are confirmed

This sweep catches files that may have been missed during individual task execution, especially documentation artifacts that are easy to overlook during coding-heavy milestones.

### A4. Per-Task Git Commit

After each successfully completed task, run the full `@git.commit` subroutine:

1. **Analyze changes** — determine version impact (usually patch for individual tasks)
2. **Bump version** — update AGENT.md version field
3. **Update CHANGELOG.md** — add entry describing task completion
4. **Stage files** — all files modified during the task + version files + progress.yaml
5. **Commit** — conventional commit message referencing the task
6. **Do NOT push** — commits accumulate locally; push only at end of run

**Commit message format**:
```
{type}({scope}): {task description}

Completed Task {N}: {task name}
- {change 1}
- {change 2}

Milestone: M{X} - {milestone name} ({completed}/{total} tasks)
Version: {new version}
```

### A5. Progress Indicators

Between each task, display a visual progress update:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ████████████░░░░░░░░ {completed}/{total} tasks ({percent}%)

  ✅ Task {id}: {name}
  ✅ Task {id}: {name}
  ✅ Task {id}: {name}
  ⏳ Task {id}: {name}            ← current
  ⬚  Task {id}: {name}
  ⬚  Task {id}: {name}

  Commits: {N} (not pushed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Symbols**:
- ✅ = completed
- ⏳ = in progress (about to start)
- ⬚ = pending
- ❌ = failed

### A6. Summary Report

At the end of the autonomous run (whether all tasks complete or halted), display:

```
═══════════════════════════════════════════════════════
  Autonomous Run Complete — M{X}: {Milestone Name}
═══════════════════════════════════════════════════════

  Progress: ████████████████░░░░ {completed}/{total} ({percent}%)

  ✅ Completed ({N}):
     • Task {id}: {name}
     • Task {id}: {name}
     • Task {id}: {name}

  ❌ Failed ({N}):                          ← only if failures
     • Task {id}: {name} — {reason}

  ⬚  Remaining ({N}):                      ← only if incomplete
     • Task {id}: {name}

  ─────────────────────────────────────────
  Commits:   {N} (not pushed)
  Version:   {old} → {new}
  ─────────────────────────────────────────

  Next steps:
    • git push                    ← push all commits
    • @acp.proceed                ← continue remaining tasks
    • @acp.status                 ← review project status

═══════════════════════════════════════════════════════
```

### A7. Dry-Run Mode

When `--dry-run` is specified (alone or with `--complete`):

1. Scan remaining tasks (same as A1)
2. Display the confirmation prompt (same as A2) but with a `(DRY RUN)` label
3. **Do NOT execute any tasks**
4. Display what would happen:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  DRY RUN — Autonomous Completion Preview
  M{X} - {Milestone Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Would complete {N} tasks:

    1. Task {id}: {name} ({hours}h)
    2. Task {id}: {name} ({hours}h)
    3. Task {id}: {name} ({hours}h)

  Would create {N} commits (1 per task)
  Would bump version {N} times

  (dry run — no files were modified)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

5. Exit without making any changes

### A8. Error Handling & Halting

**When to HALT autonomous execution:**

| Condition | Action |
|-----------|--------|
| Task fails partway through | HALT. Do NOT commit partial work. Seek user input. |
| E2E tests fail | HALT. Require user intervention guidance. |
| Blocker requiring user decision | HALT. Present the blocker and ask for guidance. |
| Agent cannot make a decision | HALT. Ask user for input. |
| Git commit fails | HALT. Seek user intervention. |

**On HALT**:
1. Stop the autonomous loop
2. Display the summary report (A6) showing what was completed before the halt
3. Clearly explain the failure:
   ```
   ⚠️  Autonomous run halted at Task {id}: {name}

   Reason: {clear explanation of what went wrong}

   What was completed before halt:
     ✅ Task {id}: {name} (committed)
     ✅ Task {id}: {name} (committed)

   Uncommitted work:
     ⚠️  Task {id}: {name} — partial, NOT committed

   Awaiting your guidance to continue.
   ```
4. Wait for user to provide guidance before continuing

**NEVER**:
- ❌ Skip a failed task and move to the next one
- ❌ Commit partial work from a failed task
- ❌ Retry a failed task without user guidance
- ❌ Auto-resolve errors by discarding changes

### A9. Interruption Handling

If the user sends a message during autonomous execution:

- **Infer user intent** from the message content
- If the user is providing guidance or a correction → incorporate it and continue
- If the user wants to stop → halt gracefully (show summary report)
- If unclear → ask the user what they'd like to do
- **Never ignore user messages** during autonomous execution

---

## Verification

### Single-Task Mode
- [ ] Current task identified from progress.yaml
- [ ] Task document read and understood
- [ ] Prerequisites checked
- [ ] All task steps executed
- [ ] All files in task's "Expected Output > Files Created" confirmed to exist
- [ ] All files in task's "Expected Output > Files Modified" confirmed to have changes
- [ ] Documentation deliverables (README, docs) contain required sections
- [ ] Verification checklist completed
- [ ] progress.yaml updated with completion
- [ ] Milestone progress percentage updated
- [ ] Recent work entry added
- [ ] Next task identified

### Autonomous Mode
- [ ] Arguments correctly detected (flags or natural language)
- [ ] Remaining tasks scanned from progress.yaml
- [ ] Confirmation prompt shown and user approved
- [ ] Each task implemented fully before moving to next
- [ ] Deliverables verified for each task before marking complete
- [ ] `@git.commit` ran after each task (version bump, changelog, progress)
- [ ] Progress indicator displayed between tasks
- [ ] Milestone completion sweep performed (all deliverables across all tasks verified)
- [ ] No push until end of run
- [ ] Summary report displayed at end
- [ ] Halted correctly on any failures (no partial commits)

---

## Expected Output

### Single-Task Mode
```
📋 Current Task: task-3-implement-core-logic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Objective: Implement the core business logic for the application

Steps:
  1. Create service layer classes
  2. Implement data access methods
  3. Add error handling
  4. Write unit tests

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Step 1: Created service layer classes
✅ Step 2: Implemented data access methods
✅ Step 3: Added error handling
✅ Step 4: Wrote unit tests

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Task 3 Complete!

Updated progress.yaml:
- Task 3: completed (2026-02-16)
- Milestone 1: 60% complete (3/5 tasks)
- Added to recent work

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 Next Task: task-4-add-integration-tests
File: agent/tasks/task-4-add-integration-tests.md
Estimated: 3 hours
```

### Autonomous Mode — Success
```
═══════════════════════════════════════════════════════
  Autonomous Run Complete — M10: Command Enhancements
═══════════════════════════════════════════════════════

  Progress: ████████████████████ 3/3 (100%)

  ✅ Completed (3):
     • Task 78: Implement @acp.proceed Autonomous Completion
     • Task 79: Add Testing Suite
     • Task 80: Update Documentation

  ─────────────────────────────────────────
  Commits:   3 (not pushed)
  Version:   5.0.1 → 5.0.4
  ─────────────────────────────────────────

  Next steps:
    • git push

═══════════════════════════════════════════════════════
```

### Autonomous Mode — Halted
```
═══════════════════════════════════════════════════════
  Autonomous Run Halted — M10: Command Enhancements
═══════════════════════════════════════════════════════

  Progress: ████████████░░░░░░░░ 2/3 (67%)

  ✅ Completed (2):
     • Task 78: Implement @acp.proceed Autonomous Completion
     • Task 79: Add Testing Suite

  ❌ Failed (1):
     • Task 80: Update Documentation — E2E test failure

  ─────────────────────────────────────────
  Commits:   2 (not pushed)
  Version:   5.0.1 → 5.0.3
  ─────────────────────────────────────────

  Awaiting your guidance to continue.

═══════════════════════════════════════════════════════
```

---

## Examples

### Example 1: Single-Task (Default)

**Context**: You want to implement the next task

**Invocation**: `@acp.proceed`

**Result**: Identifies next task, immediately starts implementing, completes task, updates progress

### Example 2: Autonomous Completion with Flags

**Context**: Milestone has 5 remaining tasks, you want them all done

**Invocation**: `@acp.proceed --complete`

**Result**: Shows confirmation with 5 tasks listed, user confirms, agent implements all 5 tasks with per-task commits, displays summary

### Example 3: Autonomous with Natural Language

**Context**: Same as above but using natural language

**Invocation**: `@acp.proceed just finish everything`

**Result**: Same as `--complete` — agent detects autonomous intent, shows confirmation, implements all tasks

### Example 4: Dry-Run Preview

**Context**: You want to see what would be done without executing

**Invocation**: `@acp.proceed --complete --dry-run`

**Result**: Shows task list with estimates, exits without making changes

### Example 5: Autonomous with Halt

**Context**: Milestone has 5 tasks, task 3 fails

**Invocation**: `@acp.proceed --complete`

**Result**: Completes tasks 1-2 with commits, halts at task 3, shows summary with 2 completed + 1 failed, waits for user guidance

### Example 6: Single-Task with Commit

**Context**: You want to implement one task and commit

**Invocation**: `@acp.proceed --commit`

**Result**: Implements next task, runs `@git.commit` after completion

---

## Related Commands

- [`@acp.init`](acp.init.md) - Use before proceeding to ensure full context loaded
- [`@acp.status`](acp.status.md) - Use to check which task is current before proceeding
- [`@acp.update`](acp.update.md) - Use to manually update progress if needed
- [`@acp.sync`](acp.sync.md) - Use after completing tasks to sync documentation
- [`@git.commit`](git.commit.md) - Git commit subroutine (used per-task in autonomous mode)

---

## Troubleshooting

### Issue 1: No current task found

**Symptom**: Error message "No current task identified"

**Cause**: All tasks are completed or progress.yaml doesn't have a current task

**Solution**: Review progress.yaml and either mark a task as `in_progress` or create new tasks for the next milestone

### Issue 2: Task document not found

**Symptom**: Error message "Cannot read task file"

**Cause**: Task file path in progress.yaml is incorrect or file doesn't exist

**Solution**: Verify the file path in progress.yaml matches the actual task file location, or create the missing task document

### Issue 3: Prerequisites not met

**Symptom**: Command reports missing prerequisites

**Cause**: Task has dependencies that aren't satisfied yet

**Solution**: Complete prerequisite tasks first, or resolve the dependencies, then run `@acp.proceed` again

### Issue 4: Verification fails

**Symptom**: Some verification items don't pass

**Cause**: Task steps weren't completed correctly or there are errors

**Solution**: Review the failed verification items, fix issues, then re-run verification steps

### Issue 5: Autonomous mode not detected

**Symptom**: Agent starts single-task mode despite passing `--complete`

**Cause**: Arguments not parsed correctly or natural language not recognized

**Solution**: Use explicit flag `--complete` instead of natural language. Ensure flag appears after `@acp.proceed`.

### Issue 6: Context window exhaustion during autonomous run

**Symptom**: Agent loses context after completing several tasks

**Cause**: Long autonomous runs consume context window

**Solution**: Agent re-reads progress.yaml and task files at the start of each iteration to maintain context freshness. If context is truly exhausted, the run will halt and can be resumed with `@acp.proceed --complete` in a new session.

---

## Security Considerations

### File Access
- **Reads**: `agent/progress.yaml`, task documents, design documents, AGENT.md, CHANGELOG.md
- **Writes**: `agent/progress.yaml`, task-specific files, AGENT.md (version), CHANGELOG.md (entries)
- **Executes**: May execute commands as specified in task steps (e.g., `npm test`, `npm run build`), git commands for commits

### Network Access
- **APIs**: May make API calls if task requires it
- **Repositories**: Interacts with git for commits (does NOT push in autonomous mode until end of run)

### Sensitive Data
- **Secrets**: Should not access secrets unless task explicitly requires configuration
- **Credentials**: Should not access credentials files

---

## Notes

- **Default behavior unchanged**: `@acp.proceed` without arguments works exactly as before (single-task)
- **`--complete` implies `--commit`**: There is no autonomous mode without per-task commits
- **Confirmation is mandatory**: Agent MUST show confirmation prompt before autonomous execution
- **No max task limit**: Agent runs until milestone complete or blocker encountered
- **Push only at end**: Commits accumulate locally; agent never pushes during autonomous run
- **Context freshness**: Agent re-reads progress.yaml at start of each task iteration
- **Interruption**: Agent infers user intent from any messages received during autonomous run
- **Error policy**: Halt on any failure, never commit partial work, always seek user guidance
- Task execution may create, modify, or delete files as specified in task documents
- Use `@acp.status` first to see which task is current
- Update progress.yaml manually if command doesn't complete successfully

---

**Namespace**: acp
**Command**: proceed
**Version**: 2.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-28
**Status**: Active
**Compatibility**: ACP 5.0.0+
**Author**: ACP Project
