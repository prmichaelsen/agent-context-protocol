# Task 120: Implement Index Semantic Entry Types

## Objective

Implement `path: null` support and new `kind` enum values (`note`, `directive`) in the key file index system. Collapse `requirements` kind into `design`.

## Context

- Design: [local.index-semantic-entry-types.md](../../design/local.index-semantic-entry-types.md)
- Parent system: [local.key-file-index-system.md](../../design/local.key-file-index-system.md)
- Milestone: M18 — Index Semantic Entry Types

## Design Reference

[Index Semantic Entry Types](../../design/local.index-semantic-entry-types.md)

## Steps

### 1. Update `@acp.validate` Kind Enum

Update the validate command directive (`agent/commands/acp.validate.md`) to document:
- Valid `kind` values: `pattern`, `command`, `design`, `note`, `directive`
- `requirements` accepted as deprecated alias for `design`
- If `path` is `null`, `kind` must be `note` or `directive`
- If `path` is a string, `kind` must be `pattern`, `command`, or `design`
- For `path: null` entries, `description` must be non-empty

### 2. Update Key File Index Design Doc

Update `agent/design/local.key-file-index-system.md`:
- Update Entry Fields table: `path` type is now `string or null`
- Update `kind` enum: add `note`, `directive`; note that `requirements` is deprecated alias for `design`
- Add a section on inline entries with examples
- Reference the new design doc

### 3. Update `@acp.init` Display

Update `agent/commands/acp.init.md` Step 2.8 display format to show inline entries:
- Notes: `📝 "First line of description..." (weight: X, note)`
- Directives: `⚡ "First line of description..." (weight: X, directive)`
- Section header: "Reading Key Files & Context" (broadened)
- Summary line: "N files read, M inline entries loaded"

### 4. Update Other Command Display Sections

Commands that read key files (`@acp.proceed` Step 1.5, `@acp.plan` Step 0, `@acp.design-create` Step 2.5, `@acp.task-create`, `@acp.pattern-create`, `@acp.command-create`) — update their display format blocks to include inline entry examples.

### 5. Update CHANGELOG.md

Add entry for this feature under the current version.

## Verification

- [ ] `@acp.validate` documentation includes new kind values
- [ ] `@acp.validate` documentation includes path: null validation rules
- [ ] Parent design doc updated with new schema
- [ ] `@acp.init` display format shows inline entries
- [ ] At least one other command's display format updated
- [ ] CHANGELOG updated
- [ ] All changes are documentation/command-directive updates (no shell script changes needed)

## Expected Output

### Files Modified
- `agent/commands/acp.validate.md` — new kind enum, path: null rules
- `agent/design/local.key-file-index-system.md` — updated schema
- `agent/commands/acp.init.md` — updated display format
- `agent/commands/acp.proceed.md` — updated display format
- `agent/commands/acp.plan.md` — updated display format
- `CHANGELOG.md` — feature entry

## Estimated Hours

1-2 hours

## Dependencies

None — all changes are to command directives and design docs.
