# Task 108: Integrate Capture Directive into Create Commands

**Milestone**: M15 - Clarification Capture System  
**Status**: Not Started  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 106, Task 107  

---

## Objective

Update `design-create`, `task-create`, `pattern-create`, and `command-create` to invoke the `@acp.clarification-capture` shared directive, supporting `--from-clar`, `--from-chat`, and `--from-context` arguments.

---

## Context

Each create command needs a new step that invokes the shared capture directive. The step should appear after context detection and key file reading, but before entity file generation. The default behavior (no flags) is auto-detect.

---

## Steps

1. Update `agent/commands/acp.design-create.md`:
   - Add Arguments section with `--from-clar`, `--from-clars`, `--from-chat`, `--from-context` support
   - Add step "Capture Clarification Context" referencing `@acp.clarification-capture` directive
   - Place step after "Read Contextual Key Files" and before "Collect Design Information"
   - Document default auto-detect behavior
2. Update `agent/commands/acp.task-create.md` (same pattern)
3. Update `agent/commands/acp.pattern-create.md` (same pattern)
4. Update `agent/commands/acp.command-create.md` (same pattern)
5. Ensure each command's "Generate File" step includes the Key Design Decisions section when context is available
6. Ensure each command's expected output mentions clarification capture when applicable

---

## Verification

- [ ] `acp.design-create.md` updated with capture step and arguments
- [ ] `acp.task-create.md` updated with capture step and arguments
- [ ] `acp.pattern-create.md` updated with capture step and arguments
- [ ] `acp.command-create.md` updated with capture step and arguments
- [ ] All four commands reference the shared directive consistently
- [ ] Default auto-detect behavior documented in each command
- [ ] Warning UX for uncaptured decisions present in each command
