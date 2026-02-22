# Command: command-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.command-create` has been invoked.
>
> **This is a CREATION command - you will create files directly, no shell scripts needed.**
>
> Follow the steps below to create a command file with proper namespace and automatic package updates.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active

---

**Purpose**: Create command files with namespace enforcement, draft support, and automatic package updates
**Category**: Creation
**Frequency**: As Needed

---

## What This Command Does

This command creates a new command file with intelligent namespace handling, optional draft file support, and automatic updates to package.yaml and README.md. It provides a guided workflow for creating well-structured commands that follow ACP conventions.

**Key Features**:
- Context-aware (detects if in package vs project)
- Automatic namespace enforcement
- Draft file support with clarification workflow
- Auto-updates package.yaml and README.md
- Uses command.template.md as base
- Collects command-specific metadata (category, frequency)

**Use this when**: Creating a new command in an ACP project or package.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] Command template exists (agent/commands/command.template.md)
- [ ] (Optional) Draft file prepared if using draft workflow

---

## Steps

### 1. Detect Context

Determine if in package or project directory:

**Actions**:
- Check if package.yaml exists
- If package: Infer namespace from package.yaml, directory, or git remote
- If project: Use "local" namespace

**Expected Outcome**: Context detected, namespace determined

### 2. Check for Draft File

Check if draft file was provided as argument:

**Syntax**:
- `@acp.command-create @my-draft.md` (@ reference)
- `@acp.command-create agent/drafts/my-draft.md` (path)
- `@acp.command-create` (no draft)

**Actions**:
- If draft provided: Read draft file
- If no draft: Proceed to Step 3

**Expected Outcome**: Draft file read (if provided)

### 3. Collect Command Information

Gather information from user via chat:

**Information to Collect**:
- **Command name** (without namespace prefix)
  - Example: "deploy" (not "firebase.deploy")
  - Validation: lowercase, alphanumeric, hyphens
- **Command description** (one-line summary)
  - Example: "Deploy Firebase functions to production"
- **Command category**:
  - Workflow
  - Documentation
  - Maintenance
  - Creation
  - Custom
- **Command frequency**:
  - Once
  - Per Session
  - As Needed
  - Continuous
- **Command arguments** (optional):
  - Ask: "Does this command accept arguments? (yes/no)"
  - If yes: Collect CLI-style flags and natural language mappings
  - If no: Skip Arguments section in generated command
- **Command version** (default: 1.0.0)

**If no draft provided**:
- Ask: "Describe what you want this command to accomplish" OR
- Offer: "Would you like to create an empty draft file first?"

**Expected Outcome**: All command metadata collected

### 4. Process Draft (If Provided)

If draft file was provided, create clarification if needed (same as pattern-create).

**Expected Outcome**: Clarification created and answered (if needed)

### 5. Generate Command File

Create command file from template:

**Actions**:
- Determine full filename: `{namespace}.{command-name}.md`
- Copy from command.template.md
- **CRITICAL**: Copy the exact directive header from template (lines 3-5)
  - Replace `@{namespace}-{command-name}` with actual values (e.g., `@firebase-deploy`)
  - Do NOT modify the directive text itself
  - This header is required for agents to recognize and execute the command
  - Example: `> **🤖 Agent Directive**: If you are reading this file, the command @firebase-deploy has been invoked.`
- Fill in metadata (name, version, date, description, category, frequency)
- If command has arguments: Fill in Arguments section (before Prerequisites)
- If no arguments: Remove Arguments section from template
- If draft/clarification provided: Incorporate content
- If no draft: Create from template with user-provided description
- Save to `agent/commands/{namespace}.{command-name}.md`

**Expected Outcome**: Command file created with proper directive header

### 6. Update package.yaml (If in Package)

Add command to package.yaml contents:

**Actions**:
- Read package.yaml
- Add entry to contents.commands array:
  ```yaml
  - name: {namespace}.{command-name}.md
    version: 1.0.0
    description: {description}
  ```
- Save package.yaml

**Expected Outcome**: package.yaml updated

### 7. Update README.md (If in Package)

Update README contents section:

**Actions**:
- Call `update_readme_contents()` from common.sh
- Regenerates "What's Included" section from package.yaml

**Expected Outcome**: README.md updated with new command

### 8. Prompt to Delete Draft (If Used)

If draft file was used, ask to delete it.

**Expected Outcome**: User chooses whether to keep draft

### 9. Report Success

Display what was created:

**Output**:
```
✅ Command Created Successfully!

File: agent/commands/{namespace}.{command-name}.md
Namespace: {namespace}
Category: {category}
Frequency: {frequency}
Version: 1.0.0

✓ Command file created
✓ package.yaml updated (if package)
✓ README.md updated (if package)

Next steps:
- Edit the command file to add detailed steps
- Run @acp.package-validate to verify (if package)
```

**Expected Outcome**: User knows command was created successfully

---

## Verification

- [ ] Context detected correctly (package vs project)
- [ ] Namespace inferred or determined
- [ ] Command information collected
- [ ] Draft processed (if provided)
- [ ] Command file created with correct namespace
- [ ] **Directive header copied exactly from template**
- [ ] **Namespace and command name replaced in directive**
- [ ] **Directive text not modified**
- [ ] package.yaml updated (if package)
- [ ] README.md updated (if package)
- [ ] Command follows template structure
- [ ] All metadata filled in correctly

---

## Expected Output

### Files Created
- `agent/commands/{namespace}.{command-name}.md` - Command file
- `agent/clarifications/clarification-{N}-command-{name}.md` - Clarification (if draft was ambiguous)

### Files Modified
- `package.yaml` - Command added to contents (if package)
- `README.md` - Contents section updated (if package)

### Example Command File Structure

```markdown
# Command: deploy

> **🤖 Agent Directive**: If you are reading this file, the command `@firebase-deploy` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@firebase-deploy NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: firebase
**Version**: 1.0.0
**Created**: 2026-02-22
**Last Updated**: 2026-02-22
**Status**: Active

---

**Purpose**: Deploy Firebase functions to production
**Category**: Workflow
**Frequency**: As Needed

---

## What This Command Does
[Command description...]

## Prerequisites
[Prerequisites...]

## Steps
[Implementation steps...]
```

---

## Examples

### Example 1: Creating Command in Package

**Context**: In acp-firebase package directory

**Invocation**: `@acp.command-create`

**Interaction**:
```
Agent: Detected package context. Namespace: firebase

Agent: What would you like to name your command? (without namespace prefix)
User: deploy

Agent: Provide a one-line description:
User: Deploy Firebase functions to production

Agent: Command category? (Workflow/Documentation/Maintenance/Creation/Custom)
User: Workflow

Agent: Command frequency? (Once/Per Session/As Needed/Continuous)
User: As Needed

Agent: Command version? (default: 1.0.0)
User: [Enter]

✅ Command Created Successfully!

File: agent/commands/firebase.deploy.md
Namespace: firebase
Category: Workflow
Frequency: As Needed
Version: 1.0.0

✓ Command file created
✓ package.yaml updated
✓ README.md updated
```

### Example 2: Creating Command in Project

**Context**: In regular project (no package.yaml)

**Invocation**: `@acp.command-create`

**Result**: Uses "local" namespace, creates `agent/commands/local.my-command.md`, no package updates

---

## Related Commands

- [`@acp.pattern-create`](acp.pattern-create.md) - Create patterns
- [`@acp.design-create`](acp.design-create.md) - Create designs
- [`@acp.package-validate`](acp.package-validate.md) - Validate package after creation

---

## Troubleshooting

### Issue 1: Namespace inference failed

**Symptom**: Cannot determine namespace

**Solution**: Provide namespace manually when prompted, or check package.yaml exists and has name field

### Issue 2: Invalid command name

**Symptom**: Command name rejected

**Solution**: Use lowercase, alphanumeric, and hyphens only. No spaces or special characters.

### Issue 3: package.yaml update failed

**Symptom**: Error updating package.yaml

**Solution**: Verify package.yaml exists and is valid YAML. Run @acp.package-validate to check.

---

## Security Considerations

### File Access
- **Reads**: package.yaml, draft files, command templates
- **Writes**: agent/commands/{namespace}.{name}.md, package.yaml, README.md
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in commands
- **Credentials**: Never include credentials

---

## Notes

- Command name should be descriptive and action-oriented
- Namespace is automatically added to filename
- Draft files can be any format (free-form markdown)
- Clarifications are created only if draft is ambiguous
- package.yaml and README.md updates are automatic in packages
- In non-package projects, uses "local" namespace
- Category and frequency help users understand command purpose

---

**Namespace**: acp
**Command**: command-create
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 2.2.0+
**Author**: ACP Project
