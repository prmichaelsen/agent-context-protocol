# Milestone 6: ACP Preferences System

**Goal**: Implement hierarchical preference system enabling users to configure agent behavior at user, workspace, and project levels
**Duration**: 2-3 weeks
**Dependencies**: Milestone 4 (Package Development System), Milestone 5 (Global Package Installation)
**Status**: Not Started

---

## Overview

This milestone implements a comprehensive preferences system that allows users to configure ACP command behavior, template defaults, and workflow automation at three distinct levels: user-global (`~/.acp/`), workspace (`.vscode/` or workspace root), and project (`./agent/`). The system uses a configurables-based approach where available preferences are defined with metadata, ensuring type safety and discoverability.

The preferences system solves the problem of repetitive configuration by allowing users to set defaults once and have them apply across all command invocations. It enables sophisticated workflow automation through preset configurations and provides package authors with a standard way to expose configuration options.

This milestone builds on the package management system (M3) and package development system (M4) by adding preference support to packages, enabling them to define their own configurables and provide preset configurations for common use cases.

---

## Deliverables

### 1. Core Infrastructure
- `agent/scripts/acp.preferences.sh` - Unified preference utilities (get, set, validate, generate)
- `agent/commands/acp.preferences-get.md` - Agent command for getting preferences
- `agent/configurables/acp.configurables.yaml` - Core ACP preference definitions
- `agent/preferences/acp.default.yaml` - Default preference template
- All preference functions in `acp.preferences.sh` (not `acp.common.sh` for separation of concerns)
- Unit tests for preference operations (`tests/acp.preferences.test.sh`)

**Note**: All preference utilities (get, set, validate, generate) are in `acp.preferences.sh` rather than `acp.common.sh` to maintain clear separation between general utilities and preference-specific logic. Other scripts can source `acp.preferences.sh` when needed.

### 2. Command Integration
- Updated `@acp.plan` command with preference support
- Updated `@acp.task-create` command with preference support
- Updated `@acp.validate` command with preference support
- Integration tests for command behavior with preferences

### 3. Management Commands
- `@acp.preferences-create` - Create preference files at any level (follows entity creation pattern)
- `@acp.preferences-show` - Display effective preferences with source
- `@acp.preferences-set` - Set preference values interactively
- `@acp.preferences-validate` - Validate preferences against configurables

**Note**: Using `@acp.preferences-create` instead of `init` to match entity creation pattern (`@acp.command-create`, `@acp.design-create`, `@acp.pattern-create`).

### 4. Package Support
- Updated `@acp.package-install` to copy configurables
- Updated `@acp.package-create` to create configurables template
- Package preference pattern documentation
- Example package with preferences (reference implementation)

### 5. Documentation
- AGENT.md updated with preferences section
- README.md updated with preference examples
- Command documentation updated for preference-aware commands
- Preferences best practices guide

### 6. Testing Suite
- Unit tests for preference resolution (precedence, fallback, validation)
- Integration tests for command usage with preferences
- E2E tests for package preferences
- Validation tests for configurables schema

---

## Success Criteria

- [ ] Preference resolution works correctly with precedence (Project > Workspace > User > Default)
- [ ] `@acp.plan` respects `plan.draft.create_mode` preference
- [ ] `@acp.task-create` respects `task.create.granularity` preference
- [ ] `@acp.preferences-show` displays effective values with source indication
- [ ] `@acp.preferences-set` can set preferences at any level (user/workspace/project)
- [ ] `@acp.preferences-validate` catches invalid preference values
- [ ] Package configurables are installed and accessible
- [ ] Preset configurations work correctly (e.g., `--preset acp.batch-planning`)
- [ ] All unit tests pass (preference resolution, validation)
- [ ] All integration tests pass (command behavior with preferences)
- [ ] All E2E tests pass (package preferences)
- [ ] Documentation is complete and accurate
- [ ] Backward compatible (commands work without preferences)

---

## Key Files to Create

```
agent/
├── scripts/
│   └── acp.preferences.sh              # Unified preference utilities
├── commands/
│   ├── acp.preferences-get.md          # Get preferences
│   ├── acp.preferences-create.md       # Create preference files
│   ├── acp.preferences-show.md         # Display preferences
│   ├── acp.preferences-set.md          # Set preferences
│   └── acp.preferences-validate.md     # Validate preferences
├── configurables/
│   └── acp.configurables.yaml          # Core preference definitions (already exists, enhance)
├── preferences/
│   ├── acp.default.yaml                # Default preferences (already exists, enhance)
│   └── acp.batch-planning.yaml         # Example preset
└── design/
    └── acp-preferences-system.md       # Design document (already created)

tests/
├── acp.preferences-get.test.sh         # Unit tests for preference resolution
└── fixtures/
    └── preferences/                     # Test preference files

e2e/
└── acp.plan-with-preferences.test.sh   # Integration tests

~/.acp/
└── agent/
    ├── preferences/
    │   └── acp.default.yaml            # User-level preferences
    └── configurables/
        └── {package}.configurables.yaml # Installed package configurables
```

---

## Tasks

1. [Task 37: Preference Loading Infrastructure](../tasks/milestone-6-preferences-system/task-37-preference-loading-infrastructure.md) - Create preference resolution functions and core infrastructure (4-6 hours)
2. [Task 38: Configurables System Enhancement](../tasks/milestone-6-preferences-system/task-38-configurables-system-enhancement.md) - Enhance configurables.yaml with comprehensive preference definitions (3-4 hours)
3. [Task 39: Command Integration - @acp.plan](../tasks/milestone-6-preferences-system/task-39-command-integration-acp-plan.md) - Integrate preferences into @acp.plan command (4-5 hours)
4. [Task 40: Preference Management Commands](../tasks/milestone-6-preferences-system/task-40-preference-management-commands.md) - Create get, create, show, set, validate commands (8-10 hours)
5. [Task 41: Package Preference Support](../tasks/milestone-6-preferences-system/task-41-package-preference-support.md) - Add configurable handling to package system (4-5 hours)
6. [Task 42: Preset Configuration System](../tasks/milestone-6-preferences-system/task-42-preset-configuration-system.md) - Implement --preset flag and preset loading (3-4 hours)
7. [Task 43: Preferences Testing Suite](../tasks/milestone-6-preferences-system/task-43-preferences-testing-suite.md) - Comprehensive unit, integration, and E2E tests (6-8 hours)
8. [Task 44: Preferences Documentation](../tasks/milestone-6-preferences-system/task-44-preferences-documentation.md) - Update all documentation with preference examples (3-4 hours)

**Total Estimated**: 35-46 hours (approximately 2-3 weeks)

---

## Environment Variables

No environment variables required. The preferences system is file-based and does not rely on environment configuration.

**Note**: Preferences should NOT contain secrets. Use environment variables or secret management systems for sensitive data.

---

## Testing Requirements

- [ ] Unit tests for preference resolution (precedence, fallback, missing values)
- [ ] Unit tests for configurable validation (schema, types, options)
- [ ] Integration tests for `@acp.plan` with preferences
- [ ] Integration tests for `@acp.task-create` with preferences
- [ ] E2E tests for package preferences
- [ ] E2E tests for preset configurations
- [ ] Validation tests for invalid preference values
- [ ] Performance tests (preference loading overhead < 100ms)

---

## Documentation Requirements

- [ ] AGENT.md updated with "Preferences System" section
- [ ] README.md updated with preference examples and quick start
- [ ] Design document complete (acp-preferences-system.md) ✅
- [ ] Command documentation updated for preference-aware commands
- [ ] Preferences best practices guide created
- [ ] Package preference pattern documentation
- [ ] Migration guide for existing projects

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Precedence confusion | Medium | Medium | Clear documentation, `@acp.preferences-show` displays source |
| Performance overhead | Low | Low | Lazy loading, caching, fast YAML parser (<100ms) |
| Backward compatibility | High | Low | All preferences optional, commands work without them |
| Complex configurables | Medium | Medium | Start with simple preferences, expand gradually |
| Package conflicts | Medium | Low | Namespace isolation, validation during package install |
| User adoption | Medium | Medium | Make preferences optional, provide clear examples |

---

**Next Milestone**: TBD (possibly M7: Advanced Workflow Automation)
**Blockers**: None (M4 and M5 provide all necessary infrastructure)
**Notes**: 
- Preferences are entirely optional - commands work without them
- Start with simple preferences (`plan.draft.create_mode`) before adding complex ones
- Package support enables ecosystem growth (packages can provide presets)
- Consider extracting as separate package after implementation
