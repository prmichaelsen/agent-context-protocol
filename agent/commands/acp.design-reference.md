# Directive: design-reference

> **🤖 Agent Directive**: This is a **SHARED DIRECTIVE**, not a user-invocable command.
> It is referenced by `@acp.task-create`, `@acp.plan` (via task-create delegation), and `@acp.proceed` to discover and cross-reference design documents, ensuring tasks contain all implementation detail.
>
> **Do NOT invoke this directive directly.** It is called internally by commands that need design document context.
>
> If you are a command reading this file, follow the steps below to discover relevant design documents, extract actionable elements, and return them to the calling command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-03-07
**Last Updated**: 2026-03-07
**Status**: Active
**Scripts**: None

---

**Purpose**: Discover and cross-reference design documents to ensure tasks have complete implementation detail
**Category**: Workflow (Internal Directive)
**Frequency**: Called by task-create and proceed when design context is needed

---

## Arguments

These arguments are passed as context from the calling command. The directive uses them to determine search scope.

| Input | Source | Description |
|---|---|---|
| `topic_keywords` | Calling command | Keywords extracted from task name, milestone name, or user description |
| `milestone_name` | Calling command | Current milestone name (optional, improves search accuracy) |
| `user_description` | Calling command | User's description of the task or feature (optional) |
| `draft_content` | Calling command | Draft file content if provided (optional) |

The directive combines these inputs to form a search query. More inputs produce better matches.

---

## What This Directive Does

This directive dynamically discovers design documents relevant to the current task or feature, reads them, extracts all actionable implementation elements, and returns them to the calling command. The calling command uses these elements to generate self-contained tasks or to load supplementary context during implementation.

**Key behaviors**:
- Always searches `agent/design/` — no explicit links or configuration required
- Uses keyword matching against filenames and content
- Reads all relevant documents (not just the first match)
- Extracts 8 categories of actionable elements
- Flags incomplete or vague design areas
- Returns structured data to the calling command
- Read-only — never modifies any files

---

## Prerequisites

- [ ] Called from within a command that needs design context (task-create, plan, proceed)
- [ ] `agent/design/` directory exists
- [ ] At least one design document exists (non-template)

---

## Steps

### 1. Determine Topic

Extract topic keywords from the calling context to form a search query.

**Actions**:
- Collect keywords from all available inputs:
  - **Task name**: e.g., "Create @acp.clarification-capture Directive" → keywords: `clarification`, `capture`, `directive`
  - **Milestone name**: e.g., "Clarification Capture System" → keywords: `clarification`, `capture`, `system`
  - **User description**: Extract nouns and action words
  - **Draft content**: Extract topic-relevant terms from first ~20 lines
- Deduplicate keywords
- Combine into a search query (e.g., `clarification capture system directive`)
- Strip common ACP terms that would match too broadly (`acp`, `command`, `task`, `system`, `implement`, `create`, `update`)

**Expected Outcome**: Set of topic keywords for search

### 2. Search for Design Documents

Search `agent/design/` for documents matching the topic.

**Actions**:
- List all files in `agent/design/` excluding `*.template.md`
- For each file, score relevance:
  - **Filename match** (high confidence): Convert filename to keywords (e.g., `local.clarification-capture-system.md` → `clarification`, `capture`, `system`). Count keyword overlaps with topic.
  - **Content match** (medium confidence): If filename match is borderline (1 keyword overlap), read first ~50 lines and check for topic keyword presence in Overview/Problem Statement sections.
- Classify each file:
  - **Relevant**: 2+ keyword overlaps in filename, or 1 filename + 3+ content overlaps
  - **Not relevant**: 0 keyword overlaps, or only 1 generic overlap
  - **Borderline**: 1 specific keyword overlap — read content to decide
- Read all relevant documents in full
- Sort by relevance score (filename matches > content matches)

**Expected Outcome**: List of relevant design documents read and scored

### 3. Report Findings

Display what was found to the user.

**When designs found**:
```
Design Reference: Searching agent/design/...
  Found: local.clarification-capture-system.md (relevant)
  Found: acp-commands-design.md (not relevant, skipped)
  Found: local.key-file-index-system.md (not relevant, skipped)

  1 design document loaded for cross-reference
```

**When no designs found**:
```
Design Reference: No design documents found for topic "{topic keywords}"
  Tasks will be created from available context only.
```

**Expected Outcome**: User informed of which designs were found/skipped

### 4. Extract Design Elements

Parse the relevant design document(s) and extract all actionable elements organized by category.

**Actions**:
- Read each relevant design document section by section
- Extract elements into these 8 categories:

| Category | What to Extract | Where to Look |
|---|---|---|
| Implementation steps/flows | Specific sequences of operations, numbered steps, flow diagrams, invocation flows | Solution, Implementation sections |
| Argument/parameter tables | Inputs, flags, aliases, behaviors — preserve exact table format | Solution, Implementation sections |
| UX specifications | Warning messages, prompt text, display formats — preserve exact text including code blocks | Implementation section, any "Display format" subsections |
| Edge cases and error handling | Boundary conditions, failure modes, what-if scenarios | Testing Strategy, Trade-offs, Implementation sections |
| Format specifications | Output structure, naming conventions, file format rules, template formats | Implementation, Solution sections |
| Integration points | Connections to other commands/systems, affected commands tables, which files are modified | Implementation section, "Affected Commands" subsections |
| Lifecycle rules | Status transitions, cleanup behavior, ordering constraints, migration steps | Implementation, Migration Path sections |
| Decision rationale | Why choices were made, alternatives rejected, trade-offs accepted | Key Design Decisions, Trade-offs, Benefits sections |

- For each element, record:
  - The element content (preserve verbatim where possible, especially tables and code blocks)
  - Which design section it came from
  - Which category it belongs to

**Expected Outcome**: Complete inventory of design elements organized by category

### 5. Flag Design Gaps

If any section of the design document is vague, incomplete, or marked TBD, flag it.

**Actions**:
- Scan for indicators of incompleteness:
  - Sections with only placeholder text or one-liners
  - "TBD", "TODO", "to be determined" markers
  - Empty sections (heading with no content)
  - Vague language without specifics ("appropriate handling", "as needed")
- If gaps found, display:

```
Design gaps detected in {filename}:
  - {Section name}: {description of gap}
  - {Section name}: {description of gap}

Suggest creating a clarification? (yes/no)
```

- If user says **yes**: Suggest invoking `@acp.clarification-create` targeting the specific gaps. Halt the directive and let the user address gaps first.
- If user says **no**: Proceed with available detail. Include a note about gaps in the returned data so the calling command can mention them in the task.

**Expected Outcome**: Design gaps identified and user informed; decision made on whether to address them

### 6. Return Elements to Calling Command

Pass the extracted data back to the calling command.

**Return data**:
- **design_elements**: List of elements grouped by category (8 categories)
- **design_gaps**: List of identified gaps (section name + description), or empty if none
- **design_paths**: Path(s) to the relevant design document(s) found (for the Design Reference metadata field)
- **design_names**: Human-readable name(s) of the design document(s)

**The calling command uses this data to**:
- **task-create**: Expand task steps with implementation detail from design elements; add verification items for each design requirement; set Design Reference metadata field; carry Key Design Decisions into the task
- **proceed**: Load design context as supplementary "why" information during implementation; consult when ambiguity or edge cases arise

**Expected Outcome**: Calling command receives structured design data for integration

---

## Verification

- [ ] Step 1 (Determine Topic) extracts keywords from task name, milestone name, user description, and draft content
- [ ] Step 1 strips overly common ACP terms to avoid false matches
- [ ] Step 2 (Search) lists all non-template files in `agent/design/`
- [ ] Step 2 scores by filename keyword overlap and content keyword overlap
- [ ] Step 2 reads first ~50 lines for borderline matches
- [ ] Step 2 reads all relevant documents in full (not just first match)
- [ ] Step 3 (Report) uses the exact "found"/"not found" display formats specified
- [ ] Step 4 (Extract) covers all 8 categories with specific extraction guidance per category
- [ ] Step 4 preserves verbatim content for tables, code blocks, and UX text
- [ ] Step 5 (Flag Gaps) detects TBD, TODO, placeholder text, empty sections, vague language
- [ ] Step 5 offers clarification creation for gaps
- [ ] Step 5 allows user to skip gaps and proceed
- [ ] Step 6 (Return) returns design_elements, design_gaps, design_paths, design_names
- [ ] Step 6 documents how each calling command uses the returned data
- [ ] Directive is read-only (never modifies files)

---

## Expected Output

### Console Output (during execution)
```
Design Reference: Searching agent/design/...
  Found: local.design-reference-system.md (relevant)
  Found: acp-commands-design.md (not relevant, skipped)

  1 design document loaded for cross-reference
  Extracted: 15 elements across 6 categories
  Gaps: None detected
```

### Data Returned to Calling Command
```
design_elements:
  implementation_steps: [...]
  argument_tables: [...]
  ux_specifications: [...]
  edge_cases: [...]
  format_specifications: [...]
  integration_points: [...]
  lifecycle_rules: [...]
  decision_rationale: [...]

design_gaps: []

design_paths:
  - agent/design/local.design-reference-system.md

design_names:
  - Design Reference System
```

---

## Examples

### Example 1: task-create finds relevant design

**Context**: User invokes `@acp.task-create` for a task about "clarification capture"

**Flow**: Directive searches `agent/design/`, matches `local.clarification-capture-system.md` by filename keywords, reads it, extracts 8-step directive flow + argument table + UX warning format + affected commands table + lifecycle rules. Returns all to task-create. Task is generated with full implementation detail.

### Example 2: No design document exists

**Context**: User invokes `@acp.task-create` for a task about "user preferences"

**Flow**: Directive searches `agent/design/`, no filenames match "preferences" (M6 has no design doc yet). Reports "No design documents found." Task is created from available context only (user input, draft, clarifications).

### Example 3: Multiple relevant designs

**Context**: User invokes `@acp.task-create` for a task about "package validation"

**Flow**: Directive finds both `acp-package-management-system.md` and `local.experimental-features-system.md` as relevant. Reads both. Extracts elements from each. Returns combined elements to task-create.

### Example 4: Design has gaps

**Context**: User invokes `@acp.task-create` for a feature whose design has a TBD Testing Strategy

**Flow**: Directive reads design, extracts elements, flags "Testing Strategy: marked TBD". Asks user whether to create clarification. User says no. Task is created with a note about the gap.

### Example 5: proceed loads design context

**Context**: Agent runs `@acp.proceed` on a task with `Design Reference: [Clarification Capture System](../design/local.clarification-capture-system.md)`

**Flow**: Proceed reads the linked design document. Uses it as supplementary context during implementation — consulting it when the task step is ambiguous or when an unlisted edge case arises.

---

## Related Commands

- [`@acp.clarification-capture`](acp.clarification-capture.md) - Sister shared directive for clarification context capture
- [`@acp.task-create`](acp.task-create.md) - Calls this directive during task creation (Step 5.5)
- [`@acp.plan`](acp.plan.md) - Calls this directive via task-create delegation
- [`@acp.proceed`](acp.proceed.md) - Calls this directive during implementation for design context
- [`@acp.design-create`](acp.design-create.md) - Creates the design documents this directive discovers

---

## Troubleshooting

### Issue 1: Wrong design document matched

**Symptom**: Directive loads an unrelated design document

**Cause**: Keyword overlap on generic terms (e.g., "system", "command")

**Solution**: Step 1 strips overly common terms. If false matches persist, the user can indicate which design is relevant when the report is displayed.

### Issue 2: Design document not found despite existing

**Symptom**: Directive reports "no design documents found" but one exists

**Cause**: Filename keywords don't overlap with topic keywords

**Solution**: User can provide additional context (mention the design doc name) or use a more specific task/milestone name. The calling command can also pass the design path explicitly if known.

### Issue 3: Too many elements extracted

**Symptom**: Returned elements are overwhelming for a single task

**Cause**: Design document covers a broad feature with many tasks

**Solution**: The calling command (task-create) filters elements by relevance to the specific task being created. Not all elements from the design need to appear in every task — only those relevant to the task's scope.

---

## Security Considerations

### File Access
- **Reads**: `agent/design/*.md` (non-template), first ~50 lines for borderline matches
- **Writes**: None (read-only directive)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in extracted elements
- **Credentials**: Never include credentials in output

---

## Notes

- This directive is modeled after `@acp.clarification-capture` (same shared directive pattern)
- Discovery is always dynamic — no explicit links or configuration required
- Multiple design documents can be loaded and cross-referenced
- The directive is read-only — it never modifies any files
- Context window cost is mitigated by keyword filtering (only relevant docs loaded, borderline checked via first ~50 lines)
- The calling command decides how to use the returned elements — the directive just extracts and returns
- When called by `@acp.proceed`, the design context is supplementary (task is primary)
- When called by `@acp.task-create`, the design elements are mandatory inputs for task generation

---

**Namespace**: acp
**Command**: design-reference
**Version**: 1.0.0
**Created**: 2026-03-07
**Last Updated**: 2026-03-07
**Status**: Active
**Compatibility**: ACP 5.13.1+
**Author**: ACP Project
