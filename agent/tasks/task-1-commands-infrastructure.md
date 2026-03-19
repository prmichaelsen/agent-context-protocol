# Task 1: Create Commands Directory Structure

**Milestone**: [M1 - ACP Commands Infrastructure](../milestones/milestone-1-acp-commands.md)  
**Estimated Time**: 1 hour  
**Dependencies**: None  
**Status**: Not Started  

---

## Objective

Create the directory structure for the ACP Commands system and ensure the command template is in place. This establishes the foundation for all command implementations.

---

## Context

The ACP Commands system uses a namespace-based directory structure where commands are organized by namespace. The `acp/` namespace is reserved for core ACP commands. This task creates the necessary directories and ensures the template is ready for use.

---

## Steps

### 1. Create Commands Directory Structure

Create the main commands directory and the reserved `acp/` namespace:

```bash
mkdir -p agent/commands/acp
touch agent/commands/.gitkeep
touch agent/commands/acp/.gitkeep
```

### 2. Verify Command Template Exists

Ensure the command template is in place:

```bash
ls -la agent/commands/command.template.md
```

If it doesn't exist, it should be created from the design document.

### 3. Update Installation Scripts

Verify that `scripts/acp.install.sh` and `scripts/acp.version-update.sh` include logic to:
- Copy `command.template.md`
- Copy all files from command namespace subdirectories
- Create `agent/commands/` directory

The scripts should already be updated from previous work.

### 4. Test Directory Structure

Verify the structure is correct:

```bash
tree agent/commands/
```

Expected output:
```
agent/commands/
├── .gitkeep
├── command.template.md
└── acp/
    └── .gitkeep
```

---

## Verification

- [ ] `agent/commands/` directory exists
- [ ] `agent/commands/acp/` directory exists
- [ ] `agent/commands/command.template.md` exists and is complete
- [ ] `.gitkeep` files present in both directories
- [ ] Installation scripts include commands directory logic
- [ ] Directory structure matches expected layout

---

## Expected Output

**Directory Structure**:
```
agent/commands/
├── .gitkeep
├── command.template.md
└── acp/
    └── .gitkeep
```

**Key Files Created**:
- `agent/commands/` - Main commands directory
- `agent/commands/acp/` - Reserved namespace for core commands
- `agent/commands/command.template.md` - Template for creating new commands

---

## Common Issues and Solutions

### Issue 1: Directory already exists

**Symptom**: `mkdir` reports directory exists  

**Solution**: This is fine, the directory structure is already in place. Verify contents are correct.  

### Issue 2: Template file missing

**Symptom**: `command.template.md` not found  

**Solution**: Copy from the design document or create from scratch following the template structure defined in `agent/design/acp-commands-design.md`.  

---

## Resources

- [ACP Commands Design](../design/acp-commands-design.md): Complete design specification
- [Command Template](../commands/command.template.md): Template for new commands

---

## Notes

- The `acp/` namespace is reserved and should not be used for user commands
- Future tasks will populate the `acp/` directory with core commands
- Users will create their own namespaces (e.g., `deploy/`, `custom/`) for project-specific commands

---

**Next Task**: [Task 2: Implement Core Workflow Commands](task-2-workflow-commands.md)  
**Related Design Docs**: [ACP Commands Design](../design/acp-commands-design.md)  
**Estimated Completion Date**: TBD  
