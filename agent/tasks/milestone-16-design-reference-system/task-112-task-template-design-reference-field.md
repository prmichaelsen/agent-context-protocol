# Task 112: Update Task Template with Design Reference Field

**Milestone**: [M16 - Design Reference System](../../milestones/milestone-16-design-reference-system.md)
**Design Reference**: [Design Reference System](../../design/local.design-reference-system.md)
**Estimated Time**: 1 hour
**Dependencies**: None
**Status**: Not Started

---

## Objective

Add a "Design Reference" metadata field to the task template (`agent/tasks/task-1-{title}.template.md`) so that tasks link back to their source design document for traceability.

---

## Context

Tasks are the unit of work agents implement, but there is currently no link from a task back to the design document it was derived from. Adding a Design Reference field provides traceability and enables `@acp.proceed` to load design context during implementation.

---

## Steps

### 1. Edit the Task Template Metadata Block

Open `agent/tasks/task-1-{title}.template.md` and add a Design Reference field after the Milestone field:

**Current metadata block**:
```markdown
# Task {N}: {Descriptive Task Name}

**Milestone**: [M{N} - Milestone Name](../milestones/milestone-{N}-{name}.md)
**Estimated Time**: [e.g., "2 hours", "4 hours", "1 day"]
**Dependencies**: [List prerequisite tasks, or "None"]
**Status**: Not Started | In Progress | Completed
```

**Updated metadata block**:
```markdown
# Task {N}: {Descriptive Task Name}

**Milestone**: [M{N} - Milestone Name](../milestones/milestone-{N}-{name}.md)
**Design Reference**: [{Design Name}](../design/{namespace}.{design-name}.md) | None
**Estimated Time**: [e.g., "2 hours", "4 hours", "1 day"]
**Dependencies**: [List prerequisite tasks, or "None"]
**Status**: Not Started | In Progress | Completed
```

### 2. Add Template Guidance for the Field

In the template's example/comment section, add guidance:

- When a design document exists for the task's feature: link to it with markdown link syntax
- When no design document exists: set to "None"
- The field is informational — the task should still be self-contained
- The link enables `@acp.proceed` to load additional context during implementation

### 3. Verify No Breaking Changes

- Existing tasks without the field should still work (the field is additive)
- No commands parse this field yet (Task 113 and 114 will add that)
- The field is optional — older tasks without it are fine

---

## Verification

- [ ] Task template (`agent/tasks/task-1-{title}.template.md`) updated with Design Reference field
- [ ] Field is positioned after Milestone, before Estimated Time
- [ ] Field format is: `[{Design Name}](../design/{namespace}.{design-name}.md) | None`
- [ ] Template guidance explains when to use "None" vs a link
- [ ] No existing task files broken by the addition (field is additive/optional)

---

## Expected Output

### Files Modified
- `agent/tasks/task-1-{title}.template.md` — Design Reference field added to metadata block

---

**Next Task**: [Task 113: Update @acp.task-create with Design Cross-Reference](task-113-task-create-design-cross-reference.md)
**Related Design Docs**: [Design Reference System](../../design/local.design-reference-system.md)
