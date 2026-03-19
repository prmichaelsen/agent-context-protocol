# Milestone 10: Command Enhancements

**Goal**: Umbrella milestone for all command improvements — autonomous completion, pattern awareness, and future command upgrades  
**Duration**: 2-4 weeks  
**Dependencies**: None (builds on existing command infrastructure)  
**Status**: Not Started  

---

## Overview

This milestone collects command enhancements that improve agent autonomy, intelligence, and user experience. Rather than a single focused feature, it serves as a rolling milestone for command-level improvements that don't warrant their own dedicated milestone.

The flagship feature is autonomous milestone completion for `@acp.proceed`, enabling agents to work through entire milestones without stopping, with per-task git commits and progress reporting.

---

## Deliverables

### 1. @acp.proceed Autonomous Completion
- `--complete` / `--auto` / `--finish-milestone` flags for autonomous mode
- `--commit` / `--commit-each` / `--with-commits` flags for per-task commits
- `--dry-run` flag to preview tasks without executing
- Natural language argument parsing (fuzzy matching)
- Confirmation prompt before autonomous execution
- Per-task `@git.commit` subroutine (version bump, changelog, progress)
- Progress indicators with bar graphs between tasks
- Summary report at end of run (completions, failures, commits)
- Error handling: halt on blockers, seek user intervention

### 2. Pattern Reading in Commands
- Commands read `agent/patterns/` during initialization
- Context-aware pattern selection
- Improved design and task decisions based on patterns

---

## Success Criteria

- [ ] `@acp.proceed --complete` autonomously completes remaining milestone tasks
- [ ] Per-task `@git.commit` runs after each completed task
- [ ] Natural language like `@acp.proceed just finish everything` works
- [ ] `--dry-run` shows planned tasks without executing
- [ ] Agent halts on blockers and test failures (seeks user input)
- [ ] Summary report with bar graphs generated at end of run
- [ ] Push only happens at end of run (not per-task)
- [ ] Pattern reading integrated into key commands
- [ ] No breaking changes to existing command behavior

---

## Key Files to Create/Modify

```
agent/
├── commands/
│   └── acp.proceed.md              (MODIFY: add autonomous mode sections)
├── milestones/
│   └── milestone-10-command-enhancements.md (this file)
└── tasks/
    └── milestone-10-command-enhancements/
        ├── task-78-proceed-autonomous-completion.md
        └── (future tasks added here)
```

---

## Tasks

1. [Task 78: Implement @acp.proceed Autonomous Completion](../tasks/milestone-10-command-enhancements/task-78-proceed-autonomous-completion.md) - Add flags, autonomous loop, progress indicators, and summary reports (8-12 hours)
2. Task 51: Pattern Reading in Commands - Update commands to read agent/patterns/ (2-3 hours) *(candidate for migration from M2)*

**Total Estimated**: 10-15 hours (approximately 2-4 weeks)  

---

## Environment Variables

No environment variables required. All changes are to command documentation (markdown agent directives).

---

## Testing Requirements

- [ ] Manual testing of `@acp.proceed --complete` on a real milestone
- [ ] Verify `--dry-run` output matches expected task list
- [ ] Verify `@git.commit` runs correctly per-task
- [ ] Verify natural language argument parsing works
- [ ] Verify agent halts on errors and requests user input
- [ ] Verify summary report is accurate

---

## Documentation Requirements

- [ ] AGENT.md updated with autonomous completion section
- [ ] CHANGELOG.md entry for each enhancement
- [ ] @acp.proceed command doc updated with new arguments section

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Context window exhaustion | High | Medium | Re-read progress.yaml and task files at start of each iteration |
| Runaway autonomous execution | Medium | Low | Confirmation prompt + halt on any errors |
| Natural language misinterpretation | Medium | Low | Always require confirmation before autonomous mode |
| Partial commits on failure | Medium | Low | Never commit partial work; halt and seek user input |

---

**Next Milestone**: TBD  
**Blockers**: None  
**Notes**:
- This is an umbrella milestone — new command enhancements can be added as tasks
- `@acp.proceed` changes are markdown directive updates, not shell scripts
- `--complete` implies `--commit` (no completion mode without commits)
- Task 51 is a candidate for migration from M2 to M10
