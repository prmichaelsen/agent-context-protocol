# Command: sync

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.sync` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp  
**Version**: 1.2.0  
**Created**: 2026-02-16  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Synchronize documentation with source code by identifying and updating stale documentation  
**Category**: Documentation  
**Frequency**: As Needed  

---

## What This Command Does

This command synchronizes ACP documentation with the actual source code implementation. It reads source files, compares them with design documents and patterns, identifies documentation drift, and updates stale documentation to match reality.

Use this command after making significant code changes, when you suspect documentation is outdated, or periodically to ensure documentation stays current. It's particularly useful after implementing features, refactoring code, or completing milestones.

Unlike `@acp.update` which updates progress tracking, `@acp.sync` focuses on keeping design documents, patterns, and technical documentation aligned with the actual codebase.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] Source code exists to compare against
- [ ] Documentation exists in `agent/` directory (design, tasks, patterns)
- [ ] Scripts exist in `agent/scripts/` (if applicable)
- [ ] You have understanding of what changed in code

---

## Steps

### 0. Display Command Header

```
⚡ @acp.sync
  Synchronize documentation with source code by identifying and updating stale documentation

  Related:
    @acp.update    Update progress tracking (not documentation)
    @acp.validate  Validate documentation structure and consistency
    @acp.init      Includes sync as part of initialization
    @acp.report    Generate report including documentation status
```

This step is informational only — do not wait for user input.

### 1. Read Design Documents

Load all design documents to understand documented architecture.

**Actions**:
- Read all files in `agent/design/`
- Note documented features, patterns, and architecture
- Understand documented API contracts
- Identify documented dependencies
- List documented file structures

**Expected Outcome**: Documented architecture understood  

### 1.5. Read Spec Documents

Load all formal specifications to understand the requirement surface.

**Actions**:
- Check if `agent/specs/` directory exists. If not, skip this step silently.
- Read all files in `agent/specs/`.
- For each spec:
  - Parse the `## Requirements` section. Extract every `R<N>` with its one-line description.
  - Parse the `## Behavior Table` (or `## Behavior`) section if present. Extract named scenarios.
  - Parse the `## Tests` section if present.
- Build an inventory of every R<N> requirement across all specs, keyed by spec path.

**Expected Outcome**: Complete spec requirement inventory (list of every R<N> in every spec)  

### 1.6. Cross-Reference Specs with Task Claims

Determine which spec requirements are claimed by which tasks, and flag unclaimed ones.

**Actions**:
- For each task in `agent/tasks/**/*.md`, parse its `## Spec Coverage` section (if present). Extract:
  - The `Source:` spec path
  - Every `R<N>` listed under "Covered requirements"
  - Every behavior scenario listed under "Covered behaviors"
- Build a claims inventory: `{ spec_path → { R<N>: [task_paths] } }`
- Compare against the requirement inventory from Step 1.5. Classify each R<N> as:
  - **Claimed** — at least one task claims it in its Spec Coverage
  - **Unclaimed** — in the spec but in no task's Spec Coverage
  - **Duplicated** — claimed by more than one task (possibly intentional; flag for review)
- Classify each claimed requirement further:
  - **Implemented** — a grep or code inspection finds an implementation
  - **Unimplemented** — claimed by a completed task but no matching implementation in code
  - **Partial** — some aspects implemented, others missing

**Expected Outcome**: Traceability map of spec R<N> → task claims → implementation status  

### 2. Read Task Documents

Review task documents to understand documented implementation approach.

**Actions**:
- Read all files in `agent/tasks/`
- Note documented implementation steps
- Identify documented tools and dependencies
- Check for code examples in task steps
- List documented functions and approaches

**Expected Outcome**: Documented implementation approach understood  

### 3. Read Artifact Documents

Review artifact documents to understand committed reference material.

**Actions**:
- Read all files in `agent/artifacts/` (research, glossary, reference)
- Note **Last Verified** dates for each artifact
- Parse artifact metadata (Created, Status, Confidence, Category)
- Identify artifact claims (findings, terms, standards, diagrams, schemas)
- Flag artifacts with Last Verified > 6 months old as potentially stale

**Expected Outcome**: Artifact inventory with staleness indicators  

### 4. Read Source Code

Review actual implementation in source files.

**Actions**:
- Identify main source directories (src/, lib/, cmd/, etc.)
- Read key implementation files
- Note actual features implemented
- Understand actual architecture
- Identify actual dependencies and tools used
- Document actual file structures
- Check which functions/utilities are actually implemented
- **Compare implementation approach with task document examples**
- **Note new terms, patterns, or concepts not in glossaries**

**Expected Outcome**: Actual implementation understood  

### 5. Compare Documentation vs Reality

Identify discrepancies between docs and code.

**Actions**:
- Compare documented features with implemented features
- **Compare documented tools (e.g., yq) with actual tools (e.g., acp.yaml-parser.sh)**
- **Compare documented functions with actual implementations**
- **Check if task code examples match actual code in scripts**
- Check if documented patterns match actual patterns
- Verify API contracts match implementation
- Compare file structures
- Note undocumented features in code
- Identify documented features not yet implemented
- **Flag task documents with outdated code examples**
- **Compare artifact claims with current codebase**:
  - **Research artifacts**: Verify findings still apply (technology versions, benchmarks, recommendations)
  - **Glossary artifacts**: Check for new terms in code not in glossary, verify existing definitions
  - **Reference artifacts**: Verify config tables, standards, schemas match current code
- **Compare spec requirements with implementation** (using the claims map from Step 1.6):
  - **Unclaimed requirements**: R<N> exists in `agent/specs/` but no task claims it in Spec Coverage. This is a *planning gap* — either a task should be created, or the requirement should be explicitly marked as deferred/out-of-scope in the spec itself.
  - **Unimplemented claims**: R<N> claimed by a completed task but no implementation found in code. This is *completion drift* — the task was marked done without satisfying the claim.
  - **Partial claims**: R<N> has some implementation but not all MUST clauses are satisfied.
  - **Drifted implementations**: Implementation exists and differs from the spec's MUST language (e.g., spec says "must use formula X", code uses formula Y).
  - **Stale requirements**: Requirement text in spec no longer matches current behavior (spec itself needs updating).

**Expected Outcome**: Documentation drift identified (including implementation details, artifact staleness, and spec/task/code traceability gaps)  

### 6. Identify Stale Documentation

Determine which documents need updates.

**Actions**:
- List design docs that are outdated
- **List task docs with outdated code examples or tool references**
- Note patterns that don't match code
- Identify missing documentation for new features
- Flag incorrect technical specifications
- **Flag task documents referencing wrong tools (e.g., yq vs acp.yaml-parser.sh)**
- **Flag stale artifacts**:
  - Research artifacts with outdated version numbers or deprecated recommendations
  - Glossary artifacts missing new terms from codebase
  - Reference artifacts with incorrect config tables, standards, or schemas
  - Artifacts with Last Verified > 6 months ago
- **Flag spec drift** (using findings from Step 5):
  - List every **unclaimed requirement** — these are planning gaps the user should resolve (create a task, defer in spec, or remove if out-of-scope)
  - List every **unimplemented claim** — these are completion drifts that should re-open their owning task
  - List every **drifted implementation** — these need a decision: update the spec or update the code
  - Do NOT auto-update the spec to match drifted code — spec is the source of truth; drift means the code is wrong until the user says otherwise
- Prioritize updates by importance

**Expected Outcome**: Update priorities established (including artifact refresh needs and spec drift findings)  

### 7. Update Design Documents

Refresh design documents to match reality.

**Actions**:
- Update feature descriptions
- Correct technical specifications
- Update code examples to match actual code
- Add notes about implementation differences
- Update status fields (Proposal → Implemented)
- Add "Last Updated" dates

**Expected Outcome**: Design docs reflect reality  

### 8. Update Task Documents

Refresh task documents to match actual implementation.

**Actions**:
- **Update code examples in task steps to match actual code**
- **Replace references to external tools with actual tools used**
- **Update function names to match actual implementations**
- **Add notes about completed vs remaining work**
- **Update Common Issues sections**
- Mark completed steps as done

**Expected Outcome**: Task docs reflect actual implementation approach  

### 9. Update Pattern Documents

Refresh patterns to match actual usage.

**Actions**:
- Update pattern examples with real code
- Correct pattern descriptions
- Add new patterns discovered in code
- Update anti-patterns based on lessons learned
- Ensure code examples compile/work

**Expected Outcome**: Patterns match actual usage  

### 10. Update Artifact Documents

Refresh artifacts to match current codebase and technology landscape.

**Actions**:
- **Research artifacts**:
  - Verify technology versions still current
  - Check if recommendations still apply
  - Update Last Verified date if validated
  - Mark as Stale if outdated (triggers user to refresh or deprecate)
- **Glossary artifacts**:
  - Add new terms discovered in codebase (use `@acp.artifact-glossary --update`)
  - Verify existing definitions still accurate
  - Update Last Verified date
- **Reference artifacts**:
  - Update config tables to match current .env files
  - Update standards to match current code style
  - Update schemas to match current data models
  - Update Last Verified date
- **General**:
  - Flag artifacts as Stale if Last Verified > 6 months and changes detected
  - Suggest `@acp.artifact-research` re-run for outdated research
  - Update artifact metadata (Last Verified, Status, Confidence if changed)

**Expected Outcome**: Artifacts current with codebase  

### 11. Document New Features

Add documentation for undocumented features.

**Actions**:
- Create design docs for undocumented features
- Document new patterns found in code
- Add technical specifications
- Include code examples
- Link related documents

**Expected Outcome**: All features documented  

### 12. Update Progress Tracking

Update progress.yaml to reflect sync activity.

**Actions**:
- Add recent work entry for sync
- Note what was updated (including artifacts refreshed)
- Update documentation counts if needed
- Add notes about documentation status
- Note artifact staleness warnings

**Expected Outcome**: Sync activity tracked  

---

## Verification

- [ ] All design documents reviewed
- [ ] **All task documents reviewed for code examples**
- [ ] **All artifact documents reviewed for staleness**
- [ ] Source code reviewed and compared
- [ ] **Scripts reviewed for actual tool usage (acp.yaml-parser.sh vs yq, etc.)**
- [ ] Documentation drift identified (including artifact staleness)
- [ ] **Task document code examples checked against actual scripts**
- [ ] **Artifact claims checked against current codebase**
- [ ] Stale documents updated
- [ ] **Task documents updated to match actual implementation**
- [ ] **Artifacts refreshed (Last Verified dates updated, new terms added, config tables updated)**
- [ ] New features documented
- [ ] Pattern documents current
- [ ] Code examples work correctly
- [ ] progress.yaml updated with sync notes (including artifact refresh activity)

---

## Expected Output

### Files Modified
- `agent/design/*.md` - Updated design documents
- `agent/patterns/*.md` - Updated pattern documents
- `agent/progress.yaml` - Sync activity logged
- Potentially new design/pattern documents created

### Console Output
```
🔄 Synchronizing Documentation with Code

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reading design documents...
✓ Read 5 design documents
✓ Read 3 pattern documents

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reviewing source code...
✓ Reviewed src/services/
✓ Reviewed src/models/
✓ Reviewed src/utils/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Comparing documentation vs reality...
⚠️  Found 3 discrepancies:
  1. auth-design.md: Documented OAuth, implemented API keys
  2. data-pattern.md: Example code outdated
  3. api-design.md: Missing /health endpoint documentation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Spec traceability (agent/specs/ ↔ task Spec Coverage ↔ code)...
✓ 18/23 requirements claimed by tasks and implemented
⚠️  3 unclaimed requirements (planning gap):
  - local.gamification.md R20 (Help System) — no task claims it
  - local.gamification.md R24 (Loot Boxes) — deferred to M11 per notes
  - local.gamification.md R30 (Notification Limits) — no task claims it
❌ 2 unimplemented claims (completion drift):
  - task-18 claims R12 but letter frequency enforcement not found in code
  - task-21 claims R18a but voice_id is a placeholder, not real ElevenLabs ID

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updating documentation...
✓ Updated auth-design.md (OAuth → API keys)
✓ Updated data-pattern.md (refreshed examples)
✓ Updated api-design.md (added /health endpoint)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Sync Complete!

Summary:
- Documents reviewed: 8
- Discrepancies found: 3
- Documents updated: 3
- New documents created: 0
- Documentation is now current
```

### Status Update
- Design documents synchronized
- Patterns updated
- New features documented
- Sync logged in progress.yaml

---

## Examples

### Example 1: After Major Refactoring

**Context**: Refactored authentication system, docs are outdated  

**Invocation**: `@acp.sync`  

**Result**: Identifies auth-design.md is stale, updates it to reflect new implementation, updates related patterns  

### Example 2: After Adding Features

**Context**: Added 3 new API endpoints, not yet documented  

**Invocation**: `@acp.sync`  

**Result**: Identifies undocumented endpoints, updates api-design.md with new endpoints, adds code examples  

### Example 3: Periodic Maintenance

**Context**: Monthly documentation review  

**Invocation**: `@acp.sync`  

**Result**: Reviews all docs, finds minor drift in 2 files, updates them, confirms rest is current  

---

## Related Commands

- [`@acp.update`](acp.update.md) - Update progress tracking (not documentation)
- [`@acp.validate`](acp.validate.md) - Validate documentation structure and consistency
- [`@acp.init`](acp.init.md) - Includes sync as part of initialization
- [`@acp.report`](acp.report.md) - Generate report including documentation status

---

## Troubleshooting

### Issue 1: Can't determine what changed

**Symptom**: Unclear what documentation needs updating  

**Cause**: Too many changes or unclear code  

**Solution**: Review git commits since last sync, focus on major changes first, update incrementally  

### Issue 2: Documentation and code both seem wrong

**Symptom**: Neither docs nor code match expected behavior  

**Cause**: Requirements changed or misunderstood  

**Solution**: Clarify requirements first, then update both code and docs to match correct requirements  

### Issue 3: Too many discrepancies to fix

**Symptom**: Overwhelming number of outdated docs  

**Cause**: Long time since last sync  

**Solution**: Prioritize by importance, fix critical docs first, schedule time for rest, sync more frequently going forward  

---

## Security Considerations

### File Access
- **Reads**: All files in `agent/design/`, `agent/patterns/`, source code directories
- **Writes**: `agent/design/*.md`, `agent/patterns/*.md`, `agent/progress.yaml`
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access secrets or credentials
- **Credentials**: Does not access credentials files

---

## Notes

- This command can be time-consuming for large projects
- Focus on high-priority documentation first
- Sync regularly to avoid large drift
- Use git diff to see what changed in code
- Document the "why" not just the "what"
- Keep code examples working and tested
- Update "Last Updated" dates in documents
- Consider running after each milestone completion

---

**Namespace**: acp  
**Command**: sync  
**Version**: 1.1.0  
**Created**: 2026-02-16  
**Last Updated**: 2026-02-18  
**Status**: Active  
**Compatibility**: ACP 1.1.0+  
**Author**: ACP Project  
