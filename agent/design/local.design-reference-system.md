# Design Reference System

**Concept**: Shared directive ensuring tasks have complete design document coverage so agents can implement from the task alone  
**Created**: 2026-03-07  
**Status**: Design Specification  

---

## Overview

The Design Reference System ensures that tasks created by `@acp.task-create` and `@acp.plan` contain all implementation detail from their source design documents. Currently, task creation produces shallow tasks that summarize designs at a high level, losing critical detail (argument tables, UX specs, edge cases, lifecycle rules). An agent picking up a task cannot faithfully implement the design without also reading the design document — but tasks are the unit of work, not designs.

This system introduces `@acp.design-reference` as a shared directive invoked by `@acp.task-create`, `@acp.plan`, and `@acp.proceed`. It dynamically discovers relevant design documents, extracts actionable elements, and ensures they are fully represented in task steps and verification items.

---

## Problem Statement

### Current Issues

1. **Detail Loss**: Design documents contain 8+ implementation steps, argument tables, UX specifications, and edge cases. Tasks created from them collapse this into 3-4 vague steps.
2. **Non-Self-Contained Tasks**: An agent reading only the task file cannot implement the feature — it must also find and read the design document, which is not referenced or linked.
3. **No Cross-Reference**: `@acp.task-create` has no step to read or cross-reference design documents. It relies on whatever the user or draft provides.
4. **Verification Gaps**: Task verification checklists don't map to design requirements, so completeness cannot be validated.

### Consequences of Not Solving

- Agents produce incomplete implementations that miss design elements
- Users must manually review tasks against designs and request corrections
- Design documents become dead artifacts — written but not consumed during implementation
- Repeated back-and-forth to add missing detail to tasks

---

## Solution

### Shared Directive: `@acp.design-reference`

A reusable directive that commands invoke to discover, read, and cross-reference design documents. It is not a standalone user-facing command — it is called internally by task-create, plan, and proceed.

### Invocation Flow

```
User: @acp.task-create
            |
            +-- Step N: Invoke @acp.design-reference
            |     |
            |     +-- 1. Search agent/design/ for relevant docs (keyword matching)
            |     +-- 2. Read all relevant design documents
            |     +-- 3. Extract actionable design elements
            |     +-- 4. Flag incomplete/vague design areas
            |     +-- 5. Return design elements for task integration
            |
            +-- Step N+1: Generate task with design elements embedded
                  |
                  +-- Task steps include all design implementation detail
                  +-- Verification items map to design requirements
                  +-- Design Reference field links back to source doc
```

### Design Element Extraction

The directive extracts these categories of actionable elements from design documents:

| Category | Description | Example |
|---|---|---|
| Implementation steps/flows | Specific sequences of operations | "8-step directive flow for clarification capture" |
| Argument/parameter tables | Inputs, flags, aliases, behaviors | "`--from-clar`, `--from-clars`, `--from-chat`" |
| UX specifications | Warning messages, prompts, display formats | "Warning text for uncaptured decisions" |
| Edge cases and error handling | Boundary conditions and failure modes | "Partial clarifications with unanswered questions" |
| Format specifications | Output structure, naming conventions | "Decision table: `Decision / Choice / Rationale`" |
| Integration points | Connections to other commands/systems | "Affected commands: design-create, task-create, etc." |
| Lifecycle rules | Status transitions, cleanup behavior | "Update status to Captured; never delete" |
| Decision rationale | Why choices were made | "Shared directive to avoid duplication across 4 commands" |

### Discovery Method

Design documents are discovered dynamically by keyword/topic matching:

1. Determine the task's topic from: milestone name, task name, user description, draft content
2. Search `agent/design/` for files whose names or content match the topic
3. If multiple relevant documents found, read all of them
4. If no design document found, warn the user and skip

No explicit links in progress.yaml are required — discovery is always dynamic.

### Completeness Rule

**Self-Contained Task Principle**: An agent reading ONLY the task file must be able to implement the feature without needing to read the design document.  

This means:
- Task steps must include implementation-level detail, not just summaries
- Argument tables from the design must appear in the task (or be fully described in prose)
- UX specifications (exact warning text, prompt formats) must be in the task
- Edge cases must be covered in task steps or verification items
- The mapping between design elements and task steps can be many-to-many (grouping is fine), but no design element may be omitted

### Incomplete Design Handling

If the design document itself is incomplete or vague:
1. Flag the vague areas to the user
2. Suggest creating a clarification to fill gaps
3. Proceed with available detail if user chooses to continue
4. Note gaps in the task for future resolution

---

## Implementation

### Directive Document: `@acp.design-reference`

Created at `agent/commands/acp.design-reference.md` as a shared directive (not user-invocable).

**Directive Steps**:

1. **Determine topic**: Extract topic keywords from task name, milestone, user description, or draft content
2. **Search for designs**: List `agent/design/` files (excluding templates), match by topic keywords against filenames and first ~50 lines of content
3. **Report findings**:
   ```
   Design Reference: Searching agent/design/...
     Found: local.clarification-capture-system.md (relevant)
     Found: acp-commands-design.md (not relevant, skipped)

     1 design document loaded for cross-reference
   ```
   If none found:
   ```
   Design Reference: No design documents found for topic "{topic}"
     Tasks will be created from available context only.
   ```
4. **Extract design elements**: Parse the design document(s) and extract all actionable elements by category (see table above)
5. **Flag design gaps**: If any section is vague or marked TBD, warn:
   ```
   Design gaps detected in local.clarification-capture-system.md:
     - Testing Strategy: Only scenario names, no detail

   Suggest creating a clarification? (yes/no)
   ```
6. **Return elements**: Pass extracted elements to the calling command for integration into the task

### Affected Commands

| Command | Invokes Directive | How It Uses the Output |
|---|---|---|
| `@acp.task-create` | Yes (new Step 5.5) | Embeds design elements in task steps and verification |
| `@acp.plan` | Yes (via task-create delegation) | Same — plan delegates to task-create which invokes the directive |
| `@acp.proceed` | Yes (new step before implementation) | Reads design doc alongside task for additional context during implementation |

### Task Template Changes

Add a **Design Reference** metadata field to the task template:

```markdown
# Task {N}: {Descriptive Task Name}

**Milestone**: [M{N} - Milestone Name](../milestones/milestone-{N}-{name}.md)  
**Design Reference**: [Design Name](../design/{namespace}.{design-name}.md) | None  
**Estimated Time**: [e.g., "2 hours", "4 hours", "1 day"]  
**Dependencies**: [List prerequisite tasks, or "None"]  
**Status**: Not Started | In Progress | Completed  
```

The Design Reference field:
- Links to the source design document when one exists
- Set to "None" when no design document was found
- Is informational — the task is still self-contained; the link is for traceability

### Changes to `@acp.task-create`

Insert new Step 5.5 between "Process Draft" and "Generate Task File":

**Step 5.5: Cross-Reference Design Documents**

1. Invoke `@acp.design-reference` directive
2. If design elements returned: hold them for Step 6
3. In Step 6, when generating the task file:
   - Expand task steps to include all implementation detail from design elements
   - Ensure argument tables, UX specs, and format specs appear in task steps
   - Map edge cases to verification items
   - Set the Design Reference metadata field
   - Include decision rationale in Key Design Decisions section or inline in steps

### Changes to `@acp.plan`

Step 6 (Create Task Documents) already delegates to `@acp.task-create`. No additional changes needed — task-create will invoke the directive automatically.

### Changes to `@acp.proceed`

Add a step early in the proceed workflow (before implementation begins):

**Step N: Load Design Context**

1. Read the task's Design Reference field
2. If a design document is linked, read it for additional implementation context
3. If no link, invoke `@acp.design-reference` to dynamically search
4. Use design context alongside the task to inform implementation decisions

This is supplementary — the task is still the primary work artifact. The design provides additional "why" context.

---

## Benefits

- **Complete Tasks**: Tasks contain all information needed for implementation
- **Self-Contained Work Units**: Agents implement from the task alone
- **Design Traceability**: Tasks link back to their source design
- **Proactive Gap Detection**: Incomplete designs are flagged before tasks are created
- **No Manual Cross-Reference**: Automated discovery eliminates human verification step

---

## Trade-offs

- **Context Window Cost**: Reading design documents during task creation consumes tokens (mitigated by keyword-based filtering — only relevant designs are loaded)
- **Directive Complexity**: Adds a step to task-create (mitigated by being a single reusable directive)
- **Larger Task Files**: Tasks will be longer with embedded design detail (acceptable — completeness is more valuable than brevity for implementation)

---

## Dependencies

- Existing commands: `task-create`, `plan`, `proceed`
- Task template (`task-1-{title}.template.md`)
- Design documents in `agent/design/`
- `@acp.clarification-capture` (existing shared directive pattern to follow)

---

## Testing Strategy

- **Discovery scenario**: task-create finds the correct design doc by keyword matching
- **No-design scenario**: task-create warns and proceeds when no design found
- **Completeness scenario**: task created from a detailed design contains all design elements in steps/verification
- **Gap detection scenario**: vague design triggers warning and clarification suggestion
- **Multi-design scenario**: multiple relevant designs are all loaded and cross-referenced
- **Proceed scenario**: @acp.proceed reads design reference and uses it during implementation

---

## Migration Path

1. Create `@acp.design-reference` shared directive document
2. Update task template with Design Reference field
3. Update `@acp.task-create` with Step 5.5
4. Update `@acp.proceed` with design context loading step
5. (Future) Create `@acp.task-validate` for retroactive completeness checking

---

## Key Design Decisions

### Architecture

| Decision | Choice | Rationale |
|---|---|---|
| Implementation approach | Shared directive (`@acp.design-reference`) | Reused across task-create, plan, and proceed |
| Discovery method | Dynamic keyword matching | No explicit links needed in progress.yaml; works automatically |
| Design search | Always search when creating tasks | Guard against missing design coverage |

### Completeness

| Decision | Choice | Rationale |
|---|---|---|
| Task self-containment | Fully self-contained | Agent implements from task alone, no design doc reading required |
| Design elements preserved | All categories (steps, args, UX, edge cases, formats, integrations, lifecycle, rationale) | Complete coverage prevents implementation gaps |
| Step granularity | Many-to-many mapping allowed | Grouping related design elements into fewer task steps is acceptable |
| Verification mapping | 1:1 with design requirements | Every design requirement has a verification item |

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Affected commands | task-create, plan (via delegation), proceed | All three interact with design-to-task flow |
| No design found | Warn, then skip | User awareness without blocking task creation |
| Incomplete design | Flag and suggest clarification | Proactive gap detection |

### Template

| Decision | Choice | Rationale |
|---|---|---|
| Template changes | Add Design Reference field | Traceability from task to source design |
| Field value when no design | "None" | Explicit absence marker |

### Future

| Decision | Choice | Rationale |
|---|---|---|
| Retroactive validation | Future `@acp.task-validate` command | Not immediate scope; address after core directive works |

---

## Future Considerations

- **`@acp.task-validate`**: Command to retroactively check existing tasks against their design documents for completeness gaps
- **Design coverage report**: Aggregate view of which design elements are covered by tasks and which are orphaned
- **Bidirectional linking**: Design documents could list which tasks implement them
- **Design versioning**: If a design is updated, tasks could be flagged as potentially stale

---

**Status**: Design Specification  
**Recommendation**: Create milestone and tasks for implementation  
**Related Documents**:
- [Clarification Capture System](local.clarification-capture-system.md) — sister shared directive pattern
- [ACP Commands Design](acp-commands-design.md) — command structure conventions
- Task template: [task-1-{title}.template.md](../tasks/task-1-{title}.template.md)
- Commands: [task-create](../commands/acp.task-create.md), [plan](../commands/acp.plan.md), [proceed](../commands/acp.proceed.md)
