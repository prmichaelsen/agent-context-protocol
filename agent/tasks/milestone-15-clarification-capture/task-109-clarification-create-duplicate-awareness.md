# Task 109: Add Duplicate Awareness to @acp.clarification-create

**Milestone**: M15 - Clarification Capture System
**Status**: Not Started
**Estimated Time**: 1-2 hours
**Dependencies**: None

---

## Objective

Update `@acp.clarification-create` to check existing clarification files and avoid generating duplicate questions that have already been answered in other clarifications.

---

## Context

When creating a new clarification, the command should be aware of existing clarifications to avoid asking the same questions. This saves user time and prevents redundant decision-making.

---

## Steps

1. Update `agent/commands/acp.clarification-create.md`:
   - Add a new step after "Determine Next Clarification Number"
   - Step: "Check Existing Clarifications for Overlap"
   - List files in `agent/clarifications/` (non-template)
   - Infer from titles which might be relevant to the current topic
   - Only load clarifications that seem relevant (avoid context token burn)
   - When generating questions, cross-reference with existing answered questions
   - Skip or note questions already answered elsewhere
2. Document the heuristic: title-based relevance check, not exhaustive content scan
3. Add visible output showing which existing clarifications were checked

---

## Verification

- [ ] `acp.clarification-create.md` updated with duplicate-awareness step
- [ ] Step uses title-based heuristic for relevance (not exhaustive loading)
- [ ] Visible output shows which clarifications were checked
- [ ] Duplicate questions are avoided or flagged
