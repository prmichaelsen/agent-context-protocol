# Task 119: Integrate Artifacts with Existing Commands

**Status**: completed  
**Priority**: medium  
**Milestone**: M17 (Artifact Commands System)  
**Design Reference**: [Artifact Commands System](../../design/local.artifact-commands-system.md)  
**Estimated Time**: 3-4 hours  
**Started**: 2026-03-17  
**Completed**: 2026-03-17  

---

## Objective

Enhance existing ACP commands (`@acp.validate`, `@acp.sync`, `@acp.update`) to be artifact-aware, and update the key file index schema to support `kind: artifact`.

---

## Requirements

1. Enhance `@acp.validate` to validate artifact metadata, file naming, and staleness
2. Enhance `@acp.sync` to detect artifact staleness and refresh artifacts
3. Enhance `@acp.update` to include artifact health in project health reports
4. Update key file index schema to support `kind: artifact`
5. Update AGENT.md with artifact documentation (if needed)

---

## Implementation

### 1. @acp.sync Enhancements

**File**: `agent/commands/acp.sync.md`  
**Version**: 1.1.0 → 1.2.0  

**Changes**:
- **Added Step 3: Read Artifact Documents**
  - Parse Last Verified dates
  - Flag artifacts > 6 months old
- **Updated Step 4 (now Step 5): Compare Documentation vs Reality**
  - Compare artifact claims with current codebase
  - Research artifacts: verify findings still apply
  - Glossary artifacts: check for new terms
  - Reference artifacts: verify config tables, standards, schemas
- **Updated Step 5 (now Step 6): Identify Stale Documentation**
  - Flag stale artifacts (outdated versions, missing terms, incorrect configs)
- **Added Step 10: Update Artifact Documents**
  - Research artifacts: verify versions, recommendations, update Last Verified
  - Glossary artifacts: add new terms via `@acp.artifact-glossary --update`
  - Reference artifacts: update config tables, standards, schemas
  - Mark as Stale if changes detected and Last Verified > 6 months
- **Updated Step 12 (formerly Step 10): Update Progress Tracking**
  - Note artifact refresh activity in recent work
- **Updated Verification checklist**:
  - Added artifact review, staleness checks, refresh activity

### 2. @acp.validate Enhancements

**File**: `agent/commands/acp.validate.md`  
**Version**: 2.0.0 → 2.1.0  

**Changes**:
- **Added Step 8: Validate Artifact Documents** (inserted before namespace conventions)
  - Validate metadata block (Type, Created, Last Verified, Status, Confidence, Category, Sources)
  - Check file naming: `{type}-{N}-{title}.md`
  - Check staleness: WARN if Last Verified > 180 days
  - WARN if Status is Stale but Last Verified is recent
  - Research: verify Executive Summary, citations, Sources section
  - Glossary: check category tables, alphabetical index, Total Terms match
  - Reference: verify Command-First Principle Check section exists
- **Updated Step 10 (formerly Step 9): Validate Key File Index**
  - Added `artifact` to valid `kind` values
- **Renumbered subsequent steps** (10 → 11, 11 → 12)
- **Updated Verification checklist**:
  - Added artifact validation checks

**Output format**:
```
📚 Artifact Validation:
  ✓ agent/artifacts/research-1-graphql-federation.md (Active, Last Verified: 2026-03-17)
  ⚠️ agent/artifacts/research-2-redis-persistence.md (Active, Last Verified: 2025-09-20, STALE: 180+ days)
  ✓ agent/artifacts/glossary-1-core-terminology.md (Active, 15 terms)
```

### 3. @acp.update Enhancements

**File**: `agent/commands/acp.update.md`  
**Version**: 1.0.0 → 1.1.0  

**Changes**:
- **Added Step 8: Check Artifact Health** (inserted before Save Changes)
  - List all artifact files
  - Parse Last Verified dates
  - Calculate days since verification
  - Identify stale artifacts (Last Verified > 180 days)
  - Add artifact health note to recent work entry:
    - If stale: "⚠️ {count} artifacts stale (Last Verified > 6 months)"
    - If all current: "✓ All artifacts current"
    - If no artifacts: Skip note
- **Updated Step 9 (formerly Step 8): Save Changes** (renumbered)
- **Updated Verification checklist**:
  - Added artifact health check
- **Updated Console Output example**:
  - Included artifact health check line

### 4. Key File Index Schema Update

**File**: `agent/commands/acp.validate.md` Step 10  

**Changes**:
- Updated valid `kind` values to include `artifact`
- Before: `pattern, command, design, requirements`
- After: `pattern, command, design, requirements, artifact`

**Usage example**:
```yaml
local:
  index:
    - path: agent/artifacts/research-1-graphql-federation.md
      weight: 0.8
      kind: artifact
      description: |
        Research on GraphQL federation patterns, benchmarks, and recommendations
      rationale: |
        Essential context for API gateway decisions
      applies: acp.proceed, acp.plan
```

---

## Testing

### Manual Testing

- [x] @acp.sync updated with 3 new/modified steps
- [x] @acp.validate updated with new step 8
- [x] @acp.update updated with new step 8
- [x] Key file index schema updated to support artifact kind
- [x] Version numbers bumped for all modified commands
- [x] Last Updated dates set to 2026-03-17

### Integration Points

- [x] @acp.sync can detect artifact staleness
- [x] @acp.sync can refresh artifacts (update Last Verified, add new terms)
- [x] @acp.validate can validate artifact structure and metadata
- [x] @acp.update includes artifact health in project reports
- [x] Key file index can reference artifacts

---

## Files Modified

1. `agent/commands/acp.sync.md` - v1.1.0 → v1.2.0
   - Added Step 3 (Read Artifact Documents)
   - Updated Steps 5, 6, 10, 12
   - Added artifact staleness detection and refresh workflow

2. `agent/commands/acp.validate.md` - v2.0.0 → v2.1.0
   - Added Step 8 (Validate Artifact Documents)
   - Updated Step 10 (artifact kind support)
   - Renumbered subsequent steps

3. `agent/commands/acp.update.md` - v1.0.0 → v1.1.0
   - Added Step 8 (Check Artifact Health)
   - Updated console output example

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Staleness threshold | 180 days (6 months) | Balances currency with maintenance burden |
| Artifact health in @acp.update | Yes, note in recent work | Surfaces staleness warnings in progress reports |
| Key file index support | Add `artifact` kind | Artifacts can be high-value reference material |
| @acp.sync integration | Full artifact refresh workflow | Keeps artifacts current with codebase evolution |
| @acp.validate integration | Metadata + staleness validation | Ensures artifact quality and freshness |

---

## Integration Points

- **@acp.artifact-research**: Referenced by sync for research artifact refresh
- **@acp.artifact-glossary**: Invoked by sync with `--update` for new terms
- **@acp.artifact-reference**: Updated by sync to match current configs/schemas
- **Key file index**: Can now reference artifacts for discoverability
- **Progress tracking**: Artifact health included in project status reports

---

## Notes

- Artifact integration makes existing commands artifact-aware without breaking changes
- Staleness threshold (6 months) is a warning, not an error (artifacts don't expire automatically)
- @acp.sync is the primary artifact maintenance command (refresh, update, verify)
- @acp.validate ensures artifact quality at creation and during reviews
- @acp.update surfaces artifact health in progress reports
- Key file index artifact kind enables discoverable high-value artifacts
- All three commands version-bumped with artifact-aware capabilities

Integration complete! M17 ready for final commit.
