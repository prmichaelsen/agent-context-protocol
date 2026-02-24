# Task 68: Script-Command Binding - Update Existing Commands

**Milestone**: [M3 - ACP Package Management System](../../milestones/milestone-3-package-management.md)
**Estimated Time**: 2-3 hours
**Dependencies**: Task 65 (Schema and Templates), Task 67 (Validation Logic)
**Status**: Not Started

---

## Objective

Add **Scripts**: field to all existing ACP commands and create package.yaml for ACP core with complete script declarations.

---

## Context

This is Phase 4 of the script-command binding system. With validation in place (Task 67), this task updates all existing commands to declare their script dependencies.

**Design Document**: [`agent/design/local.script-command-binding.md`](../../design/local.script-command-binding.md)

---

## Steps

### 1. Audit Existing Commands

Identify which scripts each command uses:

**Actions**:
- List all commands in agent/commands/
- For each command, determine script dependencies:
  - Check if matching .sh file exists (naming convention)
  - Check if command documentation mentions scripts
  - Check if scripts source acp.common.sh or acp.yaml-parser.sh
- Create mapping: command → scripts

**Example Mapping**:
```
acp.project-set.md → acp.project-set.sh, acp.common.sh, acp.yaml-parser.sh
acp.project-list.md → acp.project-list.sh, acp.common.sh, acp.yaml-parser.sh
acp.package-install.md → acp.package-install.sh, acp.common.sh, acp.yaml-parser.sh
acp.init.md → (no scripts - LLM-based command)
```

### 2. Add Scripts Field to Commands

Update each command file with **Scripts**: field:

**Actions**:
- For each command with script dependencies:
  - Add `**Scripts**:` field after `**Status**:` line
  - List all script dependencies (direct + utilities)
  - Use comma-separated format
- For commands without scripts:
  - Add `**Scripts**: None` or omit field

**Example**:
```markdown
# Command: project-set

**Namespace**: acp
**Version**: 1.0.0
**Status**: Experimental
**Scripts**: acp.project-set.sh, acp.common.sh, acp.yaml-parser.sh  # ← ADD THIS

---
```

### 3. Create ACP Core package.yaml

Create package.yaml in repository root:

**Actions**:
- Create package.yaml at repository root
- List all commands with scripts arrays
- List all scripts with descriptions and experimental status
- Mark experimental commands (acp.project-set, acp.project-list)
- Mark utility scripts (acp.common.sh, acp.yaml-parser.sh)

**Structure**:
```yaml
name: acp-core
version: 3.13.0
description: Agent Context Protocol - Core commands and utilities
author: Patrick Michaelsen
license: MIT
repository: https://github.com/prmichaelsen/agent-context-protocol.git

contents:
  commands:
    - name: acp.project-set.md
      description: Context switching command
      experimental: true
      scripts:
        - acp.project-set.sh
        - acp.common.sh
        - acp.yaml-parser.sh
    
    - name: acp.project-list.md
      description: List projects
      experimental: true
      scripts:
        - acp.project-list.sh
        - acp.common.sh
        - acp.yaml-parser.sh
    
    # ... all other commands
  
  scripts:
    - name: acp.project-set.sh
      description: Context switching script
      experimental: true
    
    - name: acp.project-list.sh
      description: List projects script
      experimental: true
    
    - name: acp.common.sh
      description: Shared utility functions
      type: utility
      experimental: false
    
    - name: acp.yaml-parser.sh
      description: YAML parsing utilities
      type: utility
      experimental: false
    
    # ... all other scripts

requires:
  acp: ">=3.13.0"

tags:
  - acp
  - core
  - commands
```

### 4. Validate with @acp.package-validate

Run validation to ensure consistency:

**Actions**:
- Run `@acp.package-validate` in repository root
- Fix any inconsistencies found
- Ensure all scripts match between frontmatter and package.yaml
- Verify all scripts exist

### 5. Update Command Versions

Bump versions for commands that were modified:

**Actions**:
- Commands with Scripts field added: Patch version bump (e.g., 1.0.0 → 1.0.1)
- Update version in command frontmatter
- Update version in package.yaml

---

## Verification

- [ ] All commands audited for script dependencies
- [ ] Scripts field added to all commands with dependencies
- [ ] package.yaml created for ACP core
- [ ] All commands listed in package.yaml
- [ ] All scripts listed in package.yaml
- [ ] Experimental commands marked correctly
- [ ] Utility scripts marked with type: utility
- [ ] Validation passes (@acp.package-validate)
- [ ] No inconsistencies between frontmatter and package.yaml

---

## Expected Outcome

**All ACP commands have Scripts field**:
- Commands with scripts: List all dependencies
- Commands without scripts: Omit field or use "None"

**ACP Core package.yaml exists**:
- Complete listing of all commands and scripts
- Experimental marking correct
- Utility scripts identified
- Ready for selective installation

---

**Next Task**: Task 69 - Script-Command Binding Testing
