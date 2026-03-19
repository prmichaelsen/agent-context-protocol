# Clarification Capture System

**Concept**: Shared directive enabling create commands to capture clarification decisions into entity documents, preventing loss of design rationale  
**Created**: 2026-03-04  
**Status**: Design Specification  

---

## Overview

The Clarification Capture System ensures that decisions made during clarification workflows are preserved in the entity documents they inform. Clarifications are ephemeral workflow files -- they are not committed to version control. Without explicit capture, design rationale documented in clarifications is permanently lost when the session ends or the working tree is cleaned.

This system introduces `@acp.clarification-capture` as a shared directive invoked by create commands (`design-create`, `task-create`, `pattern-create`, `command-create`). It synthesizes clarification responses and chat context into a "Key Design Decisions" section in the created entity document.

---

## Problem Statement

### Current Issues

1. **Decision Loss**: Clarifications capture critical design decisions but are never committed. Once a session ends, those decisions vanish.
2. **No Context Propagation**: Create commands have no mechanism to inspect what clarifications or context led to the entity being created.
3. **Disconnected Workflow**: A user may run `@acp.clarification-create`, answer 20+ questions, then invoke `@acp.design-create` -- but the design document has no record of those decisions.
4. **Reproducibility Gap**: Future developers (human or agent) reading the entity document have no access to the "why" behind design choices.

### Consequences of Not Solving

- Design rationale exists only in untracked clarification files
- Knowledge is lost between sessions, between agents, and between developers
- Entity documents describe "what" but not "why"
- Repeated clarification cycles for decisions already made

---

## Solution

### Shared Directive: `@acp.clarification-capture`

A reusable directive that create commands invoke to gather and embed context. It is not a standalone user-facing command -- it is called internally by create commands when context is available.

### Invocation Flow

```
User: @acp.clarification-create → answers questions
User: @acp.design-create --from-clar --from-chat
                │
                ├── Step 1: Detect context sources (clarifications, chat)
                ├── Step 2: Read and synthesize clarification responses
                ├── Step 3: Resolve conflicts (flag for user if needed)
                ├── Step 4: Generate "Key Design Decisions" section
                ├── Step 5: Embed in created entity document
                └── Step 6: Update clarification status to "Captured"
```

### Context Source Arguments

Create commands accept these NLP-style arguments for specifying context sources:

| Argument | Alias | Behavior |
|---|---|---|
| `--from-clarification <file>` | `--from-clar` | Capture from a specific clarification file |
| `--from-clarifications` | `--from-clars` | Capture from all recent clarifications |
| `--from-chat-context` | `--from-chat` | Capture decisions from chat conversation |
| `--from-context` | (none) | Shorthand for all sources |
| `--include-clarifications` | (none) | Alias for `--from-clars`, enforces Key Design Decisions section |

**Default behavior** (no flags): Auto-detect clarifications and context in the session. Equivalent to implicit `--from-context`.

### Conflict Resolution

When multiple clarifications contain conflicting decisions:
1. Flag the conflict to the user
2. Present the conflicting positions
3. User resolves (can accept "most recent wins" as a valid resolution)
4. Never silently merge conflicting decisions

### Priority Order

When synthesizing from multiple clarifications, more recent responses supersede older ones. Within a single clarification, all items are equal weight.

---

## Implementation

### Key Design Decisions Section

Added as an **optional** section in entity templates (design, task, pattern, command). The agent infers whether to include it based on available context -- it may be populated from clarifications, chat loops, or other session context.

**Format**: Summary tables grouped by agent-inferred category.  

```markdown
## Key Design Decisions (Optional)

### Architecture

| Decision | Choice | Rationale |
|---|---|---|
| Directive type | Shared (not per-command) | Avoids duplication across 4 create commands |
| Storage | Embedded in entity doc | Clarifications are ephemeral, entity docs are committed |

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Affected commands | design, task, pattern, command create | Project/package create don't need design rationale |
| Clarification lifecycle | Status updated to "Captured" | Don't delete, don't prompt to delete |
```

**Rules**:
- Categories are agent-inferred from content (not a predefined list)
- No references to clarification file numbers (clarifications are ephemeral and volatile; numbers won't match across different developer checkouts)
- Section is omitted entirely if no decisions to capture

### Directive Steps (for `@acp.clarification-capture`)

The directive is embedded in create commands as a shared step sequence:

**Step N: Capture Clarification Context**

1. **Detect context sources**: Check arguments (`--from-clar`, `--from-chat`, etc.) or auto-detect
2. **Read clarifications**: If `--from-clar <file>`, read that file. If `--from-clars`, list `agent/clarifications/` and read all non-template files with status "Completed" or "Awaiting Responses"
3. **Read chat context**: If `--from-chat`, synthesize decisions from the current chat conversation
4. **Warn about partial clarifications**: If any clarification has unanswered questions, warn the user before proceeding
5. **Resolve conflicts**: If multiple sources conflict, flag for user resolution
6. **Synthesize decisions**: Extract decision/choice/rationale triples, group by inferred category
7. **Generate section**: Produce "Key Design Decisions" markdown section
8. **Update clarification status**: Set captured clarifications to status "Captured"

### Affected Commands

| Command | Gets Capture Step | Notes |
|---|---|---|
| `@acp.design-create` | Yes | Primary use case |
| `@acp.task-create` | Yes | Captures scope/approach decisions |
| `@acp.pattern-create` | Yes | Captures pattern rationale |
| `@acp.command-create` | Yes | Captures command design decisions |
| `@acp.clarification-create` | No | Should check existing clars to avoid duplicates |
| `@acp.project-create` | No | Scaffold command, no design rationale |
| `@acp.package-create` | No | Scaffold command, no design rationale |

### Warning on Uncaptured Decisions

When a create command detects clarifications in the session but the user hasn't included `--from-clar` or similar:

```
⚠️  Clarification decisions detected in this session that are not being captured.
    Clarifications are not committed to version control.
    Decisions not captured here will be lost.

    Detected: clarification-6-create-command-context-capture.md (Completed)

    Include with --from-clar? (yes/no)
```

### `@acp.clarification-create` Duplicate Awareness

When creating a new clarification, the command should:
1. List existing files in `agent/clarifications/`
2. Infer from titles which might be relevant to the current topic
3. Only load relevant clarifications (to avoid context token burn)
4. Avoid generating duplicate questions already answered elsewhere

---

## Benefits

- **Decision Preservation**: Design rationale survives beyond ephemeral clarification files
- **Self-Documenting Entities**: Entity documents explain "why" not just "what"
- **Reduced Re-clarification**: Future agents/developers can read past decisions
- **Clean Workflow**: Automatic capture with minimal user friction
- **Consistent Format**: Standardized decision tables across all entity types

---

## Trade-offs

- **Context Window Cost**: Reading clarifications and chat history consumes tokens (mitigated by auto-detection heuristics and selective loading)
- **Directive Complexity**: Shared directive adds a step to every create command (mitigated by being a single reusable block)
- **Category Inference**: Agent-inferred categories may not always group perfectly (acceptable -- categories are for readability, not machine parsing)

---

## Dependencies

- Existing create commands: `design-create`, `task-create`, `pattern-create`, `command-create`
- Entity templates (need optional "Key Design Decisions" section added)
- Clarification file format (existing, no changes needed)

---

## Testing Strategy

- **Unit scenarios**: Create command with `--from-clar` produces correct Key Design Decisions section
- **Auto-detect scenario**: Create command with no flags still detects and offers to capture session clarifications
- **Conflict scenario**: Two clarifications with conflicting answers triggers user prompt
- **Partial scenario**: Clarification with unanswered questions triggers warning
- **No-context scenario**: Create command without any clarifications omits the section cleanly
- **Status update**: Clarification status changes to "Captured" after successful capture

---

## Migration Path

1. Create `@acp.clarification-capture` shared directive document
2. Add optional "Key Design Decisions" section to entity templates (design, task, pattern, command)
3. Update `design-create`, `task-create`, `pattern-create`, `command-create` to reference the shared directive
4. Update `clarification-create` with duplicate-awareness logic

---

## Future Considerations

- **Cross-session capture**: If sessions system tracks clarification history, future agents could access decisions from prior sessions
- **Decision search**: A command to search across all Key Design Decisions sections in entity docs
- **Decision index**: Automatic aggregation of decisions for project-wide decision log
- **Clarification templates**: Pre-built question sets for common entity types

---

## Key Design Decisions (Optional)

### Architecture

| Decision | Choice | Rationale |
|---|---|---|
| Implementation approach | Shared directive (`@acp.clarification-capture`) | Avoids duplicating capture logic across 4 create commands |
| Default behavior | Auto-detect context (implicit `--from-context`) | Minimizes user friction; common case is "capture everything" |
| Directive name | `@acp.clarification-capture` | Tightly coupled to clarifications, not general-purpose |

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Affected commands | design-create, task-create, pattern-create, command-create | Core entity creation commands; scaffolding commands excluded |
| Clarification-create awareness | Check existing clars by title, load if relevant | Avoids duplicate questions without burning context tokens |

### Format

| Decision | Choice | Rationale |
|---|---|---|
| Section name | "Key Design Decisions" | Clear, standard terminology |
| Decision format | Summary table: `Decision / Choice / Rationale` | Concise, scannable, structured |
| Grouping | By agent-inferred category | Flexible; no predefined category list needed |
| Clarification references | None in output | Clarifications are ephemeral; numbers are volatile across checkouts |

### Lifecycle

| Decision | Choice | Rationale |
|---|---|---|
| Clarification tracking | Permanently untracked (workflow-only) | Standard protocol; users may force-commit but system doesn't rely on it |
| Post-capture cleanup | Update status to "Captured"; never delete, never prompt to delete | Preserves clarification for remainder of session |
| Uncaptured decisions warning | Yes, warn user | Prevents accidental loss of design rationale |
| Conflict resolution | Flag and ask user; user can accept "most recent wins" | Never silently merge; never capture both sides of a conflict |

### Milestone

| Decision | Choice | Rationale |
|---|---|---|
| Tracking | New milestone: "Clarifications" | Dedicated milestone for all clarification enhancements |

---

**Status**: Design Specification  
**Recommendation**: Create milestone and tasks for implementation  
**Related Documents**:
- [ACP Commands Design](acp-commands-design.md)
- [Clarification Template](../clarifications/clarification-{N}-{title}.template.md)
- Create commands: [design-create](../commands/acp.design-create.md), [task-create](../commands/acp.task-create.md), [pattern-create](../commands/acp.pattern-create.md), [command-create](../commands/acp.command-create.md)
