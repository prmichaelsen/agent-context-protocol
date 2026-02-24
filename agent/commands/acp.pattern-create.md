# Command: pattern-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.pattern-create` has been invoked.
>
> **This is a CREATION command - you will create files directly, no shell scripts needed.**
>
> Follow the steps below to create a pattern file with proper namespace and automatic package updates.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-20
**Last Updated**: 2026-02-20
**Status**: Active
**Scripts**: None

---

**Purpose**: Create pattern files with namespace enforcement, draft support, and automatic package updates
**Category**: Creation
**Frequency**: As Needed

---

## What This Command Does

This command creates a new pattern file with intelligent namespace handling, optional draft file support, and automatic updates to package.yaml and README.md. It provides a guided workflow for creating well-structured patterns that follow ACP conventions.

**Key Features**:
- Context-aware (detects if in package vs project)
- Automatic namespace enforcement
- Draft file support with clarification workflow
- Auto-updates package.yaml and README.md
- Uses pattern.template.md as base

**Use this when**: Creating a new pattern in an ACP project or package.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] Pattern template exists (agent/patterns/pattern.template.md or similar)
- [ ] (Optional) Draft file prepared if using draft workflow

---

## Steps

### 1. Detect Context

Determine if in package or project directory:

**Actions**:
- Check if package.yaml exists (use `is_acp_package()`)
- If package: Infer namespace from package.yaml, directory, or git remote
- If project: Use "local" namespace

**Expected Outcome**: Context detected, namespace determined

### 2. Check for Draft File

Check if draft file was provided as argument:

**Syntax**:
- `@acp.pattern-create @my-draft.md` (@ reference)
- `@acp.pattern-create agent/drafts/my-draft.md` (path)
- `@acp.pattern-create` (no draft)

**Actions**:
- If draft provided: Read draft file
- If no draft: Proceed to Step 3

**Expected Outcome**: Draft file read (if provided)

### 3. Collect Pattern Information

Gather information from user via chat:

**Information to Collect**:
- **Pattern name** (without namespace prefix)
  - Example: "user-scoped-collections" (not "firebase.user-scoped-collections")
  - Validation: lowercase, alphanumeric, hyphens
- **Pattern description** (one-line summary)
  - Example: "User-scoped Firestore data organization"
- **Pattern version** (default: 1.0.0)

**If no draft provided**:
- Ask: "Describe what you want this pattern to accomplish" OR
- Offer: "Would you like to create an empty draft file first?"

**Expected Outcome**: All pattern metadata collected

### 4. Process Draft (If Provided)

If draft file was provided, create clarification:

**Actions**:
- Analyze draft for clarity and completeness
- If draft is clear and complete: Skip clarification, use draft content
- If draft is ambiguous: Create clarification document
  - Find next clarification number
  - Create `agent/clarifications/clarification-{N}-pattern-{name}.md`
  - Generate questions about unclear aspects
  - Wait for user to answer clarification
  - Read answered clarification

**Expected Outcome**: Clarification created and answered (if needed)

### 5. Generate Pattern File

Create pattern file from template:

**Actions**:
- Determine full filename: `{namespace}.{pattern-name}.md`
- Copy from pattern template
- Fill in metadata (name, version, date, description)
- If draft/clarification provided: Incorporate content
- If no draft: Create from template with user-provided description
- Save to `agent/patterns/{namespace}.{pattern-name}.md`

**Expected Outcome**: Pattern file created

### 6. Update package.yaml (If in Package)

Add pattern to package.yaml contents:

**Actions**:
- Read package.yaml
- Add entry to contents.patterns array:
  ```yaml
  - name: {namespace}.{pattern-name}.md
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

**Expected Outcome**: README.md updated with new pattern

### 8. Prompt to Delete Draft (If Used)

If draft file was used, ask to delete it:

**Actions**:
- Ask: "Would you like to delete the draft file? (yes/no)"
- If yes: Delete draft file
- If no: Keep draft file

**Expected Outcome**: User chooses whether to keep draft

### 9. Report Success

Display what was created:

**Output**:
```
✅ Pattern Created Successfully!

File: agent/patterns/{namespace}.{pattern-name}.md
Namespace: {namespace}
Version: 1.0.0

✓ Pattern file created
✓ package.yaml updated (if package)
✓ README.md updated (if package)
✓ Draft file deleted (if requested)

Next steps:
- Edit the pattern file to add implementation details
- Run @acp.package-validate to verify (if package)
```

**Expected Outcome**: User knows pattern was created successfully

---

## Verification

- [ ] Context detected correctly (package vs project)
- [ ] Namespace inferred or determined
- [ ] Pattern information collected
- [ ] Draft processed (if provided)
- [ ] Pattern file created with correct namespace
- [ ] package.yaml updated (if package)
- [ ] README.md updated (if package)
- [ ] Pattern follows template structure
- [ ] All metadata filled in correctly

---

## Expected Output

### Files Created
- `agent/patterns/{namespace}.{pattern-name}.md` - Pattern file
- `agent/clarifications/clarification-{N}-pattern-{name}.md` - Clarification (if draft was ambiguous)

### Files Modified
- `package.yaml` - Pattern added to contents (if package)
- `README.md` - Contents section updated (if package)

---

## Examples

### Example 1: Creating Pattern in Package

**Context**: In acp-firebase package directory

**Invocation**: `@acp.pattern-create`

**Interaction**:
```
Agent: Detected package context. Namespace: firebase

Agent: What would you like to name your pattern? (without namespace prefix)
User: user-scoped-collections

Agent: Provide a one-line description:
User: User-scoped Firestore data organization

Agent: Pattern version? (default: 1.0.0)
User: [Enter]

✅ Pattern Created Successfully!

File: agent/patterns/firebase.user-scoped-collections.md
Namespace: firebase
Version: 1.0.0

✓ Pattern file created
✓ package.yaml updated
✓ README.md updated
```

### Example 2: Creating Pattern with Draft

**Context**: Have draft file describing pattern

**Invocation**: `@acp.pattern-create @my-pattern-draft.md`

**Result**: Reads draft, creates clarification if needed, generates pattern, updates package files

### Example 3: Creating Pattern in Project

**Context**: In regular project (no package.yaml)

**Invocation**: `@acp.pattern-create`

**Result**: Uses "local" namespace, creates `agent/patterns/local.my-pattern.md`, no package updates

---

## Related Commands

- [`@acp.command-create`](acp.command-create.md) - Create commands
- [`@acp.design-create`](acp.design-create.md) - Create designs
- [`@acp.package-validate`](acp.package-validate.md) - Validate package after creation

---

## Troubleshooting

### Issue 1: Namespace inference failed

**Symptom**: Cannot determine namespace

**Solution**: Provide namespace manually when prompted, or check package.yaml exists and has name field

### Issue 2: Invalid pattern name

**Symptom**: Pattern name rejected

**Solution**: Use lowercase, alphanumeric, and hyphens only. No spaces or special characters.

### Issue 3: package.yaml update failed

**Symptom**: Error updating package.yaml

**Solution**: Verify package.yaml exists and is valid YAML. Run @acp.package-validate to check.

---

## Security Considerations

### File Access
- **Reads**: package.yaml, draft files, pattern templates
- **Writes**: agent/patterns/{namespace}.{name}.md, package.yaml, README.md
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in patterns
- **Credentials**: Never include credentials

---

## Notes

- Pattern name should be descriptive and specific
- Namespace is automatically added to filename
- Draft files can be any format (free-form markdown)
- Clarifications are created only if draft is ambiguous
- package.yaml and README.md updates are automatic in packages
- In non-package projects, uses "local" namespace

---

**Namespace**: acp
**Command**: pattern-create
**Version**: 1.0.0
**Created**: 2026-02-20
**Last Updated**: 2026-02-20
**Status**: Active
**Compatibility**: ACP 2.2.0+
**Author**: ACP Project
