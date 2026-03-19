# Milestone 15: Clarification Capture System

**Status**: Not Started  
**Started**: null  
**Completed**: null  
**Estimated Duration**: 1-2 weeks  

---

## Goal

Implement the Clarification Capture System — a shared directive (`@acp.clarification-capture`) that enables create commands to capture decisions from ephemeral clarification files into permanent entity documents. This prevents loss of design rationale when clarifications (which are not committed to version control) are cleaned up or lost between sessions.

---

## Deliverables

1. `@acp.clarification-capture` shared directive document
2. "Key Design Decisions" optional section added to entity templates (design, task, pattern, command)
3. Updated create commands (design-create, task-create, pattern-create, command-create) referencing the shared directive
4. `--from-clar`, `--from-clars`, `--from-chat`, `--from-context` argument support in create commands
5. Auto-detect and warning when uncaptured clarifications exist in session
6. Clarification status update to "Captured" after successful capture
7. Duplicate-awareness in `@acp.clarification-create`

---

## Success Criteria

- [ ] `@acp.clarification-capture` directive document exists and is referenced by create commands
- [ ] Entity templates include optional "Key Design Decisions" section
- [ ] `@acp.design-create --from-clar` produces entity doc with populated Key Design Decisions table
- [ ] Auto-detect mode (no flags) discovers and offers to capture session clarifications
- [ ] Conflict resolution prompts user when multiple clarifications disagree
- [ ] Partial clarification warning works (unanswered questions flagged)
- [ ] Clarification status updated to "Captured" after capture
- [ ] `@acp.clarification-create` checks existing clarifications to avoid duplicate questions
- [ ] No clarification file references appear in captured output (ephemeral design)

---

## Tasks

| Task | Name | Est. Hours | Status |
|------|------|-----------|--------|
| 106 | Create @acp.clarification-capture Directive | 3-4h | Not Started |
| 107 | Update Entity Templates with Key Design Decisions Section | 1-2h | Not Started |
| 108 | Integrate Capture Directive into Create Commands | 3-4h | Not Started |
| 109 | Add Duplicate Awareness to @acp.clarification-create | 1-2h | Not Started |

---

## Dependencies

- Existing create commands (design-create, task-create, pattern-create, command-create)
- Existing clarification template and workflow
- Design: agent/design/local.clarification-capture-system.md

---

## Design Document

- [Clarification Capture System](../design/local.clarification-capture-system.md)

---

## Notes

- This is a pure LLM-directive feature — no shell scripts needed
- All changes are to markdown command/template files
- Clarifications remain ephemeral and untracked by design
- The "Key Design Decisions" section format uses category-grouped tables with Decision/Choice/Rationale columns
