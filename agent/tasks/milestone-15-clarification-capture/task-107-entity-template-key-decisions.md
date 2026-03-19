# Task 107: Update Entity Templates with Key Design Decisions Section

**Milestone**: M15 - Clarification Capture System  
**Status**: Not Started  
**Estimated Time**: 1-2 hours  
**Dependencies**: Task 106  

---

## Objective

Add an optional "Key Design Decisions" section to all entity templates that support clarification capture: design, task, pattern, and command templates.

---

## Context

The Key Design Decisions section provides a permanent home for design rationale captured from ephemeral clarification files. It uses category-grouped summary tables.

---

## Steps

1. Update `agent/design/design.template.md` - add optional Key Design Decisions section
2. Update `agent/tasks/task-1-{title}.template.md` - add optional Key Design Decisions section
3. Update `agent/patterns/pattern.template.md` - add optional Key Design Decisions section
4. Update `agent/commands/command.template.md` - add optional Key Design Decisions section
5. Section format in each template:
   ```markdown
   ## Key Design Decisions (Optional)

   <!-- This section is populated by @acp.clarification-capture when
        create commands are invoked with --from-clar, --from-chat, or
        --from-context. It can also be manually authored.

        Group decisions by agent-inferred category using tables:
        | Decision | Choice | Rationale |
   -->
   ```
6. Mark section as optional (agent decides whether to include based on available context)

---

## Verification

- [ ] design.template.md updated with optional Key Design Decisions section
- [ ] task template updated with optional Key Design Decisions section
- [ ] pattern.template.md updated with optional Key Design Decisions section
- [ ] command.template.md updated with optional Key Design Decisions section
- [ ] Section clearly marked as optional
- [ ] Format matches design spec (category-grouped tables, no clar references)
