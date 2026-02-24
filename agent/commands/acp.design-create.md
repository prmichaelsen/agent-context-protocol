# Command: design-create

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.design-create` has been invoked.
>
> **This is a CREATION command - you will create files directly, no shell scripts needed.**
>
> Follow the steps below to create a design document with proper namespace and automatic package updates.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Scripts**: None

---

**Purpose**: Create design documents with namespace enforcement, draft support, and automatic package updates
**Category**: Creation
**Frequency**: As Needed

---

## What This Command Does

This command creates a new design document with intelligent namespace handling, optional draft file support, and automatic updates to package.yaml and README.md. It provides a guided workflow for creating well-structured design documents that follow ACP conventions.

**Key Features**:
- Context-aware (detects if in package vs project)
- Automatic namespace enforcement
- Draft file support with clarification workflow
- Auto-updates package.yaml and README.md
- Uses design.template.md as base

**Use this when**: Creating a new design document in an ACP project or package.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] Design template exists (agent/design/design.template.md)
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

Check if draft file was provided as argument (same as pattern-create and command-create).

**Expected Outcome**: Draft file read (if provided)

### 3. Collect Design Information

Gather information from user via chat:

**Information to Collect**:
- **Design name** (without namespace prefix)
  - Example: "architecture" (not "firebase.architecture")
  - Validation: lowercase, alphanumeric, hyphens
- **Design description** (one-line summary)
  - Example: "Firebase integration architecture and patterns"
- **Design version** (default: 1.0.0)

**If no draft provided**:
- Ask: "Describe what you want this design document to cover" OR
- Offer: "Would you like to create an empty draft file first?"

**Expected Outcome**: All design metadata collected

### 4. Process Draft (If Provided)

If draft file was provided, create clarification if needed (same as pattern-create).

**Expected Outcome**: Clarification created and answered (if needed)

### 5. Generate Design File

Create design file from template:

**Actions**:
- Determine full filename: `{namespace}.{design-name}.md`
- Copy from design.template.md
- Fill in metadata (name, version, date, description)
- If draft/clarification provided: Incorporate content
- If no draft: Create from template with user-provided description
- Save to `agent/design/{namespace}.{design-name}.md`

**Expected Outcome**: Design file created

### 6. Update package.yaml (If in Package)

Add design to package.yaml contents (same as pattern-create and command-create).

**Expected Outcome**: package.yaml updated

### 7. Update README.md (If in Package)

Update README contents section (same as pattern-create and command-create).

**Expected Outcome**: README.md updated with new design

### 8. Prompt to Delete Draft (If Used)

If draft file was used, ask to delete it.

**Expected Outcome**: User chooses whether to keep draft

### 9. Report Success

Display what was created.

**Expected Outcome**: User knows design was created successfully

---

## Verification

- [ ] Context detected correctly (package vs project)
- [ ] Namespace inferred or determined
- [ ] Design information collected
- [ ] Draft processed (if provided)
- [ ] Design file created with correct namespace
- [ ] package.yaml updated (if package)
- [ ] README.md updated (if package)
- [ ] Design follows template structure
- [ ] All metadata filled in correctly

---

## Expected Output

### Files Created
- `agent/design/{namespace}.{design-name}.md` - Design file
- `agent/clarifications/clarification-{N}-design-{name}.md` - Clarification (if draft was ambiguous)

### Files Modified
- `package.yaml` - Design added to contents (if package)
- `README.md` - Contents section updated (if package)

---

## Examples

### Example 1: Creating Design in Package

**Context**: In acp-firebase package directory

**Invocation**: `@acp.design-create`

**Result**: Creates `agent/design/firebase.architecture.md`, updates package.yaml and README.md

### Example 2: Creating Design in Project

**Context**: In regular project (no package.yaml)

**Invocation**: `@acp.design-create`

**Result**: Uses "local" namespace, creates `agent/design/local.my-design.md`, no package updates

---

## Related Commands

- [`@acp.pattern-create`](acp.pattern-create.md) - Create patterns
- [`@acp.command-create`](acp.command-create.md) - Create commands
- [`@acp.package-validate`](acp.package-validate.md) - Validate package after creation

---

## Troubleshooting

Same as @acp.pattern-create and @acp.command-create.

---

## Security Considerations

### File Access
- **Reads**: package.yaml, draft files, design templates
- **Writes**: agent/design/{namespace}.{name}.md, package.yaml, README.md
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets in designs
- **Credentials**: Never include credentials

---

## Notes

- Design name should be descriptive and specific
- Namespace is automatically added to filename
- Draft files can be any format (free-form markdown)
- Clarifications are created only if draft is ambiguous
- package.yaml and README.md updates are automatic in packages
- In non-package projects, uses "local" namespace

---

**Namespace**: acp
**Command**: design-create
**Version**: 1.0.0
**Created**: 2026-02-21
**Last Updated**: 2026-02-21
**Status**: Active
**Compatibility**: ACP 2.2.0+
**Author**: ACP Project
