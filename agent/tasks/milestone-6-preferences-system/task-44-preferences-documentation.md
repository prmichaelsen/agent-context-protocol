# Task 44: Preferences Documentation

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)
**Estimated Time**: 3-4 hours
**Dependencies**: Task 37-43 (All preference implementation complete)
**Status**: Not Started

---

## Objective

Update all project documentation (AGENT.md, README.md, CHANGELOG.md) with comprehensive preferences system documentation, examples, and best practices.

---

## Context

Users need clear documentation to understand and use the preferences system effectively. This includes:
- What preferences are available
- How to set and view preferences
- Precedence rules
- Preset usage
- Package preference patterns
- Best practices

---

## Steps

### 1. Update AGENT.md

Add "Preferences System" section after "ACP Commands" section:

```markdown
## ACP Preferences System

The preferences system enables users to configure agent behavior, command defaults, and workflow automation at three levels: user-global, workspace, and project.

### Preference Levels

1. **User Preferences** (`~/.acp/agent/preferences/`) - Global defaults for all projects
2. **Workspace Preferences** (`.vscode/preferences/`) - IDE/workspace-specific settings
3. **Project Preferences** (`./agent/preferences/`) - Project-specific overrides

**Precedence**: Project > Workspace > User > Default (more specific overrides more general)

### Available Preferences

Preferences are defined in [`agent/configurables/acp.configurables.yaml`](agent/configurables/acp.configurables.yaml). Common preferences:

- `acp.plan.draft.create_mode` - Draft creation behavior (structured, unstructured, guided, contextual)
- `acp.task.create.granularity` - Default task size in hours (1-8)
- `acp.validation.auto_fix.enabled` - Auto-fix validation issues (true/false)

### Managing Preferences

```bash
# Initialize preferences
@acp.preferences-init --level user --namespace acp

# View current preferences
@acp.preferences-show acp

# Set a preference
@acp.preferences-set acp plan.draft.create_mode guided --user

# Validate preferences
@acp.preferences-validate
```

### Using Presets

Presets are named preference bundles for common workflows:

```bash
# Use batch planning preset
@acp.plan --preset acp.batch-planning

# Available presets:
# - acp.batch-planning - Automated planning without interaction
# - acp.interactive-planning - Guided planning with user input
# - acp.rapid-prototyping - Fast iteration with minimal overhead
```

### Command-Line Overrides

Override any preference for a single invocation:

```bash
# Override draft mode for this invocation
@acp.plan --plan.draft.create_mode unstructured

# Precedence: Override > Preset > Project > Workspace > User > Default
```

### Package Preferences

Packages can define their own configurables and presets:

```bash
# View package preferences
@acp.preferences-show mcp-auth-server-base

# Use package preset
@mcp-auth-server-base.init --preset mcp-auth-server-base.static-jwt-auth
```

For more details, see [Design Document](agent/design/acp-preferences-system.md).
```

### 2. Update README.md

Add preferences section to README.md:

```markdown
## Preferences System

Configure ACP behavior at user, workspace, or project level.

### Quick Start

```bash
# View available preferences
@acp.preferences-show acp

# Set a preference
@acp.preferences-set acp plan.draft.create_mode guided --user

# Use a preset
@acp.plan --preset acp.batch-planning
```

### Preference Levels

- **User** (`~/.acp/agent/preferences/`) - Your personal defaults
- **Workspace** (`.vscode/preferences/`) - Team/workspace settings
- **Project** (`./agent/preferences/`) - Project-specific overrides

**Precedence**: Project > Workspace > User > Default

### Common Preferences

| Preference | Description | Default | Options |
|------------|-------------|---------|---------|
| `plan.draft.create_mode` | Draft creation behavior | `structured` | structured, unstructured, guided, contextual |
| `task.create.granularity` | Task size in hours | `3` | 1-8 |
| `validation.auto_fix.enabled` | Auto-fix issues | `true` | true, false |

### Presets

Pre-configured preference bundles for common workflows:

- **batch-planning** - Automated planning without interaction
- **interactive-planning** - Guided planning with user input
- **rapid-prototyping** - Fast iteration with minimal overhead

Usage: `@acp.plan --preset acp.batch-planning`

For complete documentation, see [AGENT.md](AGENT.md#acp-preferences-system).
```

### 3. Update CHANGELOG.md

Add preferences system to changelog:

```markdown
## [3.8.0] - 2026-02-XX

### Added
- **Preferences System**: Multi-level preference configuration (user/workspace/project)
- **Configurables**: Define available preferences with metadata and validation
- **Preset Configurations**: Named preference bundles for common workflows
- **Preference Commands**: 4 new commands for preference management
  - `@acp.preferences-init` - Initialize preference files
  - `@acp.preferences-show` - Display effective preferences
  - `@acp.preferences-set` - Set preference values
  - `@acp.preferences-validate` - Validate preferences
- **Package Preference Support**: Packages can define configurables and presets
- **Command Integration**: `@acp.plan` respects `plan.draft.create_mode` preference
- **Preset System**: Load preference bundles with `--preset` flag
- **Command-Line Overrides**: Override preferences with `--preference.path value`

### Changed
- `@acp.plan` now checks preferences before prompting user (v1.0.0 → v2.0.0)
- Package schema updated to include configurables field
- `@acp.package-install` copies configurables and presets
- `@acp.package-create` creates configurables template

### Technical Details
- Preference precedence: Project > Workspace > User > Default
- Pure bash implementation (no external dependencies)
- YAML-based configuration files
- Namespace isolation (acp, package-name, etc.)
- Backward compatible (commands work without preferences)
```

### 4. Create Preferences Best Practices Guide

Create `agent/design/preferences-best-practices.md`:

```markdown
# ACP Preferences Best Practices

## When to Use Preferences

✅ **Use preferences for**:
- Repeated configuration (same choice every time)
- Team standards (enforce consistency)
- Workflow automation (batch operations)
- Personal defaults (your preferred style)

❌ **Don't use preferences for**:
- One-time configurations
- Secrets or credentials (use environment variables)
- Dynamic values (use command arguments)

## Preference Organization

### User-Level Preferences
Use for personal defaults that apply across all projects:
- Draft creation mode preference
- Output verbosity preference
- Personal workflow preferences

### Workspace-Level Preferences
Use for team/workspace standards:
- Team coding standards
- Shared workflow configurations
- IDE-specific settings

### Project-Level Preferences
Use for project-specific requirements:
- Project-specific workflows
- Compliance requirements
- Project conventions

## Preset Patterns

### Creating Effective Presets

✅ **Good preset**:
```yaml
# acp.batch-planning.yaml
# Clear name, focused purpose, documented
acp:
  plan.draft.create_mode: 'contextual'
  plan.batch.auto_confirm: true
  task.create.granularity: 2
```

❌ **Bad preset**:
```yaml
# acp.preset1.yaml
# Unclear name, mixed concerns, undocumented
acp:
  plan.draft.create_mode: 'contextual'
  output.verbosity.level: 'verbose'  # Conflicts with batch goal
  git.auto_commit.enabled: true  # Unrelated to planning
```

### Preset Naming

- Use descriptive names: `batch-planning` not `bp`
- Include namespace: `acp.batch-planning` not just `batch-planning`
- Use kebab-case: `rapid-prototyping` not `rapidPrototyping`

## Package Preferences

### For Package Authors

1. **Define configurables** in `agent/configurables/{package}.configurables.yaml`
2. **Provide presets** for common use cases
3. **Document preferences** in README.md
4. **Validate configurables** before publishing

### For Package Users

1. **Browse configurables** to see available preferences
2. **Try presets** before creating custom preferences
3. **Override carefully** - understand what you're changing

## Common Patterns

### Pattern 1: Workflow Switching

```bash
# Development workflow (verbose, interactive)
@acp.plan --preset acp.interactive-planning

# Production workflow (quiet, automated)
@acp.plan --preset acp.batch-planning
```

### Pattern 2: Temporary Override

```bash
# Usually use guided mode, but need structured for this one
@acp.plan --plan.draft.create_mode structured
```

### Pattern 3: Team Standards

```yaml
# .vscode/preferences/acp.yaml
# Enforce team standards at workspace level
acp:
  plan.draft.create_mode: 'structured'  # Team requires structured drafts
  task.create.granularity: 4  # Team prefers larger tasks
```

## Troubleshooting

### Preference Not Applied

1. Check precedence - higher level may be overriding
2. Run `@acp.preferences-show` to see effective value
3. Verify preference path syntax (dot notation)
4. Validate preference file with `@acp.preferences-validate`

### Preset Not Found

1. Check preset filename matches namespace
2. Verify preset file exists in preferences directory
3. Use `@acp.preferences-show --presets` to list available presets

### Invalid Preference Value

1. Check configurables for valid options
2. Run `@acp.preferences-validate` to identify issues
3. Use `@acp.preferences-set` to set valid value
```

### 5. Update Command Documentation

Update preference-aware commands to document preference usage:

**For `@acp.plan`**:
```markdown
## Preferences

This command respects the following preferences:

- `acp.plan.draft.create_mode` - Default draft creation mode
- `acp.plan.batch.auto_confirm` - Auto-confirm batch operations
- `acp.task.create.granularity` - Default task size

Set preferences:
```bash
@acp.preferences-set acp plan.draft.create_mode guided --user
```

Use presets:
```bash
@acp.plan --preset acp.batch-planning
```
```

### 6. Create Quick Reference

Add preferences quick reference to README.md:

```markdown
## Preferences Quick Reference

### View Preferences
```bash
@acp.preferences-show acp              # Show ACP preferences
@acp.preferences-show --presets acp    # List available presets
```

### Set Preferences
```bash
@acp.preferences-set acp plan.draft.create_mode guided --user     # User-level
@acp.preferences-set acp task.create.granularity 2 --project      # Project-level
```

### Use Presets
```bash
@acp.plan --preset acp.batch-planning           # Use preset
@acp.plan --preset acp.batch-planning --plan.draft.create_mode structured  # With override
```

### Precedence
Override > Preset > Project > Workspace > User > Default
```

### 7. Update Directory Structure Documentation

Update directory structure in AGENT.md to include preferences:

```markdown
## Directory Structure

```
project-root/
├── AGENT.md
├── agent/
│   ├── commands/
│   ├── configurables/
│   │   └── acp.configurables.yaml      # Preference definitions
│   ├── preferences/
│   │   ├── acp.default.yaml            # Default preferences
│   │   ├── acp.batch-planning.yaml     # Preset
│   │   └── {package}.default.yaml      # Package preferences
│   ├── design/
│   ├── milestones/
│   ├── patterns/
│   ├── tasks/
│   └── progress.yaml
└── (project files)
```
```

---

## Verification

- [ ] AGENT.md updated with preferences section
- [ ] README.md updated with preferences quick start
- [ ] CHANGELOG.md updated with v3.8.0 entry
- [ ] Best practices guide created
- [ ] Command documentation updated (@acp.plan, @acp.task-create)
- [ ] Directory structure documentation updated
- [ ] Quick reference added to README
- [ ] Examples are clear and accurate
- [ ] All links work correctly
- [ ] Documentation is consistent across files

---

## Expected Output

### Files Modified
- `AGENT.md` - Added preferences section (~100 lines)
- `README.md` - Added preferences quick start (~50 lines)
- `CHANGELOG.md` - Added v3.8.0 entry
- `agent/commands/acp.plan.md` - Added preferences documentation
- `agent/commands/acp.task-create.md` - Added preferences documentation

### Files Created
- `agent/design/preferences-best-practices.md` - Best practices guide

### Documentation Sections Added
- Preferences System overview
- Preference levels and precedence
- Management commands
- Preset usage
- Package preferences
- Quick reference
- Best practices

---

## Common Issues and Solutions

### Issue 1: Documentation inconsistency
**Symptom**: Different files describe preferences differently
**Solution**: Use consistent terminology and examples across all docs

### Issue 2: Missing examples
**Symptom**: Users don't understand how to use preferences
**Solution**: Add concrete examples for each use case

### Issue 3: Unclear precedence
**Symptom**: Users confused about which preference applies
**Solution**: Include precedence diagram and clear examples

---

## Resources

- [Design Document](../design/acp-preferences-system.md) - Complete specification
- [Current AGENT.md](../../AGENT.md) - File to update
- [Current README.md](../../README.md) - File to update

---

## Notes

- Keep documentation user-friendly (avoid technical jargon)
- Provide examples for every concept
- Link related documentation
- Update version numbers consistently
- Ensure backward compatibility is documented

---

**Next Task**: None (Milestone 6 complete)
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md)
**Estimated Completion Date**: TBD