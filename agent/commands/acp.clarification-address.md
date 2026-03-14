# Command: clarification-address

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-clarification-address` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-clarification-address NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-03-14
**Last Updated**: 2026-03-14
**Status**: Active
**Scripts**: None

---

**Purpose**: Address clarification responses by researching, exploring code/web, using tools, and presenting recommendations
**Category**: Workflow
**Frequency**: As Needed

---

## Arguments

**CLI-Style Arguments**:
- `<file>` (positional) - Path to a specific clarification file
- `--latest` or `-l` - Auto-detect the most recent clarification with user responses
- `--dry-run` or `-n` - Preview what would be addressed without modifying the file
- `--scope <path>` or `-s <path>` - Limit codebase exploration to a specific directory

**Natural Language Arguments**:
- `@acp.clarification-address agent/clarifications/clarification-9-foo.md` - Address a specific file
- `@acp.clarification-address --latest` - Address the most recent clarification
- `@acp.clarification-address` - Same as `--latest` (auto-detect)

**Argument Mapping**:
The agent infers intent from context:
- If a file path is provided → use that clarification file
- If `--latest` → find the most recent clarification with status "Awaiting Responses" or "Completed"
- If no arguments → same as `--latest` (auto-detect)

---

## What This Command Does

This command reads a clarification document, understands what the user has responded, and actively engages with those responses. Unlike `@acp.clarifications-research` which only fills in agent-delegated research lines (`> research this`), this command works *after* the user has responded — it reads user answers, honors embedded research directives, explores code or the web when asked, invokes MCP tools when directed, analyzes tradeoffs, provides recommendations, and responds to open questions the user has left in comment blocks.

The agent writes its responses as HTML comment blocks (`<!-- ... -->`) directly below the relevant question-response pair. This keeps the clarification document clean — user responses remain the canonical content on the `>` lines, while agent analysis, tradeoffs, and recommendations live in comments that are visible when editing but don't clutter the rendered view.

Use this command after filling out clarification responses when you want the agent to process your answers, do follow-up research, and provide analysis before moving to design or task creation.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] At least one clarification file exists in `agent/clarifications/`
- [ ] Target clarification has user responses on `>` lines (not all empty)

---

## Steps

### 1. Locate Clarification File

Find the clarification file to process.

**Actions**:
- If a positional `<file>` argument was provided, use that path directly
- If `--latest` was passed (or no arguments at all):
  - List all files in `agent/clarifications/` matching `clarification-*.md` (exclude `*.template.md`)
  - Read each file's `Status:` field
  - Select the one with the highest clarification number (most recent)
  - Prefer "Awaiting Responses" status, but also accept "Completed"
- Verify the file exists and is readable

**Expected Outcome**: A single clarification file path is identified

### 2. Read and Parse the Clarification

Read the entire clarification document and build a structured understanding of its contents.

**Actions**:
- Read the full file
- For each Item/Questions section, parse:
  - The question text (the `- ` bullet line)
  - The response line (the `> ` line below it)
  - Any existing comment blocks (`<!-- ... -->`) below the response
  - The parent Item and Questions headings for context
- Classify each question-response pair:
  1. **Answered** — `>` line has substantive user text (not empty, not a research trigger)
  2. **Research directive** — user response contains a research request (same triggers as `@acp.clarifications-research`: "research this", "look into this", "check the codebase", "agent: ...", etc.)
  3. **Empty** — `>` line is blank
  4. **Comment-block question** — user has written a new open question or feedback inside an HTML comment block (`<!-- ... -->`) that needs a response
- Build the full list of addressable items

**Expected Outcome**: Structured parse of all question-response pairs with classifications

### 3. Report Scan Results

Display a summary of what was found.

**Display format**:
```
📋 Addressing clarification: agent/clarifications/clarification-{N}-{title}.md

  Questions found: {total}
    ✎ User answers to address:     {count}
    🔬 Research directives:         {count}
    💬 Comment-block questions:     {count}
    ⬚ Empty (skipped):             {count}
```

**If `--dry-run`**: Display the summary above and stop. Do not proceed to Step 4.

**If nothing to address** (all empty, no comment-block questions): Report that there is nothing to address and stop.

**Expected Outcome**: User sees what will be addressed; dry-run exits here

### 4. Address Each Item

Process each addressable item in document order. For each item, the agent reads the question, reads the user's response, and determines what action to take.

**4a. Honor Research Directives**

For items classified as **research directives**:

**Actions**:
- If the directive asks to explore the codebase: use Glob, Grep, Read tools
  - If `--scope <path>` was provided, limit searches to that directory
- If the directive asks to explore the web: use WebSearch and WebFetch tools
- If the directive asks to use MCP tools: invoke the specified MCP tool(s)
- If the directive is a general research request: use codebase exploration by default
- If the directive says "tradeoffs": provide tradeoffs
- If the directive says "clarify": then clarify your question
- Compile findings into a concise summary

**Expected Outcome**: Research compiled for each directive

**4b. Analyze User Answers**

For items classified as **answered**:

**Actions**:
- Read and understand the user's response in the context of the question
- Determine if the response implies follow-up work:
  - Does the response reference code that should be verified? → Explore the code
  - Does the response mention an external tool, API, or resource? → Research it if clarification would help
  - Does the response introduce a tradeoff? → Analyze both sides
  - Does the response leave ambiguity? → Note what needs further clarification
  - Is the response clear and complete? → Acknowledge briefly, no comment block needed
- Only generate a comment block if the agent has something substantive to add (tradeoff analysis, recommendation, code reference, follow-up question)
- Do NOT generate comment blocks that merely restate or acknowledge the user's answer

**Expected Outcome**: Substantive analysis generated where warranted

**4c. Respond to Comment-Block Questions**

Content in comment blocks is only ever authored by you.

**Actions**:
- Read the comment content

**Expected Outcome**: All user comment-block questions addressed

### 5. Present Tradeoffs and Recommendations

For any question where the user's response surfaces a meaningful tradeoff or where the agent's research reveals competing approaches:

**Actions**:
- If applicable, present tradeoffs as either:
  - a concise comparison (2-4 bullet points per option)
  - a detailed response
  - a summary table 
  - or all three
- Provide a recommendation with rationale (if the agent has enough context to justify one)
- If the agent cannot recommend: state that clearly and explain what additional information would help
- Frame recommendations in terms of the project's existing patterns and architecture

**Expected Outcome**: Tradeoffs and recommendations documented where relevant

### 6. Write Comment Blocks to File

Insert agent responses into the clarification document.

**Actions**:
- For each addressable item that produced a response, insert an HTML comment block directly below the `>` response line (or below an existing comment block if responding to one)
- Comment block format:
  ```markdown
  <!-- [Agent]
  {response content}
  -->
  ```
- For research results:
  ```markdown
  <!-- [Agent — Researched]
  {findings with file references}
  -->
  ```
- For tradeoff analysis:
  ```markdown
  <!-- [Agent Analysis]
  {tradeoff and recommendation}
  -->
  ```
- Preserve the original file's formatting, indentation, and surrounding content
- Do NOT modify any `>` response lines
- Do NOT modify any user-written comment blocks
- Do NOT change the clarification's `Status:` field

**Expected Outcome**: Clarification file updated with agent comment blocks

### 7. Report Results

Show what was addressed and what remains.

**Display format**:
```
✅ Clarification Addressed!

File: agent/clarifications/clarification-{N}-{title}.md

  Addressed: {count} items
    🔬 Research responses:      {count}
    💡 Tradeoff analyses:       {count}
    💬 Comment responses:        {count}
    ○ Skipped (clear answers):  {count}

  Remaining empty lines: {empty-count} (still need user answers)

  Status unchanged — review agent comments, then capture or continue.
```

**Expected Outcome**: User sees a summary of what was addressed and knows what's next

---

## Verification

- [ ] Clarification file located correctly (positional, --latest, or auto-detect)
- [ ] All question-response pairs parsed and classified correctly
- [ ] User responses on `>` lines are completely untouched
- [ ] Research directives honored (codebase, web, MCP tools as specified)
- [ ] Tradeoffs presented with clear pro/con analysis
- [ ] Recommendations provided where agent has sufficient context
- [ ] Comment-block questions responded to
- [ ] All agent responses written as HTML comment blocks
- [ ] `--dry-run` reports without modifying the file
- [ ] `--scope` limits codebase exploration to specified directory
- [ ] Clarification status is NOT changed
- [ ] Existing user comment blocks are NOT modified

---

## Expected Output

### Files Modified
- `agent/clarifications/clarification-{N}-{title}.md` - Agent comment blocks inserted below addressed items

### Console Output
```
📋 Addressing clarification: agent/clarifications/clarification-9-handoff-requirements.md

  Questions found: 18
    ✎ User answers to address:     14
    🔬 Research directives:         2
    💬 Comment-block questions:     1
    ⬚ Empty (skipped):             1

✅ Clarification Addressed!

  Addressed: 8 items
    🔬 Research responses:      2
    💡 Tradeoff analyses:       3
    💬 Comment responses:        1
    ○ Skipped (clear answers):  10

  Remaining empty lines: 1 (still need user answers)

  Status unchanged — review agent comments, then capture or continue.
```

### Example Comment Block in Document

```markdown
- Should the handoff be written as a markdown file saved to disk, or output directly to chat?

> Prompt user

<!-- [Agent Analysis]
**Tradeoff**: Output destination
- Disk (agent/reports/): Pro: persistent, shareable, version-controlled. Con: extra file to manage.
- Chat: Pro: immediate, no file cleanup. Con: lost when context ends, can't be referenced later.

**Recommendation**: Prompt user (as specified) — both options have clear use cases. The prompt should default to chat for quick handoffs and offer disk for complex ones.
-->
```

---

## Examples

### Example 1: Address Latest Clarification

**Context**: Just finished answering questions in a clarification, want the agent to analyze responses

**Invocation**: `@acp.clarification-address`

**Result**: Auto-detects the latest clarification, reads all user responses, researches directives, presents tradeoffs where relevant, and writes analysis as comment blocks.

### Example 2: Address with Web Research

**Context**: Clarification has questions where user responded "look into this" about an external API

**Invocation**: `@acp.clarification-address --latest`

**Result**: Agent finds research directives, uses WebSearch/WebFetch to research external APIs, writes findings as `[Agent — Researched]` comment blocks.

### Example 3: Dry Run

**Context**: Want to preview what would be addressed before modifying the file

**Invocation**: `@acp.clarification-address agent/clarifications/clarification-5-foo.md --dry-run`

**Result**: Shows count of items to address by type, without modifying the file.

### Example 4: Respond to User Feedback in Comment Blocks

**Context**: User reviewed agent's previous comment blocks and left follow-up questions in their own comment blocks

**Invocation**: `@acp.clarification-address`

**Result**: Agent detects user comment blocks containing questions, researches and responds with new comment blocks below each.

---

## Related Commands

- [`@acp.clarification-create`](acp.clarification-create.md) - Create clarification documents (run first)
- [`@acp.clarifications-research`](acp.clarifications-research.md) - Simpler alternative: only fills in `> research this` lines without analysis
- [`@acp.clarification-capture`](acp.clarification-capture.md) - Capture answered clarifications into design docs / tasks (run after addressing)
- [`@acp.design-create`](acp.design-create.md) - Create design documents (often follows clarification)
- [`@acp.task-create`](acp.task-create.md) - Create task documents (may use clarification answers)

---

## Troubleshooting

### Issue 1: No clarifications found

**Symptom**: "No clarification files found"

**Cause**: No clarification files exist or all have been captured

**Solution**: Create a new clarification with `@acp.clarification-create` or provide a specific file path

### Issue 2: No items to address

**Symptom**: "Nothing to address — all response lines are empty"

**Cause**: User hasn't answered any questions yet

**Solution**: Fill out the clarification first, then re-run this command

### Issue 3: MCP tool not available

**Symptom**: Agent cannot invoke a requested MCP tool

**Cause**: The MCP server isn't configured or the tool name is incorrect

**Solution**: Check MCP server configuration. The agent will note the failure in its comment block and suggest manual resolution.

### Issue 4: Web research blocked

**Symptom**: WebSearch/WebFetch calls fail

**Cause**: Network restrictions or tool permissions

**Solution**: Agent will note "Unable to research — manual answer needed" in the comment block. User can fill in manually.

---

## Security Considerations

### File Access
- **Reads**: Clarification files in `agent/clarifications/`, any codebase files during research
- **Writes**: The target clarification file only (inserting comment blocks)
- **Executes**: None

### Network Access
- **APIs**: WebSearch/WebFetch when user directs web research; MCP tools when user directs tool use
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets or credentials in comment blocks
- **Credentials**: If a question involves credentials or secrets, note "manual review needed" instead

---

## Notes

- This command never changes the clarification's `Status:` field — the user reviews agent comments and then uses `@acp.clarification-capture` when satisfied
- Agent responses are always written as HTML comment blocks, keeping `>` response lines as the canonical user content
- The `[Agent]`, `[Agent — Researched]`, and `[Agent Analysis]` prefixes make it easy to distinguish agent comment types
- If a comment block response is wrong, the user can delete it or leave a follow-up comment block — re-running the command will address the new comment
- This command is complementary to `@acp.clarifications-research`: use research for quick fill-in of delegated lines, use address for comprehensive analysis after user responses
- The agent should be selective about which answers get comment blocks — clear, unambiguous answers that need no follow-up should be skipped silently

---

**Namespace**: acp
**Command**: clarification-address
**Version**: 1.0.0
**Created**: 2026-03-14
**Last Updated**: 2026-03-14
**Status**: Active
**Compatibility**: ACP 5.16.0+
**Author**: ACP Project
