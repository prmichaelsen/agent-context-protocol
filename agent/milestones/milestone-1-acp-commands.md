# Milestone 1: ACP Commands Infrastructure

**Goal**: Establish the foundational infrastructure for the ACP Commands system  
**Duration**: 1 week  
**Dependencies**: None  
**Status**: Not Started  

---

## Overview

This milestone establishes the core infrastructure for the ACP Commands system, including the namespace directory structure, core command implementations, and documentation updates. It creates the foundation that all future commands will build upon.

---

## Deliverables

### 1. Directory Structure
- `agent/commands/` directory with namespace subdirectories
- `agent/commands/acp/` namespace for core commands
- `.gitkeep` files for empty directories
- Command template in place

### 2. Core Commands Implemented
- `@acp-init` - Initialize agent context
- `@acp-proceed` - Continue with next task
- `@acp-status` - Show current status
- `@acp-version-check` - Show current ACP version
- `@acp-version-check-for-updates` - Check for updates
- `@acp-version-update` - Update ACP to latest version

### 3. Documentation
- AGENT.md updated with commands section
- README.md updated with commands examples
- All core commands fully documented

---

## Success Criteria

- [ ] `agent/commands/acp/` directory exists with all core commands
- [ ] All 6 core commands (Phase 1) are implemented and documented
- [ ] Commands follow the template structure consistently
- [ ] AGENT.md references commands system
- [ ] README.md includes command examples
- [ ] Installation scripts install command template
- [ ] All commands have version 1.0.0
- [ ] Commands can be invoked using `@acp-{action}` syntax

---

## Key Files to Create

```
agent/commands/
├── acp/
│   ├── init.md
│   ├── proceed.md
│   ├── status.md
│   ├── version-check.md
│   ├── version-check-for-updates.md
│   └── version-update.md
```

---

## Tasks

1. [Task 1: Create Commands Directory Structure](../tasks/task-1-commands-infrastructure.md) - Set up directories and template
2. [Task 2: Implement Core Workflow Commands](../tasks/task-2-workflow-commands.md) - Create init, proceed, status
3. [Task 3: Implement Version Commands](../tasks/task-3-version-commands.md) - Create version-check, version-check-for-updates, version-update
4. [Task 4: Update Documentation](../tasks/task-4-update-documentation.md) - Update AGENT.md and README.md

---

## Environment Variables

None required for this milestone.

---

## Testing Requirements

- [ ] Manual testing of each command
- [ ] Verify command template structure is followed
- [ ] Test command invocation with `@acp-{action}` syntax
- [ ] Verify version tracking in each command
- [ ] Test that commands are discoverable via file system

---

## Documentation Requirements

- [ ] Each command has complete documentation
- [ ] AGENT.md section on commands
- [ ] README.md examples of command usage
- [ ] Command template is up to date

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Commands don't follow consistent structure | Medium | Low | Use template and review each command |
| Documentation gets out of sync | Medium | Medium | Keep commands self-documenting, no central README |
| Version tracking not maintained | Low | Low | Include version in template, enforce in reviews |

---

**Next Milestone**: [Milestone 2: Documentation & Creation Commands](milestone-2-acp-commands-advanced.md)  
**Blockers**: None  
**Notes**: This milestone focuses on core infrastructure and essential commands. Advanced commands will be in Milestone 2.  
