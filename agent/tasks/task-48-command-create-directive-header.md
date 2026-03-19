# Task 48: Enforce Directive Header in @acp.command-create

**Milestone**: Future Enhancement  
**Estimated Time**: 1-2 hours  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Update [`@acp.command-create`](../commands/acp.command-create.md) to explicitly require copying the exact directive header from [`command.template.md`](command.template.md) to new commands, ensuring all commands have the proper agent directive.

---

## Context

Currently, `@acp.command-create` doesn't explicitly state that the directive header from `command.template.md` must be copied verbatim to new commands. This can lead to:
- Missing or incorrect directive headers
- Inconsistent command behavior
- Agents not recognizing commands properly

**Solution**: Make it explicit in the command documentation that the directive header must be copied exactly.  

**Directive Header** (from command.template.md):
```markdown
> **🤖 Agent Directive**: If you are reading this file, the command `@{namespace}.{command-name}` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."
```

---

## Steps

### 1. Update @acp.command-create Documentation

Update [`agent/commands/acp.command-create.md`](../commands/acp.command-create.md):

**Location**: Step 6 (Generate Command File)  

**Addition**:
```markdown
### 6. Generate Command File

Create command file from template:

**Actions**:
- Determine full filename: `{namespace}.{command-name}.md`
- Copy from command template (agent/commands/command.template.md)
- **CRITICAL**: Copy the exact directive header from template (lines 3-6)
  - Replace `{namespace}.{command-name}` with actual values
  - Do NOT modify the directive text
  - This header is required for agents to recognize the command
- Fill in metadata:
  - Namespace
  - Version (start at 1.0.0)
  - Created date
  - Purpose
  - Category
  - Frequency
- Fill in sections:
  - What This Command Does
  - Prerequisites
  - Steps
  - Verification
  - Examples
- Save to `agent/commands/{namespace}.{command-name}.md`

**Expected Outcome**: Command file created with proper directive header  
```

**Verification**:
- Documentation explicitly requires directive header
- Instructions are clear
- Example shows proper header

### 2. Add Verification Step

Add verification item to ensure directive header is present:

**Location**: Verification section  

**Addition**:
```markdown
- [ ] Directive header copied exactly from template
- [ ] Namespace and command name replaced in directive
- [ ] Directive text not modified
```

**Verification**:
- Verification checklist updated
- Header requirement is checkable

### 3. Update Example Output

Add directive header to example output:

**Location**: Expected Output section  

**Addition**:
```markdown
### Example Command File

```markdown
# Command: deploy

> **🤖 Agent Directive**: If you are reading this file, the command `@deploy.production` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@deploy-production NOW...

**Namespace**: deploy  
**Version**: 1.0.0  
...
```
```

**Verification**:
- Example shows complete header
- Example is accurate

### 4. Test Command Creation

Test that updated documentation produces correct commands:

**Actions**:
- Invoke `@acp.command-create` with test command
- Verify directive header is present
- Verify header has correct namespace/command
- Verify header text is unmodified

**Verification**:
- Test command created successfully
- Header is correct
- Command works as expected

---

## Verification

- [ ] @acp.command-create documentation updated
- [ ] Directive header requirement is explicit
- [ ] Verification checklist includes header check
- [ ] Example output shows complete header
- [ ] Test command created successfully
- [ ] All commands have proper directive headers

---

## Expected Output

### Files Modified
- `agent/commands/acp.command-create.md` - Updated Step 6 and verification

### Documentation Quality
- ✅ Directive header requirement is explicit
- ✅ Instructions are clear and unambiguous
- ✅ Examples show proper usage
- ✅ Verification ensures compliance

---

## Common Issues and Solutions

### Issue 1: Directive header missing from new command

**Symptom**: Command created without directive header  

**Solution**: Follow updated Step 6 instructions. Copy header from template exactly.  

### Issue 2: Directive header modified

**Symptom**: Header text changed or simplified  

**Solution**: Do not modify directive text. Copy exactly from template.  

### Issue 3: Namespace not replaced in header

**Symptom**: Header still says `{namespace}.{command-name}`  

**Solution**: Replace placeholders with actual namespace and command name.  

---

## Resources

- [command.template.md](../commands/command.template.md): Command template with directive header
- [@acp.command-create](../commands/acp.command-create.md): Command creation command
- [AGENT.md](../../AGENT.md): ACP methodology

---

## Notes

- Directive header is critical for agent recognition
- Header must be copied exactly (except namespace/command placeholders)
- This is a documentation update, not a code change
- Improves consistency across all commands
- Prevents missing or incorrect headers
- Makes command creation requirements explicit

---

**Next Task**: None (future enhancement)  
**Related Design Docs**: None  
**Estimated Completion Date**: TBD  
