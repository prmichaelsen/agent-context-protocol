# Command: clarification-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-clarification-create` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-clarification-create NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
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

**Natural Language Arguments**:
- `@acp.clarification-create from draft file` - Analyze draft and create clarifications
- `@acp.clarification-create for feature X` - Create clarifications about feature X
- `@acp.clarification-create` - Interactive mode (no file)

**Argument Mapping**:
The agent infers intent from context:
- If file path mentioned → Read and analyze that file
- If topic mentioned → Create clarifications about that topic
- If no arguments → Interactive chat-based clarification creation

---

## What This Command Does

This command creates structured clarification documents following the [`agent/clarifications/clarification-{N}-{title}.template.md`](../clarifications/clarification-{N}-{title}.template.md) format. It can analyze existing files (drafts, designs, requirements) to identify gaps and generate targeted questions, or work interactively via chat to gather requirements.

Clarification documents use a hierarchical structure (Items > Questions > Bullet points) to organize related questions logically. They include response markers (`>`) for users to provide answers inline, making it easy to capture detailed requirements without lengthy back-and-forth conversations.

Use this command when you need to gather detailed information about ambiguous requirements, unclear design decisions, or incomplete specifications. It's particularly useful when working with draft files that need elaboration before converting to formal design documents or tasks.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] Clarification template exists (agent/clarifications/clarification-{N}-{title}.template.md)
- [ ] (Optional) Source file to analyze if using file-based workflow

---

## Steps

### 1. Determine Next Clarification Number

Find the next available clarification number:

**Actions**:
- List all existing clarification files in agent/clarifications/
- Parse clarification numbers (clarification-1-*, clarification-2-*, etc.)
- Find highest number
- Increment by 1 for new clarification number

**Expected Outcome**: Next clarification number determined (e.g., clarification-7)

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

**If analyzing file**:
- Generate 10-30 questions based on gaps found
- Organize by logical topic areas
- Reference specific sections of source file

**If interactive mode**:
- Ask user: "What topics need clarification?"
- Generate questions based on user's description
- Aim for 5-15 questions initially

**Expected Outcome**: Structured questions generated

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
- Update Status to "Completed" when done
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
- After clarification is complete, use answers to update design docs, tasks, or create new entities
- Clarifications are typically kept in version control for historical reference
- Good clarifications have 10-30 questions organized into 3-5 major topics

---

**Namespace**: acp
**Command**: clarification-create
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
**Status**: Active
**Compatibility**: ACP 4.0.0+
**Author**: ACP Project
