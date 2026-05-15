# Command: task-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.task-create` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."
>
> **This is a CREATION command - you will create files directly, no shell scripts needed.**
>
> Follow the steps below to create a task file with proper structure and automatic progress updates.

> **🔌 Driver Override Check** (TOP-OF-FILE — runs BEFORE any other step in this file)
>
> 1. Read `agent/driver.yaml`. If the file does not exist OR there is no `workflows.acp.task-create` mapping, jump to step 5 (fallback to the markdown steps below).
> 2. Look up `bindings.workflow.run` — the MCP tool name this driver uses for workflow dispatch. If the mapping exists but `workflow.run` is unbound, surface a clear configuration error (`"workflows.acp.task-create is mapped but bindings.workflow.run is unset in agent/driver.yaml"`) and STOP.
> 3. Invoke that MCP tool with input `{action: "start", workflow: <mapped-value>, args: <user-arguments-from-this-invocation>}`. The command is now BLOCKED — execute the workflow loop per the canonical pattern (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): follow each returned `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion or termination. The workflow's final output IS this command's output. **STOP. Do NOT execute any of the markdown steps below.**
> 4. **Error handling** (one-shot AND every loop iteration):
>    - If any tool response contains an `"error"` key, surface that message to the user and STOP. Do NOT fall through to the markdown steps below — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule.
> 5. **Fallback (only when `workflows.acp.task-create` is unmapped or `agent/driver.yaml` is absent):** Proceed to the markdown steps below as written — they describe ACP's default behavior for this command.
>
> ⚠️  **The rest of this file is the unbound-case fallback.** If the override block above dispatched a workflow (whether it completed successfully or errored), do NOT also execute the steps below. They are "execute only if step 5 above is the path you took."

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

### 0. Display Command Header

```
⚡ @acp.task-create
  Create task files with proper structure, milestone linking, and automatic progress.yaml updates

  Usage:
    @acp.task-create                               Guided task creation
    @acp.task-create @my-draft.md                  Create from draft file
    @acp.task-create --from-clar <file>            Capture from specific clarification
    @acp.task-create --from-context                Capture from all sources

  Related:
    @acp.pattern-create    Create patterns
    @acp.command-create    Create commands
    @acp.design-create     Create designs
    @acp.proceed           Start working on created task
```

This step is informational only — do not wait for user input.

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
- Directive returns a "Key Design Requirements" markdown section (or nothing if no context)
- Hold the generated section for insertion during Step 6 (Generate Task File)

**Expected Outcome**: Key Design Requirements section generated (if context available), or skipped cleanly  

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
- **Record DR-ID incorporation.** As you extract atomic design units, note their `DR<N>` IDs. If the design uses DR-IDs (look for `\*\*DR\d+[:\s*]` bold-prefix or `### DR\d+:` heading forms), record the specific DR-IDs you intend to inline in the task body. These become the `incorporates:` field in the task's `@scry.entry` marker during Step 6. If the design has no DR-IDs (legacy, pre-v5.41), skip this; validate will warn and suggest backfilling DR-IDs via `@acp.sync`.

**If no design found**: The directive warns and returns empty. Proceed to Step 6 with available context only (user input, draft, clarifications).  

**Expected Outcome**: Design elements extracted and ready for task generation, or skipped cleanly with warning  

### 5.6. Cross-Reference Spec Documents

Discover and extract requirements from any matching spec in `agent/specs/`, using the canonical marker parser script.

**Actions**:
- Check if `agent/specs/` directory exists. If not, skip silently.
- Invoke the marker scanner:
  ```sh
  # Query scry for spec markers (scry-spec v1.0 compliant)
  scry_sql "SELECT id, summary, tags FROM scry__doc WHERE kind = 'spec'"
  ```
  For each spec entry, read its `summary` and `tags` fields. (Fallback if scry is unavailable: scan `agent/specs/*.md` by filename and `## Requirements` sections.)
- Match each spec's `topic:` keywords against the current task's topic (task name + milestone name + design document name from Step 5.5). A spec is a candidate if at least one keyword overlaps.
- **Open only the candidate specs** (typically 1-3 out of however many exist). For each candidate:
  1. Parse the `## Requirements` section verbatim. Each requirement has an ID like `FR1`, `FR2`, ..., `FR<N>`. Extract ID + one-line description.
  2. Parse the `## Behavior Table` / `## Behavior` section if present. Extract scenario rows that belong to this task's scope (match by keywords and by which requirements they cover).
  3. Extract relevant test names from the `## Tests` section.
- Narrow the extracted requirements to those the task should cover. Use judgment: a task about pen pal unlock claims FR10 (pen pal system), FR11 (collectibles), maybe FR12 (adaptive frequency) — NOT every requirement in the spec.
- Produce structured data:
  ```yaml
  spec_path: agent/specs/local.feature-name.md
  claimed_requirements:
    - id: FR10
      description: "Each of 8 regions MUST have one unique pen pal character..."
    - id: FR11
      description: "Each pen pal MUST send themed collectible gifts..."
  claimed_behaviors:
    - name: pen-pal-unlock
      description: "User completes Tier 2 regional quest → pen pal created..."
  ```
- Hold this data for use in Step 6.

**If scry returns no spec entries**: No specs have scry markers. Fall back to scanning `agent/specs/*.md` by filename and `## Requirements` sections, and warn the user that spec markers should be migrated to `@scry.entry` format.

**If no spec matches the task topic**: Skip silently. The `Spec Coverage` section in the task file is omitted entirely (not left as scaffolding). Proceed to Step 6.  

**Expected Outcome**: Spec requirements extracted and scoped to this task, or skipped cleanly when no spec applies. Only relevant spec files were opened — no broad directory scan.  

**Note**: This is a narrower cross-reference than Step 5.5. Designs describe *how*; specs define *what must be true*. Both can exist for the same feature, and both should be consulted.

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
> **🔌 Driver Dispatch — `marker.mint`**
>
> 1. Read `agent/driver.yaml`. If the file does not exist, OR `bindings.marker.mint` is unset, jump to step 4 (fallback to the `@scry.entry` stamping below).
> 2. Invoke the MCP tool named by `bindings.marker.mint` with input: `{kind: "task", context: {milestone_id: "<from earlier in this step>", title: "<from earlier in this step>"}}`. The response is one-shot `{id, marker_open, marker_close, fields: [...]}` (or a workflow handle — handle per Core Principle 6 of `agent/patterns/local.driver-dispatch-directive.md`).
>    - **Filename**: Use the response's `id` verbatim as the new file's basename (e.g., `id: "task.implement-watcher~d8c4a1f7"` → file `task.implement-watcher~d8c4a1f7.md`). Place the file under `agent/tasks/<milestone_id>/` (or `agent/tasks/unassigned/` if no milestone). **Do NOT compute a sequential `task-<N>` filename** — when `marker.mint` is bound, the driver owns the namespace and chooses the canonical id (typically with a uuid suffix for collision avoidance).
>    - For each field with `agent_fills: false`: use the supplied `value` verbatim.
>    - For each field with `agent_fills: true` (implied by `instructions`): read the field's `instructions` and produce a value matching its `type` and `required` constraints (the LLM generates semantic content — summary, rationale, weight, etc.).
>    - Assemble the marker block by comment-wrapping `marker_open` + the fields + `marker_close` for the target language (markdown → `<!-- ... -->`).
>    - Stamp the assembled block at the top of the new task file. **Do NOT also stamp `@scry.entry`** — per DR9, when `marker.mint` is bound, the driver owns the marker vocabulary exclusively.
> 3. **Error handling:**
>    - If the response contains an `"error"` key, surface and STOP. Do NOT fall through to step 4.
>    - If the tool call raises an MCP infrastructure exception, surface and STOP. Same rule.
> 4. **Fallback (only when `bindings.marker.mint` is unset or `agent/driver.yaml` is absent):** Populate the `@scry.entry` marker block as described in the bullet immediately below.

- **Populate the `@scry.entry` marker block at the top** — the template ships with `{placeholder}` values; every one of them MUST be replaced before saving. Use `scry_mint_with_check` with `kind=doc` and `prefix=task.{kebab-task-name}` to get the canonical `id`:
  - `id:` — minted via `scry_mint_with_check` (e.g. `task.implement-auth~a1b2c3d4`)
  - `kind:` — literal `task`
  - `summary:` — user-provided task description from Step 4, one line, <=150 chars
  - `status:` — literal `draft`
  - `weight:` — `0.6` (default for tasks; raise to 0.8 for critical-path tasks)
  - `tags:` — YAML list of `"topic:keyword"` strings derived from task name + milestone name
  - `rationale:` — one sentence explaining why this task is needed (or `""` if not obvious)
  - `applies:` — `""` (tasks are looked up by ID, not by context trigger)
  - `seeded_questions:` — `[]` (or add 1-3 questions that would help a sub-agent)
  - `milestone:` — milestone ID string (e.g. `M10`) from Step 1. If no milestone, omit the line entirely.
  - `spec:` — the spec path from Step 5.6 if a matching spec was found, otherwise OMIT
  - `covers:` — comma-separated FR-IDs from Step 5.6 (e.g. `FR10, FR11, FR12`), otherwise OMIT
  - `design:` — the design path from Step 5.5 if a design was found, otherwise OMIT
  - `incorporates:` — comma-separated DR-IDs from the design that this task actually inlines (e.g. `DR1, DR3, DR7`). When Step 5.5 extracts design content for inlining, record the specific `DR<N>` IDs of the atomic units being copied into the task body. If the design has DR-IDs but none are being inlined, OMIT. If the design has no DR-IDs yet (legacy), OMIT.
  - `depends_on:` — YAML list of task IDs (e.g. `[task-17, task-19]`), otherwise `[]`
  - `updated:` — today's ISO date (`YYYY-MM-DD`)
  - **Do not leave any `{placeholder}` text in the marker block.** An incomplete marker is worse than no marker — it breaks scry parsing.
- Fill in metadata:
  - Task number and name
  - Milestone link
  - **Design Reference**: If Step 5.5 found a design document, link to it: `[{Design Name}](../design/{namespace}.{design-name}.md)`. If none found, set to `None`.
  - Estimated time
  - Do NOT add `**Status**` or `**Dependencies**` prose fields. The marker supersedes them (`status:` and `depends_on:`). Task lifecycle state is in `progress.yaml`.
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
  - **User-Observable Acceptance** — REQUIRED section in every task:
    - Write at least one acceptance criterion describing what a user can observe after the task is done — in a browser session, CLI invocation, API response, or file on disk.
    - Backend-only "it compiles" is not observable. "Tests pass" is not observable. "Table exists with new column" IS observable (via a DB query).
    - If the task genuinely has no user-observable outcome (pure refactor, internal rename, dev tooling, test-only changes), replace the checklist with a single line: `N/A — <one-sentence reason>`. The justification must be >= 10 characters.
    - Feature work should never be N/A. If you are creating a task for a user-visible feature and you find yourself writing N/A, stop and identify the observable effect first.
    - This section is validated by `@acp.proceed` after task completion. Tasks with empty or unjustified N/A will block completion.
  - **Spec Coverage** — CONDITIONAL section:
    - Include this section ONLY if Step 5.6 found a matching spec in `agent/specs/`.
    - Populate it with the spec path and the scoped FR<N> requirements from Step 5.6, copying each requirement's short description verbatim from the spec so the implementing sub-agent has the full requirement text inline:
      ```markdown
      ## Spec Coverage

      **Source**: agent/specs/{namespace}.{name}.md

      Covered requirements:
      - [ ] FR10: Each of 8 regions MUST have one unique pen pal character unlockable via Tier 2 regional quest
      - [ ] FR11: Each pen pal MUST send themed collectible gifts matching their personality
      ...

      Covered behaviors:
      - [ ] pen-pal-unlock: User completes Tier 2 Berlin quest → pen pal created, first letter scheduled
      ...
      ```
    - If no spec was found, OMIT the `## Spec Coverage` section entirely. Do not leave empty scaffolding.
  - If Key Design Requirements section was generated in Step 2.7: Insert it into the task document
  - If Step 5.5 returned design decisions (from the design doc's Key Design Requirements section): Carry relevant decisions into the task's Key Design Requirements section
- Save to appropriate path (milestone subdirectory or unassigned/)

> **🚨 Self-Contained Task Principle (NON-NEGOTIABLE)**:
>
> Sub-agents implementing tasks do not read the design document. They do not read the spec. They do not hunt through the repository for context. They read THIS TASK FILE and only this task file.
>
> That means every snippet, requirement, interface, type signature, SQL schema, example, formula, or edge case that is relevant to this task MUST be inlined into the task document — verbatim — even when it duplicates content that exists elsewhere. Yes, this creates duplication. Yes, that is intentional. Duplication is the cost of sub-agent reliability.
>
> When Step 5.5 returns design elements, copy them into the task. When Step 5.6 returns spec requirements, copy them into the task. Do not link. Do not summarize. Do not say "see design doc for details."
>
> **Verification before saving**: Re-read the generated task and answer: "If I hand this file to a sub-agent who has never seen this project and has no other context, can they implement it correctly?" If the answer is anything less than yes, keep inlining until it is.

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

✓ Task file created
✓ progress.yaml updated
✓ @scry.entry marker populated (verified no {placeholder} text remains)
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
- [ ] `User-Observable Acceptance` section present and populated (at least one criterion OR justified N/A)
- [ ] `Spec Coverage` section present if a matching spec was found in Step 5.6; absent otherwise
- [ ] Spec requirements (when present) copied verbatim from `agent/specs/` — not paraphrased
- [ ] `@scry.entry` marker block fully populated — every `{placeholder}` replaced, `id:` minted via `scry_mint_with_check`, `updated:` is today's date, optional lines (`spec:`, `covers:`, `depends_on:`) omitted if not applicable
- [ ] Scry can parse the marker: `scry_sql "SELECT id, kind, summary FROM scry__doc WHERE id LIKE 'task.%'" ` returns this task's entry

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
