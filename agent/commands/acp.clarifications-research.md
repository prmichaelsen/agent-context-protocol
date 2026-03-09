# Command: clarifications-research

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-clarifications-research` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-clarifications-research NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-03-09
**Last Updated**: 2026-03-09
**Status**: Active
**Scripts**: None

---

**Purpose**: Research and fill in agent-delegated clarification response lines
**Category**: Workflow
**Frequency**: As Needed

---

## Arguments

**CLI-Style Arguments**:
- `<file>` (positional) - Path to a specific clarification file
- `--latest` or `-l` - Auto-detect the most recent non-captured clarification
- `--dry-run` or `-n` - Preview research items without modifying the file
- `--scope <path>` or `-s <path>` - Limit codebase research to a specific directory

**Natural Language Arguments**:
- `@acp.clarifications-research agent/clarifications/clarification-5-foo.md` - Research a specific file
- `@acp.clarifications-research --latest` - Research the most recent clarification
- `@acp.clarifications-research --dry-run` - Preview without modifying

**Argument Mapping**:
The agent infers intent from context:
- If a file path is provided → use that clarification file
- If `--latest` → find the most recent clarification with status "Awaiting Responses"
- If no arguments → same as `--latest` (auto-detect)

---

## What This Command Does

This command scans a clarification document for response lines (`>`) that contain research delegation markers — phrases like "research this", "look into this", "agent: check the codebase", etc. For each such line, the agent researches the answer using codebase exploration (Glob, Grep, Read) in the context of the preceding question, then replaces the trigger line with a `[Researched]`-prefixed answer.

User-written answers and empty response lines are never modified. The clarification's status field is also left unchanged, since the user still needs to review agent-provided answers.

Use this command after filling out a clarification document when some questions are better answered by the agent exploring the codebase rather than the user typing answers manually.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] At least one clarification file exists in `agent/clarifications/`
- [ ] Target clarification has response lines with research delegation markers

---

## Steps

### 1. Locate Clarification File

Find the clarification file to process.

**Actions**:
- If a positional `<file>` argument was provided, use that path directly
- If `--latest` was passed (or no arguments at all):
  - List all files in `agent/clarifications/` matching `clarification-*.md` (exclude `*.template.md`)
  - Read each file's `Status:` field
  - Filter to those with status "Awaiting Responses"
  - Select the one with the highest clarification number (most recent)
- Verify the file exists and is readable

**Expected Outcome**: A single clarification file path is identified

### 2. Parse Response Lines

Read the clarification file and classify every `>` response line.

**Classification rules** (applied in order):

1. **Empty** — the line is `> ` followed by only whitespace (or just `>` with nothing after). Leave these alone.
2. **Research request** — the line matches any of these trigger phrases (case-insensitive):
   - `research this`, `look this up`, `look into this`
   - `check the codebase`, `check the code`, `check the repo`
   - `figure this out`, `figure it out`, `find out`, `investigate`
   - Line content (after `> `) starts with `agent:` prefix (explicit delegation, e.g. `> agent: check how the yaml parser works`)
3. **User answer** — any other line starting with `>` that contains substantive text. **Never modify these.**

For each research-request line, also capture the **question context**: the nearest preceding bullet point question (the `- ` line above the `>` line) plus the parent `##` heading. This context is needed for Step 4.

**Expected Outcome**: A list of classified response lines with their line numbers and question context

### 3. Report Scan Results

Display a summary of what was found.

**Display format**:
```
🔍 Scanning clarification: agent/clarifications/clarification-{N}-{title}.md

  Response lines found: {total}
    ✎ User answers (untouched):    {count}
    ⬚ Empty (untouched):           {count}
    🔬 Research requests:           {count}

  Research items:
    L{line}: "{question text}" — trigger: "{trigger phrase}"
    L{line}: "{question text}" — trigger: "agent: {directive}"
    ...
```

**If `--dry-run`**: Display the summary above and stop. Do not proceed to Step 4.

**If no research requests found**: Report that no research items were detected and stop.

**Expected Outcome**: User sees what will be researched; dry-run exits here

### 4. Research Each Item

For each research-request line, explore the codebase to find the answer.

**Actions**:
- Use the question context (question text + section heading) to determine what to search for
- If `agent:` prefix was used, the text after `agent:` is an explicit research directive — follow it
- Otherwise, infer what to look up from the question
- Use Glob, Grep, and Read tools to explore the codebase
  - If `--scope <path>` was provided, limit searches to that directory
- Synthesize a concise, factual answer (1-3 sentences) with file references where applicable

**Answer quality guidelines**:
- Be specific — cite file paths and line numbers (e.g., `see agent/scripts/acp.yaml-parser.sh:L45-L120`)
- If the answer cannot be determined from the codebase, write: `[Researched] Unable to determine from codebase — manual answer needed.`
- Do not speculate beyond what the code shows
- Keep answers concise but complete

**Expected Outcome**: A researched answer for each research-request line

### 5. Fill In Researched Answers

Replace each research-request response line with the researched answer.

**Format**:
```
> [Researched] {answer text with file references}
```

**Actions**:
- For each research-request line, replace the entire `> {trigger}` line with `> [Researched] {answer}`
- Preserve the original file's formatting, indentation, and surrounding content
- Do NOT modify any user-answer lines
- Do NOT modify any empty response lines
- Do NOT change the clarification's `Status:` field

**Expected Outcome**: Clarification file updated with researched answers in place of trigger lines

### 6. Report Results

Show what was filled in and what remains.

**Display format**:
```
✅ Research Complete!

File: agent/clarifications/clarification-{N}-{title}.md

  Researched: {count} answers filled in
  Unchanged: {user-answer-count} user answers + {empty-count} empty lines

  Filled answers:
    L{line}: [Researched] {first ~60 chars of answer}...
    L{line}: [Researched] {first ~60 chars of answer}...

  ⚠ Remaining empty lines: {empty-count} (still need answers)

  Status unchanged — review researched answers before capturing.
```

**Expected Outcome**: User sees a summary of changes and knows what still needs attention

---

## Verification

- [ ] Clarification file located correctly (positional, --latest, or auto-detect)
- [ ] All response lines classified correctly (empty, research, user-answer)
- [ ] User answers are completely untouched
- [ ] Empty response lines are completely untouched
- [ ] Research-request lines are replaced with `[Researched]` prefixed answers
- [ ] Answers include file references where applicable
- [ ] `--dry-run` reports without modifying the file
- [ ] `--scope` limits research to specified directory
- [ ] Clarification status is NOT changed

---

## Expected Output

### Files Modified
- `agent/clarifications/clarification-{N}-{title}.md` - Research-request lines replaced with answers

### Console Output
```
🔍 Scanning clarification: agent/clarifications/clarification-5-yaml-parser.md

  Response lines found: 15
    ✎ User answers (untouched):    6
    ⬚ Empty (untouched):           4
    🔬 Research requests:           5

  Research items:
    L23: "How does the YAML parser handle nested keys?" — trigger: "research this"
    L45: "What error handling exists for malformed YAML?" — trigger: "agent: check the yaml parser"
    ...

✅ Research Complete!

  Researched: 5 answers filled in
  Unchanged: 6 user answers + 4 empty lines

  Status unchanged — review researched answers before capturing.
```

---

## Examples

### Example 1: Research Latest Clarification

**Context**: Just finished answering some questions in a clarification, left "research this" on others

**Invocation**: `@acp.clarifications-research`

**Result**: Auto-detects the latest "Awaiting Responses" clarification, finds research markers, explores the codebase, and fills in answers.

### Example 2: Dry Run on Specific File

**Context**: Want to see what would be researched before committing

**Invocation**: `@acp.clarifications-research agent/clarifications/clarification-5-yaml-parser.md --dry-run`

**Result**: Shows list of research items without modifying the file.

### Example 3: Scoped Research

**Context**: Questions relate to a specific subsystem

**Invocation**: `@acp.clarifications-research --latest --scope agent/scripts/`

**Result**: Researches answers but limits codebase exploration to `agent/scripts/`.

---

## Related Commands

- [`@acp.clarification-create`](acp.clarification-create.md) - Create clarification documents (run first)
- [`@acp.clarification-capture`](acp.clarification-capture.md) - Capture answered clarifications into design docs / tasks
- [`@acp.design-create`](acp.design-create.md) - Create design documents (often follows clarification)

---

## Troubleshooting

### Issue 1: No clarifications found

**Symptom**: "No clarification files with status 'Awaiting Responses' found"

**Cause**: All clarifications are already captured or completed

**Solution**: Create a new clarification with `@acp.clarification-create` or provide a specific file path

### Issue 2: Research answer is "Unable to determine"

**Symptom**: Answer says "Unable to determine from codebase — manual answer needed"

**Cause**: The question requires knowledge not present in the codebase (e.g., business requirements, user preferences)

**Solution**: Replace the `[Researched]` line with a manual answer

### Issue 3: Research scope too narrow

**Symptom**: Answers are incomplete or miss relevant code

**Cause**: `--scope` flag limited search to a directory that doesn't contain all relevant code

**Solution**: Re-run without `--scope` or with a broader scope path

---

## Security Considerations

### File Access
- **Reads**: Clarification files in `agent/clarifications/`, any codebase files during research
- **Writes**: The target clarification file only (replacing research-request lines)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets or credentials in researched answers
- **Credentials**: If a question asks about credentials or secrets, answer with "manual answer needed"

---

## Notes

- This command never changes the clarification's `Status:` field — the user should review researched answers and then use `@acp.clarification-capture` when satisfied
- The `[Researched]` prefix makes it easy to distinguish agent-provided answers from user-provided answers
- If a researched answer is wrong, the user can simply edit the line — it's still a regular response line
- The `agent:` prefix on response lines allows users to give specific research directives beyond the standard trigger phrases
- Research quality depends on the question context — more specific questions yield better answers

---

**Namespace**: acp
**Command**: clarifications-research
**Version**: 1.0.0
**Created**: 2026-03-09
**Last Updated**: 2026-03-09
**Status**: Active
**Compatibility**: ACP 5.0.0+
**Author**: ACP Project
