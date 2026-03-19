# Task 114: Update @acp.proceed with Design Context Loading

**Milestone**: [M16 - Design Reference System](../../milestones/milestone-16-design-reference-system.md)  
**Design Reference**: [Design Reference System](../../design/local.design-reference-system.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 111 (directive must exist), Task 112 (template field must exist)  
**Status**: Not Started  

---

## Objective

Update `agent/commands/acp.proceed.md` to load design document context before implementation begins. When a task has a Design Reference field, proceed should read the linked design document for additional "why" context. When no link exists, proceed should dynamically search using `@acp.design-reference`.

---

## Context

Even with self-contained tasks, the design document provides valuable supplementary context — especially the "why" behind decisions, alternative approaches considered, and trade-offs. Loading this context during implementation helps agents make better decisions when they encounter ambiguity or edge cases not explicitly covered in the task.

This is supplementary — the task remains the primary work artifact. The design provides additional context, not replacement detail.

---

## Steps

### 1. Read @acp.proceed to Understand Current Structure

Read `agent/commands/acp.proceed.md` to identify where to insert the new step. The design loading should happen early in the workflow — after the task is identified but before implementation begins.

### 2. Add Step: Load Design Context

Insert a new step in `@acp.proceed` at the appropriate point (after task identification, before implementation):

**Step N: Load Design Context**

Document the following actions:

1. **Check Design Reference field**: Read the current task file's metadata for the Design Reference field
   - If field contains a markdown link: extract the path and read that design document
   - If field is "None": invoke `@acp.design-reference` directive to dynamically search
   - If field is missing (older task without the field): invoke `@acp.design-reference` directive to dynamically search

2. **Read design document**: If a design document was found (via link or search):
   - Read the full document
   - Note key sections: Solution, Implementation, Key Design Decisions, Trade-offs
   - Hold this context for use during implementation

3. **Report**:

   **When design loaded**:
   ```
   Design Context: Loaded local.design-reference-system.md
     Sections: Solution, Implementation, Key Design Decisions, Trade-offs
     Use as supplementary context during implementation.
   ```

   **When no design found**:
   ```
   Design Context: No design document found for this task.
     Implementing from task file only.
   ```

4. **Usage during implementation**: The design context informs implementation decisions when:
   - The task step is ambiguous about approach
   - An edge case arises not explicitly covered in the task
   - The agent needs to understand "why" a particular approach was chosen
   - Integration with other systems requires understanding the broader architecture

### 3. Document Relationship to Self-Contained Tasks

Add a note clarifying the relationship:

> **Note**: Tasks should be self-contained — an agent should be able to implement from the task alone. The design document provides supplementary "why" context and helps with edge cases not explicitly covered. If the task is missing critical implementation detail that exists in the design, that indicates a task creation gap (see `@acp.design-reference` directive for how task-create prevents this).

### 4. Handle Autonomous Mode (`--complete`)

If `@acp.proceed` is running in autonomous mode (`--complete` flag):
- Still load design context (no user interaction needed)
- Skip the dynamic search if no Design Reference field (to avoid unnecessary context window usage in autonomous mode)
- Only use the explicit link if present

---

## Verification

- [ ] New step added to `@acp.proceed` after task identification, before implementation
- [ ] Step checks Design Reference field first (explicit link)
- [ ] Step falls back to `@acp.design-reference` directive for dynamic search when field is "None" or missing
- [ ] Report format documented for both "loaded" and "not found" cases
- [ ] Usage guidance explains when to consult design context during implementation
- [ ] Note clarifies relationship to self-contained tasks
- [ ] Autonomous mode (`--complete`) behavior documented — uses explicit link only, skips dynamic search
- [ ] No breaking changes to existing proceed behavior (step is additive)

---

## Expected Output

### Files Modified
- `agent/commands/acp.proceed.md` — design context loading step added

---

**Next Task**: None (last task in M16)  
**Related Design Docs**: [Design Reference System](../../design/local.design-reference-system.md)  
