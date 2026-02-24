# Task 65: Script-Command Binding - Schema and Templates

**Milestone**: [M3 - ACP Package Management System](../../milestones/milestone-3-package-management.md)
**Estimated Time**: 1-2 hours
**Dependencies**: Task 45 (Package Script Bundling), Task 62 (Installation Filtering)
**Status**: Not Started

---

## Objective

Update schemas and templates to support script-command binding with dual declaration. This is Phase 1 of the script-command binding system implementation.

---

## Context

This task implements the foundation for script-command binding by updating schemas and templates. The accepted solution (Dual Declaration) requires:

1. Commands declare script dependencies in frontmatter (`**Scripts**:` field)
2. package.yaml requires `scripts` array in command entries
3. Both sources must match (validated)

**Design Document**: [`agent/design/local.script-command-binding.md`](../../design/local.script-command-binding.md)

**This is Part 1 of 5** in the script-command binding implementation.

---

## Steps

### 1. Update package.schema.yaml

Make `scripts` field REQUIRED in command entries:

**Actions**:
- Open `agent/schemas/package.schema.yaml`
- Find `contents.commands.items.properties` section
- Add `scripts` field with `required: true`
- Set type to array of strings
- Add pattern validation for script names

**Example**:
```yaml
contents:
  commands:
    items:
      properties:
        scripts:
          type: array
          required: true  # ✅ NEW: Make this required
          description: "Script dependencies for this command"
          items:
            type: string
            pattern: "^[a-z0-9-]+\\.[a-z0-9-]+\\.sh$"
```

### 2. Update command.template.md

Add **Scripts**: field to command template:

**Actions**:
- Open `agent/commands/command.template.md`
- Add `**Scripts**:` field after `**Status**:` field
- Document that it's REQUIRED
- Provide example with shared utilities

**Example**:
```markdown
**Namespace**: {namespace}
**Version**: 1.0.0
**Status**: Active | Experimental
**Scripts**: {namespace}.{command-name}.sh, acp.common.sh  # REQUIRED: List all script dependencies

---
```

### 3. Update package.template.yaml

Add scripts array example in command entries:

**Actions**:
- Open `agent/package.template.yaml`
- Update commands section to include scripts array
- Add example with shared utilities
- Document that scripts field is REQUIRED

**Example**:
```yaml
contents:
  commands:
    - name: namespace.command-name.md
      description: Command description
      scripts:  # REQUIRED: Must match command frontmatter
        - namespace.command-name.sh
        - acp.common.sh
```

### 4. Validate Changes

Ensure schema and templates are correct:

**Actions**:
- Run `bash -n` on any modified scripts
- Validate YAML syntax
- Check that examples are consistent
- Verify documentation is clear

---

## Verification

- [ ] Binding approach documented in design doc
- [ ] Schema updated (if needed)
- [ ] acp.install.sh updated for selective copying
- [ ] acp.package-install.sh implements binding logic
- [ ] acp.package-update.sh handles script updates
- [ ] ACP core package.yaml created
- [ ] E2E tests created and passing
- [ ] Experimental scripts respected
- [ ] Utility scripts handled correctly
- [ ] Documentation updated
- [ ] No unused scripts installed

---

## Expected Outcome

**Before**:
```bash
@acp.package-install repo --commands firebase.init
# Installs: firebase.init.md + ALL scripts (firebase.*.sh)
```

**After**:
```bash
@acp.package-install repo --commands firebase.init
# Installs: firebase.init.md + firebase.init.sh only
# Utility scripts (firebase.common.sh) installed if listed in package.yaml
```

---

**Next Task**: TBD (depends on milestone priority)
