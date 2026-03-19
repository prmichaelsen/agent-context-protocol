# Directive: clarification-capture

> **🤖 Agent Directive**: This is a **SHARED DIRECTIVE**, not a user-invocable command.
> It is referenced by create commands (`design-create`, `task-create`, `pattern-create`, `command-create`) to capture clarification decisions into entity documents.
>
> **Do NOT invoke this directive directly.** It is called internally by create commands when context capture is needed.
>
> If you are a create command reading this file, follow the steps below to capture clarification context and generate a "Key Design Decisions" section for the entity being created.

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-03-04  
**Last Updated**: 2026-03-04  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Capture decisions from ephemeral clarification files and chat context into permanent entity documents  
**Category**: Workflow (Internal Directive)  
**Frequency**: Called by create commands when context is available  

---

## Arguments

These arguments are passed through from the calling create command. The create command parses them and passes the relevant context to this directive.

**CLI-Style Arguments**:

| Argument | Alias | Behavior |
|---|---|---|
| `--from-clarification <file>` | `--from-clar` | Capture from a specific clarification file |
| `--from-clarifications` | `--from-clars` | Capture from all recent clarifications |
| `--from-chat-context` | `--from-chat` | Capture decisions from chat conversation |
| `--from-context` | (none) | Shorthand for all sources (clarifications + chat) |
| `--include-clarifications` | (none) | Alias for `--from-clars`, enforces Key Design Decisions section |

**Natural Language**:
- `@acp.design-create --from-clar` → Capture from clarifications in session
- `@acp.design-create --from-chat` → Capture from chat conversation
- `@acp.design-create --from-context` → Capture from all sources
- `@acp.design-create` (no flags) → **Auto-detect**: equivalent to implicit `--from-context`

**Default Behavior**: When no `--from-*` flags are specified, the directive auto-detects clarifications and context in the current session. This is the common case.  

---

## What This Directive Does

This directive captures design decisions from ephemeral sources (clarifications, chat conversation) and embeds them as a "Key Design Decisions" section in the entity document being created. This prevents loss of design rationale — clarifications are workflow-only files that are never committed to version control.

The directive is called internally by create commands after context detection and key file reading, but before entity file generation. It produces a markdown section that the create command inserts into the generated entity document.

**Key behaviors**:
- Auto-detects clarifications in the session by default (no flags needed)
- Warns the user if uncaptured clarification decisions are detected
- Resolves conflicts between multiple clarifications by flagging for user
- Synthesizes decisions into category-grouped summary tables
- Updates captured clarification status to "Captured"
- Never includes clarification file references in output (clarifications are ephemeral and volatile)

---

## Prerequisites

- [ ] Called from within a create command (design-create, task-create, pattern-create, or command-create)
- [ ] `agent/clarifications/` directory exists (if capturing from clarifications)
- [ ] At least one clarification or chat context available

---

## Steps

### 1. Detect Context Sources

Determine which sources to capture from based on arguments or auto-detection.

**Actions**:
- If `--from-clar <file>` specified: Use that specific clarification file
- If `--from-clars` specified: Use all recent clarifications
- If `--from-chat` specified: Synthesize decisions from chat conversation
- If `--from-context` specified: Use all sources (clarifications + chat)
- If **no flags** specified (default): Auto-detect — scan for clarifications in session and chat context. Equivalent to implicit `--from-context`.

**Expected Outcome**: List of context sources identified  

### 2. Read Clarification Files

If clarifications are a source, read and parse them.

**Actions**:
- List files in `agent/clarifications/` (exclude `*.template.md`)
- Filter by status: read files with status "Completed", "Awaiting Responses", or "Captured"
- If `--from-clar <file>`: Read only the specified file
- If `--from-clars` or auto-detect: Read all qualifying files
- Parse each clarification's Items, Questions, and responses (lines starting with `>`)
- Order by recency (file modification time or clarification number)

**Priority rule**: More recent clarification responses supersede older ones. Within a single clarification, all items are equal weight.  

**Expected Outcome**: Clarification responses parsed and ordered  

### 3. Warn About Partial Clarifications

If any clarification has unanswered questions, warn the user.

**Actions**:
- Scan each clarification for questions with empty `>` response lines
- If unanswered questions found, display warning:

```
⚠️  Partial clarification detected: clarification-{N}-{title}.md
    {X} of {Y} questions unanswered.

    Proceed with answered portions only? (yes/no)
```

- If user says yes: Continue with answered portions
- If user says no: Halt capture and let user complete the clarification first

**Expected Outcome**: User informed of partial clarifications, decision made  

### 4. Resolve Conflicts

If multiple clarifications contain conflicting decisions, flag for user resolution.

**Actions**:
- Compare responses across clarifications for overlapping topics
- If conflicting decisions detected:

```
⚠️  Conflicting decisions detected:

    Topic: {topic}

    Clarification {A}: "{response A}"
    Clarification {B}: "{response B}"

    The more recent answer is "{response B}" (clarification {B}).
    Use this? (yes/no/custom)
      yes    → Use clarification {B}
      no     → Use clarification {A}
      custom → Provide a different answer
```

- Wait for user resolution
- Never silently merge conflicting decisions
- Never capture both sides of a conflict

**Expected Outcome**: All conflicts resolved  

### 5. Synthesize Chat Context

If chat context is a source (`--from-chat` or auto-detect), extract decisions from the conversation.

**Actions**:
- Review chat history for design decisions, preferences, and requirements expressed by the user
- Extract decision/choice/rationale triples from conversational context
- Merge with clarification decisions (chat context has equal weight to clarifications)

**Expected Outcome**: Chat decisions extracted and merged  

### 6. Generate Key Design Decisions Section

Create the markdown section for embedding in the entity document.

**Actions**:
- Group all captured decisions by agent-inferred category (e.g., "Architecture", "Scope", "Format", "Lifecycle")
- Categories are inferred from content — there is no predefined list
- Format as category-grouped tables:

```markdown
## Key Design Decisions (Optional)

### {Category 1}

| Decision | Choice | Rationale |
|---|---|---|
| {decision} | {choice} | {rationale} |
| {decision} | {choice} | {rationale} |

### {Category 2}

| Decision | Choice | Rationale |
|---|---|---|
| {decision} | {choice} | {rationale} |
```

- **Do NOT include clarification file references** — clarifications are ephemeral and volatile. File numbers will not match across different developer checkouts.
- If no decisions to capture, omit the section entirely

**Expected Outcome**: Key Design Decisions markdown section generated  

### 7. Update Clarification Status

After successful capture, update the status of captured clarification files.

**Actions**:
- For each clarification file that was captured from:
  - Update `**Status**:` line from current value to `Captured`
- Do NOT delete clarification files
- Do NOT prompt to delete clarification files

**Expected Outcome**: Clarification statuses updated to "Captured"  

### 8. Return Section to Calling Command

Pass the generated Key Design Decisions section back to the create command for insertion into the entity document.

**Expected Outcome**: Create command receives the section and inserts it into the generated entity file  

---

## Warning UX: Uncaptured Decisions

When a create command detects clarifications in the session but the user hasn't explicitly included capture flags, the auto-detect behavior triggers this flow:

```
⚠️  Clarification decisions detected in this session that have not been captured.
    Clarifications are not committed to version control.
    Decisions not captured in this document will be lost.

    Detected:
      • clarification-{N}-{title}.md ({status}, {X} questions answered)

    Include these decisions in the document? (yes/no)
```

- If yes: Proceed with capture (equivalent to `--from-clars`)
- If no: Skip capture, create entity without Key Design Decisions section

This warning is **mandatory** when uncaptured clarifications exist. It ensures the user is aware that decisions may be lost.

---

## Verification

- [ ] Context sources correctly detected (flags or auto-detect)
- [ ] Clarification files read and parsed
- [ ] Partial clarifications warned about
- [ ] Conflicts flagged and resolved (never silently merged)
- [ ] Chat context synthesized (if applicable)
- [ ] Key Design Decisions section generated with category-grouped tables
- [ ] No clarification file references in output
- [ ] Clarification statuses updated to "Captured"
- [ ] Section returned to calling create command

---

## Expected Output

### Generated Section (inserted into entity document)
```markdown
## Key Design Decisions (Optional)

### Architecture

| Decision | Choice | Rationale |
|---|---|---|
| Implementation approach | Shared directive | Avoids duplicating capture logic across create commands |

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Affected commands | design, task, pattern, command create | Core entity creation commands only |
```

### Console Output (during capture)
```
📋 Capturing Clarification Context...
  ✓ Read clarification-6-create-command-context-capture.md (20 questions, 20 answered)
  ✓ Synthesized chat context (3 additional decisions)
  ✓ No conflicts detected
  ✓ Generated Key Design Decisions (4 categories, 13 decisions)
  ✓ Updated clarification-6 status → Captured

  Key Design Decisions section ready for embedding.
```

---

## Examples

### Example 1: Auto-detect with clarifications in session

**Context**: User created and answered a clarification, then invokes `@acp.design-create`  

**Flow**: Directive auto-detects the clarification, warns user, user confirms, decisions captured into design document  

### Example 2: Explicit capture from specific file

**Context**: User invokes `@acp.task-create --from-clar clarification-6-create-command-context-capture.md`  

**Flow**: Directive reads only that clarification, synthesizes decisions, generates section  

### Example 3: Chat-only capture

**Context**: User had extensive discussion about design choices, invokes `@acp.pattern-create --from-chat`  

**Flow**: Directive synthesizes decisions from chat history, generates section (no clarification files involved)  

### Example 4: No context available

**Context**: User invokes `@acp.design-create` with no prior clarifications or design discussion  

**Flow**: Directive finds no context sources, skips capture silently, entity created without Key Design Decisions section  

---

## Related Commands

- [`@acp.clarification-create`](acp.clarification-create.md) - Creates clarification files that this directive captures from
- [`@acp.design-create`](acp.design-create.md) - Calls this directive during design creation
- [`@acp.task-create`](acp.task-create.md) - Calls this directive during task creation
- [`@acp.pattern-create`](acp.pattern-create.md) - Calls this directive during pattern creation
- [`@acp.command-create`](acp.command-create.md) - Calls this directive during command creation

---

## Troubleshooting

### Issue 1: No clarifications found

**Symptom**: Directive reports no context sources  

**Cause**: No clarification files exist or all have status "Captured"  

**Solution**: This is normal. Entity will be created without Key Design Decisions section. If you expected clarifications, check `agent/clarifications/` directory.  

### Issue 2: Clarification has no answered questions

**Symptom**: Warning about fully unanswered clarification  

**Cause**: Clarification was created but not yet answered  

**Solution**: Answer the clarification first, then re-run the create command.  

### Issue 3: Too many conflicts

**Symptom**: Multiple conflict resolution prompts  

**Cause**: Multiple clarifications with overlapping but contradictory answers  

**Solution**: Consider consolidating clarifications before capture, or resolve each conflict as prompted.  

---

## Security Considerations

### File Access
- **Reads**: `agent/clarifications/*.md` (non-template), chat conversation context
- **Writes**: `agent/clarifications/*.md` (status update to "Captured" only)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in Key Design Decisions
- **Credentials**: Never include credentials in captured output

---

## Notes

- This is a shared directive, not a user-invocable command
- Default behavior is auto-detect (no flags needed for common case)
- Clarifications are ephemeral — never reference their file numbers in output
- Categories in the output tables are agent-inferred, not predefined
- The directive never deletes clarification files and never prompts to delete them
- Conflict resolution always involves the user — never silently merge
- The Key Design Decisions section is optional — omit if no decisions to capture

---

**Namespace**: acp  
**Command**: clarification-capture  
**Version**: 1.0.0  
**Created**: 2026-03-04  
**Last Updated**: 2026-03-04  
**Status**: Active  
**Compatibility**: ACP 5.12.0+  
**Author**: ACP Project  
