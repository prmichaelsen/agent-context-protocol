# Milestone 7: Global ACP Project Registry

**Goal**: Implement centralized project registry system for global ACP workspace with discovery, metadata tracking, and context switching
**Duration**: 1-2 weeks
**Dependencies**: Milestone 5 (Global Package Installation)
**Status**: Not Started

---

## Overview

This milestone implements a comprehensive project registry system at `~/.acp/projects.yaml` that tracks all projects in the global workspace. It provides project discovery, metadata management, relationship tracking, and seamless context switching between projects via `@acp.project-set`.

The registry complements the existing global package system (M5) by providing similar management capabilities for projects, enabling users to easily discover, navigate, and manage multiple projects in `~/.acp/projects/`.

---

## Deliverables

### 1. Registry Infrastructure
- `~/.acp/projects.yaml` - Central project registry
- Registry initialization in `init_global_acp()`
- Schema definition for projects.yaml
- Registry utility functions in `acp.common.sh`

### 2. Project Management Commands
- `@acp.project-list` - List all projects with filtering
- `@acp.project-set` - Switch to project (context switching)
- `@acp.project-info` - Show project details
- `@acp.project-update` - Update project metadata
- `@acp.project-remove` - Remove from registry
- `@acp.projects-sync` - Sync registry with filesystem (discover unregistered projects)

### 3. Integration Updates
- Enhanced `@acp.project-create` with auto-registration
- Context-aware file operations via `current_project`
- Automatic timestamp tracking (`last_accessed`)

### 4. Testing & Documentation
- Unit tests for registry operations
- Integration tests for commands
- E2E tests for workflows
- AGENT.md and README.md updates

---

## Success Criteria

- [ ] Registry auto-created on first project creation
- [ ] `@acp.project-list` displays all projects with metadata
- [ ] `@acp.project-set` switches context and changes directory
- [ ] `@acp.project-info` shows complete project details
- [ ] `@acp.project-update` modifies registry correctly
- [ ] `@acp.project-remove` removes projects from registry
- [ ] `@acp.projects-sync` discovers existing projects
- [ ] `@acp.project-create` auto-registers new projects
- [ ] Current project tracked in registry
- [ ] All commands work with current project context
- [ ] Unit tests pass (registry operations)
- [ ] Integration tests pass (command workflows)
- [ ] E2E tests pass (full scenarios)
- [ ] Documentation complete and accurate

---

## Key Files to Create

```
agent/
├── commands/
│   ├── acp.project-list.md
│   ├── acp.project-set.md
│   ├── acp.project-info.md
│   ├── acp.project-update.md
│   ├── acp.project-remove.md
│   └── acp.projects-sync.md
├── scripts/
│   ├── acp.project-list.sh
│   ├── acp.project-set.sh
│   ├── acp.project-info.sh
│   ├── acp.project-update.sh
│   ├── acp.project-remove.sh
│   └── acp.projects-sync.sh
└── schemas/
    └── projects.schema.yaml

tests/
└── acp.project-registry.test.sh

e2e/
├── acp.project-list.test.sh
├── acp.project-set.test.sh
└── acp.projects-sync.test.sh

~/.acp/
└── projects.yaml
```

---

## Tasks

1. [Task 52: Project Registry Infrastructure](../tasks/milestone-7-project-registry/task-52-registry-infrastructure.md) - Create registry structure and utility functions (2-3 hours)
2. [Task 53: @acp.project-list Command](../tasks/milestone-7-project-registry/task-53-project-list.md) - List projects with filtering (2-3 hours)
3. [Task 54: @acp.project-set Command](../tasks/milestone-7-project-registry/task-54-project-set.md) - Context switching implementation (2-3 hours)
4. [Task 55: @acp.project-info Command](../tasks/milestone-7-project-registry/task-55-project-info.md) - Show project details (1-2 hours)
5. [Task 56: @acp.project-update Command](../tasks/milestone-7-project-registry/task-56-project-update.md) - Update project metadata (1-2 hours)
6. [Task 57: @acp.project-remove Command](../tasks/milestone-7-project-registry/task-57-project-remove.md) - Remove projects from registry (1-2 hours)
7. [Task 58: @acp.projects-sync Command](../tasks/milestone-7-project-registry/task-58-projects-sync.md) - Sync registry with filesystem (2-3 hours)
8. [Task 59: Integration & Testing](../tasks/milestone-7-project-registry/task-59-integration-testing.md) - Comprehensive testing suite (3-4 hours)
9. [Task 60: Documentation Updates](../tasks/milestone-7-project-registry/task-60-documentation.md) - Update AGENT.md, README.md, CHANGELOG.md (2-3 hours)

**Total Estimated**: 16-25 hours (approximately 1-2 weeks)

---

## Environment Variables

No environment variables required. The registry system is file-based and uses standard ACP infrastructure.

---

## Testing Requirements

- [ ] Unit tests for registry initialization
- [ ] Unit tests for project registration
- [ ] Unit tests for project lookup and filtering
- [ ] Integration tests for `@acp.project-create` auto-registration
- [ ] Integration tests for `@acp.project-set` context switching
- [ ] E2E tests for complete workflows (create → list → set → info → update → remove)
- [ ] Edge case tests (missing registry, corrupted registry, deleted projects)
- [ ] Performance tests (registry operations < 100ms)

---

## Documentation Requirements

- [ ] AGENT.md updated with "Project Registry" section
- [ ] README.md updated with project management examples
- [ ] Design document complete (local.projects-yaml-feature.md) ✅
- [ ] Command documentation for all 6 commands
- [ ] Migration guide for existing projects
- [ ] Best practices guide for project organization

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Registry staleness | Medium | Medium | Auto-update on operations, provide sync command |
| Directory changes | Medium | Low | Validate paths on access, warn if missing |
| Duplicate names | Low | Low | Validate uniqueness on registration |
| Performance overhead | Low | Low | Lazy loading, efficient YAML queries |
| User adoption | Medium | Medium | Make optional, provide clear examples |

---

**Next Milestone**: TBD (possibly M8: Advanced Workflow Automation)
**Blockers**: None (M5 provides all necessary infrastructure)
**Notes**: 
- Registry is optional - projects work without it
- Builds on global package system patterns from M5
- Context switching is key feature for multi-project workflows
- Consider extracting as separate package after implementation
