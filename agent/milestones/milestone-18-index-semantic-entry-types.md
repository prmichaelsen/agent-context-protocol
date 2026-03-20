# Milestone 18: Index Semantic Entry Types

## Goal

Extend the agent/index schema to support inline context entries (`path: null`) with two new `kind` values (`note`, `directive`), and collapse the `requirements` kind into `design`.

## Deliverables

1. Updated `@acp.validate` command to accept `path: null` entries with `kind: note` or `kind: directive`, and accept `requirements` as a deprecated alias for `design`
2. Updated command display logic in `@acp.init` and index-reading commands to show inline entries with appropriate icons
3. Updated parent design doc (`local.key-file-index-system.md`) with new schema
4. Updated CHANGELOG.md and version bump

## Success Criteria

- [ ] `path: null` entries with `kind: note` load correctly during `@acp.init`
- [ ] `path: null` entries with `kind: directive` load correctly during `@acp.init`
- [ ] `@acp.validate` accepts new kind values and rejects invalid path/kind combinations
- [ ] `kind: requirements` still accepted (backward compat) with deprecation note
- [ ] Display uses correct icons (📝 for notes, ⚡ for directives)
- [ ] Design doc updated with new schema

## Estimated Duration

1-2 hours (single task)

## Design Reference

[Index Semantic Entry Types](../design/local.index-semantic-entry-types.md)
