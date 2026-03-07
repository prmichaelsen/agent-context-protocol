# Task 113: Update @acp.task-create with Design Cross-Reference

**Milestone**: [M16 - Design Reference System](../../milestones/milestone-16-design-reference-system.md)
**Design Reference**: [Design Reference System](../../design/local.design-reference-system.md)
**Estimated Time**: 3-4 hours
**Dependencies**: Task 111 (directive must exist), Task 112 (template must have field)
**Status**: Not Started

---

## Objective

Update `agent/commands/acp.task-create.md` to invoke the `@acp.design-reference` shared directive, ensuring generated tasks contain all implementation detail from relevant design documents.

---

## Context

`@acp.task-create` currently generates tasks from user input, drafts, and clarifications — but never reads design documents. This results in shallow tasks that miss argument tables, UX specs, edge cases, and other design detail. After this change, task-create will automatically discover and cross-reference design documents, embedding all actionable elements in the task.

Since `@acp.plan` delegates to `@acp.task-create` for task creation, this change also fixes plan-generated tasks.

---

## Steps

### 1. Add Step 5.5: Cross-Reference Design Documents

Insert a new step between Step 5 ("Process Draft") and Step 6 ("Generate Task File") in `agent/commands/acp.task-create.md`:

**Step 5.5: Cross-Reference Design Documents**

Document the following actions:

1. Invoke `@acp.design-reference` directive:
   - Pass topic keywords from: task name, milestone name, user description, draft content
   - Read and follow the directive in `agent/commands/acp.design-reference.md`

2. If design elements returned: hold them for Step 6

3. If no design found: the directive will warn; proceed with available context

**Expected Outcome**: Design elements extracted and ready for task generation (or skipped cleanly with warning)

### 2. Update Step 6: Generate Task File — Metadata Section

Add instruction to set the Design Reference field:

- If `@acp.design-reference` found a design document: set to markdown link
  - Format: `[{Design Name}](../design/{namespace}.{design-name}.md)`
- If no design found: set to `None`

### 3. Update Step 6: Generate Task File — Steps Section

Replace the current vague "Steps (from draft/clarification or template structure)" bullet with detailed instructions:

**Updated Steps generation instructions**:
- Steps must include implementation-level detail from design documents (Step 5.5)
- Each step should be concrete and actionable, not a vague summary
- Include specific sub-steps for complex operations
- Preserve argument tables from the design — include them verbatim or as detailed prose in the relevant step
- Preserve UX specifications — exact warning text, prompt formats, display output must appear in the step that implements them
- Preserve format specifications — output structure, naming conventions, file format rules
- Include integration points — which other commands/systems are affected and how
- Include lifecycle rules — status transitions, cleanup behavior, ordering constraints
- If the design describes N distinct operations, the task should have corresponding steps covering all N (grouping related operations into fewer steps is acceptable, but no operation may be omitted)
- Include decision rationale inline where it aids implementation (e.g., "Use shared directive approach to avoid duplication across 4 commands")

### 4. Update Step 6: Generate Task File — Verification Section

Replace the current generic verification guidance with:

**Updated Verification generation instructions**:
- One verification item per design requirement
- Include edge cases from the design (partial data, conflicts, empty state, missing files)
- Include format verification (output matches specified format)
- Include integration verification (affected commands updated correctly)
- If the design has a Testing Strategy section, map each test scenario to a verification item

### 5. Update Step 6: Generate Task File — Key Design Decisions

Add instruction:
- If the design document has a Key Design Decisions section, carry relevant decisions into the task's Key Design Decisions section
- Focus on decisions that directly affect this task's implementation
- Use the same table format: `Decision | Choice | Rationale`

### 6. Add Self-Containment Check Note

Add a note to Step 6:

> **Self-Contained Task Principle**: After generating the task, verify that an agent reading ONLY this task file could implement the feature without needing to read the design document. If any design element is missing from the task, add it before saving.

---

## Verification

- [ ] Step 5.5 added to `acp.task-create.md` between Step 5 and Step 6
- [ ] Step 5.5 references `@acp.design-reference` directive by path
- [ ] Step 5.5 documents passing topic keywords from task name, milestone, description, draft
- [ ] Step 5.5 documents both "found" and "not found" outcomes
- [ ] Step 6 metadata instructions include Design Reference field population
- [ ] Step 6 steps instructions require implementation-level detail from design
- [ ] Step 6 steps instructions require preserving argument tables verbatim
- [ ] Step 6 steps instructions require preserving UX specs (exact warning text, prompts)
- [ ] Step 6 steps instructions require preserving format specifications
- [ ] Step 6 steps instructions require including integration points and lifecycle rules
- [ ] Step 6 steps instructions prohibit omitting design operations (grouping OK, omission not OK)
- [ ] Step 6 verification instructions require 1:1 mapping with design requirements
- [ ] Step 6 verification instructions require edge case coverage
- [ ] Step 6 Key Design Decisions instructions carry relevant decisions from design
- [ ] Self-Containment Check note added
- [ ] Plan delegates to task-create, so no separate plan changes needed

---

## Expected Output

### Files Modified
- `agent/commands/acp.task-create.md` — Step 5.5 added, Step 6 strengthened

---

**Next Task**: [Task 114: Update @acp.proceed with Design Context Loading](task-114-proceed-design-context-loading.md)
**Related Design Docs**: [Design Reference System](../../design/local.design-reference-system.md)
