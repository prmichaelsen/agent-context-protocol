# Task 101: Creation Command Integration

**Milestone**: [M14 - Key File Index System](../../milestones/milestone-14-key-file-index-system.md)  
**Estimated Time**: 2-3 hours  
**Dependencies**: [Task 99](task-99-index-directory-infrastructure.md)  
**Status**: Completed  

---

## Objective

Update creation command directives (`@acp.design-create`, `@acp.task-create`, `@acp.pattern-create`, `@acp.command-create`) to contextually read relevant key files before generating content, and prompt to add newly created files to the index.

---

## Context

Creation commands are where key file ignorance hurts the most — agents create new designs or tasks without reading existing patterns that define conventions. This task adds two behaviors: (1) contextual pre-read of relevant key files, and (2) post-creation prompt to add the new file to the index.

---

## Steps

### 1. Add Contextual Pre-Read to @acp.design-create

- Add step before "Collect Design Information" to read key files
- Filter by `applies` including `acp.design-create`
- Use `description` and `kind` to prioritize (e.g., patterns and requirements most relevant)
- Display what was read

### 2. Add Contextual Pre-Read to @acp.task-create

- Add step before task information collection
- Filter by `applies` including `acp.task-create`
- Prioritize patterns that define testing conventions, architecture constraints

### 3. Add Contextual Pre-Read to @acp.pattern-create

- Filter by `applies` including `acp.pattern-create`
- Existing patterns are most relevant context

### 4. Add Contextual Pre-Read to @acp.command-create

- Filter by `applies` including `acp.command-create`
- Existing command patterns and designs most relevant

### 5. Add Post-Creation Index Prompt

After each creation command successfully creates a file, add:

```
Would you like to add this to the key file index?
  - Yes, add to agent/index/local.main.yaml
  - No, skip
```

If yes, prompt for weight, description, rationale, and applies values.

---

## Verification

- [ ] `@acp.design-create` reads relevant key files before generating content
- [ ] `@acp.task-create` reads relevant key files before generating content
- [ ] `@acp.pattern-create` reads relevant key files before generating content
- [ ] `@acp.command-create` reads relevant key files before generating content
- [ ] All four commands prompt to add new file to index after creation
- [ ] Agent uses `description`/`kind` to decide which files are relevant
