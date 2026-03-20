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
> **If autonomous arguments detected (`--complete`, `--auto`, `--autonomous`, `--finish-milestone`, `--turbo`, `--yolo`, or natural language like "finish milestone", "just finish everything", "complete all tasks"):**
> - Follow **Autonomous Mode** section.
> - If `--yes`, `--turbo`, or `--yolo` is present, skip the confirmation prompt (A2).
> - If `--this` is present (or implied by `--turbo`/`--yolo`), use the task from chat context rather than scanning progress.yaml.
> - If `--parallel` is present (or implied by `--turbo`/`--yolo`), spin up sub-agents on separate worktrees.
> - If `--noworktreemerge` / `--holdmerge` / `--safemerge` / `--safe` is present, do NOT auto-merge worktrees; prompt user before each merge (see A10).
> - Do NOT start implementing individual tasks until confirmation is received (unless `--yes`).
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

### Targeting Flags

| Flag | Description |
|------|-------------|
| `--this` | Work on the task already in chat context or implied by the current conversation, rather than scanning progress.yaml for the next task |

### Execution Flags

| Flag | Description |
|------|-------------|
| `--parallel` | Spin up sub-agents on separate git worktrees to work on tasks concurrently |
| `--yes` | Skip the confirmation prompt (A2) and begin execution immediately |
| `--dry-run` | Preview what tasks would be completed without executing |
| `--noworktreemerge` | Do not auto-merge worktrees when sub-agents complete; prompt for permission before each merge (see A10) |

#### `--noworktreemerge` Aliases (all equivalent)

| Flag | Description |
|------|-------------|
| `--noworktreemerge` | Canonical form |
| `--holdmerge` | Short form — "hold the merge until I say go" |
| `--safemerge` | Emphasizes safety of sequential merging |
| `--safe` | Shortest form — not overloaded, well-documented |

### Combo Flags

| Flag | Description |
|------|-------------|
| `--turbo` | Shorthand for `--auto --this --parallel --yes` |
| `--yolo` | Same as `--turbo` |

**`--turbo` / `--yolo` expand to**: autonomous mode, targeting the current/contextual task, parallel worktree sub-agents, no confirmation prompt.  

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
| `@acp.proceed --turbo` | Autonomous (parallel, no confirm, contextual task) |
| `@acp.proceed --yolo` | Same as `--turbo` |
| `@acp.proceed --yolo --safe` | Autonomous parallel, but prompt before each worktree merge |
| `@acp.proceed --yolo hold merge` | Same as `--yolo --safe` (NLP) |
| `@acp.proceed --yolo wait before merging` | Same as `--yolo --safe` (NLP) |
| `@acp.proceed` | Single-Task (default) |

**Matching rules**:
- Look for keywords: `complete`, `finish`, `auto`, `autonomous`, `all tasks`, `everything`, `milestone`, `turbo`, `yolo`
- Look for `--noworktreemerge` keywords: `safe`, `hold merge`, `wait before merging`, `pause before merge`, `defer merge`, `don't auto-merge`, `gate merge`, `prompt before merge`, `no auto merge`
- Be generous with matching — if the user's intent is clearly "do everything", enter autonomous mode
- When in doubt, **always show the confirmation prompt** before starting autonomous execution
- Never enter autonomous mode silently — the confirmation gate is mandatory

### Flag Combinations

| Combination | Behavior |
|-------------|----------|
| `--complete` | Autonomous completion with per-task commits |
| `--complete --yes` | Autonomous completion, skip confirmation prompt |
| `--complete --parallel` | Autonomous completion with parallel worktree sub-agents |
| `--complete --this` | Autonomous completion starting from contextual task |
| `--turbo` / `--yolo` | `--auto --this --parallel --yes` (full autonomous, no confirm, parallel, contextual) |
| `--yolo --safe` | Full autonomous parallel, but prompt user before each worktree merge |
| `--complete --parallel --safe` | Autonomous parallel with merge gating |
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

**🚨 MANDATORY STATUS UPDATES (do these NOW, not later):**
- **Task status**: If task status is `not_started`, set it to `in_progress` in progress.yaml immediately
- **Task `started`**: If the task's `started` field is `null` or missing, set it to the current ISO 8601 timestamp (e.g., `2026-03-20T10:30:00Z`). Do NOT overwrite an existing `started` value.
- **Milestone status**: If the milestone's `status` is `not_started`, set it to `in_progress` immediately
- **Milestone `started`**: If the milestone's `started` field is `null` or missing, set it to today's date (e.g., `2026-03-20`). Do NOT overwrite an existing `started` value.

These updates MUST be written to progress.yaml before moving to Step 2. Do not defer them.

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

### 1.7. Load Design Context

Load the design document for supplementary implementation context.

**Actions**:
- Check the current task file's metadata for the **Design Reference** field
  - If field contains a markdown link (e.g., `[Design Name](../design/local.feature.md)`): Extract the path and read that design document
  - If field is `None`: Invoke `@acp.design-reference` directive ([`agent/commands/acp.design-reference.md`](acp.design-reference.md)) to dynamically search by topic keywords from the task name and milestone
  - If field is missing (older task without the field): Invoke `@acp.design-reference` directive to dynamically search
- If a design document was found, read it and note key sections: Solution, Implementation, Key Design Decisions, Trade-offs
- Hold this context for use during implementation

**Display**:

When design loaded:
```
Design Context: Loaded local.design-reference-system.md
  Sections: Solution, Implementation, Key Design Decisions, Trade-offs
  Use as supplementary context during implementation.
```

When no design found:
```
Design Context: No design document found for this task.
  Implementing from task file only.
```

**Usage during implementation**: The design context informs implementation decisions when:  
- The task step is ambiguous about approach
- An edge case arises not explicitly covered in the task
- The agent needs to understand "why" a particular approach was chosen
- Integration with other systems requires understanding the broader architecture

> **Note**: Tasks should be self-contained — an agent should be able to implement from the task alone. The design document provides supplementary "why" context and helps with edge cases not explicitly covered. If the task is missing critical implementation detail that exists in the design, that indicates a task creation gap (see `@acp.design-reference` directive for how task-create prevents this).

**Do NOT spend excessive time here — read quickly and move to implementation.**

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

**🚨 MANDATORY TASK UPDATES:**
- Mark task `status` as `completed` (if done) or leave as `in_progress` (if partial)
- **Set `completed_date`** to the current ISO 8601 timestamp (e.g., `2026-03-20T14:45:00Z`). This is MANDATORY for completed tasks.
- **Auto-compute `actual_hours`**: If both `started` and `completed_date` are set, calculate `actual_hours = (completed_date - started)` in hours, rounded to 1 decimal place. If `started` is missing, set `actual_hours` to `null`.
- Increment `tasks_completed` on the milestone

**🚨 MANDATORY MILESTONE UPDATES:**
- Update milestone `progress` percentage: `(tasks_completed / tasks_total) * 100`
- **If this was the LAST task in the milestone** (all tasks now completed):
  - Set milestone `status` to `completed`
  - Set milestone `completed` to today's date (e.g., `2026-03-20`)
  - Set milestone `progress` to `100`
  - Update `current_milestone` to the next incomplete milestone (if any)

**Additional updates:**
- Add `recent_work` entry describing what was IMPLEMENTED
- Update `next_steps`

**Do NOT skip timestamp or status updates. Every completed task MUST have a `completed_date`. Every completed milestone MUST have a `completed` date.**

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

  2. READ task document, key files, and design context
     - Re-read progress.yaml at start of each iteration (context freshness)
     - Set task `status` to `in_progress` and set task `started` timestamp if null — IMMEDIATELY
     - If milestone `status` is `not_started`, set it to `in_progress` and set milestone `started` to today's date — IMMEDIATELY
     - Write these updates to progress.yaml NOW before continuing
     - Read contextual key files from agent/index/ (filter by acp.proceed applies)
     - Read the task file
     - Load design context: If task has Design Reference field with a link, read that
       design document. If field is "None" or missing, skip dynamic search in autonomous
       mode (to conserve context window). Use explicit link only.

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

  6. UPDATE progress tracking (🚨 ALL fields mandatory — do not skip any)
     - Mark task `status` as `completed`
     - Set `completed_date` to current ISO 8601 timestamp — MANDATORY
     - If `started` is `null` or missing, set `started` to current timestamp (same as completed_date)
     - Auto-compute `actual_hours` from `(completed_date - started)` in hours
     - Increment milestone `tasks_completed`
     - Update milestone `progress` percentage: `(tasks_completed / tasks_total) * 100`
     - If this was the LAST task: set milestone `status` to `completed`, set milestone `completed` to today's date, update `current_milestone` to next incomplete milestone
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

### A10. Worktree Merge Gating (`--noworktreemerge` / `--safe`)

When `--noworktreemerge` (or any alias: `--holdmerge`, `--safemerge`, `--safe`) is active, the agent **does NOT auto-merge worktrees** when sub-agents complete. Instead, it queues completed worktrees and prompts the user before each merge.

**Why this exists**: When multiple Claude CLI instances run `--yolo` in parallel across overlapping feature areas, concurrent worktree merges create destructive conflicts. Git worktree merges involve intensive, relatively destructive commands — two inflight merges will constantly collide, produce spurious merge conflicts, and leave each agent seeing state that is inconsistent with its context. `--safe` ensures only one merge happens at a time, controlled by the user.

**Behavior**:

1. **Sub-agents work normally** on their worktrees — no change to task execution
2. **When a sub-agent completes**, instead of immediately merging:
   - Mark the worktree as `merge-ready` in the agent's internal tracking
   - Display a notification:
     ```
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
       Worktree ready to merge (--safe mode)

       Task {id}: {name}
       Branch: {worktree-branch}
       Files changed: {N}

       Other agents may be running. Merge when ready:
         → Reply "merge" to merge this worktree now
         → Reply "merge all" to merge all ready worktrees
         → Reply "skip" to defer this merge

       Pending merges: {N} ready, {N} still running
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     ```
3. **Wait for user permission** before executing any merge
4. **On "merge"**: Execute the worktree merge for the specified task, then report result
5. **On "merge all"**: Merge all `merge-ready` worktrees sequentially (one at a time, in completion order)
6. **On "skip"**: Leave the worktree unmerged; user can merge manually or later

**Without `--safe`** (default `--parallel` behavior): worktrees auto-merge as soon as each sub-agent completes. This is fine when only one agent is running, but risky with concurrent agents.

**`--safe` does NOT change**:
- How sub-agents are spawned or how they work
- The task loop, commit flow, or progress tracking
- The confirmation prompt (A2) or summary report (A6)

**`--safe` only gates the final worktree-to-main merge step.**

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

### Example 7: Yolo with Safe Merge (Multiple Agents)

**Context**: You have 3 Claude CLI instances working on different milestones. You want parallel worktree execution but need to control when merges happen to avoid collisions.

**Invocation**: `@acp.proceed --yolo --safe`

**Result**: Sub-agents spin up on worktrees and work in parallel. When each finishes, instead of auto-merging, the agent notifies you and waits. You reply "merge" when no other agent is mid-merge, ensuring clean sequential merges.

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
