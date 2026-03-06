# Task 110: Implement Yes/No Question Format Preference

**Milestone**: [M15 - Clarification Capture System](../milestones/milestone-15-clarification-capture-system.md)
**Estimated Time**: 1 hour
**Dependencies**: Task 109
**Status**: In Progress

---

## Objective

Update clarification and capture commands to prefer discrete Yes/No questions over "Option A or Option B?" format, making it easier for users to respond with simple "yes/no" instead of "the former/the latter".

---

## Context

User feedback identified that "this or that?" style questions in clarification documents force awkward responses like "the former" or "the latter". Discrete Yes/No questions with agent recommendations are faster to answer and less ambiguous. This applies to both generated clarification documents and inline prompts during capture/conflict resolution.

---

## Steps

### 1. Update Question Generation Guidelines in `acp.clarification-create.md`

Add a guideline to Step 5 (Generate Questions) **Guidelines** section with the following rules:

**Yes/No question preference** — prefer Yes/No format over "Option A or Option B?":
- **Two options, with clear recommendation**: "We recommend X. Acceptable?" (yes/no)
- **Two options, no clear recommendation**: "Do you prefer X? (yes/no)" — state the first option and let the user accept or reject. Do NOT force a recommendation when neither option is clearly better.
- **3+ options**: Use labeled choices (A, B, C, etc.)
- Recommendations are optional — only include one when the agent has enough context to genuinely justify a preference. When in doubt, omit the recommendation and just present the choice.

**Multi-option discrete questions** — when asking about a set of properties/features/items, list each option as a separate bullet with its own `>` response line so the user can accept/reject each individually without retyping:

```markdown
- Which properties should be included?

  - name
  >
  - description
  >
  - version
  >
  - author
  >
```

This lets users answer "yes", "no", or add notes per item inline.

### 2. Update Inline Prompts in `acp.clarification-capture.md`

Update the conflict resolution prompt in Step 4 to use yes/no/custom format instead of (a)/(b)/(c) lettered choices:

```
The more recent answer is "{response B}" (clarification {B}).
Use this? (yes/no/custom)
  yes    → Use clarification {B}
  no     → Use clarification {A}
  custom → Provide a different answer
```

### 3. Verify All Inline Prompts Across Commands

Check that existing inline prompts (partial clarification warnings, uncaptured decisions warnings) already follow yes/no format. Update any that don't.

---

## Verification

- [ ] `acp.clarification-create.md` Step 5 Guidelines includes Yes/No preference guideline
- [ ] `acp.clarification-capture.md` conflict resolution prompt uses yes/no/custom format
- [ ] All inline prompts in capture directive use yes/no where applicable
- [ ] Clarification 7 status updated to Completed

---

## Key Design Decisions

### Question Format

| Decision | Choice | Rationale |
|---|---|---|
| Two-option format | Yes/No | Easier to answer than "the former/the latter" |
| Two options, clear preference | "We recommend X. Acceptable?" (yes/no) | Agent leads with justified recommendation |
| Two options, no clear preference | "Do you prefer X? (yes/no)" | State first option, let user accept/reject — no forced recommendation |
| 3+ option format | Labeled choices (A, B, C) | Current behavior works well |
| Multi-option discrete | Each sub-option gets its own `>` response line | Users can yes/no each item without retyping the list |
| Recommendations | Optional, only when genuinely justified | Do NOT fabricate a recommendation when neither choice is clearly better |

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Affected commands | All clarifications + inline prompts | Consistent UX across all ACP commands |

---

## Notes

- Source: clarification-7-question-format-preferences.md (8 questions, 8 answered)
- Changes are documentation-only (command markdown files), no scripts affected

---

**Next Task**: None (final task in M15)
**Related Design Docs**: agent/design/local.clarification-capture-system.md
