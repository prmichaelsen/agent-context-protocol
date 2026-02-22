# Command: {command-name}

> **🤖 Agent Directive**: If you are reading this file, the command `@{namespace}-{command-name}` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: {namespace}
**Version**: 1.0.0
**Created**: YYYY-MM-DD
**Last Updated**: YYYY-MM-DD
**Status**: [Draft | Active | Deprecated]

---

**Purpose**: [One-line description of what this command does]
**Category**: [Workflow | Documentation | Maintenance | Creation | Custom]
**Frequency**: [Once | Per Session | As Needed | Continuous]

---

## Arguments

[If your command accepts arguments, document them here. Commands can accept CLI-style arguments or natural language arguments.]

**CLI-Style Arguments** (optional):
- `--flag` or `-f` - Description of what this flag does
- `--option <value>` - Description of option that takes a value
- `--another-flag` - Another flag description

**Natural Language Arguments** (optional):
- `@{namespace}.{command} for specific item` - Description
- `@{namespace}.{command} with custom setting` - Description

**Argument Mapping**:
Arguments are inferred from chat context. The agent will:
1. Parse explicit CLI-style flags if present
2. Extract intent from natural language
3. Ask for clarification if ambiguous
4. Default to interactive mode if unclear

**Example**:
```markdown
## Arguments

**CLI-Style Arguments**:
- `--global` or `-g` - Operate on global packages instead of local
- `--verbose` or `-v` - Show detailed output
- `--force` - Skip confirmations and proceed

**Natural Language Arguments**:
- `@acp.package-list global packages` - List global packages
- `@acp.package-list with details` - Verbose mode

**Argument Mapping**:
The agent infers intent from context. "Show me global packages" maps to `--global` flag.
```

**Note**: If your command has no arguments, you can omit this section entirely.

---

## What This Command Does

[2-3 paragraph explanation of:
- What the command accomplishes
- When to use it
- What problems it solves
- Any important context]

**Example**: "This command initializes the agent context by reading all documentation in the agent/ directory, reviewing key source files, and updating progress tracking. Use this at the start of each session to ensure the agent has complete project context."

---

## Prerequisites

[List any requirements before running this command:]

- [ ] Prerequisite 1 (e.g., "Docker must be installed")
- [ ] Prerequisite 2 (e.g., "AWS credentials configured")
- [ ] Prerequisite 3 (e.g., "Build completed successfully")

**Example** (for a deployment command):
- [ ] Docker installed and running
- [ ] AWS CLI configured with valid credentials
- [ ] Application built successfully (`npm run build` completed)
- [ ] Environment variables configured in `.env.production`

---

## Steps

[Detailed, sequential steps the agent should follow:]

### 1. [Step Name]

[Description of what to do in this step]

**Actions**:
- Action item 1
- Action item 2
- Action item 3

**Expected Outcome**: [What should happen after this step]

**Example**:
```bash
# If shell commands needed
command --with-flags
```

```typescript
// If code examples needed
const example = "code";
```

### 2. [Next Step]

[Description of what to do]

**Actions**:
- Action item 1
- Action item 2

**Expected Outcome**: [What should happen]

### 3. [Next Step]

[Continue with additional steps as needed]

---

## Verification

[Checklist to confirm command executed successfully:]

- [ ] Verification item 1: [Specific condition to check]
- [ ] Verification item 2: [Specific condition to check]
- [ ] Verification item 3: [Specific condition to check]
- [ ] Verification item 4: [Specific condition to check]

**Example**:
- [ ] All agent files read successfully
- [ ] Key source files identified and reviewed
- [ ] `agent/progress.yaml` updated with current status
- [ ] No errors encountered during execution

---

## Expected Output

[Describe what the user should see after command execution:]

### Files Modified
- `path/to/file1` - [What changed]
- `path/to/file2` - [What changed]

### Console Output
```
Example output message or status report
```

### Status Update
[Description of any status changes in progress.yaml or other tracking]

**Example**:

### Files Modified
- `agent/progress.yaml` - Updated current status and recent work

### Console Output
```
✓ Read 15 agent files
✓ Reviewed 8 source files
✓ Updated progress tracking
✓ Ready to proceed with task-3
```

### Status Update
- Current milestone: M1 (Foundation)
- Current task: task-3 (Implement core logic)
- Progress: 40% complete

---

## Examples

### Example 1: [Scenario Name]

**Context**: [When you'd use this command in this way]

**Invocation**: `@{namespace}-{command-name}`

**Result**: [What happens]

**Example**:

### Example 1: Starting Fresh Session

**Context**: Beginning work on a project after a break

**Invocation**: `@acp-init`

**Result**: Agent reads all documentation, reviews source code, updates progress tracking, and reports current status with next steps.

### Example 2: [Another Scenario]

**Context**: [Different use case]

**Invocation**: `@{namespace}-{command-name}`

**Result**: [What happens]

---

## Related Commands

[Link to related commands and explain relationships:]

- [`@{namespace}-{related-command}`](../{namespace}/{related-command}.md) - [When to use instead or in combination]
- [`@{namespace}-{another-command}`](../{namespace}/{another-command}.md) - [How it relates]

**Example**:
- [`@acp-proceed`](../acp/proceed.md) - Use after `@acp-init` to start working on tasks
- [`@acp-status`](../acp/status.md) - Use to check current status without full initialization
- [`@acp-sync`](../acp/sync.md) - Use to update documentation after code changes

---

## Troubleshooting

### Issue 1: [Common Problem]

**Symptom**: [What the user sees]

**Cause**: [Why this happens]

**Solution**: [How to fix it]

**Example** (for a deployment command):

### Issue 1: Deployment fails with authentication error

**Symptom**: Error message "AWS credentials not found"

**Cause**: AWS CLI not configured or credentials expired

**Solution**: Run `aws configure` to set up credentials, or refresh your AWS SSO session with `aws sso login`

### Issue 2: [Another Common Problem]

**Symptom**: [What the user sees]

**Cause**: [Why this happens]

**Solution**: [How to fix it]

---

## Security Considerations

[Document any security implications of this command:]

### File Access
- **Reads**: [What files this command reads]
- **Writes**: [What files this command modifies]
- **Executes**: [Any scripts or commands this executes]

### Network Access
- **APIs**: [Any external APIs called]
- **Repositories**: [Any git operations]

### Sensitive Data
- **Secrets**: [How this command handles secrets - should never read them]
- **Credentials**: [How this command handles credentials]

**Example**:

### File Access
- **Reads**: All files in `agent/` directory, key source files in `src/`
- **Writes**: `agent/progress.yaml` only
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never reads `.env` files or credential files
- **Credentials**: Does not access any credentials

---

## Notes

[Any additional context, warnings, or considerations:]

- Note 1: [Important information]
- Note 2: [Important information]
- Note 3: [Important information]

**Example**:
- This command should be run at the start of each session
- Reading all agent files may take 30-60 seconds for large projects
- If source code is very large, consider specifying which files to review
- Always review the output to ensure context was loaded correctly

---

**Namespace**: {namespace}
**Command**: {command-name}
**Version**: 1.0.0
**Created**: YYYY-MM-DD
**Last Updated**: YYYY-MM-DD
**Status**: [Draft | Active | Deprecated]
**Compatibility**: ACP 1.1.0+
**Author**: [Your name or organization]
