# Milestone 9: Template Source Files Support (agent/files/)

**Goal**: Extend ACP package system to bundle and install template source files in agent/files/ directory for safe, organized code template distribution
**Duration**: 2-3 weeks
**Dependencies**: Milestone 3 (Package Management System)
**Status**: Not Started

---

## Overview

This milestone implements support for template source files in ACP packages via the `agent/files/` directory. Packages can distribute actual code files, configuration files, and project structure templates that install to `agent/files/` for safe storage and user-controlled copying.

The feature enables packages like `acp-core-sdk` to provide pre-configured TypeScript setups, build scripts, and source code templates instead of requiring users to manually create files or embedding large code blocks in command heredocs.

**Key Innovation**: Files are first-class citizens in the package system with version tracking, selective installation, variable substitution, and safe storage in `agent/files/` - maintaining ACP's principle of keeping all package content within the `agent/` directory.

**Architectural Decision**: Files install to `agent/files/` (not project root) for safety, consistency, and user control. Users explicitly copy files from `agent/files/` to their project as needed, or commands automate the copying.

---

## Deliverables

### 1. Schema and Validation
- Extended `agent/schemas/package.schema.yaml` with files section
- File metadata fields (name, description, target, required, variables, experimental)
- Validation rules for file declarations
- File existence checking in agent/files/
- Target path safety validation

### 2. Installation System
- File scanning in `acp.package-install.sh` (agent/files/ directory)
- `--files` flag for selective installation
- `--files-only` and `--no-files` flags
- Variable substitution system
- Installation to agent/files/ with subdirectory structure
- No conflict detection needed (installs to agent/, not project root)

### 3. Manifest Tracking
- Extended `agent/manifest.yaml` to track installed files
- File version tracking
- Installation path tracking (agent/files/...)
- Target path tracking (where user should copy to)
- Variable values tracking
- Checksum-based modification detection

### 4. Command Updates
- Updated `@acp.package-install` for file installation to agent/files/
- Updated `@acp.package-update` for file updates
- Updated `@acp.package-remove` for file removal from agent/files/
- Updated `@acp.package-validate` for file validation
- Updated `@acp.package-list` to show files

### 5. Testing & Documentation
- Unit tests for template operations
- Integration tests for installation workflows
- E2E tests for complete scenarios
- Updated AGENT.md with templates section
- Updated README.md with template examples
- CHANGELOG.md with feature announcement

---

## Success Criteria

- [ ] `package.yaml` schema supports files section
- [ ] Files can be declared with metadata (name, description, target, variables)
- [ ] `@acp.package-install` installs files to agent/files/ directory
- [ ] `--files` flag enables selective file installation
- [ ] Variable substitution works for files with placeholders
- [ ] Files install to agent/files/ maintaining subdirectory structure
- [ ] Manifest tracks installed files with versions and checksums
- [ ] `@acp.package-update` updates files in agent/files/
- [ ] `@acp.package-remove` removes files from agent/files/
- [ ] `@acp.package-validate` validates file declarations
- [ ] `--list` mode shows available files
- [ ] Files respect experimental flag (if marked)
- [ ] All tests pass (unit, integration, E2E)
- [ ] Documentation complete and accurate
- [ ] No breaking changes to existing package functionality
- [ ] Files remain in agent/ directory (not scattered in project root)

---

## Key Files to Create

```
agent/
├── files/                          # NEW: Template source files directory
│   ├── .gitkeep
│   └── (installed from packages)
├── milestones/
│   └── milestone-9-template-source-files.md (this file)
├── tasks/
│   └── milestone-9-template-source-files/
│       ├── task-71-schema-extension.md
│       ├── task-72-installation-system.md
│       ├── task-73-manifest-tracking.md
│       ├── task-74-command-updates.md
│       ├── task-75-testing-suite.md
│       └── task-76-documentation.md
└── schemas/
    └── package.schema.yaml (updated)

tests/
└── acp.file-installation.test.sh

e2e/
└── acp.template-source-files.test.sh
```

---

## Tasks

1. [Task 71: Schema Extension](../tasks/milestone-9-template-source-files/task-71-schema-extension.md) - Extend package.yaml schema for files (3-4 hours)
2. [Task 72: Installation System](../tasks/milestone-9-template-source-files/task-72-installation-system.md) - Implement file installation to agent/files/ (6-8 hours)
3. [Task 73: Manifest Tracking](../tasks/milestone-9-template-source-files/task-73-manifest-tracking.md) - Track installed files in manifest (2-3 hours)
4. [Task 74: Command Updates](../tasks/milestone-9-template-source-files/task-74-command-updates.md) - Update package commands for files (4-5 hours)
5. [Task 75: Testing Suite](../tasks/milestone-9-template-source-files/task-75-testing-suite.md) - Comprehensive tests for file system (6-8 hours)
6. [Task 76: Documentation](../tasks/milestone-9-template-source-files/task-76-documentation.md) - Update all documentation (3-4 hours)

**Total Estimated**: 24-32 hours (approximately 2-3 weeks)

---

## Environment Variables

No environment variables required. The template system is file-based and uses standard ACP infrastructure.

---

## Testing Requirements

- [ ] Unit tests for file metadata parsing
- [ ] Unit tests for variable substitution
- [ ] Unit tests for agent/files/ path handling
- [ ] Integration tests for file installation to agent/files/
- [ ] Integration tests for file updates
- [ ] Integration tests for file removal from agent/files/
- [ ] E2E tests for complete workflows (install → update → remove)
- [ ] E2E tests for selective installation (--files flag)
- [ ] E2E tests for variable substitution
- [ ] Edge case tests (missing files, subdirectory structure)
- [ ] Performance tests (file operations < 100ms per file)

---

## Documentation Requirements

- [ ] AGENT.md updated with "Template Source Files (agent/files/)" section
- [ ] README.md updated with file examples and agent/files/ explanation
- [ ] Design document complete (local.acp-template-source-files.md) ✅ (Revised to agent/files/)
- [ ] Command documentation for all updated commands
- [ ] Migration guide for package authors
- [ ] Best practices guide for file creation and usage
- [ ] Workflow guide for copying from agent/files/ to project

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| User confusion | Medium | Medium | Clear docs on copying from agent/files/, provide command automation |
| Unused files | Low | Medium | Files stay in agent/, easy to clean up, selective installation |
| Variable injection | Medium | Low | Sanitize variable values, validate patterns, escape special chars |
| Package size bloat | Medium | Medium | Warn if files exceed size limits, document best practices |
| Complexity creep | Medium | Medium | Keep API simple, provide clear examples, comprehensive docs |
| Breaking changes | Medium | Low | Maintain backward compatibility, version bump appropriately |

---

**Next Milestone**: TBD (possibly M10: Advanced File Features or M10: ACP CLI Tool)
**Blockers**: None (M3 provides all necessary infrastructure)
**Notes**:
- Files are optional - packages work without them
- Builds on package management patterns from M3
- Variable substitution is key feature for personalization
- Files install to agent/files/ maintaining ACP's agent/ containment principle
- Users copy files from agent/files/ to project as needed
- Commands can automate copying for better UX
- Consider extracting as experimental feature initially
- May want to prototype with acp-core-sdk package first
