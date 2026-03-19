# Milestone 2: Documentation & Utility Commands

**Goal**: Implement documentation management and utility commands  
**Duration**: 1 week  
**Dependencies**: Milestone 1 (ACP Commands Infrastructure)  
**Status**: Not Started  

---

## Overview

This milestone adds commands for managing documentation and providing utility functions. These commands enable agents to update progress tracking, sync documentation with code, validate documents, generate reports, and install third-party command packages.

**Note**: Creation commands (milestone-create, task-create, etc.) have been removed as they add unnecessary complexity. Natural language is sufficient for creating documents from templates.  

---

## Deliverables

### 1. Documentation Commands
- `@acp.update` - Update progress.yaml with latest status
- `@acp.sync` - Read code and update stale documentation
- `@acp.validate` - Validate all ACP documents for consistency

### 2. Utility Commands
- `@acp.report` - Generate comprehensive project report
- `@acp.install` - Install third-party command packages

---

## Success Criteria

- [ ] All 5 commands are implemented and documented
- [ ] Documentation commands can update progress.yaml
- [ ] Sync command can identify stale documentation
- [ ] Validate command checks document consistency
- [ ] Install command can clone and install from git repos
- [ ] Report command generates useful project summaries
- [ ] All commands follow template structure
- [ ] All commands have version 1.0.0

---

## Key Files to Create

```
agent/commands/
├── acp.update.md
├── acp.sync.md
├── acp.validate.md
├── acp.report.md
└── acp.install.md
```

---

## Tasks

1. [Task 5: Implement Documentation Commands](../tasks/task-5-documentation-commands.md) - Create update, sync, validate
2. [Task 6: Implement Utility Commands](../tasks/task-6-utility-commands.md) - Create report, install
3. [Task 7: Integration Testing](../tasks/task-7-integration-testing.md) - Test all commands together

---

## Environment Variables

None required for this milestone.

---

## Testing Requirements

- [ ] Test update command modifies progress.yaml correctly
- [ ] Test sync command identifies documentation drift
- [ ] Test validate command catches inconsistencies
- [ ] Test install command with sample repository
- [ ] Test report command output format
- [ ] Integration test: full workflow using all commands

---

## Documentation Requirements

- [ ] Each command has complete documentation
- [ ] Security considerations documented for install command
- [ ] Examples for each command
- [ ] Troubleshooting sections complete

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Install command security concerns | High | Medium | Clear documentation of risks, user assumes responsibility |
| Sync command complexity | Medium | Medium | Start with simple file comparison, iterate |
| Validate command false positives | Medium | Low | Thorough testing with various project states |

---

**Next Milestone**: None (Milestone 2 completes core ACP Commands)  
**Blockers**: Requires Milestone 1 completion  
**Notes**: Focus on utility and safety. Install command needs clear security warnings. Removed creation commands to reduce complexity - natural language is sufficient for creating documents.  
