# Task 2: Implement Core Workflow Commands

**Milestone**: [M1 - ACP Commands Infrastructure](../milestones/milestone-1-acp-commands.md)  
**Estimated Time**: 3 hours  
**Dependencies**: Task 1 (Commands Infrastructure)  
**Status**: Not Started  

---

## Objective

Implement the three core workflow commands: `@acp-init`, `@acp-proceed`, and `@acp-status`. These commands form the foundation of the ACP workflow.

---

## Context

These commands replace the existing "AGENT.md: Initialize" and "AGENT.md: Proceed" prompts with a more structured, file-based approach. Each command should follow the template structure and provide clear, actionable instructions for agents.

---

## Steps

### 1. Create `acp/init.md`

Copy template and implement initialization command:

```bash
cp agent/commands/command.template.md agent/commands/acp/init.md
```

Fill in:
- **Namespace**: acp
- **Version**: 1.0.0
- **Purpose**: Initialize agent context and prepare for work
- **Category**: Workflow
- **Frequency**: Once per session

**Steps to document**:
1. Check for ACP updates (`./agent/scripts/acp.version-check-for-updates.sh`)
2. Read all files in `agent/` directory
3. Read key source files based on project type
4. Update stale documentation
5. Update `agent/progress.yaml`
6. Report current status and next steps

### 2. Create `acp/proceed.md`

Copy template and implement proceed command:

```bash
cp agent/commands/command.template.md agent/commands/acp/proceed.md
```

Fill in:
- **Purpose**: Continue with current or next task
- **Steps**:
  1. Read `agent/progress.yaml` to find current task
  2. Read current task document
  3. Execute task steps
  4. Verify completion
  5. Update `agent/progress.yaml`
  6. Report progress

### 3. Create `acp/status.md`

Copy template and implement status command:

```bash
cp agent/commands/command.template.md agent/commands/acp/status.md
```

Fill in:
- **Purpose**: Display current project status
- **Steps**:
  1. Read `agent/progress.yaml`
  2. Show current milestone and progress
  3. Show current task
  4. List recent work
  5. List next steps
  6. List blockers

### 4. Add Related Commands Links

In each command file, link to related commands:
- `init.md` → relates to `proceed.md`, `status.md`
- `proceed.md` → relates to `init.md`, `update.md`
- `status.md` → relates to `init.md`, `proceed.md`

---

## Verification

- [ ] `agent/commands/acp/init.md` exists and is complete
- [ ] `agent/commands/acp/proceed.md` exists and is complete
- [ ] `agent/commands/acp/status.md` exists and is complete
- [ ] All commands follow template structure
- [ ] All commands have version 1.0.0
- [ ] All commands have realistic examples
- [ ] Related commands are linked
- [ ] Security considerations documented

---

## Expected Output

**Files Created**:
- `agent/commands/acp/init.md` - Initialization command
- `agent/commands/acp/proceed.md` - Proceed command
- `agent/commands/acp/status.md` - Status command

---

## Notes

- These commands replace the old "AGENT.md: Initialize" and "AGENT.md: Proceed" prompts
- Commands should be self-contained and not require reading AGENT.md
- Include clear examples of expected output
- Document what files each command reads and writes

---

**Next Task**: [Task 3: Implement Version Commands](task-3-version-commands.md)  
**Related Design Docs**: [ACP Commands Design](../design/acp-commands-design.md)  
