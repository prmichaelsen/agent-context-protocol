# Task 38: Configurables System Enhancement

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)
**Estimated Time**: 3-4 hours
**Dependencies**: Task 37 (Preference Loading Infrastructure)
**Status**: Not Started

---

## Objective

Enhance the existing `agent/configurables/acp.configurables.yaml` file with comprehensive preference definitions for core ACP commands, including metadata, options, types, and validation rules. Update the default preferences file accordingly.

---

## Context

The configurables file defines what preferences are available, their valid values, descriptions, and defaults. This serves as both documentation (users can browse to see available preferences) and validation schema (preference values are checked against configurables).

The existing `acp.configurables.yaml` has a basic structure. This task expands it to cover all preference-aware commands and establishes patterns for future preferences. The `acp.preferences.sh` script will use these definitions for validation and default resolution.

---

## Steps

### 1. Review Existing Configurables

Read current `agent/configurables/acp.configurables.yaml`:

```bash
cat agent/configurables/acp.configurables.yaml
```

Understand the existing structure and identify what needs to be added.

### 2. Define @acp.plan Preferences

Add comprehensive preferences for the plan command:

```yaml
acp:
  plan:
    draft:
      create_mode:
        id: 'plan.draft.create_mode'
        description: Define your agent's default behavior when creating draft documents.
        default: structured
        type: string
        options:
          - name: unstructured
            description: |
              Drafts will be created as empty documents placed in the 
              appropriate location with appropriate filenames
            value: unstructured
          
          - name: structured
            description: | 
              Drafts will be created as structured documents with clear
              template sections and placeholders for user input
            value: structured
          
          - name: guided
            description: | 
              Draft contents collected via chat conversation.
              No draft file created - summary provided in chat.
            value: guided
          
          - name: contextual
            description: | 
              Draft contents inferred from existing context.
              No clarification questions asked, no draft file created.
            value: contextual
    
    batch:
      auto_confirm:
        id: 'plan.batch.auto_confirm'
        description: Automatically confirm batch planning operations without prompting
        default: false
        type: boolean
```

### 3. Define @acp.task-create Preferences

Add preferences for task creation:

```yaml
  task:
    create:
      granularity:
        id: 'task.create.granularity'
        description: Default task size in hours for planning
        default: 3
        type: number
        min: 1
        max: 8
      
      auto_number:
        id: 'task.create.auto_number'
        description: Automatically assign task numbers (find highest + 1)
        default: true
        type: boolean
```

### 4. Define @acp.validate Preferences

Add preferences for validation:

```yaml
  validation:
    auto_fix:
      enabled:
        id: 'validation.auto_fix.enabled'
        description: Automatically fix validation issues when possible
        default: true
        type: boolean
    
    strict_mode:
      enabled:
        id: 'validation.strict_mode.enabled'
        description: Enable strict validation (fail on warnings)
        default: false
        type: boolean
```

### 5. Define General ACP Preferences

Add system-wide preferences:

```yaml
  output:
    verbosity:
      level:
        id: 'output.verbosity.level'
        description: Default output verbosity for commands
        default: normal
        type: string
        options:
          - name: quiet
            description: Minimal output (errors only)
            value: quiet
          - name: normal
            description: Standard output (progress and results)
            value: normal
          - name: verbose
            description: Detailed output (debug information)
            value: verbose
  
  git:
    auto_commit:
      enabled:
        id: 'git.auto_commit.enabled'
        description: Automatically commit changes after task completion
        default: false
        type: boolean
```

### 6. Add Metadata and Documentation

Add file header and usage instructions:

```yaml
# ACP Configurables
# Defines available preferences with metadata, options, and defaults
# 
# Structure:
#   namespace:
#     category:
#       subcategory:
#         preference_name:
#           id: 'category.subcategory.preference_name'
#           description: Human-readable description
#           default: default_value
#           type: string | number | boolean
#           options: [array of option objects] (for string types)
#           min: minimum_value (for number types)
#           max: maximum_value (for number types)
#
# Usage:
#   - Preference instances reference these definitions
#   - Validation checks values against options/types
#   - Defaults used when no preference set
#
# Version: 1.0.0
# Created: 2026-02-22

acp:
  # ... preferences defined above
```

### 7. Validate Configurables Structure

Ensure all configurables follow the schema:

```bash
# Check that all preferences have required fields
# - id (matches path)
# - description
# - default
# - type (if applicable)
# - options (for string types with limited values)
```

### 8. Update Default Preferences

Update `agent/preferences/acp.default.yaml` to reference new configurables:

```yaml
# ACP Default Preferences
# Preference instances reference configurables definitions
# Three-part dot path notation

acp:
  # Planning preferences
  plan.draft.create_mode: 'structured'
  plan.batch.auto_confirm: false
  
  # Task preferences
  task.create.granularity: 3
  task.create.auto_number: true
  
  # Validation preferences
  validation.auto_fix.enabled: true
  validation.strict_mode.enabled: false
  
  # Output preferences
  output.verbosity.level: 'normal'
  
  # Git preferences
  git.auto_commit.enabled: false
```

---

## Verification

- [ ] `acp.configurables.yaml` enhanced with all core preferences
- [ ] All preferences have required fields (id, description, default)
- [ ] String preferences with limited values have options array
- [ ] Number preferences have min/max constraints
- [ ] Boolean preferences have true/false defaults
- [ ] IDs match dot path notation
- [ ] Descriptions are clear and helpful
- [ ] `acp.default.yaml` updated with all preferences
- [ ] File is valid YAML (no syntax errors)
- [ ] All preference paths are consistent
- [ ] Documentation comments added to file

---

## Expected Output

### Files Modified
- `agent/configurables/acp.configurables.yaml` - Enhanced with ~10 core preferences
- `agent/preferences/acp.default.yaml` - Updated with all preference values

### Configurables Structure
```yaml
acp:
  plan:
    draft:
      create_mode: {...}
    batch:
      auto_confirm: {...}
  task:
    create:
      granularity: {...}
      auto_number: {...}
  validation:
    auto_fix:
      enabled: {...}
    strict_mode:
      enabled: {...}
  output:
    verbosity:
      level: {...}
  git:
    auto_commit:
      enabled: {...}
```

---

## Common Issues and Solutions

### Issue 1: Preference path mismatch
**Symptom**: ID doesn't match YAML path
**Solution**: Ensure `id: 'plan.draft.create_mode'` matches path `acp.plan.draft.create_mode`

### Issue 2: Missing required fields
**Symptom**: Preference lacks description or default
**Solution**: Add all required fields per schema

### Issue 3: Invalid option values
**Symptom**: Option value doesn't match name
**Solution**: Ensure consistency between name and value fields

---

## Resources

- [Design Document](../design/acp-preferences-system.md) - Complete specification
- [Existing Configurables](../configurables/acp.configurables.yaml) - Current structure
- [YAML Parser](../scripts/acp.yaml-parser.sh) - For validation

---

## Notes

- Start with preferences that have immediate value (`plan.draft.create_mode`)
- Add more preferences iteratively as commands are enhanced
- Keep descriptions user-friendly (avoid technical jargon)
- Options should be self-explanatory
- Consider future preferences but don't over-engineer

---

**Next Task**: [Task 39: Command Integration - @acp.plan](task-39-command-integration-acp-plan.md)
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md)
**Estimated Completion Date**: TBD
