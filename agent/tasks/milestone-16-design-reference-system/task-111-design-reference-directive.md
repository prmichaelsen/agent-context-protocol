# Task 111: Create @acp.design-reference Shared Directive

**Milestone**: [M16 - Design Reference System](../../milestones/milestone-16-design-reference-system.md)  
**Design Reference**: [Design Reference System](../../design/local.design-reference-system.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Create the `@acp.design-reference` shared directive document at `agent/commands/acp.design-reference.md`. This is not a user-facing command but a reusable directive that `@acp.task-create`, `@acp.plan`, and `@acp.proceed` invoke to discover and cross-reference design documents, ensuring tasks contain all implementation detail.

---

## Context

Currently, task creation commands have no mechanism to discover or read design documents. Tasks are generated from user input, drafts, or clarifications — but not from the design docs that define the feature. This directive fills that gap by providing a standardized process for finding relevant designs, extracting actionable elements, and passing them to the calling command.

This follows the same shared directive pattern as `@acp.clarification-capture` (created in M15).

---

## Steps

### 1. Create the Directive File

Create `agent/commands/acp.design-reference.md` with the following structure:

- Mark as shared directive (not user-invocable) in the header
- Include the standard agent directive preamble
- Namespace: `acp`, Version: `1.0.0`, Status: Active
- Category: Shared Directive

### 2. Define Step 1: Determine Topic

The directive extracts topic keywords from the calling context:

- **From task-create**: task name, milestone name, user description, draft content
- **From proceed**: task name, milestone name, task objective
- Combine keywords into a search query (e.g., "clarification capture system")

### 3. Define Step 2: Search for Design Documents

Search `agent/design/` for relevant documents:

- List all files in `agent/design/` excluding `*.template.md`
- Match filenames against topic keywords (e.g., "clarification-capture" matches `local.clarification-capture-system.md`)
- For borderline matches, read first ~50 lines of content to check relevance
- If multiple relevant documents found, read all of them
- Sort by relevance (filename match > content match)

### 4. Define Step 3: Report Findings

Display what was found using this exact format:

**When designs found**:
```
Design Reference: Searching agent/design/...
  Found: local.clarification-capture-system.md (relevant)
  Found: acp-commands-design.md (not relevant, skipped)

  1 design document loaded for cross-reference
```

**When no designs found**:
```
Design Reference: No design documents found for topic "{topic}"
  Tasks will be created from available context only.
```

### 5. Define Step 4: Extract Design Elements

Parse the design document(s) and extract all actionable elements organized by these categories:

| Category | What to Extract |
|---|---|
| Implementation steps/flows | Specific sequences of operations, numbered steps, flow diagrams |
| Argument/parameter tables | Inputs, flags, aliases, behaviors — preserve exact table format |
| UX specifications | Warning messages, prompt text, display formats — preserve exact text |
| Edge cases and error handling | Boundary conditions, failure modes, what-if scenarios |
| Format specifications | Output structure, naming conventions, file format rules |
| Integration points | Connections to other commands/systems, affected commands tables |
| Lifecycle rules | Status transitions, cleanup behavior, ordering constraints |
| Decision rationale | Why choices were made (from Key Design Decisions or inline) |

For each element, record:
- The element content (preserve verbatim where possible)
- Which design section it came from
- Which category it belongs to

### 6. Define Step 5: Flag Design Gaps

If any section of the design document is vague, incomplete, or marked TBD:

**Display format**:
```
Design gaps detected in {filename}:
  - {Section name}: {description of gap}

Suggest creating a clarification? (yes/no)
```

If user says yes, suggest invoking `@acp.clarification-create` for the specific gaps.
If user says no, proceed with available detail and note gaps in the task.

### 7. Define Step 6: Return Elements

The directive returns extracted elements to the calling command as structured data:
- List of design elements grouped by category
- List of design gaps (if any)
- Path(s) to the design document(s) found (for the Design Reference field)

The calling command uses these to:
- Expand task steps with implementation detail
- Add verification items for each design requirement
- Set the Design Reference metadata field
- Populate Key Design Decisions section

### 8. Document the Argument Interface

The directive accepts context from the calling command:

| Input | Source | Description |
|---|---|---|
| `topic_keywords` | Calling command | Keywords extracted from task/milestone name |
| `milestone_name` | Calling command | Current milestone name (optional) |
| `user_description` | Calling command | User's description of the task (optional) |
| `draft_content` | Calling command | Draft file content if provided (optional) |

### 9. Add Notes Section

Document:
- This directive is modeled after `@acp.clarification-capture`
- Discovery is always dynamic (no explicit links required)
- Multiple design documents can be loaded
- The directive does not modify any files — it only reads and returns data
- Context window cost is mitigated by keyword filtering (only relevant docs loaded)

---

## Verification

- [ ] Directive document created at `agent/commands/acp.design-reference.md`
- [ ] Marked as shared directive (not user-invocable)
- [ ] Step 1 (Determine Topic) documented with all keyword sources
- [ ] Step 2 (Search) documented with filename + content matching
- [ ] Step 3 (Report Findings) documented with both "found" and "not found" display formats
- [ ] Step 4 (Extract Elements) documented with all 8 categories and what to extract per category
- [ ] Step 5 (Flag Gaps) documented with display format and clarification suggestion flow
- [ ] Step 6 (Return Elements) documented with output structure
- [ ] Argument interface table documented
- [ ] Notes section covers dynamic discovery, multiple docs, read-only behavior

---

## Expected Output

### Files Created
- `agent/commands/acp.design-reference.md` — shared directive document

### Files Modified
- None

---

**Next Task**: [Task 112: Update Task Template with Design Reference Field](task-112-task-template-design-reference-field.md)  
**Related Design Docs**: [Design Reference System](../../design/local.design-reference-system.md)  
