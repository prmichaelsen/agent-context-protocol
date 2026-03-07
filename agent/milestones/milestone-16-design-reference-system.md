# Milestone 16: Design Reference System

**Goal**: Ensure tasks have complete design document coverage so agents can implement from the task alone
**Duration**: 1-2 weeks
**Dependencies**: M15 (Clarification Capture System — provides shared directive pattern)
**Status**: Not Started

---

## Overview

The Design Reference System addresses a critical gap: tasks created by `@acp.task-create` and `@acp.plan` produce shallow summaries that lose implementation detail from design documents. An agent picking up a task cannot faithfully implement the design without also reading the design doc. This milestone introduces `@acp.design-reference` as a shared directive that dynamically discovers design documents, extracts all actionable elements, and ensures they are fully represented in task steps and verification items.

---

## Deliverables

### 1. Shared Directive
- `agent/commands/acp.design-reference.md` — reusable directive for design cross-referencing

### 2. Command Updates
- `@acp.task-create` updated with Step 5.5 invoking the directive
- `@acp.proceed` updated with design context loading step

### 3. Template Updates
- Task template updated with "Design Reference" metadata field

---

## Success Criteria

- [ ] `@acp.design-reference` directive document created with all steps documented
- [ ] Task template includes Design Reference field
- [ ] `@acp.task-create` invokes directive and produces self-contained tasks
- [ ] `@acp.proceed` reads design context before implementation
- [ ] Tasks created after this milestone contain all design elements (steps, args, UX, edge cases, formats, integrations, lifecycle, rationale)

---

## Key Files to Create

```
agent/
├── commands/
│   └── acp.design-reference.md (new — shared directive)
├── tasks/
│   ├── task-1-{title}.template.md (modified — Design Reference field)
│   └── milestone-16-design-reference-system/
│       ├── task-111-design-reference-directive.md
│       ├── task-112-task-template-design-reference-field.md
│       ├── task-113-task-create-design-cross-reference.md
│       └── task-114-proceed-design-context-loading.md
└── commands/
    ├── acp.task-create.md (modified — Step 5.5)
    └── acp.proceed.md (modified — design loading step)
```

---

## Tasks

1. [Task 111: Create @acp.design-reference Shared Directive](../tasks/milestone-16-design-reference-system/task-111-design-reference-directive.md) - Create the reusable directive document
2. [Task 112: Update Task Template with Design Reference Field](../tasks/milestone-16-design-reference-system/task-112-task-template-design-reference-field.md) - Add Design Reference metadata field
3. [Task 113: Update @acp.task-create with Design Cross-Reference](../tasks/milestone-16-design-reference-system/task-113-task-create-design-cross-reference.md) - Add Step 5.5 invoking the directive
4. [Task 114: Update @acp.proceed with Design Context Loading](../tasks/milestone-16-design-reference-system/task-114-proceed-design-context-loading.md) - Add design reading step before implementation

---

## Testing Requirements

- [ ] Task created with design-reference produces self-contained task with all design elements
- [ ] Task created without a design doc warns and proceeds
- [ ] @acp.proceed loads design context when Design Reference field is populated
- [ ] Multiple relevant design docs are all discovered and loaded

---

## Documentation Requirements

- [ ] Design document: agent/design/local.design-reference-system.md (already created)
- [ ] Directive document: agent/commands/acp.design-reference.md

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Keyword matching discovers wrong design docs | Medium | Low | Agent uses topic + milestone context; user can correct |
| Larger task files from embedded detail | Low | High | Acceptable trade-off — completeness > brevity |
| Context window cost from reading design docs | Medium | Medium | Only load relevant docs via keyword filtering |

---

**Next Milestone**: TBD
**Blockers**: None
**Notes**: Future work includes `@acp.task-validate` for retroactive completeness checking (not in this milestone scope)
