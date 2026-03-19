# Task 76: Documentation for Templates

**Milestone**: [M9 - Template Source Files Support](../../milestones/milestone-9-template-source-files.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Task 75 (Testing Suite)  
**Status**: Not Started  

---

## Objective

Update all project documentation to include template source files support with comprehensive examples, migration guides, and best practices.

---

## Context

This is the final phase of the Template Source Files Support implementation. Complete documentation ensures users understand how to create, install, and use templates effectively.

**Design Document**: [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md)  

---

## Steps

### 1. Update AGENT.md

Add Template Source Files section:

**Actions**:
- Open `AGENT.md`
- Add new section after "Experimental Features"
- Document template system overview
- Explain template vs patterns/commands/designs
- Document security considerations
- Provide examples

**Section to Add**:
```markdown
## Template Source Files

ACP packages can bundle template source files (code, configs, etc.) alongside patterns, commands, and designs.

### What are Templates?

Templates are actual code files, configuration files, and project scaffolding that packages can distribute:
- TypeScript/JavaScript source files
- Configuration files (tsconfig.json, package.json, etc.)
- Build scripts and tooling configs
- Project structure scaffolding

### Templates vs Other Content Types

| Type | Location | Purpose |
|------|----------|---------|
| Patterns | `agent/patterns/` | Documentation and guidance |
| Commands | `agent/commands/` | Agent directives |
| Designs | `agent/design/` | Architecture documentation |
| Scripts | `agent/scripts/` | Shell utilities |
| **Templates** | **Project root** | **Actual code and config files** |

### Installing Templates

```bash
# Install all templates
@acp.package-install --repo https://github.com/user/acp-core-sdk.git

# Install only templates
@acp.package-install --templates-only --repo <url>

# Install specific templates
@acp.package-install --templates config/tsconfig.json src/example.ts --repo <url>
```

### Variable Substitution

Templates can contain `{{VARIABLE}}` placeholders:

```json
{
  "name": "{{PACKAGE_NAME}}",
  "author": "{{AUTHOR_NAME}}"
}
```

During installation, you'll be prompted for values.

### Security Considerations

⚠️ Templates install to project directories (not agent/):
- May overwrite existing files
- Always prompted before installation
- Target paths validated for safety
- Conflict detection shows diffs

### Creating Template Packages

See [`@acp.package-create`](agent/commands/acp.package-create.md) for creating packages with templates.
```

### 2. Update README.md

Add templates section to README:

**Actions**:
- Open `README.md`
- Add templates to "What is ACP?" section
- Add template installation examples
- Update directory structure diagram

**Updates**:
```markdown
## What is ACP?

The **Agent Context Protocol** provides:

- **Design Documents** - Architectural decisions
- **Milestones** - Project phases
- **Tasks** - Actionable work items
- **Patterns** - Reusable patterns
- **Progress Tracking** - YAML-based monitoring
- **Templates** - Source code and config files ✨ NEW

## Directory Structure

```
project-root/
├── AGENT.md
├── agent/
│   ├── commands/
│   ├── design/
│   ├── milestones/
│   ├── patterns/
│   ├── tasks/
│   ├── scripts/
│   └── progress.yaml
├── templates/           # NEW: Template source files (in packages)
│   ├── config/
│   └── src/
└── (your project files)
```

## Template Installation

```bash
# Install package with templates
@acp.package-install --repo https://github.com/user/acp-core-sdk.git

# Templates install to project directories with variable substitution
```
```

### 3. Update CHANGELOG.md

Add version entry for templates feature:

**Actions**:
- Open `CHANGELOG.md`
- Add new version entry (determine version: likely 5.0.0 - major feature)
- Document all changes
- Provide migration guide

**CHANGELOG Entry**:
```markdown
## [5.0.0] - YYYY-MM-DD

### Added

**Template Source Files Support** (Milestone 9):
- Added `templates` section to package.yaml schema
- Templates can bundle actual code files, configs, and project scaffolding
- Variable substitution system with `{{PLACEHOLDER}}` format
- Target path specification (install to project root, not agent/)
- Selective installation via `--templates` flag
- `--templates-only` and `--no-templates` flags
- Conflict detection before overwriting existing files
- Safety warnings for template installation
- Manifest tracking for installed templates
- Template version tracking and modification detection
- Experimental template support
- Updated all package commands for template support

**Schema Extension**:
- `agent/schemas/package.schema.yaml` now supports templates array
- Template metadata: name, description, target, required, variables, experimental
- Target path validation (relative paths only, no escaping project root)
- Variable naming validation (UPPER_SNAKE_CASE)

**Command Updates**:
- `@acp.package-install` - Install templates with variable substitution
- `@acp.package-update` - Update templates with conflict detection
- `@acp.package-remove` - Remove templates from target locations
- `@acp.package-validate` - Validate template declarations
- `@acp.package-list` - Show installed templates

**Testing**:
- Unit tests for template functions (11 tests)
- Integration tests for workflows (29 tests)
- E2E tests for complete scenarios
- All tests passing (40/40 assertions, 100%)

### Changed

**Package System**:
- Packages can now distribute more than documentation
- Templates enable code reuse and project scaffolding
- Installation extends beyond agent/ directory

### Security

**Template Installation**:
- Templates install to project root (not agent/ directory)
- Target paths validated to prevent directory escape
- User warned before template installation
- Conflict detection prevents accidental overwrites
- Variable values sanitized before substitution

### Migration Guide

**For Package Authors**:
1. Create `templates/` directory in package root
2. Add template files (code, configs, etc.)
3. Declare templates in package.yaml with metadata
4. Test installation with `--list` flag
5. Publish new version

**For Package Users**:
- Backward compatible - old packages work unchanged
- New packages with templates install automatically
- Use `--no-templates` to skip template installation
- Templates prompt for variables during installation
```

### 4. Create Migration Guide

Create detailed migration guide for package authors:

**Actions**:
- Create `docs/template-migration-guide.md` (if docs/ exists)
- Or add to AGENT.md as subsection
- Document step-by-step migration process
- Provide before/after examples
- Include best practices

### 5. Update Design Document Status

Mark design as implemented:

**Actions**:
- Open `agent/design/local.acp-template-source-files.md`
- Change status from "Proposal" to "Implemented"
- Add implementation notes
- Link to milestone and tasks

**Status Update**:
```markdown
**Status**: Implemented (v5.0.0)  

## Implementation

Implemented in Milestone 9 with 6 tasks:
- Task 71: Schema Extension
- Task 72: Installation System
- Task 73: Manifest Tracking
- Task 74: Command Updates
- Task 75: Testing Suite
- Task 76: Documentation (this task)

See [Milestone 9](../milestones/milestone-9-template-source-files.md) for details.
```

---

## Verification

- [ ] AGENT.md updated with templates section
- [ ] README.md updated with templates overview
- [ ] CHANGELOG.md updated with v5.0.0 entry
- [ ] Migration guide created
- [ ] Design document status updated to "Implemented"
- [ ] All examples tested and working
- [ ] Security considerations documented
- [ ] Best practices documented
- [ ] Links between documents verified

---

## Expected Output

### Documentation Updates

**Files Modified**:
- `AGENT.md` - Added "Template Source Files" section (~100 lines)
- `README.md` - Added templates to overview and examples (~30 lines)
- `CHANGELOG.md` - Added v5.0.0 entry with complete feature list (~80 lines)
- `agent/design/local.acp-template-source-files.md` - Status updated to "Implemented"

**New Files** (optional):
- `docs/template-migration-guide.md` - Detailed migration guide for package authors

### Documentation Quality

- Clear explanations of template system
- Comprehensive examples for all use cases
- Security warnings prominently displayed
- Migration path clearly documented
- Best practices for template creation
- Troubleshooting guide included

---

## Common Issues and Solutions

### Issue 1: Documentation examples don't work

**Symptom**: Users report examples fail when copied  
**Solution**: Test all examples before publishing, verify syntax and paths  

### Issue 2: Security warnings unclear

**Symptom**: Users confused about template safety  
**Solution**: Clarify that templates install outside agent/, explain validation, provide clear examples  

### Issue 3: Migration guide incomplete

**Symptom**: Package authors unsure how to add templates  
**Solution**: Provide step-by-step guide with before/after examples, link to working packages  

---

## Resources

- [`AGENT.md`](../../../AGENT.md): Main documentation
- [`README.md`](../../../README.md): Project overview
- [`CHANGELOG.md`](../../../CHANGELOG.md): Version history
- [`agent/design/local.acp-template-source-files.md`](../../design/local.acp-template-source-files.md): Design document

---

## Notes

- Documentation is final step before release
- All examples must be tested and working
- Security considerations critical for user trust
- Migration guide helps ecosystem adoption
- Consider creating video tutorial or blog post
- Update version to 5.0.0 (major feature addition)

---

**Next Task**: None (Milestone 9 complete)  
**Related Design Docs**: [Template Source Files Support](../../design/local.acp-template-source-files.md)  
**Estimated Completion Date**: TBD  
