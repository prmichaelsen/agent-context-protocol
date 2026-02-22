# Task 51: Pattern Reading in Commands

**Milestone**: M2 - Documentation & Utility Commands
**Estimated Time**: 2-3 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Update key ACP commands to list and read `agent/patterns/` at least once during initialization, ensuring agents have context on project patterns before making design decisions.

---

## Context

Agents need to understand project patterns before creating designs, tasks, or making architectural decisions. Currently, commands like `@acp.init`, `@acp.proceed`, and entity creation commands don't explicitly read patterns, which can lead to agents missing important architectural conventions.

**The Problem**: Agents may create designs or tasks that don't follow established project patterns because they haven't read the patterns directory.

**The Solution**: Update commands to include a pattern reading step, allowing agents to intelligently decide which patterns to read based on context.

---

## Steps

### 1. Update @acp.init Command

Add pattern reading step to initialization:

**Actions**:
- Add Step 2.75 (after reading agent documentation, before reviewing source files)
- Title: "Review Project Patterns"
- Actions:
  - List all files in `agent/patterns/`
  - Read relevant patterns based on project type
  - Note key architectural patterns
  - Understand coding standards and conventions

**Implementation**:
```markdown
### 2.75. Review Project Patterns

Load architectural patterns and coding standards.

**Actions**:
- List all files in `agent/patterns/`
- Read patterns relevant to current work:
  - Always read: `bootstrap.md` or `bootstrap.template.md`
  - Language-specific: Read patterns in language subdirectories
  - Technology-specific: Read patterns matching project stack
- Note key architectural decisions
- Understand coding conventions

**Expected Outcome**: Project patterns understood
```

**Expected Outcome**: @acp.init updated

### 2. Update @acp.proceed Command

Add pattern review before task execution:

**Actions**:
- Add Step 1.5 (after identifying task, before implementing)
- Title: "Review Relevant Patterns"
- Actions:
  - Check if task references any patterns
  - Read patterns mentioned in task document
  - Read patterns relevant to task objective
  - Apply pattern conventions during implementation

**Implementation**:
```markdown
### 1.5. Review Relevant Patterns (30 seconds max)

**Actions**:
- Check task document for pattern references
- List files in `agent/patterns/`
- Read patterns relevant to this task
- Note conventions to follow

**DO NOT spend excessive time. Read only directly relevant patterns.**
```

**Expected Outcome**: @acp.proceed updated

### 3. Update @acp.plan Command

Add pattern reading to planning workflow:

**Actions**:
- Add step after reading progress.yaml
- Title: "Review Architectural Patterns"
- Actions:
  - List `agent/patterns/`
  - Read patterns relevant to planning
  - Consider patterns when creating milestones/tasks
  - Reference patterns in design documents

**Implementation**:
```markdown
### 2.5. Review Architectural Patterns

**Actions**:
- List all files in `agent/patterns/`
- Read patterns relevant to what's being planned
- Note architectural constraints
- Consider patterns when defining milestones and tasks

**Expected Outcome**: Patterns inform planning decisions
```

**Expected Outcome**: @acp.plan updated

### 4. Update @acp.design-create Command

Add pattern reading before design creation:

**Actions**:
- Add step after collecting design information
- Title: "Review Related Patterns"
- Actions:
  - List `agent/patterns/`
  - Read patterns related to design topic
  - Ensure design aligns with existing patterns
  - Reference patterns in design document

**Implementation**:
```markdown
### 4.5. Review Related Patterns

**Actions**:
- List all files in `agent/patterns/`
- Read patterns related to this design
- Ensure design aligns with project patterns
- Reference relevant patterns in design document

**Expected Outcome**: Design follows project patterns
```

**Expected Outcome**: @acp.design-create updated

### 5. Update @acp.pattern-create Command

Add pattern reading to understand existing patterns:

**Actions**:
- Add step after detecting context
- Title: "Review Existing Patterns"
- Actions:
  - List `agent/patterns/`
  - Read similar patterns
  - Ensure consistency with existing patterns
  - Avoid duplication

**Implementation**:
```markdown
### 2.5. Review Existing Patterns

**Actions**:
- List all files in `agent/patterns/`
- Read patterns similar to what's being created
- Check for duplication
- Ensure consistent style and structure

**Expected Outcome**: New pattern aligns with existing patterns
```

**Expected Outcome**: @acp.pattern-create updated

### 6. Update @acp.task-create Command

Add pattern reading for task planning:

**Actions**:
- Add step after detecting milestone
- Title: "Review Relevant Patterns"
- Actions:
  - List `agent/patterns/`
  - Read patterns relevant to task objective
  - Consider patterns when defining task steps
  - Reference patterns in task document

**Implementation**:
```markdown
### 1.5. Review Relevant Patterns

**Actions**:
- List all files in `agent/patterns/`
- Read patterns relevant to this task
- Consider patterns when defining steps
- Reference patterns in task document if applicable

**Expected Outcome**: Task steps align with project patterns
```

**Expected Outcome**: @acp.task-create updated

### 7. Test Pattern Reading

Verify patterns are read correctly:

**Test Cases**:
- Run `@acp.init` - Should list and read patterns
- Run `@acp.proceed` on a task - Should read relevant patterns
- Run `@acp.plan` - Should read patterns before planning
- Run `@acp.design-create` - Should read patterns before creating design
- Run `@acp.pattern-create` - Should read existing patterns
- Run `@acp.task-create` - Should read patterns before creating task

**Expected Outcome**: All commands read patterns appropriately

---

## Verification

- [ ] @acp.init reads patterns during initialization
- [ ] @acp.proceed reads patterns before task execution
- [ ] @acp.plan reads patterns before planning
- [ ] @acp.design-create reads patterns before design creation
- [ ] @acp.pattern-create reads existing patterns
- [ ] @acp.task-create reads patterns before task creation
- [ ] Pattern reading is contextual (reads relevant patterns, not all)
- [ ] Commands document which patterns were read
- [ ] All commands tested and working

---

## Files to Modify

```
agent/commands/
├── acp.init.md                  # Add Step 2.75
├── acp.proceed.md               # Add Step 1.5
├── acp.plan.md                  # Add Step 2.5
├── acp.design-create.md         # Add Step 4.5
├── acp.pattern-create.md        # Add Step 2.5
└── acp.task-create.md           # Add Step 1.5
```

---

## Implementation Notes

### Intelligent Pattern Selection

Agents should read patterns intelligently based on context:

**For @acp.init**:
- Always read: `bootstrap.md` or `bootstrap.template.md`
- Language-specific: Read patterns in language subdirectories (e.g., `typescript/`)
- Technology-specific: Read patterns matching project stack

**For @acp.proceed**:
- Read patterns mentioned in task document
- Read patterns relevant to task objective
- Skip if no relevant patterns exist

**For @acp.plan**:
- Read architectural patterns
- Read patterns that inform milestone/task structure
- Consider patterns when defining deliverables

**For Entity Creation Commands**:
- Read similar entities (patterns for pattern-create, designs for design-create)
- Ensure consistency with existing content
- Reference patterns in new content

### Performance Considerations

- Don't read ALL patterns every time
- Read only relevant patterns based on context
- Limit to 3-5 patterns per command invocation
- Prioritize recently modified patterns

### Documentation

Each command should document:
- When patterns are read
- How to determine which patterns to read
- What to do with pattern information

---

## Testing

### Manual Testing

```bash
# Test @acp.init
@acp.init
# Verify: Lists agent/patterns/ and reads relevant patterns

# Test @acp.proceed
@acp.proceed
# Verify: Reads patterns mentioned in task or relevant to task

# Test @acp.plan
@acp.plan
# Verify: Reads architectural patterns before planning

# Test entity creation
@acp.design-create
# Verify: Reads existing designs and patterns
```

### Expected Behavior

**Before Enhancement**:
- Commands don't read patterns
- Agents may miss important conventions
- Designs may not follow project patterns

**After Enhancement**:
- Commands explicitly read patterns
- Agents understand project conventions
- Designs align with established patterns

---

## Related Tasks

- Task 2: Implement Core Workflow Commands (original @acp.init, @acp.proceed)
- Task 17: @acp.pattern-create Command
- Task 19: @acp.design-create Command

---

## Success Criteria

- [ ] All 6 commands updated with pattern reading steps
- [ ] Pattern reading is contextual and intelligent
- [ ] Commands document which patterns were read
- [ ] Agents understand project patterns before making decisions
- [ ] No performance degradation (read only relevant patterns)
- [ ] All commands tested and working correctly

---

**Next Task**: TBD
**Estimated Completion**: 2-3 hours
**Priority**: Medium (improves agent context awareness)
**Complexity**: Low (documentation updates to command files)
