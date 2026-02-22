# Command: plan

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.plan` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-22
**Last Updated**: 2026-02-22
**Status**: Active

---

**Purpose**: Plan milestones OR tasks for undefined items in progress.yaml or new requirements
**Category**: Workflow
**Frequency**: As Needed

---

## Arguments

This command supports both CLI-style and natural language arguments:

**CLI-Style Arguments**:
- `--batch` or `--all` - Plan all undefined items without prompting
- `--milestone <id>` - Plan specific milestone
- `--task <id>` - Plan specific task
- `--draft <path>` - Use specific draft file

**Natural Language Arguments**:
- `@acp.plan for milestone 6` - Plan specific milestone
- `@acp.plan all undefined tasks` - Batch mode
- `@acp.plan @my-draft.md` - Use draft file
- `@acp.plan new feature: user authentication` - Inline requirements

**Argument Mapping**:
Arguments are inferred from chat context. The agent will:
1. Parse explicit CLI-style flags if present
2. Extract intent from natural language
3. Ask for clarification if ambiguous
4. Default to interactive mode if unclear

---

## What This Command Does

This command helps agents systematically plan project milestones and tasks. It scans [`agent/progress.yaml`](../progress.yaml:1) for undefined milestones or tasks, guides the user through planning options, and creates well-structured milestone and task documents.

**Key Features**:
- Automatic detection of undefined milestones/tasks in progress.yaml
- Support for design document creation (structured or unstructured drafts)
- Clarification workflow for ambiguous requirements
- Invokes `@acp.design-create`, `@acp.task-create` as subroutines
- Automatic progress.yaml updates
- Flexible workflow (iterative or batch planning)

**Use this when**:
- Starting a new project phase and need to plan milestones
- Breaking down a milestone into tasks
- Have new requirements to plan for
- Need to fill gaps in project roadmap

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/progress.yaml` exists
- [ ] Templates exist (milestone, task, design, clarification)
- [ ] (Optional) Draft files prepared for requirements

---

## Steps

### 1. Scan for Undefined Planning Items

Automatically scan progress.yaml for items needing planning:

**Actions**:
- Read [`agent/progress.yaml`](../progress.yaml:1)
- Check for undefined milestones:
  - Milestone ID exists in progress.yaml but no `milestone-{N}-{name}.md` file
  - Milestone has no tasks defined in progress.yaml
- Check for undefined tasks:
  - Task ID exists in progress.yaml but no `task-{N}-{name}.md` file
  - Task has minimal notes (just one-liner)
- Prioritize milestones over tasks (but use conversation context to determine user intent)

**Expected Outcome**: List of undefined items identified

### 2. Present Planning Options

Show user what can be planned and offer choices:

**If undefined items found**:
```
📋 Planning Items Detected:

Undefined Milestones:
  • M6: Advanced Features (no milestone document)
  • M7: Production Deployment (no tasks defined)

Undefined Tasks:
  • Task 42: API Integration (no task document)
  • Task 43: Performance Optimization (minimal notes)

Options:
  1. Plan specific milestone (choose from list)
  2. Plan specific task (choose from list)
  3. Plan all undefined items (batch mode)
  4. Plan something new (provide requirements)

What would you like to plan?
```

**If no undefined items**:
```
✅ All milestones and tasks in progress.yaml are defined.

Options:
  1. Create a new milestone (provide requirements)
  2. Refine existing plans (review and enhance existing milestone/task documents)
  3. Create a design document first (unstructured draft or structured draft)
  4. Create a requirements document first (unstructured draft or structured draft)
  5. Provide requirements in chat (immediate planning without drafts)

What would you like to do?
```

**Expected Outcome**: User selects planning path

### 3. Gather Requirements

Based on user selection, gather requirements:

**Option A: Design Document First**
- Ask: "Structured draft (with questions) or unstructured draft (free-form)?"
- If structured: Create `agent/drafts/{requirement-title}-design.draft.md` with 3 key questions:
  1. **What problem does this solve?** (Problem statement)
  2. **What is the proposed solution?** (High-level approach)
  3. **What are the key technical decisions?** (Architecture, patterns, trade-offs)
- If unstructured: Create empty `agent/drafts/{requirement-title}-feature.draft.md` or `agent/design/{requirement-title}-feature.draft.md`
- Wait for user to fill draft
- Read completed draft
- Create full design document from draft responses

**Option B: Requirements Document First**
- Ask: "Structured draft (with questions) or unstructured draft (free-form)?"
- If structured: Create `agent/drafts/{requirement-title}-requirements.draft.md` with 3 key questions:
  1. **What should the system do?** (Functional requirements)
  2. **What are the constraints?** (Technical, business, resource constraints)
  3. **What defines success?** (Success criteria, acceptance criteria)
- If unstructured: Create empty `agent/drafts/{requirement-title}-requirements.draft.md`
- Wait for user to fill draft
- Read completed draft
- Create full requirements document from draft responses

**Option C: Milestone Document First**
- Ask: "Structured draft (with questions) or unstructured draft (free-form)?"
- If structured: Create `agent/drafts/milestone-{N}-{title}.draft.md` with 3 key questions:
  1. **What is the goal of this milestone?** (Objective, what will be accomplished)
  2. **What are the key deliverables?** (Concrete outputs, features, artifacts)
  3. **How will we know it's complete?** (Success criteria, verification)
- If unstructured: Create empty `agent/drafts/milestone-{N}-{title}.draft.md`
- Wait for user to fill draft
- Read completed draft
- Create milestone document from draft responses

**Option D: Task Document First**
- Ask: "Structured draft (with questions) or unstructured draft (free-form)?"
- If structured: Create `agent/drafts/task-{N}-{title}.draft.md` with 3 key questions:
  1. **What needs to be done?** (Objective, specific actions)
  2. **What are the steps?** (Implementation steps, order of operations)
  3. **How do we verify it works?** (Verification checklist, acceptance criteria)
- If unstructured: Create empty `agent/drafts/task-{N}-{title}.draft.md`
- Wait for user to fill draft
- Read completed draft
- Create task document from draft responses

**Option E: Requirements in Chat**
- Ask: "Describe the feature/requirement you want to plan for"
- Collect requirements via conversation
- If requirements unclear, request chat clarification or offer to create clarification document
- Wait for clarification responses

**Option F: Point to Existing Draft**
- Support syntax: `@acp.plan @agent/drafts/my-feature.draft.md`
- Read draft file
- If ambiguous, request chat clarification or offer to create clarification


**Expected Outcome**: Requirements gathered and clarified

### 4. Determine Planning Scope

Decide what to create based on requirements:

**Actions**:
- Analyze requirements complexity
- Determine if single milestone or multiple milestones needed
- Estimate number of tasks per milestone
- Ask user: "This looks like {N} milestone(s) with ~{M} tasks each. Sound good, or prefer more granular/broader tasks?"
- Confirm planning scope

**Expected Outcome**: Planning scope agreed upon

### 5. Create Milestone Documents

For each milestone to plan:

**Actions**:
- Determine milestone number (find highest M{N} in progress.yaml and increment)
- Invoke `@acp.design-create` if design document needed (ask user)
- Create milestone document using template or invoke `@acp.milestone-create`
- Fill in:
  - Goal and overview
  - Deliverables
  - Success criteria
  - Estimated duration (calculate from task estimates)
- Save to `agent/milestones/milestone-{N}-{name}.md`
- Add to progress.yaml milestones section

**Expected Outcome**: Milestone document(s) created

### 6. Create Task Documents

For each task in milestone:

**Actions**:
- Determine task number (find highest task-{N} across ALL milestones and increment)
- Invoke `@acp.task-create` for each task (follows its routine)
- Tasks created in: `agent/tasks/milestone-{N}-{title}/task-{M}-{title}.md`
- **New Structure**: Tasks grouped by milestone folder
- For orphaned tasks (no milestone): Use `agent/tasks/unassigned/task-{M}-{title}.md`
- Each task includes:
  - Objective
  - Context
  - Steps
  - Verification checklist
  - Dependencies (auto-detected or user-provided)
  - Estimated hours (AI-suggested, user can adjust)
- Add each task to progress.yaml under appropriate milestone section

**Expected Outcome**: Task documents created and organized by milestone

### 7. Update progress.yaml

Update progress tracking with new planning items:

**Actions**:
- Add milestones to milestones array (with complete metadata)
- Add tasks to appropriate milestone_N sections
- Update milestone tasks_total counts
- Calculate estimated_weeks from task hour estimates
- Update next_steps with new planning items
- Do NOT update current_milestone (that's for implementation, not planning)

**Expected Outcome**: progress.yaml fully updated

### 8. Generate Planning Report

Create visual summary of what was planned:

**Output**:
```
✅ Planning Complete!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestones Created:
  📋 M6: Advanced Features (3 weeks, 8 tasks)
      └── agent/milestones/milestone-6-advanced-features.md
  
  📋 M7: Production Deployment (2 weeks, 5 tasks)
      └── agent/milestones/milestone-7-production-deployment.md

Tasks Created (13 total):
  M6: Advanced Features
    ├── Task 42: API Integration (4-6 hours)
    │   └── agent/tasks/milestone-6-advanced-features/task-42-api-integration.md
    ├── Task 43: Performance Optimization (3-4 hours)
    │   └── agent/tasks/milestone-6-advanced-features/task-43-performance-optimization.md
    └── [6 more tasks...]
  
  M7: Production Deployment
    ├── Task 50: CI/CD Pipeline (6-8 hours)
    │   └── agent/tasks/milestone-7-production-deployment/task-50-cicd-pipeline.md
    └── [4 more tasks...]

Files Created:
  ✓ 2 milestone documents
  ✓ 13 task documents
  ✓ 1 design document (optional)
  ✓ progress.yaml updated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next Steps:
  • Review milestone and task documents
  • Refine task steps and verification items
  • Run @acp.validate to check consistency
  • Run @acp.proceed to start first task
  • Run @acp.sync to update related documentation (optional)
```

**Expected Outcome**: User understands what was created

### 9. Offer Next Actions

Prompt user for next action:

**Options**:
- `@acp.proceed` - Start implementing first task
- `@acp.plan` - Continue planning (if more to plan)
- `@acp.validate` - Validate planning consistency
- `@acp.sync` - Sync documentation with new plans
- Review and refine manually

**Expected Outcome**: User chooses next action

---

## Verification

- [ ] progress.yaml scanned for undefined items
- [ ] Planning options presented to user
- [ ] Requirements gathered (draft, chat, or clarification)
- [ ] Planning scope determined and confirmed
- [ ] Milestone documents created (if applicable)
- [ ] Task documents created in milestone folders
- [ ] Orphaned tasks placed in unassigned/ folder
- [ ] progress.yaml updated with all new items
- [ ] Planning report generated
- [ ] Next actions offered

---

## Expected Output

### Files Created

**Milestones**:
- `agent/milestones/milestone-{N}-{name}.md` (one or more)

**Tasks** (new structure):
- `agent/tasks/milestone-{N}-{title}/task-{M}-{title}.md` (tasks grouped by milestone)
- `agent/tasks/unassigned/task-{M}-{title}.md` (orphaned tasks)

**Optional**:
- `agent/design/{requirement-title}-{feature|design|requirements}.md` (if design created)
- `agent/drafts/{requirement-title}-{feature|design|requirements}.draft.md` (if draft created)
- `agent/clarifications/clarification-{N}-{title}.md` (if clarification needed)

### Files Modified

- `agent/progress.yaml` - Milestones and tasks added

---

## Examples

### Example 1: Planning Undefined Milestone

**Context**: M6 exists in progress.yaml but no milestone document

**Invocation**: `@acp.plan`

**Result**:
```
📋 Found undefined milestone: M6 - Advanced Features

Would you like to:
  1. Create design document first
  2. Create milestone document directly
  3. Provide requirements in chat

User: 2

Creating milestone document...

What are the key deliverables for M6?
User: API integration, caching system, performance monitoring

How many weeks estimated?
User: 3 weeks

✅ Milestone Created!
File: agent/milestones/milestone-6-advanced-features.md

Would you like to break this into tasks now? (yes/no)
User: yes

[Proceeds to create tasks...]
```

### Example 2: Planning with Draft File

**Context**: Have requirements draft prepared

**Invocation**: `@acp.plan @agent/drafts/auth-feature.draft.md`

**Result**: Reads draft, creates clarification if needed, generates milestone and tasks, updates progress.yaml

### Example 3: Batch Planning

**Context**: Multiple undefined items

**Invocation**: `@acp.plan --all`

**Result**: Plans all undefined milestones and tasks without prompting, generates report

### Example 4: New Feature Planning

**Context**: No undefined items, want to plan new feature

**Invocation**: `@acp.plan`

**Result**:
```
✅ All current items are defined.

What would you like to plan?
  1. New milestone
  2. Refine existing plans
  3. Create design document

User: 1

Describe the new feature/milestone:
User: Add real-time collaboration features

Would you like to:
  a) Create structured requirements draft (with questions)
  b) Create unstructured draft (free-form)
  c) Provide details in chat now

User: c

[Collects requirements in chat, creates milestone and tasks...]
```

---

## Related Commands

- [`@acp.task-create`](acp.task-create.md) - Create individual tasks (invoked as subroutine)
- [`@acp.design-create`](acp.design-create.md) - Create design documents (invoked as subroutine)
- [`@acp.proceed`](acp.proceed.md) - Start implementing planned tasks
- [`@acp.validate`](acp.validate.md) - Validate planning consistency
- [`@acp.sync`](acp.sync.md) - Sync documentation after planning
- [`@acp.status`](acp.status.md) - Check current project status

---

## Troubleshooting

### Issue 1: No milestones in progress.yaml

**Symptom**: Error "No milestones found"

**Solution**: Guide user through creating first milestone. Offer to create default milestone structure or collect requirements in chat.

### Issue 2: Ambiguous requirements

**Symptom**: Cannot determine full requirements for a requested plan item

**Solution**: Create clarification document to gather missing details. Inform user this takes longer but yields better results.

### Issue 3: Task numbering conflicts

**Symptom**: Task numbers overlap or have gaps

**Solution**: Agent auto-detects highest task number across ALL milestones and increments. Gaps are acceptable.

### Issue 4: Milestone numbering gaps

**Symptom**: M1, M2, M5 exist but M3, M4 missing

**Solution**: Prompt user to either fill gaps or continue with M6. Offer options to refine requirements, create drafts, or skip to more defined milestones.

---

## Security Considerations

### File Access
- **Reads**: progress.yaml, draft files, templates, existing milestones/tasks, design documents
- **Writes**: milestone documents, task documents, progress.yaml, design documents (if created), clarifications (if needed)
- **Executes**: None (invokes other @acp commands as subroutines)

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in planning documents
- **Credentials**: Never include credentials

---

## Notes

- **New Task Structure**: Tasks now organized in `agent/tasks/milestone-{N}-{title}/task-{M}-{title}.md`
- **Orphaned Tasks**: Tasks without milestone go in `agent/tasks/unassigned/task-{M}-{title}.md`
- **Task Numbering**: Sequential across ALL milestones (M2: T1-T2, M3: T3-T5, etc.)
- **Milestone Priority**: Generally prioritized over tasks, but agent uses context to determine intent
- **Subroutine Pattern**: Invokes `@acp.milestone-create`, `@acp.task-create`, `@acp.design-create` to ensure consistent structure
- **No current_milestone Update**: Planning updates next_steps, not current_milestone (which is for implementation)
- **Validation**: Defer to `@acp.validate` for consistency checking (offer to run before or after planning)
- **Context Window**: If >20% used, suggest `@acp.report` → new session → `@acp.resume`

### Estimation Guidelines

**Dev Hours vs Agent Hours**:
- Default estimates are in human dev hours (industry standard)
- If user asks about agent time/cost/tokens, provide agent-specific estimates
- Agent can complete tasks faster than estimates suggest (estimates are conservative)
- Use historical performance from recent_work to inform agent hour estimates

**Task Granularity**:
- Agent suggests task size based on complexity
- User can request "more granular" or "broader scope"
- Typical range: 2-4 hours per task (moderate granularity)
- Adjust based on user preference

### Dependency Detection

Dependencies may be inferred from:
- progress.yaml (existing task relationships)
- Existing milestones and tasks
- Design documents
- Requirements documents
- Related patterns
- Conversation context
- Recent reports
- Clarifications

**Dependency Expression**:
- If task undefined: "Task 24"
- If task defined but no document: "Task 24: Pre-Commit Hook System"
- If task document exists: "[Task 24](../tasks/milestone-4-package-development/task-24-precommit-hook-system.md)"

---

**Namespace**: acp
**Command**: plan
**Version**: 1.0.0
**Created**: 2026-02-22
**Last Updated**: 2026-02-22
**Status**: Active
**Compatibility**: ACP 3.7.3+
**Author**: ACP Project
