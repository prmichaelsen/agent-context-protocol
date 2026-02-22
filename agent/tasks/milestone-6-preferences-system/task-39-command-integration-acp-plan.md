# Task 39: Command Integration - @acp.plan

**Milestone**: [M6 - Preferences System](../milestones/milestone-6-preferences-system.md)
**Estimated Time**: 4-5 hours
**Dependencies**: Task 37 (Preference Loading), Task 38 (Configurables Enhancement)
**Status**: Not Started

---

## Objective

Integrate the preferences system into the `@acp.plan` command, enabling it to respect the `plan.draft.create_mode` preference by invoking `@acp.preferences-get` to determine draft creation behavior automatically.

---

## Context

The `@acp.plan` command currently asks users to choose between structured/unstructured/guided/contextual draft modes every time. With preferences, the command should:
1. Invoke `@acp.preferences-get` to load complete preference set
2. Extract `plan.draft.create_mode` value
3. Use the preference value if available
4. Fall back to asking the user if no preference is set
5. Allow temporary override via command-line flag

This task demonstrates the preference integration pattern that other commands will follow. The command invokes `@acp.preferences-get` as a subroutine rather than calling shell functions directly.

---

## Steps

### 1. Review Current @acp.plan Implementation

Read `agent/commands/acp.plan.md` to understand current draft creation logic:

```bash
cat agent/commands/acp.plan.md | grep -A 20 "Gather Requirements"
```

Identify where draft mode is determined (currently asks user every time).

### 2. Add Preference Check to Step 3

Update Step 3 "Gather Requirements" in `acp.plan.md`:

**Before**:
```markdown
**Option A: Design Document First**
- Ask: "Structured draft (with questions) or unstructured draft (free-form)?"
- If structured: Create structured draft...
- If unstructured: Create empty draft...
```

**After**:
```markdown
**Option A: Design Document First**
- Check preference: Invoke `@acp.preferences-get acp` and extract `plan.draft.create_mode`
- If preference set:
  - Use preference value (structured/unstructured/guided/contextual)
  - Inform user: "Using draft mode: {value} (from {source})"
- If no preference:
  - Ask: "Structured draft (with questions) or unstructured draft (free-form)?"
- If command-line override provided (`--plan.draft.create_mode <value>`):
  - Use override value (highest precedence)
  - Inform user: "Using draft mode: {value} (override)"
- Based on final value:
  - If 'structured': Create structured draft with 3 key questions
  - If 'unstructured': Create empty draft file
  - If 'guided': Collect requirements in chat (no draft file)
  - If 'contextual': Infer from context (no draft file)
```

### 3. Add Command-Line Override Support

Add argument parsing section to `acp.plan.md`:

```markdown
## Arguments

This command supports both CLI-style and natural language arguments:

**CLI-Style Arguments**:
- `--batch` or `--all` - Plan all undefined items without prompting
- `--milestone <id>` - Plan specific milestone
- `--task <id>` - Plan specific task
- `--draft <path>` - Use specific draft file
- `--plan.draft.create_mode <value>` - Override draft mode preference

**Preference Overrides**:
Any preference can be overridden using dot notation:
- `--plan.draft.create_mode structured` - Use structured drafts
- `--plan.batch.auto_confirm true` - Auto-confirm batch operations
```

### 4. Update Step 1 to Load Preferences

Add preference loading to Step 1:

```markdown
### 1. Scan for Undefined Planning Items

Automatically scan progress.yaml for items needing planning:

**Actions**:
- Load preferences: Invoke `@acp.preferences-get acp` to get complete preference set
- Parse command-line arguments for preference overrides
- Merge overrides with loaded preferences (overrides win)
- Store effective preferences for use in subsequent steps
- Read `agent/progress.yaml`
- Check for undefined milestones and tasks
- Prioritize based on context
```

### 5. Add Preference Source Indication

When using preferences, inform the user where the value came from:

```markdown
**Preference Source Display**:
- Project: "Using draft mode: structured (from project preferences)"
- Workspace: "Using draft mode: guided (from workspace preferences)"
- User: "Using draft mode: contextual (from user preferences)"
- Default: "Using draft mode: structured (default)"
- Override: "Using draft mode: unstructured (command-line override)"
```

### 6. Update Examples

Add preference-aware examples to `acp.plan.md`:

```markdown
### Example 5: Using Preferences

**Context**: User has set `plan.draft.create_mode: 'contextual'` in user preferences

**Invocation**: `@acp.plan`

**Result**:
```
📋 No undefined items found.

Using draft mode: contextual (from user preferences)

Describe the new feature/milestone:
User: Add real-time collaboration

[Infers requirements from context, creates milestone and tasks directly]
```

### Example 6: Overriding Preferences

**Context**: User has preference set but wants different behavior for this invocation

**Invocation**: `@acp.plan --plan.draft.create_mode structured`

**Result**: Uses structured mode for this invocation only, preference unchanged
```

### 7. Test Integration

Test the updated command with various preference configurations:

```bash
# Test 1: No preferences set (should ask user)
@acp.plan

# Test 2: Preference set (should use preference)
# Setup: Set plan.draft.create_mode = 'guided'
@acp.plan

# Test 3: Command-line override (should use override)
@acp.plan --plan.draft.create_mode unstructured
```

### 8. Update Command Version

Bump version in `acp.plan.md` to reflect preference support:

```markdown
**Namespace**: acp
**Command**: plan
**Version**: 2.0.0  # Was 1.0.0
**Compatibility**: ACP 3.8.0+  # Requires preferences system
```

---

## Verification

- [ ] `acp.plan.md` updated with preference integration
- [ ] Step 1 loads preferences via `@acp.preferences-get`
- [ ] Step 3 checks preference before asking user
- [ ] Command-line override support added
- [ ] Preference source indicated in output
- [ ] Examples updated with preference scenarios
- [ ] Version bumped to 2.0.0
- [ ] Backward compatible (works without preferences)
- [ ] Tested with no preferences (asks user)
- [ ] Tested with preference set (uses preference)
- [ ] Tested with override (uses override)

---

## Expected Output

### Files Modified
- `agent/commands/acp.plan.md` - Updated with preference integration

### Command Behavior

**Without Preferences**:
```
@acp.plan
→ Asks user: "Structured draft or unstructured draft?"
```

**With Preferences**:
```
@acp.plan
→ Using draft mode: structured (from project preferences)
→ Creates structured draft automatically
```

**With Override**:
```
@acp.plan --plan.draft.create_mode guided
→ Using draft mode: guided (command-line override)
→ Collects requirements in chat
```

---

## Common Issues and Solutions

### Issue 1: Preference not respected
**Symptom**: Command asks user despite preference being set
**Solution**: Check preference path syntax, ensure `@acp.preferences-get` is invoked

### Issue 2: Invalid preference value
**Symptom**: Error about invalid draft mode
**Solution**: Validate preference value against configurables options

### Issue 3: Override not working
**Symptom**: Command uses preference instead of override
**Solution**: Ensure override parsing happens before preference loading

---

## Resources

- [Design Document](../design/acp-preferences-system.md) - Preference integration patterns
- [Current @acp.plan](../commands/acp.plan.md) - Command to update
- [Configurables](../configurables/acp.configurables.yaml) - Preference definitions

---

## Notes

- This is the reference implementation for preference integration
- Other commands will follow this pattern
- Backward compatibility is critical (must work without preferences)
- Preference source indication improves user understanding
- Command-line overrides enable flexibility without changing preferences

---

**Next Task**: [Task 40: Preference Management Commands](task-40-preference-management-commands.md)
**Related Design Docs**: [ACP Preferences System](../design/acp-preferences-system.md)
**Estimated Completion Date**: TBD
