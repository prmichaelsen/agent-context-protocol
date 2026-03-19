# Command: clarification-address

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-clarification-address` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-clarification-address NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 2.0.0  
**Created**: 2026-03-14  
**Last Updated**: 2026-03-17  
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
- `--deep` or `-d` - Full analysis: web research, MCP tools, tradeoff analysis, recommendations (default)
- `--shallow` - Codebase-only research, no tradeoffs/recommendations, no web/MCP

**Natural Language Arguments**:
- `@acp.clarification-address agent/clarifications/clarification-9-foo.md` - Address a specific file
- `@acp.clarification-address --latest` - Address the most recent clarification
- `@acp.clarification-address` - Same as `--latest` (auto-detect), deep mode
- `@acp.clarification-address --shallow` - Quick codebase-only pass

**Argument Mapping**:
The agent infers intent from context:
- If a file path is provided → use that clarification file
- If `--latest` → find the most recent clarification with status "Awaiting Responses" or "Completed"
- If no arguments → same as `--latest` (auto-detect)
- If neither `--deep` nor `--shallow` → default to `--deep`

### Depth Modes

| | `--deep` (default) | `--shallow` |
|---|---|---|
| Codebase research (Glob/Grep/Read) | Yes | Yes |
| Web research (WebSearch/WebFetch) | Yes | No |
| MCP tool invocation | Yes | No |
| Tradeoff analysis | Yes | No |
| Recommendations | Yes | No |
| Analyze user answers for follow-up | Yes | No — only process research directives |
| Comment-block questions | Yes | Yes |

In `--shallow` mode, the agent only processes **research directives** and **comment-block questions**. User answers classified as "answered" are skipped entirely — no analysis, no follow-up, no comment blocks. This makes `--shallow` ideal for a quick pass to fill in delegated research before the user reviews.

---

## What This Command Does

This command reads a clarification document, understands what the user has responded, and actively engages with those responses. It reads user answers, honors embedded research directives, explores code or the web when asked, invokes MCP tools when directed, analyzes tradeoffs, provides recommendations, and responds to open questions the user has left in comment blocks.

The agent writes its responses as HTML comment blocks (`<!-- ... -->`) directly below the relevant question-response pair. This keeps the clarification document clean — user responses remain the canonical content on the `>` lines, while agent analysis, tradeoffs, and recommendations live in comments that are visible when editing but don't clutter the rendered view. The agent never modifies `>` response lines.

Use `--deep` (default) after filling out clarification responses when you want the agent to process your answers, do follow-up research, and provide analysis before moving to design or task creation.

Use `--shallow` for a quick pass when you've left "research this" or "agent: ..." directives on response lines and just want the agent to fill in codebase-based answers without full analysis.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] At least one clarification file exists in `agent/clarifications/`
- [ ] Target clarification has user responses on `>` lines (not all empty), or research directives

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
  2. **Research directive** — user response contains a research request. Trigger phrases (case-insensitive): "research this", "look this up", "look into this", "check the codebase", "check the code", "check the repo", "figure this out", "figure it out", "find out", "investigate", or line content (after `> `) starts with `agent:` prefix (explicit delegation, e.g. `> agent: check how the yaml parser works`)
  3. **Empty** — `>` line is blank
  4. **Comment-block question** — user has written a new open question or feedback inside an HTML comment block (`<!-- ... -->`) that needs a response
- Build the full list of addressable items

**Expected Outcome**: Structured parse of all question-response pairs with classifications  

### 3. Report Scan Results

Display a summary of what was found.

**Display format**:
```
📋 Addressing clarification: agent/clarifications/clarification-{N}-{title}.md
   Mode: {--deep|--shallow}

  Questions found: {total}
    ✎ User answers to address:     {count}
    🔬 Research directives:         {count}
    💬 Comment-block questions:     {count}
    ⬚ Empty (skipped):             {count}
```

**If `--shallow`**: Also note which items will be skipped due to shallow mode:  
```
  ℹ️  Shallow mode: {answered-count} user answers will be skipped (use --deep for full analysis)
```

**If `--dry-run`**: Display the summary above and stop. Do not proceed to Step 4.  

**If nothing to address** (all empty, no research directives, no comment-block questions): Report that there is nothing to address and stop.

**Expected Outcome**: User sees what will be addressed; dry-run exits here  

### 4. Address Each Item

Process each addressable item in document order. For each item, the agent reads the question, reads the user's response, and determines what action to take.

**4a. Honor Research Directives** (both `--deep` and `--shallow`)

For items classified as **research directives**:

**Actions**:
- Use the question context (question text + section heading) to determine what to search for
- If `agent:` prefix was used, the text after `agent:` is an explicit research directive — follow it
- Otherwise, infer what to look up from the question
- Use Glob, Grep, and Read tools to explore the codebase
  - If `--scope <path>` was provided, limit searches to that directory
- **`--deep` only**: If the directive asks to explore the web, use WebSearch and WebFetch tools
- **`--deep` only**: If the directive asks to use MCP tools, invoke the specified MCP tool(s)
- **`--deep` only**: If the directive says "tradeoffs", provide tradeoffs
- If the directive says "clarify": then clarify your question
- Synthesize a concise, factual answer with file references where applicable
  - Be specific — cite file paths and line numbers (e.g., `see agent/scripts/acp.yaml-parser.sh:L45-L120`)
  - If the answer cannot be determined from the codebase, write: "Unable to determine from codebase — manual answer needed."
  - Do not speculate beyond what the code shows
  - Keep answers concise but complete

**Expected Outcome**: Research compiled for each directive  

**4b. Analyze User Answers** (`--deep` only)

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

**In `--shallow` mode**: Skip all "answered" items entirely. Do not analyze, do not generate comment blocks.  

**Expected Outcome**: Substantive analysis generated where warranted  

**4c. Respond to Comment-Block Questions** (both `--deep` and `--shallow`)

Content in comment blocks is only ever authored by you.

**Actions**:
- Read the comment content

**Expected Outcome**: All user comment-block questions addressed  

### 5. Present Tradeoffs and Recommendations (`--deep` only)

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

**In `--shallow` mode**: Skip this step entirely.  

**Expected Outcome**: Tradeoffs and recommendations documented where relevant  

### 6. Write Comment Blocks to File

Insert agent responses into the clarification document.

**Actions**:
- For each addressable item that produced a response, insert an HTML comment block directly below the `>` response line (or below an existing comment block if responding to one)
- **Always add a blank `>` response line** immediately after each comment block to allow the user to respond
- Comment block format:
  ```markdown
  <!-- [Agent]
  {response content}
  -->

  >
  ```
- For research results:
  ```markdown
  <!-- [Agent — Researched]
  {findings with file references}
  -->

  >
  ```
- For tradeoff analysis with recommendation (`--deep` only):
  ```markdown
  <!-- [Agent Analysis]
  {tradeoff and recommendation}

  Would you like to accept this recommendation? (yes/no)
  -->

  >
  ```
- For tradeoff analysis without recommendation (`--deep` only):
  ```markdown
  <!-- [Agent Analysis]
  {tradeoff analysis}
  -->

  >
  ```
- If the comment block contains a recommendation, end the comment block with "Would you like to accept this recommendation? (yes/no)" before the closing `-->`
- Preserve the original file's formatting, indentation, and surrounding content
- Do NOT modify any `>` response lines
- Do NOT modify any user-written comment blocks
- Do NOT change the clarification's `Status:` field

**Expected Outcome**: Clarification file updated with agent comment blocks, each followed by a blank `>` response line  

### 7. Report Results

Show what was addressed and what remains.

**Display format**:
```
✅ Clarification Addressed!

File: agent/clarifications/clarification-{N}-{title}.md
Mode: {--deep|--shallow}

  Addressed: {count} items
    🔬 Research responses:      {count}
    💡 Tradeoff analyses:       {count}  (--deep only)
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
- [ ] Research directives honored (codebase always; web/MCP in `--deep` only)
- [ ] `--deep`: Tradeoffs presented with clear pro/con analysis
- [ ] `--deep`: Recommendations provided where agent has sufficient context
- [ ] `--deep`: Recommendations end with "Would you like to accept this recommendation? (yes/no)"
- [ ] `--shallow`: Only research directives and comment-block questions processed
- [ ] `--shallow`: No web research, MCP tools, tradeoffs, or answer analysis
- [ ] Comment-block questions responded to
- [ ] All agent responses written as HTML comment blocks
- [ ] Each comment block is followed by a blank `>` response line
- [ ] `--dry-run` reports without modifying the file
- [ ] `--scope` limits codebase exploration to specified directory
- [ ] Clarification status is NOT changed
- [ ] Existing user comment blocks are NOT modified

---

## Expected Output

### Files Modified
- `agent/clarifications/clarification-{N}-{title}.md` - Agent comment blocks inserted below addressed items

### Console Output (--deep)
```
📋 Addressing clarification: agent/clarifications/clarification-9-handoff-requirements.md
   Mode: --deep

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

### Console Output (--shallow)
```
📋 Addressing clarification: agent/clarifications/clarification-5-yaml-parser.md
   Mode: --shallow

  Questions found: 15
    ✎ User answers to address:     6
    🔬 Research directives:         5
    💬 Comment-block questions:     0
    ⬚ Empty (skipped):             4

  ℹ️  Shallow mode: 6 user answers will be skipped (use --deep for full analysis)

✅ Clarification Addressed!

  Addressed: 5 items
    🔬 Research responses:      5
    ○ Skipped (shallow mode):   6

  Remaining empty lines: 4 (still need user answers)

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

Would you like to accept this recommendation? (yes/no)
-->

>
```

---

## Examples

### Example 1: Address Latest Clarification (Deep, Default)

**Context**: Just finished answering questions in a clarification, want the agent to analyze responses  

**Invocation**: `@acp.clarification-address`  

**Result**: Auto-detects the latest clarification, reads all user responses, researches directives, presents tradeoffs where relevant, and writes analysis as comment blocks.  

### Example 2: Shallow Pass for Research Directives

**Context**: Left "research this" on several questions, want quick codebase answers before reviewing  

**Invocation**: `@acp.clarification-address --shallow`  

**Result**: Finds research directives, explores the codebase, writes `[Agent — Researched]` comment blocks. Skips user answers entirely — no tradeoffs, no web research.  

### Example 3: Address with Web Research (Deep)

**Context**: Clarification has questions where user responded "look into this" about an external API  

**Invocation**: `@acp.clarification-address --deep`  

**Result**: Agent finds research directives, uses WebSearch/WebFetch to research external APIs, writes findings as `[Agent — Researched]` comment blocks.  

### Example 4: Dry Run

**Context**: Want to preview what would be addressed before modifying the file  

**Invocation**: `@acp.clarification-address agent/clarifications/clarification-5-foo.md --dry-run`  

**Result**: Shows count of items to address by type, without modifying the file.  

### Example 5: Respond to User Feedback in Comment Blocks

**Context**: User reviewed agent's previous comment blocks and left follow-up questions in their own comment blocks  

**Invocation**: `@acp.clarification-address`  

**Result**: Agent detects user comment blocks containing questions, researches and responds with new comment blocks below each.  

---

## Related Commands

- [`@acp.clarification-create`](acp.clarification-create.md) - Create clarification documents (run first)
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

### Issue 3: MCP tool not available (--deep only)

**Symptom**: Agent cannot invoke a requested MCP tool  

**Cause**: The MCP server isn't configured or the tool name is incorrect  

**Solution**: Check MCP server configuration. The agent will note the failure in its comment block and suggest manual resolution.  

### Issue 4: Web research blocked (--deep only)

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
- **APIs**: `--deep` only: WebSearch/WebFetch when user directs web research; MCP tools when user directs tool use. `--shallow`: no network access.
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets or credentials in comment blocks
- **Credentials**: If a question involves credentials or secrets, note "manual review needed" instead

---

## Notes

- This command never changes the clarification's `Status:` field — the user reviews agent comments and then uses `@acp.clarification-capture` when satisfied
- Agent responses are always written as HTML comment blocks, keeping `>` response lines as the canonical user content — `>` lines are never modified
- Each comment block is followed by a blank `>` response line to allow the user to respond interactively
- Recommendations end with "Would you like to accept this recommendation? (yes/no)" to prompt user feedback
- The `[Agent]`, `[Agent — Researched]`, and `[Agent Analysis]` prefixes make it easy to distinguish agent comment types
- If a comment block response is wrong, the user can delete it or respond in the `>` line below — re-running the command will address the new response
- The agent should be selective about which answers get comment blocks — clear, unambiguous answers that need no follow-up should be skipped silently
- This command replaces the former `@acp.clarifications-research` command — use `--shallow` for the equivalent quick research-only behavior

---

**Namespace**: acp  
**Command**: clarification-address  
**Version**: 2.0.0  
**Created**: 2026-03-14  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Compatibility**: ACP 6.0.0+  
**Author**: ACP Project  
