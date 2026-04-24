# Command: clarification-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-clarification-create` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-clarification-create NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 1.2.0  
**Created**: 2026-02-25  
**Last Updated**: 2026-04-24  
**Status**: Active  

---

**Purpose**: Create clarification documents from file input or chat to gather detailed requirements  
**Category**: Creation  
**Frequency**: As Needed  

---

## Arguments

**CLI-Style Arguments**:
- `--file <path>` or `-f <path>` - Path to source file to analyze for clarifications
- `--title <title>` or `-t <title>` - Title for the clarification document
- `--auto` or `-a` - Automatically generate questions without user review
- `--interactive` or `-i` - **One-question-at-a-time chat mode** (see "Interactive Mode" below). Can be combined with a topic string: `-i "topic description"`

**Natural Language Arguments**:
- `@acp.clarification-create from draft file` - Analyze draft and create clarifications
- `@acp.clarification-create for feature X` - Create clarifications about feature X
- `@acp.clarification-create` - Chat-based mode (agent asks for topic, then generates full file)
- `@acp.clarification-create -i "topic"` - One-question-at-a-time interactive mode

**Argument Mapping**:
The agent infers intent from context:
- If `-i` or `--interactive` present → **One-question-at-a-time mode** (see below). Do NOT generate the file upfront.
- If file path mentioned → Read and analyze that file, generate full file
- If topic mentioned (no `-i`) → Create clarifications about that topic, generate full file
- If no arguments → Chat-based mode (asks for topic, generates full file)

### Interactive Mode (`-i` / `--interactive`) — One Question at a Time

**Critical behavior**: In interactive mode, the agent does **NOT** generate a clarification file. Clarifications are transient by default — the Q&A happens in chat and the answers feed directly into whatever comes next (impl, design update, task creation).

1. The agent presents **one question at a time in chat**, each with a strong y/n recommendation (per the Answer-effort principle).
2. The user answers with `y`, `n`, or a short override in prose.
3. Based on the answer, the agent either:
   - Asks the next question (may branch based on previous answers)
   - Drills deeper into a sub-decision the previous answer raised
   - Summarizes accumulated answers and awaits direction
4. The agent **does NOT write a file unless the user explicitly asks** ("save this as a clar", "write the file", "persist this", etc.). Skip Step 6 (Create Clarification File) by default.

**Why this mode exists**: Pre-generating 20+ questions forces the user to context-switch through the whole document before any feedback loop. One-at-a-time lets the agent adapt — if the user's answer reveals a misunderstanding, the agent can correct course on the next question instead of committing everything to a file. And since most clarifications are transient (used once to reach alignment, then consumed by the next command), there's no value in writing a file by default.

**What NOT to do in interactive mode**:
- ❌ Generate the clarification file first, then "discuss" it
- ❌ Generate the file at the end unless the user explicitly asks
- ❌ Batch multiple questions into one chat turn
- ❌ Skip the recommendation — each question must still lead with a y/n recommendation
- ❌ Ask open-ended "what do you think about X?" questions when a y/n with a recommendation is possible

**When to write the file**: Only when the user explicitly says to persist the clarification ("save this", "write the file", "make a clar out of this"). Otherwise, the accumulated answers live in chat context and get applied directly to the user's next request.

---

## What This Command Does

This command creates structured clarification documents following the [`agent/clarifications/clarification-{N}-{title}.template.md`](../clarifications/clarification-{N}-{title}.template.md) format. It can analyze existing files (drafts, designs, requirements) to identify gaps and generate targeted questions, or work interactively via chat to gather requirements.

Clarification documents use a hierarchical structure (Items > Questions > Bullet points) to organize related questions logically. They include response markers (`>`) for users to provide answers inline, making it easy to capture detailed requirements without lengthy back-and-forth conversations.

Use this command when you need to gather detailed information about ambiguous requirements, unclear design decisions, or incomplete specifications. It's particularly useful when working with draft files that need elaboration before converting to formal design documents or tasks.

**Answer-effort principle**: clarification questions should, wherever possible, be y/n-answerable with a strong recommendation. A well-authored clarification lets the user work through the whole document typing mostly just `y` or `n`, writing prose only where they want to override the recommendation. Long clarifications are fine; long *user replies* mean the questions were authored poorly. See the "Generate Questions" guidelines below for the concrete format.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] Clarification template exists (agent/clarifications/clarification-{N}-{title}.template.md)
- [ ] (Optional) Source file to analyze if using file-based workflow

---

## Steps

### 0. Display Command Header

```
⚡ @acp.clarification-create
  Create clarification documents from file input or chat to gather detailed requirements

  Usage:
    @acp.clarification-create                      Chat-based mode (asks topic, generates file)
    @acp.clarification-create -i "topic"           One-question-at-a-time in chat
    @acp.clarification-create --file <path>        Analyze source file
    @acp.clarification-create -t <title>           Set clarification title
    @acp.clarification-create --auto               Auto-generate questions

  Related:
    @acp.clarification-address  Address responses with research and recommendations
    @acp.design-create          Create design documents (often follows clarification)
    @acp.task-create             Create tasks (may use clarification answers)
```

This step is informational only — do not wait for user input.

### 1. Determine Next Clarification Number

Find the next available clarification number:

**Actions**:
- List all existing clarification files in agent/clarifications/
- Parse clarification numbers (clarification-1-*, clarification-2-*, etc.)
- Find highest number
- Increment by 1 for new clarification number

**Expected Outcome**: Next clarification number determined (e.g., clarification-7)  

### 1.5. Check Existing Clarifications for Overlap

Before generating questions, check if existing clarifications already cover related topics.

**Actions**:
- List all files in `agent/clarifications/` (exclude `*.template.md`)
- For each file, extract the title from the filename (e.g., `clarification-5-key-file-directive.md` → "key-file-directive")
- Infer from titles which clarifications might be relevant to the current topic
  - Use keyword matching between the current topic/title and existing clarification titles
  - Only load clarifications that appear relevant (avoid unnecessary context token consumption)
- If relevant clarifications found:
  - Read them to identify already-answered questions
  - When generating questions in Step 5, cross-reference with these answered questions
  - Skip or note questions that have already been answered elsewhere
- Produce visible output showing what was checked

**Display format**:
```
🔍 Checking existing clarifications for overlap...
  ✓ clarification-5-key-file-directive.md — not relevant (skipped)
  ✓ clarification-6-create-command-context-capture.md — relevant, loaded
    → 20 questions already answered on context capture topic

  1 existing clarification loaded, 1 skipped
  Will avoid duplicating answered questions.
```

**Heuristic**: This is a title-based relevance check, not an exhaustive content scan. If a title doesn't seem related to the current topic, skip it entirely to conserve context tokens. When in doubt, skip — it's better to occasionally re-ask a question than to burn tokens loading irrelevant clarifications.  

**Expected Outcome**: Existing relevant clarifications identified, duplicate questions will be avoided  

### 2. Check for Source File

Check if file was provided as argument:

**Syntax**:
- `@acp.clarification-create --file agent/drafts/my-draft.md`
- `@acp.clarification-create @my-draft.md` (@ reference)
- `@acp.clarification-create` (no file - interactive mode)

**Actions**:
- If file provided: Read source file
- If no file: Proceed to interactive mode

**Expected Outcome**: Source file read (if provided) or interactive mode confirmed  

### 3. Collect Clarification Information

Gather information from user via chat:

**Information to Collect**:
- **Clarification title** (descriptive, kebab-case)
  - Example: "package-create-enhancements" or "firebase-auth-requirements"
  - Validation: lowercase, alphanumeric, hyphens
- **Purpose** (one-line description of what needs clarification)
  - Example: "Clarify package creation workflow and metadata requirements"
- **Source context** (what document/feature this relates to)
  - Example: "agent/design/acp-package-development-system.md"

**Expected Outcome**: All clarification metadata collected  

### 4. Analyze Source Content (If File Provided)

If source file was provided, analyze for gaps:

**Actions**:
- Read and understand source file content
- Identify ambiguous statements
- Find missing details
- Note incomplete specifications
- Detect assumptions that need validation
- List areas needing user input

**Expected Outcome**: List of topics needing clarification identified  

### 5. Generate Questions

Create structured questions organized by topic:

**Structure**:
```markdown
# Item 1: {Major Topic}

## Questions 1.1: {Subtopic}

- Specific question 1?

> 

- Specific question 2?

> 

## Questions 1.2: {Another Subtopic}

- Question 1?

> 
```

**Guidelines**:
- Group related questions under Items (major topics)
- Use Questions subsections for subtopics
- Keep questions specific and actionable
- Provide context for complex questions
- Include examples where helpful
- Leave blank response lines (`>`) for user answers
- **Default to a strong recommendation in yes/no form.** The goal is that the user can work through a clarification document typing mostly just `y` / `n` (or `yes` / `no`), elaborating in prose *only* where they want to override the recommendation. This cuts the length of `@acp.clarification-address` passes dramatically and keeps the user's effort proportional to the disagreements, not the question count.
  - **Default form**: "We recommend **X** — {1-clause rationale}. Accept? (y/n)" — user types `y` to accept or `n` to reject; rejecting triggers follow-up in `@acp.clarification-address`.
  - **Take a stance.** If you have enough context to justify a preference, give one even when both options have real tradeoffs. A confident recommendation the user can reject with one keystroke is cheaper than a neutral "which do you want?" that forces them to write a sentence.
  - **3+ options**: still lead with the recommended option in y/n form — "Recommend **A** — {rationale}. Accept? (y/n; if n we'll ask which of B/C/D)." This keeps the common path to a single keystroke.
  - **Multi-option per-item questions** (a set of features/properties decided independently): each bullet gets its own per-item recommendation with a `>` response line so the user can accept or override each with `y`/`n`:
    ```markdown
    - Which properties should be included in the schema?

      - **name** — recommend: yes (every entity needs a display name)
      >
      - **description** — recommend: yes (searchability)
      >
      - **version** — recommend: no (only for versioned entities)
      >
      - **author** — recommend: no (metadata not worth the space)
      >
    ```
    Users type `y`/`n` per line, or override with a short note on the line where they disagree.
  - **When options are genuinely equivalent** (pure taste, no evidence either way): drop the recommendation and ask neutrally — "Prefer **X**? (y/n — if n we'll use the alternative)." Still one-keystroke-answerable, just without a stance.
  - **Do NOT hedge.** "We might suggest X, but Y could also work" is worse than no recommendation — it asks the user to pick without helping them. If you can't justify a stance in one clause, drop the recommendation and present the neutral y/n.
  - **Keep rationales short** — one clause, ideally under 15 words. If a recommendation needs a paragraph to justify, that's a signal the question belongs in `@acp.clarification-address` for research, not here.
- **Reserve prose-answer questions for genuinely open-ended questions** (names, descriptions, free-text context). If a question could plausibly be re-framed as a y/n with a recommendation, do that instead.

**If analyzing file**:
- Generate 10-30 questions based on gaps found
- Organize by logical topic areas
- Reference specific sections of source file

**If chat-based mode (no `-i` flag)**:
- Ask user: "What topics need clarification?"
- Generate questions based on user's description
- Aim for 5-15 questions initially
- Write the full file when questions are ready

**If interactive mode (`-i` / `--interactive`)** — one question at a time, transient by default:
- Do NOT generate the file. Do NOT batch questions.
- Present **one question per chat turn**, each with a strong y/n recommendation
- Branch based on answers: if an answer opens a sub-decision, drill into it before returning to the main thread
- Keep a running internal list of accumulated Q&A in chat context
- After ~8-20 questions (or when the user says "that's enough" / "go"), summarize accumulated answers and await direction
- **Skip Step 6 (Create Clarification File) by default** — clarifications are transient; the Q&A feeds directly into the user's next request
- Only write the file if the user explicitly asks ("save this as a clar", "write the file", "persist this")
- Questions still follow the y/n recommendation format — interactive mode is not permission to ask open-ended questions

**Expected Outcome**: Structured questions generated (chat-based / file-based) OR accumulated transient Q&A from interactive session (no file unless requested)  

### 6. Create Clarification File

Generate clarification document from template:

**Actions**:
- Determine full filename: `clarification-{N}-{title}.md`
  - N = clarification number from Step 1
  - title = kebab-case version of clarification title
- Copy structure from clarification template
- Fill in metadata:
  - Clarification number and title
  - Purpose
  - Created date
  - Status: "Awaiting Responses"
- Fill in Items and Questions sections with generated questions
- Include "How to Use This Document" section from template
- Save to `agent/clarifications/clarification-{N}-{title}.md`

**Expected Outcome**: Clarification file created  

### 7. Report Success

Display what was created:

**Output**:
```
✅ Clarification Created Successfully!

File: agent/clarifications/clarification-{N}-{title}.md
Number: {N}
Title: {title}
Questions: {count} questions across {item-count} topics
Status: Awaiting Responses

✓ Clarification file created
✓ {count} questions generated

Next steps:
- Review the clarification file
- Answer questions by typing responses after > markers
- To leave feedback or ask follow-up questions, use HTML comment blocks (<!-- your feedback -->)
- Update Status to "Completed" when done
- Run @acp.clarification-address to have the agent analyze your responses and address comment-block feedback
- Use answers to update design docs, tasks, or create new entities
```

**Expected Outcome**: User knows clarification was created and how to use it  

---

## Verification

- [ ] Next clarification number determined correctly
- [ ] Clarification information collected
- [ ] Source file analyzed (if provided)
- [ ] Questions generated and organized logically
- [ ] Clarification file created with correct number and title
- [ ] File follows template structure
- [ ] All metadata filled in correctly
- [ ] Questions are clear and actionable
- [ ] Response markers (>) included for all questions

---

## Expected Output

### Files Created
- `agent/clarifications/clarification-{N}-{title}.md` - Clarification document with structured questions

### Files Modified
- None (clarifications are standalone documents)

---

## Examples

### Example 1: Creating Clarification from Draft File

**Context**: Have draft design document that needs elaboration  

**Invocation**: `@acp.clarification-create --file agent/drafts/auth-system-draft.md`  

**Result**:
```
✅ Clarification Created Successfully!

File: agent/clarifications/clarification-7-auth-system-requirements.md
Number: 7
Title: auth-system-requirements
Questions: 25 questions across 4 topics
Status: Awaiting Responses

Topics covered:
- Authentication Methods (8 questions)
- Security Requirements (7 questions)
- User Management (6 questions)
- Integration Points (4 questions)

✓ Clarification file created
✓ 25 questions generated

Next steps:
- Review agent/clarifications/clarification-7-auth-system-requirements.md
- Answer questions by typing responses after > markers
- Update Status to "Completed" when done
```

### Example 2: Creating Clarification Interactively

**Context**: Need to gather requirements for new feature  

**Invocation**: `@acp.clarification-create`  

**Interaction**:
```
Agent: What would you like to title this clarification? (kebab-case)
User: payment-integration-requirements

Agent: What's the purpose? (one-line description)
User: Clarify payment gateway integration requirements and workflow

Agent: What topics need clarification?
User: Payment providers, security, webhooks, error handling

Agent: Generating questions for these topics...

✅ Clarification Created Successfully!

File: agent/clarifications/clarification-8-payment-integration-requirements.md
Number: 8
Title: payment-integration-requirements
Questions: 12 questions across 4 topics
Status: Awaiting Responses

✓ Clarification file created
✓ 12 questions generated
```

### Example 3: Creating Clarification with Custom Title

**Context**: Analyzing existing design document  

**Invocation**: `@acp.clarification-create --file agent/design/local.api-design.md --title api-endpoint-details`  

**Result**: Creates clarification-9-api-endpoint-details.md with questions about API design gaps  

---

## Related Commands

- [`@acp.clarification-address`](acp.clarification-address.md) - Address user responses with research, tradeoffs, and recommendations (use `--shallow` for quick research-only pass)
- [`@acp.design-create`](acp.design-create.md) - Create design documents (often follows clarification)
- [`@acp.task-create`](acp.task-create.md) - Create tasks (may use clarification answers)
- [`@acp.pattern-create`](acp.pattern-create.md) - Create patterns (may use clarification answers)

---

## Troubleshooting

### Issue 1: Source file not found

**Symptom**: Error message "File not found"  

**Solution**: Verify file path is correct. Use relative path from project root or @ reference for files in agent/drafts/  

### Issue 2: No questions generated

**Symptom**: Clarification created but empty  

**Solution**: Provide more context about what needs clarification. Source file may be too complete or too vague.  

### Issue 3: Questions too generic

**Symptom**: Generated questions are not specific enough  

**Solution**: Provide more detailed source file or specify topics more precisely in interactive mode  

### Issue 4: Clarification number conflict

**Symptom**: Clarification file already exists with that number  

**Solution**: Command should auto-detect and use next available number. If conflict persists, manually check agent/clarifications/ directory.  

---

## Security Considerations

### File Access
- **Reads**: Source files (drafts, designs, requirements), clarification template
- **Writes**: agent/clarifications/clarification-{N}-{title}.md
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in clarifications
- **Credentials**: Never include credentials in questions or examples

---

## Notes

- Clarification title should be descriptive and relate to the topic
- Clarification number is automatically assigned (sequential)
- Questions should be specific and actionable
- Use hierarchical structure (Items > Questions > Bullet points)
- Response markers (>) make it easy for users to answer inline
- Clarifications are living documents - can be updated as questions are answered
- Users can leave feedback or follow-up questions in HTML comment blocks (`<!-- ... -->`); run `@acp.clarification-address` to have the agent respond
- After clarification is complete, use answers to update design docs, tasks, or create new entities
- Clarifications are typically kept in version control for historical reference
- Good clarifications have 10-30 questions organized into 3-5 major topics
- **A good clarification document can be answered almost entirely with `y`/`n` keystrokes.** If most of your questions require prose answers, you're under-recommending — take stances on the things you have context for and reserve prose for genuinely open-ended decisions.

---

**Namespace**: acp  
**Command**: clarification-create  
**Version**: 1.2.0  
**Created**: 2026-02-25  
**Last Updated**: 2026-04-24  
**Status**: Active  
**Compatibility**: ACP 4.0.0+  
**Author**: ACP Project  
