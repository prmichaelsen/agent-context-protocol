# Command: task-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.task-create` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."
>
> **This is a CREATION command - you will create files directly, no shell scripts needed.**
>
> Follow the steps below to create a task file with proper structure and automatic progress updates.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Scripts**: None

---

**Purpose**: Create task files with proper structure, milestone linking, and automatic progress.yaml updates
**Category**: Creation
**Frequency**: As Needed

---

## What This Command Does

This command creates a new task file with proper structure, milestone linking, and automatic updates to progress.yaml. It provides a guided workflow for creating well-structured tasks that follow ACP conventions.

**Key Features**:
- Milestone-aware (links to current or specified milestone)
- Automatic task numbering
- Draft file support with clarification workflow
- Auto-updates progress.yaml with new task
- Uses task-1-{title}.template.md as base

**Use this when**: Creating a new task in an ACP project.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] Task template exists (agent/tasks/task-1-{title}.template.md)
- [ ] progress.yaml exists with at least one milestone
- [ ] (Optional) Draft file prepared if using draft workflow

---

## Arguments

**Context Capture Arguments** (optional — passed to `@acp.clarification-capture` directive):

| Argument | Alias | Behavior |
|---|---|---|
| `--from-clarification <file>` | `--from-clar` | Capture decisions from a specific clarification file |
| `--from-clarifications` | `--from-clars` | Capture from all recent clarifications |
| `--from-chat-context` | `--from-chat` | Capture decisions from chat conversation |
| `--from-context` | (none) | Shorthand for all sources (clarifications + chat) |
| `--include-clarifications` | (none) | Alias for `--from-clars` |

**Default behavior** (no flags): Auto-detect clarifications and context in session.

---

## Steps

### 1. Detect Current Milestone

Determine which milestone this task belongs to:

**Actions**:
- Read progress.yaml
- Identify current milestone (current_milestone field)
- Get milestone details (name, ID)
- Ask user to confirm or select different milestone

**Expected Outcome**: Target milestone identified

### 2. Determine Task Number

Find the next available task number:

**Actions**:
- List all existing task files in agent/tasks/
- Parse task numbers (task-1-*, task-2-*, etc.)
- Find highest number
- Increment by 1 for new task number

**Expected Outcome**: Next task number determined (e.g., task-25)

### 2.5. Read Contextual Key Files

Before creating content, load relevant key files from the index.

**Actions**:
- Check if `agent/index/` directory exists
- If exists, scan for all `*.yaml` files (excluding `*.template.yaml`)
- Filter entries where `applies` includes `acp.task-create`
- Sort by weight descending, read matching files
- Produce visible output

**Note**: If `agent/index/` does not exist, skip silently.

### 2.7. Capture Clarification Context

Invoke the `@acp.clarification-capture` shared directive to capture decisions from clarifications and/or chat context.

**Actions**:
- Read and follow the directive in [`agent/commands/acp.clarification-capture.md`](acp.clarification-capture.md)
- Pass through any `--from-*` arguments from this command's invocation
- If no `--from-*` flags specified: auto-detect clarifications in session (default behavior)
- If uncaptured clarifications detected, show warning and ask user whether to include
- Directive returns a "Key Design Decisions" markdown section (or nothing if no context)
- Hold the generated section for insertion during Step 6 (Generate Task File)

**Expected Outcome**: Key Design Decisions section generated (if context available), or skipped cleanly

### 3. Check for Draft File

Check if draft file was provided as argument:

**Syntax**:
- `@acp.task-create @my-draft.md` (@ reference)
- `@acp.task-create agent/drafts/my-draft.md` (path)
- `@acp.task-create` (no draft)

**Actions**:
- If draft provided: Read draft file
- If no draft: Proceed to Step 4

**Expected Outcome**: Draft file read (if provided)

### 4. Collect Task Information

Gather information from user via chat:

**Information to Collect**:
- **Task name** (descriptive, without "Task N:" prefix)
  - Example: "Implement User Authentication" (not "Task 25: Implement User Authentication")
  - Validation: Clear, action-oriented
- **Task description** (objective - what this task accomplishes)
  - Example: "Implement Firebase Authentication with email/password and Google sign-in"
- **Estimated time** (hours or days)
  - Example: "4-6 hours" or "2 days"
- **Dependencies** (other tasks that must complete first)
  - Example: "Task 24" or "None"
- **Context** (background information)
  - Example: "Authentication is required before implementing user-scoped data"

**If no draft provided**:
- Ask: "Describe what you want this task to accomplish" OR
- Offer: "Would you like to create an empty draft file first?"

**Expected Outcome**: All task metadata collected

### 5. Process Draft (If Provided)

If draft file was provided, create clarification if needed:

**Actions**:
- Analyze draft for clarity and completeness
- If draft is clear and complete: Skip clarification, use draft content
- If draft is ambiguous: Create clarification document
  - Find next clarification number
  - Create `agent/clarifications/clarification-{N}-task-{name}.md`
  - Generate questions about unclear aspects
  - Wait for user to answer clarification
  - Read answered clarification

**Expected Outcome**: Clarification created and answered (if needed)

### 5.5. Cross-Reference Design Documents

Invoke the `@acp.design-reference` shared directive to discover and extract design document context.

**Actions**:
- Read and follow the directive in [`agent/commands/acp.design-reference.md`](acp.design-reference.md)
- Pass context from this command:
  - `topic_keywords`: Keywords from task name and milestone name
  - `milestone_name`: Current milestone name (from Step 1)
  - `user_description`: User's task description (from Step 4)
  - `draft_content`: Draft file content (from Step 3, if provided)
- The directive will:
  1. Search `agent/design/` for relevant documents by keyword matching
  2. Report what was found/skipped
  3. Extract design elements across 8 categories (implementation steps, argument tables, UX specs, edge cases, format specs, integration points, lifecycle rules, decision rationale)
  4. Flag any design gaps (suggest clarification if needed)
  5. Return structured data: design elements, gaps, and paths
- Hold the returned design elements for use in Step 6

**If no design found**: The directive warns and returns empty. Proceed to Step 6 with available context only (user input, draft, clarifications).

**Expected Outcome**: Design elements extracted and ready for task generation, or skipped cleanly with warning

### 6. Generate Task File

Create task file from template:

**Actions**:
- Determine full filename and path:
  - If milestone assigned: `milestone-{N}-{title}/task-{M}-{name}.md`
  - If no milestone: `unassigned/task-{M}-{name}.md`
  - N = milestone number, M = task number from Step 2
  - name = kebab-case version of task name
- Create milestone subdirectory if it doesn't exist
- Copy from task template (agent/tasks/task-1-{title}.template.md)
- Fill in metadata:
  - Task number and name
  - Milestone link
  - **Design Reference**: If Step 5.5 found a design document, link to it: `[{Design Name}](../design/{namespace}.{design-name}.md)`. If none found, set to `None`.
  - Estimated time
  - Dependencies
  - Status: "Not Started"
- Fill in sections:
  - Objective (from collected info)
  - Context (from collected info or draft)
  - **Steps** — must include implementation-level detail:
    - Each step should be concrete and actionable, not a vague summary
    - Include specific sub-steps for complex operations
    - If Step 5.5 returned design elements, integrate them:
      - Preserve argument/parameter tables from the design — include verbatim or as detailed prose
      - Preserve UX specifications — exact warning text, prompt formats, display output
      - Preserve format specifications — output structure, naming conventions, file format rules
      - Include integration points — which other commands/systems are affected and how
      - Include lifecycle rules — status transitions, cleanup behavior, ordering constraints
      - Include decision rationale inline where it aids implementation
    - If the design describes N distinct operations, the task should have corresponding steps covering all N (grouping related operations into fewer steps is acceptable, but no operation may be omitted)
  - **Verification checklist** — must cover every design requirement:
    - One verification item per design requirement from the design document
    - Include edge cases from the design (partial data, conflicts, empty state, missing files)
    - Include format verification (output matches specified format)
    - Include integration verification (affected commands updated correctly)
    - If the design has a Testing Strategy section, map each test scenario to a verification item
  - If Key Design Decisions section was generated in Step 2.7: Insert it into the task document
  - If Step 5.5 returned design decisions (from the design doc's Key Design Decisions section): Carry relevant decisions into the task's Key Design Decisions section
- Save to appropriate path (milestone subdirectory or unassigned/)

> **Self-Contained Task Principle**: After generating the task, verify that an agent reading ONLY this task file could implement the feature without needing to read the design document. If any design element is missing from the task, add it before saving.

**Note**: Older tasks may use flat structure (`agent/tasks/task-{N}-{name}.md`) for historical reasons. New tasks should use milestone subdirectories.

**Expected Outcome**: Task file created in milestone subdirectory with complete design coverage

### 7. Update progress.yaml

Add task to progress.yaml:

**Actions**:
- Read progress.yaml
- Find the milestone section (e.g., milestone_4)
- Add new task entry:
  ```yaml
  - id: task-{N}
    name: {Task Name}
    status: not_started
    started: null
    file: agent/tasks/milestone-{N}-{title}/task-{M}-{name}.md
    estimated_hours: {hours}
    actual_hours: null
    completed_date: null
    notes: |
      {Brief description or empty}
  ```
- Update milestone tasks_total count
- Save progress.yaml

**Expected Outcome**: progress.yaml updated with new task

### 8. Prompt to Delete Draft (If Used)

If draft file was used, ask to delete it:

**Actions**:
- Ask: "Would you like to delete the draft file? (yes/no)"
- If yes: Delete draft file
- If no: Keep draft file

**Expected Outcome**: User chooses whether to keep draft

### 9. Report Success

Display what was created:

**Output**:
```
✅ Task Created Successfully!

File: agent/tasks/milestone-{N}-{title}/task-{M}-{name}.md
Task Number: {M}
Milestone: M{X} - {Milestone Name}
Estimated Time: {hours}
Status: Not Started

✓ Task file created
✓ progress.yaml updated
✓ Draft file deleted (if requested)

Next steps:
- Review and refine task steps
- Add verification items
- Start working with @acp.proceed
```

**Expected Outcome**: User knows task was created successfully

### 10. Prompt to Add to Key File Index

After successful creation, offer to add the new file to the index (if `agent/index/` exists).

**Display**:
```
Would you like to add this to the key file index?
  - Yes, add to agent/index/local.main.yaml
  - No, skip
```

If yes, prompt for weight, description, rationale, and applies values. Add entry to `agent/index/local.main.yaml`.

**Note**: Skip silently if `agent/index/` does not exist.

---

## Verification

- [ ] Current milestone identified
- [ ] Next task number determined correctly
- [ ] Task information collected
- [ ] Draft processed (if provided)
- [ ] Task file created with correct number and name
- [ ] progress.yaml updated with new task
- [ ] Milestone tasks_total incremented
- [ ] Task follows template structure
- [ ] All metadata filled in correctly
- [ ] Task linked to correct milestone

---

## Expected Output

### Files Created
- `agent/tasks/milestone-{N}-{title}/task-{M}-{name}.md` - Task file (in milestone subdirectory)
- `agent/tasks/unassigned/task-{M}-{name}.md` - Task file (if no milestone assigned)
- `agent/clarifications/clarification-{N}-task-{name}.md` - Clarification (if draft was ambiguous)

### Files Modified
- `agent/progress.yaml` - Task added to milestone section

**Note**: Older tasks may exist in flat structure (`agent/tasks/task-{N}-{name}.md`) for historical reasons.

---

## Examples

### Example 1: Creating Task for Current Milestone

**Context**: Working on Milestone 3, need to add a new task

**Invocation**: `@acp.task-create`

**Interaction**:
```
Agent: Current milestone: M3 - ACP Package Management System
Agent: Create task for this milestone? (yes/no)
User: yes

Agent: What would you like to name your task?
User: Implement Package Search Command

Agent: Provide a description (what this task accomplishes):
User: Create @acp.package-search command to discover ACP packages via GitHub API

Agent: Estimated time? (e.g., "4 hours", "2 days")
User: 6-8 hours

Agent: Dependencies? (other task numbers or "None")
User: Task 10

Agent: Any additional context?
User: Needs GitHub API integration for repository search

✅ Task Created Successfully!

File: agent/tasks/milestone-3-package-management/task-11-package-search-command.md
Task Number: 11
Milestone: M3 - ACP Package Management System
Estimated Time: 6-8 hours
Status: Not Started

✓ Task file created
✓ progress.yaml updated
```

### Example 2: Creating Task with Draft

**Context**: Have draft file describing task

**Invocation**: `@acp.task-create @my-task-draft.md`

**Result**: Reads draft, creates clarification if needed, generates task, updates progress.yaml

### Example 3: Creating Task for Different Milestone

**Context**: Want to add task to future milestone

**Invocation**: `@acp.task-create`

**Interaction**:
```
Agent: Current milestone: M3 - ACP Package Management System
Agent: Create task for this milestone? (yes/no)
User: no

Agent: Available milestones:
  - M1: ACP Commands Infrastructure (completed)
  - M2: Documentation & Utility Commands (completed)
  - M3: ACP Package Management System (in progress)
  - M4: Package Development System (not started)

Agent: Which milestone? (enter ID like "M4")
User: M4

[Continues with task creation for M4...]
```

---

## Related Commands

- [`@acp.pattern-create`](acp.pattern-create.md) - Create patterns
- [`@acp.command-create`](acp.command-create.md) - Create commands
- [`@acp.design-create`](acp.design-create.md) - Create designs
- [`@acp.proceed`](acp.proceed.md) - Start working on created task

---

## Troubleshooting

### Issue 1: No milestones found

**Symptom**: Error message "No milestones found in progress.yaml"

**Solution**: Create a milestone first using milestone template, or add milestone to progress.yaml manually

### Issue 2: Invalid task name

**Symptom**: Task name rejected

**Solution**: Use descriptive, action-oriented names. Avoid special characters except hyphens.

### Issue 3: progress.yaml update failed

**Symptom**: Error updating progress.yaml

**Solution**: Verify progress.yaml exists and is valid YAML. Check milestone section exists for target milestone.

### Issue 4: Task number conflict

**Symptom**: Task file already exists with that number

**Solution**: Command should auto-detect and use next available number. If conflict persists, manually check agent/tasks/ directory.

---

## Security Considerations

### File Access
- **Reads**: progress.yaml, draft files, task templates, milestone documents
- **Writes**: agent/tasks/task-{N}-{name}.md, progress.yaml
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in tasks
- **Credentials**: Never include credentials

---

## Notes

- Task name should be action-oriented (start with verb)
- Task number is automatically assigned (sequential)
- Tasks are always created as "Not Started" status
- Draft files can be any format (free-form markdown)
- Clarifications are created only if draft is ambiguous
- progress.yaml is automatically updated
- Task is linked to milestone via file path and progress.yaml entry
- Estimated time helps with milestone planning

---

**Namespace**: acp
**Command**: task-create
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 2.10.0+
**Author**: ACP Project
