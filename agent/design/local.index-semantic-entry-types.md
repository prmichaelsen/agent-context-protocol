# Index Semantic Entry Types

**Concept**: Extend agent/index schema to support inline context entries (notes, directives) via `path: null`, with no new fields or arrays
**Created**: 2026-03-20
**Status**: Design Specification

---

## Overview

The Key File Index System currently supports only file-path entries — each entry has a `path` pointing to a file the agent should read. This design extends the system to support **inline context entries** by allowing `path: null`, where the `description` field carries the content directly. Two new `kind` enum values (`note`, `directive`) distinguish informational context from behavioral instructions.

This is a minimal, backward-compatible extension. No new fields, no new arrays, no schema migration. The existing loading, filtering, and display infrastructure works unchanged.

**Clarification source**: agent/clarifications/clarification-13-index-semantic-entry-types.md

---

## Problem Statement

- Project knowledge that doesn't belong in a file (migration numbering rules, rate limit values, architectural constraints) has no structured place in the index
- CLAUDE.md and AGENT.md carry blanket instructions but lack per-command targeting (`applies` filtering) and weighted importance
- Agents need both factual context ("migrations use 4-digit prefixes") and behavioral instructions ("never modify src/legacy/ without asking") injected at the right time
- Creating a separate file for every small note or rule adds unnecessary file bloat

---

## Solution

### `path: null` Convention

An index entry with `path: null` signals "the `description` field IS the content." The agent surfaces the description text directly instead of reading a file.

```yaml
local:
  index:
    # File entry (existing — unchanged)
    - path: agent/patterns/local.e2e-testing.md
      weight: 0.8
      kind: pattern
      description: |
        E2E testing pattern used across all test suites.
      rationale: |
        Prevents agents from writing tests that don't follow conventions.
      applies: acp.task-create, acp.proceed

    # Inline note (new)
    - path: null
      weight: 1.0
      kind: note
      description: |
        Migration files MUST be numbered sequentially with zero-padded
        4-digit prefixes (e.g. 0037_feature_name.sql). Before creating a
        migration, check src/lib/db/migrations/ for the current highest
        number and use the next available.
      rationale: |
        Parallel worktree sessions collided on migration numbers.
        Sequential ordering matters for apply-migrations.ts.
      applies: acp.proceed, acp.plan, acp.task-create

    # Inline directive (new)
    - path: null
      weight: 0.9
      kind: directive
      description: |
        Never modify files in src/legacy/ without explicitly asking
        the user first. These files have no test coverage.
      rationale: |
        Production incidents from untested legacy changes.
      applies: acp.proceed
```

### Updated `kind` Enum

| kind | path | purpose |
|------|------|---------|
| `pattern` | file | Read a pattern document |
| `command` | file | Read a command document |
| `design` | file | Read a design or requirements document |
| `note` | null | Factual context — things the agent needs to know |
| `directive` | null | Behavioral instruction — things the agent must do/avoid |

**Changes from current enum**:
- **Removed**: `requirements` — collapsed into `design` (both serve the same role: context for decision-making, both live in `agent/design/`)
- **Added**: `note` — informational inline content
- **Added**: `directive` — imperative inline instruction

### Note vs Directive

The split is clean: **note = information**, **directive = instruction**.

- A `note` tells the agent something it should know: "The auth service rate-limits at 100 req/min"
- A `directive` tells the agent something it should do: "Always run lint before committing"

Weight handles the severity spectrum within directives. A `directive` at `weight: 0.6` is a soft preference. A `directive` at `weight: 1.0` is a hard constraint. No separate `preference` or `constraint` kinds needed.

### Alternative Approaches Rejected

| Approach | Rejected Because |
|---|---|
| Separate `type` discriminator field | `path: null` + `kind` is sufficient; no new fields needed |
| Separate arrays per type (`files:`, `notes:`, `directives:`) | Breaks single sorted-by-weight list; more complex loading |
| `preference` as separate kind | Just a directive with lower weight |
| `constraint` as separate kind | Just a directive with weight 1.0 |
| `variable` kind (key-value pairs) | Overengineered; notes can carry key-value context in description text |
| New `content` field for inline text | Unnecessary; `description` already exists and serves this purpose |

---

## Implementation

### 1. Schema Changes

**Entry Fields** (updated):

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `path` | Yes | string or null | File path, or `null` for inline entries |
| `weight` | Yes | float | 0.0 - 1.0 importance |
| `kind` | Yes | enum | `pattern`, `command`, `design`, `note`, `directive` |
| `description` | Yes | string | File description OR inline content (when path is null) |
| `rationale` | Yes | string | Why this entry exists |
| `applies` | Yes | string | Comma-separated command names |

**Backward compatibility**: All existing entries have `path` set to a string. They continue working unchanged. The `requirements` kind value should still be accepted (treated as `design`) but new entries should use `design`.

### 2. Loading Behavior

When the agent encounters a `path: null` entry during index loading:

1. **Skip file read** — there is no file to read
2. **Surface description text** — inject the `description` content into agent context
3. **Same filtering** — `weight` and `applies` filtering work identically to file entries
4. **Same thresholds** — `@acp.init` loads entries with weight >= 0.8, same as files

The agent treats the `description` text as the equivalent of "reading a file." The content is now in context.

### 3. Display Format

During `@acp.init` and command execution:

```
📑 Reading Key Files & Context...
  ✓ agent/design/acp-commands-design.md (weight: 0.9, design)
  ✓ agent/patterns/local.e2e-testing.md (weight: 0.8, pattern)
  📝 "Migration files MUST be numbered sequentia..." (weight: 1.0, note)
  ⚡ "Never modify files in src/legacy/ without..." (weight: 0.9, directive)

  2 files read, 2 inline entries loaded
```

**Display conventions**:
- File entries: `✓` prefix with file path
- Notes: `📝` prefix with truncated first line of description in quotes
- Directives: `⚡` prefix with truncated first line of description in quotes
- Section header: "Reading Key Files & Context" (broadened from "Reading Key Files")

### 4. Validation Updates

`@acp.validate` should check:
- If `path` is `null`, `kind` must be `note` or `directive`
- If `path` is a string, `kind` must be `pattern`, `command`, or `design`
- `requirements` kind is accepted but generates a deprecation warning ("use `design` instead")
- For `path: null` entries, `description` must be non-empty (it IS the content)
- All other existing validation rules apply unchanged

### 5. Package Support

Packages CAN ship `path: null` entries in their index files. A package might include:
```yaml
my-package:
  index:
    - path: null
      weight: 0.7
      kind: note
      description: |
        This package expects Node 18+ and uses ESM imports.
      rationale: |
        Prevents CommonJS/ESM mismatch errors.
      applies: acp.proceed, acp.plan
```

No restrictions on which `kind` values packages can ship. Package weights should follow the existing convention (0.3 - 0.7 range).

---

## Benefits

- **Zero schema migration** — existing index files work unchanged
- **No file bloat** — small notes and rules don't need their own .md files
- **Targeted context** — `applies` and `weight` filtering works for inline entries just like files
- **Clean taxonomy** — five `kind` values with clear semantics, no overlap
- **Backward compatible** — `requirements` kind still accepted as alias for `design`

---

## Trade-offs

- **Description overloading** — `description` now serves double duty (file summary vs inline content). Mitigated by clear `path: null` signal.
- **No syntax highlighting** — inline entries in YAML lack the formatting of dedicated .md files. Acceptable for short notes/directives; long content should still be a file.
- **Discoverability** — inline entries are less visible than files in directory listings. Mitigated by `@acp.index` command and init display.

---

## Dependencies

- Existing key file index system (agent/design/local.key-file-index-system.md)
- `@acp.validate` needs updated kind enum validation
- Command directives that read index entries need minor display updates
- `@acp.init` display header changes from "Key Files" to "Key Files & Context"

---

## Testing Strategy

- **E2E tests**: Index with `path: null` entries loads correctly during `@acp.init`
- **Validation tests**: `@acp.validate` catches invalid kind/path combinations
- **Backward compat**: Existing `requirements` kind entries still work
- **Display tests**: Init output shows correct icons for notes vs directives

---

## Migration Path

1. Update design doc (this document) with new schema
2. Update `@acp.validate` kind enum and add `path: null` validation rules
3. Update command display logic for notes/directives
4. Update `@acp.init` section header
5. Migrate any existing `kind: requirements` entries to `kind: design`
6. Document in CHANGELOG

---

## Key Design Decisions

### Schema Approach

| Decision | Choice | Rationale |
|---|---|---|
| How to signal inline entries | `path: null` | Zero new fields, backward compatible, already clear signal |
| Where inline content lives | `description` field | Reuses existing field, no new `content`/`value`/`text` field needed |
| Separate arrays per type? | No — single `index` array | Maintains single weight-sorted list, simpler loading |

### Kind Enum

| Decision | Choice | Rationale |
|---|---|---|
| Remove `requirements`? | Yes (accept as alias for `design`) | Both serve same role, live in same directory |
| Add `preference` kind? | No | Just a `directive` with lower weight |
| Add `constraint` kind? | No | Just a `directive` with weight 1.0 |
| Add `variable` kind? | No | Notes can carry structured info in description text |
| Final enum | `pattern`, `command`, `design`, `note`, `directive` | Clean split: 3 file kinds, 2 inline kinds |

### Behavioral Split

| Decision | Choice | Rationale |
|---|---|---|
| How to distinguish note from directive | `note` = information, `directive` = instruction | Only meaningful semantic distinction for inline content |
| How to handle severity spectrum | Weight field (0.0-1.0) | No need for separate kinds when weight already captures soft vs hard |

---

## Future Considerations

- If inline entries become very long, consider a `max_length` validation rule to encourage using files instead
- `@acp.index add --note "..."` shorthand for adding inline entries via CLI

---

**Status**: Design Specification
**Recommendation**: Implement as a small standalone task
**Related Documents**:
- [Key File Index System](local.key-file-index-system.md)
- [Clarification 13](../clarifications/clarification-13-index-semantic-entry-types.md)
