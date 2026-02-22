# Command: proceed

> **🤖 CRITICAL AGENT DIRECTIVE**: You are reading this file because `@acp.proceed` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."
>
> **YOU MUST IMMEDIATELY BEGIN IMPLEMENTING THE CURRENT OR NEXT TASK.**
>
> **DO NOT**:
> - ❌ Provide status reports or summaries
> - ❌ Ask about session size, cost, or token limits
> - ❌ Suggest pushing commits or taking breaks
> - ❌ End with "ready to proceed" or similar passive statements
>
> **DO**:
> - ✅ Read the task document
> - ✅ START IMPLEMENTING immediately
> - ✅ Create files, write code, make changes
> - ✅ Complete the task or make substantial progress
> - ✅ Update progress.yaml when done
>
> **This is an ACTION command, not a STATUS command.**

**Namespace**: acp
**Version**: 1.1.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-18
**Status**: Active

---

**Purpose**: IMMEDIATELY implement the current or next task - NO DELAYS, NO REPORTS, JUST ACTION
**Category**: Workflow
**Frequency**: As Needed

---

## What This Command Does

**THIS IS AN IMPLEMENTATION COMMAND.**

When you invoke `@acp.proceed`, you are commanding the agent to:
1. Find the current/next task
2. **IMMEDIATELY START IMPLEMENTING IT**
3. Write code, create files, make changes
4. Complete the task or make substantial progress
5. Update progress tracking

**This is NOT a status command.** Do not confuse this with `@acp.status`. The purpose of `@acp.proceed` is to **DO WORK**, not report on work.

**Agent Behavior**:
- Read task document
- Start implementing within the same response
- Create files, write code, execute commands
- Make real progress on the task
- Only stop when task is complete or substantial progress made
- Update progress.yaml with what was accomplished

**Forbidden Behaviors**:
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

## Steps

### 🚨 CRITICAL: These are IMPLEMENTATION steps, not planning steps

### 1. Identify Current Task (30 seconds max)

**Actions**:
- Read `agent/progress.yaml`
- Find first task with status `in_progress` or `not_started`
- Read the task document

**DO NOT spend time analyzing or planning. MOVE TO STEP 2 IMMEDIATELY.**

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

### 4. Update Progress Tracking

**Only after implementing**, update `agent/progress.yaml`:
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

## Verification

- [ ] Current task identified from progress.yaml
- [ ] Task document read and understood
- [ ] Prerequisites checked
- [ ] All task steps executed
- [ ] Verification checklist completed
- [ ] progress.yaml updated with completion
- [ ] Milestone progress percentage updated
- [ ] Recent work entry added
- [ ] Next task identified

---

## Expected Output

### Files Modified
- `agent/progress.yaml` - Task marked complete, progress updated, recent work added
- Task-specific files (as defined in task document)

### Console Output
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

Executing task steps...

✅ Step 1: Created service layer classes
✅ Step 2: Implemented data access methods
✅ Step 3: Added error handling
✅ Step 4: Wrote unit tests

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Verification:
✅ All service classes created
✅ Unit tests pass
✅ TypeScript compiles without errors
✅ Code follows project patterns

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

### Status Update
- Task status: `not_started` → `completed`
- Milestone progress: 40% → 60%
- Tasks completed: 2 → 3

---

## Examples

### Example 1: Continuing Current Task

**Context**: You're in the middle of task-3 and want to continue working on it

**Invocation**: `@acp-proceed`

**Result**: Loads task-3, shows remaining steps, guides you through completion, updates progress when done

### Example 2: Starting Next Task

**Context**: Just finished task-2, ready to start task-3

**Invocation**: `@acp-proceed`

**Result**: Identifies task-3 as next, loads task document, guides through all steps, marks complete when done

### Example 3: Task with Blockers

**Context**: Task has unmet prerequisites

**Invocation**: `@acp-proceed`

**Result**: Identifies missing prerequisites, reports blockers, suggests resolution steps, does not proceed until resolved

---

## Related Commands

- [`@acp-init`](acp.init.md) - Use before proceeding to ensure full context loaded
- [`@acp-status`](acp.status.md) - Use to check which task is current before proceeding
- [`@acp-update`](acp.update.md) - Use to manually update progress if needed
- [`@acp-sync`](acp.sync.md) - Use after completing tasks to sync documentation

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

**Solution**: Complete prerequisite tasks first, or resolve the dependencies, then run `@acp-proceed` again

### Issue 4: Verification fails

**Symptom**: Some verification items don't pass

**Cause**: Task steps weren't completed correctly or there are errors

**Solution**: Review the failed verification items, fix issues, then re-run verification steps

---

## Security Considerations

### File Access
- **Reads**: `agent/progress.yaml`, current task document, related design documents
- **Writes**: `agent/progress.yaml` (updates task status and progress), task-specific files as defined in task document
- **Executes**: May execute commands as specified in task steps (e.g., `npm test`, `npm run build`)

### Network Access
- **APIs**: May make API calls if task requires it
- **Repositories**: May interact with git if task requires it

### Sensitive Data
- **Secrets**: Should not access secrets unless task explicitly requires configuration
- **Credentials**: Should not access credentials files

---

## Notes

- This command modifies `agent/progress.yaml` to track progress
- Task execution may create, modify, or delete files as specified in the task document
- Always review task steps before proceeding to understand what will be done
- Use `@acp-status` first to see which task is current
- If task is complex, consider breaking it into smaller steps
- Update progress.yaml manually if command doesn't complete successfully

---

**Namespace**: acp
**Command**: proceed
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.0.3+
**Author**: ACP Project
