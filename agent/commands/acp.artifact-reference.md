# Command: artifact-reference

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.artifact-reference` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.artifact-reference NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-03-17  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Create reference guides for passive information after command-first principle check  
**Category**: Entity Creation  
**Frequency**: As Needed  

---

## Arguments

**CLI-Style Arguments**:
- `<topic>` (positional) - The reference topic (e.g., "environment variables")
- `--type <type>` - Reference type (config-table, cli-syntax, standards, diagrams, schemas, troubleshooting, api-contract)
- `--from-clarification <file>` - Pull topic and context from clarification file
- `--output <path>` or `-o <path>` - Custom output path (default: auto-numbered in `agent/artifacts/`)
- `--skip-check` - Skip command-first principle check (use with caution)
- `--auto-commit` - Auto-commit the artifact after creation (default: true)
- `--no-commit` - Skip auto-commit, leave artifact staged

**Natural Language Arguments**:
- `@acp.artifact-reference environment variables` - Create reference for topic
- `@acp.artifact-reference CLI syntax --type cli-syntax` - Specify reference type
- `@acp.artifact-reference --from-clarification clarification-9` - Pull from clarification
- `@acp.artifact-reference` - Infer topic from conversation context

**Argument Mapping**:
The agent infers intent from context:
1. If explicit topic provided → create reference for that
2. If `--from-clarification` → extract topic and context from clarification
3. If no arguments → infer from current task, milestone, or conversation context
4. If still ambiguous → prompt user for topic

---

## What This Command Does

This command creates reference guides for passive information that cannot be automated as executable commands. Before creating a reference, the command performs a mandatory "command-first principle check" to evaluate whether the content should be a command instead.

**Command-first principle**: If information can be automated as an executable directive (`@local.*` or `@namespace.*`), create a command instead of a reference artifact. References should contain only passive information (lookup tables, diagrams, standards) that require human judgment or are purely informational.  

Reference artifacts are appropriate for:
- **Configuration tables** (environment variables, feature flags)
- **CLI syntax** (Git, Docker, SQL — generic tools, not project-specific workflows)
- **Standards/conventions** (code style, commit format, documentation style)
- **Architecture diagrams** (service maps, data flows, deployment topology)
- **Data schemas** (database ER diagrams, file format specifications)
- **Troubleshooting guides** (diagnostic decision trees requiring human judgment)
- **API/protocol contracts** (API request/response formats, message queue schemas)

---

## Prerequisites

- [ ] ACP installed in current directory (`agent/` directory exists)
- [ ] `agent/artifacts/` directory exists (will be created if not)
- [ ] `agent/artifacts/reference.template.md` exists

---

## Steps

### 1. Determine Reference Topic

Identify what reference to create.

**Actions**:
- If `--from-clarification <file>` provided:
  - Read the clarification file
  - Extract topic from clarification title, description, or questions
  - Extract any relevant context (decisions, constraints)
- If positional `<topic>` argument provided:
  - Use that as the reference topic directly
- If no arguments:
  - Infer from current conversation context (active task, recent discussion)
- If still unclear:
  - Prompt user: "What reference would you like to create?"

**Expected Outcome**: Clear reference topic identified (e.g., "environment variables", "Git workflow", "troubleshooting guide")  

### 2. Command-First Principle Check

Evaluate whether the content should be a command instead of a reference.

**Actions**:
- **Ask the critical question**: "Could this information be automated as an executable directive?"
- **Evaluate indicators**:
  - **Should be a COMMAND if**:
    - Contains step-by-step procedures agents can follow
    - Describes project-specific workflows (deploy, hotfix, release, feature start)
    - Involves code scaffolding (API endpoint creation, test generation, migrations)
    - Contains checklists with clear success criteria
    - Automates repetitive tasks
    - Examples: "how to deploy", "how to create a feature branch", "how to generate a migration"
  - **Should be a REFERENCE if**:
    - Contains lookup tables or configuration data
    - Describes generic CLI syntax (not project-specific)
    - Provides architecture diagrams requiring human interpretation
    - Documents external API contracts
    - Contains troubleshooting decision trees requiring human judgment
    - Lists standards/conventions that guide but don't automate
    - Examples: "environment variables", "Git command syntax", "architecture diagram", "API schema"

**Decision flow**:
```
Is this content executable by an agent?
  ├─ YES → Suggest creating a command instead
  │         "This looks like an executable workflow. Consider:
  │          @local.{workflow-name} or @namespace.{workflow-name}
  │          Would you like me to create a command instead?"
  │         Wait for user response.
  │         If yes → Exit this command, suggest invoking @acp.command-create
  │         If no → Proceed to Step 3
  └─ NO → Proceed to Step 3 (passive information, reference appropriate)
```

**If `--skip-check` flag**:
- Skip this step entirely, proceed directly to Step 3
- Use with caution — only when user is certain content is passive

**Expected Outcome**: Command-first check completed, decision made (command vs reference)  

### 3. Determine Reference Type

Identify the reference type to use the appropriate template structure.

**Actions**:
- If `--type <type>` provided:
  - Use that type directly
- Otherwise, infer from topic and content:
  - Keywords like "environment", "config", "variables" → config-table
  - Keywords like "CLI", "syntax", "commands" → cli-syntax
  - Keywords like "style", "conventions", "standards" → standards
  - Keywords like "architecture", "diagram", "topology" → diagrams
  - Keywords like "schema", "database", "model" → schemas
  - Keywords like "troubleshooting", "debug", "diagnose" → troubleshooting
  - Keywords like "API", "endpoint", "contract" → api-contract
- If still ambiguous, prompt user:
  "What type of reference is this?
   1. Configuration table (env vars, feature flags)
   2. CLI syntax (generic tool commands)
   3. Standards/conventions (code style, commit format)
   4. Architecture diagrams (service maps, data flows)
   5. Data schemas (DB schemas, file formats)
   6. Troubleshooting guide (diagnostic decision trees)
   7. API/protocol contracts (request/response formats)"

**Reference type determines template structure** (see Step 5)

**Expected Outcome**: Reference type determined  

### 4. Gather Content

Collect information to populate the reference.

**Actions**:

**4a. Codebase Exploration** (if applicable):
- Search for existing configuration files, diagrams, documentation
- Extract current patterns, conventions, or standards from code
- Note file locations for "Related Documents" section

**4b. User Input**:
- For some reference types, user input is primary source:
  - Configuration tables: "List environment variables with descriptions"
  - Standards: "What are the code style rules?"
  - Troubleshooting: "What are common issues and resolutions?"
- Prompt user for content if not inferable from codebase

**4c. External Documentation** (if relevant):
- For CLI syntax references (Git, Docker, SQL):
  - Include basic command syntax
  - Cite official documentation URLs
  - Note version compatibility (e.g., "Git 2.x")

**Expected Outcome**: Sufficient content gathered to populate reference artifact  

### 5. Create Reference Artifact

Populate the reference artifact from template.

**Actions**:
- Start from template: `agent/artifacts/reference.template.md`
- Fill metadata block:
  - **Type**: reference
  - **Created**: Today's date (YYYY-MM-DD)
  - **Last Verified**: Same as Created
  - **Status**: Active
  - **Confidence**: High (9-10/10) if sourced from official docs, Medium (5-8/10) if inferred
  - **Category**: Domain-specific category (Configuration, Standards, Troubleshooting, etc.)
  - **Sources**: List of sources (official docs, codebase files, user input)
- Fill **Purpose** section (1-2 sentences: what this reference covers, when to use)
- Fill **Command-First Principle Check** section:
  - "Could this be a command?" → No
  - "Reason:" → Brief explanation (e.g., "Passive lookup table, no executable steps")

**Fill Content section based on reference type**:

**Config Table**:
```markdown
### Configuration Reference

| Variable | Type | Default | Description | Required |
|----------|------|---------|-------------|----------|
| `VAR_NAME` | string | `value` | Description | Yes/No |
```

**CLI Syntax**:
```markdown
### Command Syntax

```bash
# Command description
command [options] [arguments]

# Options:
#   -a, --flag-a    Description
#   -b, --flag-b    Description

# Examples:
command --flag-a value
command --flag-b value1 value2
```
```

**Standards**:
```markdown
### Standards

#### Category 1

- **Rule 1**: Description
  - Example: `code example`
  - Rationale: Why this standard exists
```

**Diagrams**:
```markdown
### Architecture Overview

```
[ASCII diagram or mermaid diagram]
```

**Component Descriptions:**
- **Component 1**: Purpose and responsibilities
```

**Schemas**:
```markdown
### Schema Definition

```json
{
  "field1": "type",
  "field2": {
    "nested": "value"
  }
}
```

**Field Descriptions:**
- `field1`: Description, constraints, examples
```

**Troubleshooting**:
```markdown
### Troubleshooting Decision Tree

**Symptom**: Observable issue  

1. **Check Thing 1**
   - If condition: Resolution
   - If not: Go to step 2
```

**API Contract**:
```markdown
### API Contract

**Endpoint**: `HTTP METHOD /path`  

**Request Format:**
```json
{"field": "value"}
```

**Response Format:**
```json
{"status": "success", "data": {}}
```
```

- Fill **Sources & References** section (all URLs with access dates)
- Fill **Related Documents** section (links to commands, designs, research artifacts)

**Expected Outcome**: Reference artifact file populated with content  

### 6. Validate Content

Verify reference artifact quality.

**Actions**:
- **Check for executability**: Re-verify no steps that could be automated
- **Check for completeness**: All sections filled (no "TODO" or placeholders)
- **Check for clarity**: Descriptions are clear and unambiguous
- **Check for accuracy**: Information is correct and up-to-date
- **Check for sources**: External info has citations with dates

**If validation fails**:
- Flag issues to user
- Prompt: "Issues detected: {list}. Should I proceed or revise?"

**Expected Outcome**: Reference artifact validated and ready to commit  

### 7. Auto-Commit (unless `--no-commit`)

Establish baseline commit for the reference.

**Actions**:
- Determine next artifact number:
  - List files in `agent/artifacts/` matching `reference-*`
  - Parse highest number, increment by 1
- Create file: `agent/artifacts/reference-{N}-{topic-slug}.md`
  - Topic slug: kebab-case, derived from topic
  - Example: "environment variables" → "environment-variables"
- If `--output <path>` provided, use that path instead
- If `--auto-commit` (default):
  - `git add agent/artifacts/reference-{N}-{topic-slug}.md`
  - Commit message: `docs(artifact): reference {topic-slug} (reference-{N})`
  - Notify user: "Baseline committed. Review and refine with visible git diff."
- If `--no-commit`:
  - Leave file staged but uncommitted
  - Notify user: "Reference staged, awaiting commit."

**Expected Outcome**: Reference artifact committed (or staged if `--no-commit`)  

### 8. Report Success

Display what was produced.

**Output format**:
```
✅ Reference Artifact Created!

File: agent/artifacts/reference-{N}-{topic-slug}.md
Topic: {topic}
Type: {reference-type}
Category: {category}
Confidence: {score}/10
Status: Active

{If auto-committed: "✓ Baseline committed. Refine with `git diff` and amend."}
{If --no-commit: "ℹ️  Staged, not committed. Review and commit when ready."}

Next steps:
- Review the reference for accuracy
- {If committed: Refine content and `git commit --amend`}
- Reference this artifact in related commands or documentation
```

**Expected Outcome**: User knows reference is complete and where to find it  

---

## Verification

- [ ] Reference topic identified (explicit or inferred)
- [ ] Command-first principle check completed (or skipped with `--skip-check`)
- [ ] If executable content detected, user prompted to create command instead
- [ ] Reference type determined (inferred or explicit)
- [ ] Content gathered (codebase, user input, external docs)
- [ ] Reference artifact created from template
- [ ] Metadata block complete (all required fields)
- [ ] Purpose section filled (what this covers, when to use)
- [ ] Command-first check section documented (explicit reasoning)
- [ ] Content section structured by reference type
- [ ] Sources & References section complete (citations with dates)
- [ ] No "TODO" or placeholder text
- [ ] Reference artifact file created in `agent/artifacts/reference-{N}-{topic-slug}.md`
- [ ] Auto-commit executed (unless `--no-commit`)
- [ ] Success message displayed

---

## Expected Output

### Files Created
- `agent/artifacts/reference-{N}-{topic-slug}.md` - Reference artifact

### Files Modified
- None

### Console Output
```
✅ Reference Artifact Created!

File: agent/artifacts/reference-1-environment-variables.md
Topic: Environment variables
Type: config-table
Category: Configuration
Confidence: 9/10
Status: Active

✓ Baseline committed. Refine with `git diff` and amend.

Next steps:
- Review the reference for accuracy
- Refine content and `git commit --amend`
- Reference this artifact in related commands or documentation
```

---

## Examples

### Example 1: Configuration Table

**Context**: Need to document all environment variables for new developers  

**Invocation**: `@acp.artifact-reference environment variables --type config-table`  

**Result**: Agent performs command-first check (passive lookup table, not executable), gathers env vars from .env.example and codebase, creates config table reference with Variable/Type/Default/Description/Required columns, auto-commits.  

### Example 2: CLI Syntax (Generic Tool)

**Context**: Team uses Git but not everyone knows advanced commands  

**Invocation**: `@acp.artifact-reference Git CLI syntax --type cli-syntax`  

**Result**: Agent checks command-first (generic tool syntax, not project workflow), creates CLI syntax reference with common Git commands + examples, cites official Git docs, auto-commits.  

### Example 3: Command Suggestion (Executable Workflow)

**Context**: Want to document deploy process  

**Invocation**: `@acp.artifact-reference deployment process`  

**Result**: Agent performs command-first check, detects executable workflow steps, prompts: "This looks like an executable workflow. Consider: @local.deploy or @acme.deploy. Would you like me to create a command instead?" User says yes, agent exits and suggests `@acp.command-create deployment`.  

### Example 4: Troubleshooting Guide

**Context**: Common auth errors, need diagnostic guide  

**Invocation**: `@acp.artifact-reference auth troubleshooting --type troubleshooting`  

**Result**: Agent checks command-first (diagnostic decision tree with human judgment, not automated), prompts user for common symptoms + resolutions, creates troubleshooting guide with "Symptom → Check → Resolution" flow, auto-commits.  

### Example 5: Architecture Diagram

**Context**: New team members need service topology overview  

**Invocation**: `@acp.artifact-reference architecture diagram --type diagrams`  

**Result**: Agent checks command-first (passive diagram, requires human interpretation), searches for existing architecture docs, creates reference with ASCII/mermaid diagram + component descriptions, auto-commits.  

---

## Related Commands

- [`@acp.artifact-research`](acp.artifact-research.md) - Create research artifacts (external knowledge)
- [`@acp.artifact-glossary`](acp.artifact-glossary.md) - Create terminology glossaries
- [`@acp.command-create`](acp.command-create.md) - Create commands (if content is executable)
- [`@acp.sync`](acp.sync.md) - Detect reference staleness after code changes
- [`@acp.validate`](acp.validate.md) - Validate artifact metadata and structure

---

## Troubleshooting

### Issue 1: Content feels like a command but check says reference

**Symptom**: Reference contains step-by-step procedures but passed command-first check  

**Cause**: Steps are not automatable (require human judgment) or are generic (not project-specific)  

**Solution**: Re-evaluate. If truly project-specific and automatable, create command instead. If generic or requires judgment, reference is appropriate.  

### Issue 2: Reference type unclear

**Symptom**: Topic doesn't fit any reference type cleanly  

**Cause**: Topic is hybrid (e.g., "API integration guide" could be standards, API contract, or troubleshooting)  

**Solution**: Prompt user to clarify primary purpose. Create multiple references if needed (one for contract, one for troubleshooting).  

### Issue 3: Reference becoming a tutorial

**Symptom**: Reference grows to include lengthy explanations and examples  

**Cause**: Topic is too broad or educational content is being mixed with reference material  

**Solution**: Split into research artifact (educational investigation) and reference artifact (lookup/quick reference). Or create command for executable parts.  

### Issue 4: CLI syntax is project-specific

**Symptom**: Creating Git CLI reference but it's actually project Git workflow  

**Cause**: Confusing generic tool syntax with project-specific workflow  

**Solution**: Generic syntax → reference. Project workflow → command. Create `@local.git-feature-start` command instead of "Git workflow reference".  

---

## Security Considerations

### File Access
- **Reads**: Any file in project (for content gathering)
- **Writes**: `agent/artifacts/reference-{N}-{topic-slug}.md` only
- **Executes**: `git add`, `git commit` (if auto-commit)

### Network Access
- **APIs**: None (codebase + user input only)
- **Repositories**: Local git only (no remote operations)

### Sensitive Data
- **Secrets**: Never include actual secrets or credentials in references
- **Private data**: If documenting config, use placeholder values (e.g., `<API_KEY>`, not real keys)
- **URLs**: Only public documentation URLs (no private/authenticated content)

---

## Key Design Decisions

### Command-First Principle

| Decision | Choice | Rationale |
|---|---|---|
| Mandatory check | Yes (unless `--skip-check`) | Prevents reference bloat, encourages automation |
| Check timing | Step 2 (before content gathering) | Saves work if content should be a command instead |
| Decision criteria | Executable vs passive information | Clear boundary: commands do, references inform |
| User override | `--skip-check` flag available | User has final say but must be explicit |

### Reference Types

| Decision | Choice | Rationale |
|---|---|---|
| Type system | 7 types (config-table, cli-syntax, standards, diagrams, schemas, troubleshooting, api-contract) | Covers common use cases, each has distinct structure |
| Type inference | Keyword-based heuristics | Reduces user burden, explicit `--type` for precision |
| Template structure | Varies by type | Each type has optimal layout (table vs syntax vs decision tree) |

### Content Gathering

| Decision | Choice | Rationale |
|---|---|---|
| Primary source | User input + codebase | References often document existing patterns/standards |
| External docs | Cited for CLI syntax references | Generic tools (Git, Docker) need official doc links |
| Automation level | Low (mostly user-driven) | References are often domain-specific, hard to fully automate |

### Integration

| Decision | Choice | Rationale |
|---|---|---|
| Template-based | Use `reference.template.md` | Consistent structure, explicit command-first check |
| Auto-commit | Yes (default), `--no-commit` to disable | Establishes baseline, enables visible diff |
| Command suggestions | Explicit prompts when executable content detected | Educates users on command-first principle |

---

## Notes

- References are for passive information only — executable procedures should be commands
- Command-first principle check is mandatory (except with `--skip-check`) to prevent reference bloat
- Reference types guide structure but are not rigid — adapt as needed
- References complement commands (informational support) but don't replace them
- Consider splitting large references into multiple focused references
- Use `@acp.sync` to detect staleness (code changes affecting reference content)
- References are living documents — update as project standards evolve

---

**Namespace**: acp  
**Command**: artifact-reference  
**Version**: 1.0.0  
**Created**: 2026-03-17  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Compatibility**: ACP 5.26.0+  
**Author**: ACP Project  
