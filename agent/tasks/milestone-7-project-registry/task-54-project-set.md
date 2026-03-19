# Task 54: @acp.project-set Command

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: Task 52 (Registry Infrastructure), Task 53 (Project List)  
**Status**: Not Started  

---

## Objective

Implement the `@acp.project-set` command to enable seamless context switching between projects. This command sets the current project in the registry, changes to the project directory, and updates the `last_accessed` timestamp.

---

## Context

This is the key feature of the project registry system. `@acp.project-set` allows users to switch between projects without manually navigating directories. All subsequent ACP commands will automatically use the current project's path for file operations.

**Key Behavior**: Changes the shell's working directory to the project path, making all relative file operations work correctly.  

---

## Steps

### 1. Create Shell Script

Create `agent/scripts/acp.project-set.sh` with the implementation from the design document.

### 2. Create Command Document

Create `agent/commands/acp.project-set.md` with agent directives.

### 3. Add Validation

- Validate project exists in registry
- Validate project directory exists on filesystem
- Handle missing/moved projects gracefully

### 4. Update Timestamps

- Set `current_project` in registry
- Update `last_accessed` timestamp
- Update `last_updated` registry timestamp

### 5. Change Directory

- Use `cd` to change to project directory
- Report new working directory to user
- Suggest running `@acp.init` to load context

### 6. Make Executable

```bash
chmod +x agent/scripts/acp.project-set.sh
```

---

## Verification

- [ ] `acp.project-set.sh` created
- [ ] `acp.project-set.md` created
- [ ] Script validates project exists
- [ ] Script validates directory exists
- [ ] Script updates `current_project`
- [ ] Script updates `last_accessed`
- [ ] Script changes directory
- [ ] Error handling for missing projects
- [ ] Clear success message displayed
- [ ] No syntax errors

---

## Expected Output

```
✓ Switched to project: agentbase-mcp-server
  Path: /home/user/.acp/projects/agentbase-mcp-server
  Type: mcp-server

You are now in the project directory. All file operations will be relative to:
  /home/user/.acp/projects/agentbase-mcp-server

Run '@acp.init' to load project context
```

---

**Next Task**: [Task 55: @acp.project-info Command](task-55-project-info.md)  
