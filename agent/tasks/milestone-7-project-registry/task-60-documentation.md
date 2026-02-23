# Task 60: Documentation Updates

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)
**Estimated Time**: 2-3 hours
**Dependencies**: Tasks 52-59 (All implementations complete)
**Status**: Not Started

---

## Objective

Update all project documentation to include the project registry system with examples, usage patterns, and migration guides.

---

## Steps

### 1. Update AGENT.md

Add "Project Registry System" section after "Global Package Discovery":

```markdown
## Project Registry System

Global ACP supports a project registry at `~/.acp/projects.yaml` that tracks all projects in `~/.acp/projects/`.

### Key Features
- Project discovery via `@acp.project-list`
- Context switching via `@acp.project-set`
- Metadata tracking (type, status, tags, relationships)
- Automatic registration on project creation

### Commands
- `@acp.project-list` - List registered projects
- `@acp.project-set` - Switch to project
- `@acp.project-info` - Show project details
- `@acp.project-update` - Update metadata
- `@acp.project-remove` - Remove from registry
- `@acp.projects-sync` - Discover unregistered projects
```

### 2. Update README.md

Add "Project Registry" section with quick examples.

### 3. Update CHANGELOG.md

Add version entry (determine version bump: likely minor - new feature):

```markdown
## [X.Y.0] - 2026-02-23

### Added

**Project Registry System**:
- Global project registry at `~/.acp/projects.yaml`
- `@acp.project-list` - List all registered projects with filtering
- `@acp.project-set` - Switch between projects (context switching)
- `@acp.project-info` - Show detailed project information
- `@acp.project-update` - Update project metadata
- `@acp.project-remove` - Remove projects from registry
- `@acp.projects-sync` - Discover and register existing projects
- Automatic project registration on creation
- Current project tracking for context-aware operations
- Relationship and dependency tracking

### Changed
- `@acp.project-create` now auto-registers projects in registry
- `init_global_acp()` initializes projects registry
```

### 4. Update Version Numbers

Update version in:
- AGENT.md
- agent/progress.yaml

---

## Verification

- [ ] AGENT.md updated
- [ ] README.md updated
- [ ] CHANGELOG.md updated
- [ ] Version numbers updated
- [ ] Examples are clear and accurate
- [ ] Migration guide included

---

**Milestone Complete**: All 9 tasks done!
