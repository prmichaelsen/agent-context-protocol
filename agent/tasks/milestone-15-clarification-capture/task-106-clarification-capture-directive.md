# Task 106: Create @acp.clarification-capture Directive

**Milestone**: M15 - Clarification Capture System  
**Status**: Not Started  
**Estimated Time**: 3-4 hours  
**Dependencies**: None  

---

## Objective

Create the `@acp.clarification-capture` shared directive document. This is not a user-facing command but a reusable directive that create commands invoke to gather and embed clarification context into entity documents.

---

## Context

Clarifications are ephemeral workflow files that capture design decisions but are never committed. The capture directive provides a standardized process for extracting these decisions and embedding them in permanent entity documents.

---

## Steps

1. Create `agent/commands/acp.clarification-capture.md` as a shared directive (not user-invocable)
2. Define the directive steps:
   - Detect context sources (check `--from-clar`, `--from-clars`, `--from-chat`, `--from-context` args)
   - Default behavior: auto-detect clarifications in session (implicit `--from-context`)
   - Read clarification files from `agent/clarifications/` (non-template, status Completed/Awaiting Responses)
   - Warn about partial clarifications (unanswered questions)
   - Resolve conflicts between multiple clarifications (flag for user, accept "most recent wins")
   - Synthesize decisions into category-grouped tables (`Decision | Choice | Rationale`)
   - Categories are agent-inferred, not predefined
   - No clarification file references in output (clarifications are ephemeral)
   - Generate "Key Design Decisions" markdown section
   - Update captured clarification status to "Captured"
3. Define the warning UX for uncaptured decisions detected in session
4. Document argument table with all `--from-*` variants and aliases

---

## Verification

- [ ] Directive document created at `agent/commands/acp.clarification-capture.md`
- [ ] All directive steps documented clearly
- [ ] Argument table complete with all variants
- [ ] Conflict resolution flow documented
- [ ] Warning UX for uncaptured decisions specified
- [ ] Document marked as shared directive (not user-invocable)
