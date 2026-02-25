# Command: project-update

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.project-update` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
**Status**: Experimental

---

**Purpose**: Update project metadata in the global registry
**Category**: Project Management
**Frequency**: As Needed

---

## What This Command Does

This command updates metadata for a project in `~/.acp/projects.yaml`, allowing you to modify status, description, type, tags, and related projects. It provides granular control over project metadata without requiring manual YAML editing.

Use this command to keep project metadata current as projects evolve, mark projects as archived when completed, add tags for organization, link related projects, or correct project information. All updates automatically update the `last_modified` timestamp.

Unlike [`@acp.project-info`](acp.project-info.md:1) which displays information, this command modifies the registry. It supports multiple update operations in a single invocation.

---

## Prerequisites

- [ ] Global ACP infrastructure initialized (`~/.acp/` exists)
- [ ] Project registry exists (`~/.acp/projects.yaml`)
- [ ] Project is registered in the registry

---

## Steps

### 1. Parse Arguments

Extract project name and update options.

**Actions**:
- Parse project name (required)
- Parse update flags (--status, --description, --type, etc.)
- Validate at least one update option provided

**Expected Outcome**: Arguments parsed successfully

### 2. Validate Project Exists

Check that the project is in the registry.

**Actions**:
- Load registry with `yaml_parse()`
- Check project exists with `yaml_has_key()`
- Show error if not found

**Expected Outcome**: Project found in registry

### 3. Validate Update Values

Check that provided values are valid.

**Actions**:
- Validate status is one of: active, archived, paused
- Validate other fields as needed
- Show errors for invalid values

**Expected Outcome**: All values validated

### 4. Apply Updates

Update registry with new values.

**Actions**:
- Update status (if provided)
- Update description (if provided)
- Update type (if provided)
- Add tags (if provided)
- Remove tags (if provided)
- Add related projects (if provided)
- Remove related projects (if provided)
- Update last_modified timestamp
- Update registry last_updated timestamp

**Expected Outcome**: All updates applied to AST

### 5. Write Changes

Save updated registry to disk.

**Actions**:
- Write changes with `yaml_write()`
- Report number of updates applied
- Show success message

**Expected Outcome**: Registry updated on disk

---

## Verification

- [ ] Script created and executable
- [ ] Command document created
- [ ] Validates project name argument
- [ ] Validates at least one update option provided
- [ ] Validates status values (active|archived|paused)
- [ ] Updates status correctly
- [ ] Updates description correctly
- [ ] Updates type correctly
- [ ] Adds tags correctly (prevents duplicates)
- [ ] Removes tags correctly
- [ ] Adds related projects correctly (prevents duplicates)
- [ ] Removes related projects correctly
- [ ] Updates last_modified timestamp
- [ ] Updates registry last_updated timestamp
- [ ] Writes changes to disk
- [ ] No syntax errors

---

## Expected Output

### Files Created
- `agent/scripts/acp.project-update.sh` - Shell script for updating projects
- `agent/commands/acp.project-update.md` - This command documentation

### Console Output
```
Updating project: remember-mcp-server

✓ Updated status: archived
✓ Added tag: production
✓ Added tag: critical
✓ Removed tag: development

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Project updated successfully!
   Updates applied: 4
   Registry: ~/.acp/projects.yaml

Run 'acp.project-info.sh remember-mcp-server' to see updated information
```

### Status Update
- Project metadata updated in registry
- Timestamps updated
- Changes persisted to disk

---

## Examples

### Example 1: Update Project Status

**Context**: Mark project as archived when completed

**Invocation**: `@acp.project-update old-project --status archived`

**Result**: Status changed to "archived", last_modified timestamp updated

### Example 2: Add Multiple Tags

**Context**: Add organization tags to project

**Invocation**: `@acp.project-update my-project --add-tag production --add-tag critical --add-tag backend`

**Result**: Three tags added, duplicates prevented if tags already exist

### Example 3: Update Description

**Context**: Improve project description

**Invocation**: `@acp.project-update my-project --description "Multi-tenant memory system with vector search and relationship tracking"`

**Result**: Description updated in registry

### Example 4: Link Related Projects

**Context**: Connect server and client projects

**Invocation**: `@acp.project-update remember-mcp-server --add-related remember-mcp`

**Result**: remember-mcp added to related_projects array

### Example 5: Multiple Updates

**Context**: Update several fields at once

**Invocation**: `@acp.project-update my-project --status active --add-tag production --remove-tag development`

**Result**: Status updated, production tag added, development tag removed

### Example 6: Remove Tag

**Context**: Remove obsolete tag

**Invocation**: `@acp.project-update my-project --remove-tag deprecated`

**Result**: Tag removed from tags array

---

## Related Commands

- [`@acp.project-info`](acp.project-info.md) - View project details before updating
- [`@acp.project-list`](acp.project-list.md) - List all projects
- [`@acp.project-set`](acp.project-set.md) - Switch to a project
- [`@acp.projects-sync`](acp.projects-sync.md) - Sync registry with filesystem

---

## Troubleshooting

### Issue 1: Registry not found

**Symptom**: Error "Project registry not found"

**Cause**: `~/.acp/projects.yaml` doesn't exist

**Solution**: Create a project with `@acp.project-create` to initialize the registry

### Issue 2: Project not found

**Symptom**: Error "Project 'name' not found in registry"

**Cause**: Project not registered or wrong name

**Solution**: Run `@acp.project-list` to see available projects

### Issue 3: Invalid status value

**Symptom**: Error "Invalid status 'value'"

**Cause**: Status must be one of: active, archived, paused

**Solution**: Use a valid status value

### Issue 4: No updates specified

**Symptom**: Error "No updates specified"

**Cause**: Command requires at least one update option

**Solution**: Provide at least one update flag (--status, --description, --add-tag, etc.)

### Issue 5: Tag already exists

**Symptom**: Message "Tag already exists: tag-name"

**Cause**: Trying to add a tag that's already in the tags array

**Solution**: This is informational, not an error. The tag won't be duplicated.

---

## Security Considerations

### File Access
- **Reads**: `~/.acp/projects.yaml` (project registry)
- **Writes**: `~/.acp/projects.yaml` (updates project metadata)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access any secrets or credentials
- **Credentials**: Does not access credentials

---

## Notes

- Updates are applied immediately to the registry file
- Multiple updates can be applied in a single command
- Timestamps are automatically updated (last_modified, last_updated)
- Tags and related projects prevent duplicates automatically
- Status values are validated (active, archived, paused)
- Does not modify the project directory itself, only registry metadata
- Part of Milestone 7 (Global ACP Project Registry)
- Marked as Experimental until M7 is complete

---

**Namespace**: acp
**Command**: project-update
**Version**: 1.0.0
**Created**: 2026-02-25
**Last Updated**: 2026-02-25
**Status**: Experimental
**Compatibility**: ACP 4.1.1+
**Author**: ACP Project
