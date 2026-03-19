# Task 3: Implement Version Commands

**Milestone**: [M1 - ACP Commands Infrastructure](../milestones/milestone-1-acp-commands.md)  
**Estimated Time**: 2 hours  
**Dependencies**: Task 1 (Commands Infrastructure)  
**Status**: Not Started  

---

## Objective

Implement the three version management commands: `@acp-version-check`, `@acp-version-check-for-updates`, and `@acp-version-update`.

---

## Steps

### 1. Create `acp/version-check.md`

**Purpose**: Display current ACP version and basic info  

**Steps to document**:
1. Read AGENT.md header for version number
2. Read CHANGELOG.md for current version details
3. Display version information
4. Show when last updated
5. Report compatibility information

### 2. Create `acp/version-check-for-updates.md`

**Purpose**: Check if ACP updates are available without applying them  

**Steps to document**:
1. Run `./agent/scripts/acp.version-check-for-updates.sh`
2. Report if updates are available
3. Show what changed (from CHANGELOG)
4. Ask if user wants to update
5. If yes, suggest running `@acp-version-update`

### 3. Create `acp/version-update.md`

**Purpose**: Update ACP files to latest version  

**Steps to document**:
1. Run `./agent/scripts/acp.version-update.sh`
2. Review changes
3. Report what was updated
4. Suggest next actions

---

## Verification

- [ ] All three version commands exist and are complete
- [ ] Commands follow template structure
- [ ] All commands have version 1.0.0
- [ ] Related commands are linked
- [ ] Examples show expected output

---

**Next Task**: [Task 4: Update Documentation](task-4-update-documentation.md)  
