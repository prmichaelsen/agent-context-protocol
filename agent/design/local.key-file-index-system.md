# ACP Key File Index System

**Concept**: A weighted index of critical project files that agents must read before taking action, preventing silent ignorance of existing guardrails and patterns
**Created**: 2026-03-02
**Status**: Design Specification

---

## Overview

The Key File Index System introduces an `agent/index/` directory containing YAML index files that declare which project files are critical for agent context. Each entry carries a weight, description, kind, and rationale so agents can make intelligent decisions about which files to read before executing commands.

The system solves a fundamental problem with documentation-first development: agents frequently ignore existing patterns, designs, and guardrails even though those files exist. The index provides a curated "must-read" list that is loaded during initialization, context compaction, and before any command that requires intelligent decision-making.

**Clarification source**: agent/clarifications/clarification-5-key-file-directive.md

---

## Problem Statement

- Agents silently ignore important files (patterns, designs, requirements) even though they exist for guidance
- Existing patterns and guardrails go unread, causing agents to make mistakes that already have documented solutions
- No mechanism exists to elevate certain files above others in importance
- After context compaction, agents lose awareness of critical project files
- Package-installed patterns are never guaranteed to be read
- Creation commands (`@acp.design-create`, `@acp.task-create`, etc.) don't ensure relevant patterns are loaded before generating content

---

## Solution

### Architecture: `agent/index/` Directory

A new `agent/index/` directory containing per-namespace YAML index files:

```
agent/
  index/
    local.main.yaml          # Project's own key files (highest precedence)
    core-sdk.main.yaml       # Key files from core-sdk package
    my-package.main.yaml     # Key files from any installed package
```

**Naming convention**: `{namespace}.{qualifier}.yaml` — the qualifier allows multiple index files per namespace for different purposes (e.g., `core-sdk.main.yaml`, `core-sdk.testing.yaml`). Start with `main` as the default qualifier.

**Precedence**: `local.*.yaml` files always take precedence over package index files. This ensures project-specific context overrides package defaults.

**Implicit key files**: `AGENT.md` and `agent/progress.yaml` are always read by `@acp.init` and are NOT listed in index files. The index is for files that would otherwise be missed.

### Schema

Each index file follows this structure:

```yaml
# agent/index/local.main.yaml
# Key file index for project-local files

local:                    # namespace (matches first segment of filename)
  index:
    - path: agent/design/requirements.md
      weight: 1.0         # 0.0 - 1.0, how important (1.0 = always read)
      kind: requirements   # enum: pattern, command, design, requirements
      description: |
        Core project requirements defining goals, constraints,
        and success criteria for the application.
      rationale: |
        Must be read before any design or task creation to ensure
        alignment with project goals.
      applies: acp.init, acp.design-create, acp.task-create, acp.plan, acp.proceed

    - path: agent/patterns/local.e2e-testing.md
      weight: 0.8
      kind: pattern
      description: |
        E2E testing pattern used across all test suites.
        Defines test structure, assertions, and fixture patterns.
      rationale: |
        Prevents agents from writing tests that don't follow
        established project conventions.
      applies: acp.task-create, acp.proceed

    - path: src/core/state-machine.ts
      weight: 0.6
      kind: design
      description: |
        Core state machine implementation that drives the
        application's primary workflow.
      rationale: |
        Essential context for any work touching business logic.
      applies: acp.proceed, acp.design-create
```

### Entry Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `path` | Yes | string | Explicit path to file (no globs) |
| `weight` | Yes | float | 0.0 - 1.0 importance (1.0 = always read) |
| `kind` | Yes | enum | `pattern`, `command`, `design`, `requirements` |
| `description` | Yes | string | What the file contains and why it matters |
| `rationale` | Yes | string | Why this file is in the index |
| `applies` | Yes | string | Comma-separated list of fully qualified command names (e.g., `acp.init`, `core-sdk.bootstrap`) where this file is relevant |

### No Glob Patterns

Index entries use explicit paths only. Globs are intentionally excluded because:
- Key files should have laser focus on specific, curated files
- Globs could overload context by forcing the agent to read too many files
- Each entry needs its own weight/description, which globs can't provide

### Alternatives Considered

| Approach | Rejected Because |
|---|---|
| Single `agent/key-files.yaml` | Doesn't support package-shipped indices |
| Global `~/.acp/key-files.yaml` | Key files are project-specific, not global |
| Glob pattern support | Overloads context, prevents per-file weighting |
| Flat list without metadata | Agent can't make contextual decisions about what to read |
| Embedding in `package.yaml` | Mixes concerns; index is about agent behavior, not package structure |

---

## Implementation

### 1. Index Loading

When a command triggers index loading, the agent:

1. Scans `agent/index/` for all `*.yaml` files
2. Parses each file's entries
3. Merges all entries into a single list
4. `local.yaml` entries take precedence (highest priority namespace)
5. Filters entries based on the current command context (`applies` field)
6. Sorts by `weight` descending
7. Reads files in weight order, respecting recommended limits

### 2. Contextual Reading

Not all commands read all key files. The agent uses the `applies` field and `weight` to decide:

**Commands that read key files** (need intelligence for decisions):
- `@acp.init` — Read high-weight files (weight >= 0.8) automatically
- `@acp.resume` — Same as init
- `@acp.proceed` — Read files where `applies` includes `acp.proceed`
- `@acp.plan` — Read files where `applies` includes `acp.plan`
- `@acp.design-create` — Read files where `applies` includes `acp.design-create`
- `@acp.task-create` — Read files where `applies` includes `acp.task-create`
- `@acp.pattern-create` — Read files where `applies` includes `acp.pattern-create`
- `@acp.command-create` — Read files where `applies` includes `acp.command-create`
- Any package command (e.g., `core-sdk.bootstrap`) — matches its qualified name

**Commands that skip key files** (lightweight, no decisions):
- `@acp.status`
- `@acp.report`
- `@acp.version-check`
- `@acp.package-list`

### 3. Context Compaction Behavior

On context compaction, the agent:

1. Re-reads `agent/index/` to reload the index
2. Proposes which key files to re-read based on current work context:

```
It looks like we are working on [current task/topic]. Here are key files
I think I should read before continuing:
  - agent/design/requirements.md (weight: 1.0, requirements)
  - agent/patterns/local.e2e-testing.md (weight: 0.8, pattern)

Do you think this is sufficient?
```

3. Offers options:
   - These files look good
   - Read less (specify which to keep/discard)
   - Add specific files
   - Do a broader search
   - What other files do you think we should use? Present options only

This approach manages token cost by letting the user control how much context is re-loaded.

### 4. Visible Output

When reading key files, the agent produces transparent output:

```
📑 Reading Key Files...
  ✓ agent/design/requirements.md (weight: 1.0, requirements)
  ✓ agent/patterns/local.e2e-testing.md (weight: 0.8, pattern)
  ○ src/core/state-machine.ts (weight: 0.6, skipped — not relevant to task-create)

  3 index files scanned, 2 key files read
```

### 5. Package-Shipped Indices

Packages can include index files that get installed to `agent/index/{namespace}.{qualifier}.yaml`:

```yaml
# In package.yaml contents section
contents:
  indices:
    - name: core-sdk.main.yaml
      description: Key patterns for core-sdk package
```

Package indices should:
- Specify only a few key files (respect the recommended limit)
- Provide good descriptions for each entry
- Use appropriate weights (packages should generally use lower weights than local)
- Convention: package weights should be 0.3 - 0.7 unless truly critical

### 6. `@acp.index` Command

A new command for managing the index:

```
@acp.index                        # List all indexed key files
@acp.index add <path>             # Add a file to local.main.yaml
@acp.index remove <path>          # Remove a file from local.main.yaml
@acp.index explore                # Scan codebase, suggest key files
@acp.index show                   # Show full index with all namespaces
```

The `explore` subcommand scans the codebase and suggests files that should probably be indexed based on:
- Files in `agent/design/` that aren't indexed
- Files in `agent/patterns/` that aren't indexed
- Frequently referenced source files
- Requirements documents

### 7. Auto-Prompting on Creation

When `@acp.design-create`, `@acp.pattern-create`, or similar commands create a new file, the agent prompts:

```
✅ Design created: agent/design/local.my-feature.md

Would you like to add this to the key file index?
  - Yes, add to agent/index/local.main.yaml
  - No, skip
```

### 8. Auto-Population on Package Install

When `@acp.package-install` installs a package that includes index files, they install to `agent/index/{namespace}.{qualifier}.yaml` automatically.

### 9. AGENT.md Integration

AGENT.md should include a section about the key file index system to help agents discover it:

```markdown
## Key File Index

This project uses the ACP Key File Index system. Before making decisions,
read `agent/index/` to discover critical project files.
See: agent/design/local.key-file-index-system.md
```

### 10. Validation

`@acp.validate` checks:
- All paths in index files actually exist
- Required fields are present (path, weight, kind, description, rationale, applies)
- Weight values are in range 0.0 - 1.0
- Kind values are valid enum members
- Warns if `agent/index/` directory doesn't exist (optional but recommended)
- Warns if total indexed files exceed recommended limit

---

## Benefits

- **Guardrail enforcement**: Critical patterns and designs are actually read before the agent acts
- **Contextual intelligence**: Weight and description let the agent decide what's relevant
- **Token efficiency**: Not everything is read every time; context-aware filtering reduces waste
- **Package ecosystem**: Packages can ship their own key files for automatic discovery
- **User control**: Context compaction prompt lets users manage what gets re-loaded
- **Transparency**: Visible output shows what the agent read and what it skipped

---

## Trade-offs

- **Manual curation**: Someone must maintain the index (mitigated by `@acp.index explore` and auto-prompting)
- **Extra directory**: Adds `agent/index/` to project structure (minimal overhead, version controlled)
- **Command overhead**: Commands that read key files take slightly longer (mitigated by weight filtering and recommended limits)
- **Learning curve**: New concept for users to understand (mitigated by AGENT.md integration and `@acp.index` command)

---

## Dependencies

- ACP YAML parser (`acp.yaml-parser.sh`) for reading index files
- Existing command directives (`@acp.init`, `@acp.proceed`, etc.) need updating
- `@acp.validate` needs new validation rules
- `@acp.package-install` needs index file support
- AGENT.md needs new section

---

## Testing Strategy

- **Unit tests**: YAML parsing of index files, weight sorting, filtering by `applies`
- **E2E tests**: Full workflow — create index, run `@acp.init`, verify files are read
- **Integration tests**: Package install with index file, `@acp.validate` with index
- **Edge cases**: Missing files, empty index, malformed YAML, weight boundary values (0.0, 1.0)

---

## Migration Path

1. Create `agent/index/` directory structure
2. Add `local.yaml` template and documentation
3. Update commands to read index on execution
4. Add `@acp.index` command
5. Update `@acp.package-install` to support index files in packages
6. Update `@acp.validate` with index validation rules
7. Update AGENT.md with key file index section
8. Add auto-prompting to creation commands

---

## Recommended Limits

- **Per-namespace**: 5-10 entries maximum
- **Total across all namespaces**: 15-20 entries maximum
- **High-weight files** (>= 0.8): Limit to 3-5 per namespace
- **Source files**: Keep to a minimum (1-3 essential files)

---

## Future Considerations

- **Automatic weight adjustment**: Track which files agents actually reference and auto-tune weights
- **Index inheritance**: Child projects inherit parent project's index
- **Index diffing**: Show what changed in index between sessions
- **Smart suggestions**: `@acp.index explore` could use LLM analysis to suggest entries

---

**Status**: Design Specification
**Recommendation**: Create milestone and tasks for implementation
**Related Documents**:
- [ACP Commands Design](acp-commands-design.md)

---

## Appendix: Clarification Summary

The following decisions were made via clarification-5-key-file-directive (18 questions, all answered).

### File Format & Location
- **Project-level only** — no global `~/.acp/key-files.yaml`; key files are project-specific
- **Package-shipped indices** — packages define their own index files in `agent/index/{namespace}.{qualifier}.yaml`; `agent/index/local.main.yaml` carries highest precedence
- **Schema** — namespaced YAML with `path`, `weight` (0.0-1.0), `description`, `kind`, `rationale`, `applies`; requirements/architecture docs should always be included by default
- **No globs** — explicit paths only to maintain laser focus and avoid context overload
- **Description + rationale** — `description` explains what the file contains; `rationale` explains why it's in the index (both required)

### Integration Points
- **Contextual command reading** — only commands that need intelligence read key files; agent uses `description`, `rationale`, and `weight` to decide which files are relevant to the current operation
- **Lightweight commands skip** — `@acp.status`, `@acp.report` do not read key files
- **Context compaction** — agent proposes which files to re-read with user confirmation (options: keep as-is, read less, add files, broader search, present options)
- **Token cost managed** — the compaction prompt mitigates excessive re-reading

### Content & Scope
- **Mostly patterns and designs** — limited source files allowed (essential ones only, e.g., core state machine)
- **Recommended limit** — yes, to prevent context bloat
- **AGENT.md and progress.yaml are implicit** — not listed in index, but AGENT.md should reference the key file system for discoverability
- **Auto-population** — `@acp.package-install` can populate index; `@acp.init` can prompt user
- **Creation commands prompt** — `@acp.design-create`, `@acp.pattern-create` ask "Add to index?" after creating files

### Behavior & Enforcement
- **Visible output** — transparent reporting of which files were read/skipped
- **`applies` property** — each entry declares which commands it's relevant to, using fully qualified names
- **Validation** — `@acp.validate` checks paths exist and warns on missing `agent/index/`
- **Warning if no index** — yes, index is optional but recommended

### Lifecycle & Maintenance
- **`@acp.index` command** — with NLP support to explore codebase and suggest key files
- **Version controlled** — index files are project-specific knowledge, tracked in git
- **Elevates patterns** — the index is a "must-read" list that promotes certain files above others
- **New milestone** — standalone milestone, not part of M6 (Preferences System)
