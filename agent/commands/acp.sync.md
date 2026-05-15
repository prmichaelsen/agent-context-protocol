# Command: sync

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.sync` has been invoked. Follow the steps below to execute this command.

> **🔌 Driver Override Check** (TOP-OF-FILE — runs BEFORE any other step in this file)
>
> 1. Read `agent/driver.yaml`. If the file does not exist OR there is no `workflows.acp.sync` mapping, jump to step 5 (fallback to the markdown steps below).
> 2. Look up `bindings.workflow.run` — the MCP tool name this driver uses for workflow dispatch. If the mapping exists but `workflow.run` is unbound, surface a clear configuration error (`"workflows.acp.sync is mapped but bindings.workflow.run is unset in agent/driver.yaml"`) and STOP.
> 3. Invoke that MCP tool with input `{action: "start", workflow: <mapped-value>, args: <user-arguments-from-this-invocation>}`. The command is now BLOCKED — execute the workflow loop per the canonical pattern (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): follow each returned `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion or termination. The workflow's final output IS this command's output. **STOP. Do NOT execute any of the markdown steps below.**
> 4. **Error handling** (one-shot AND every loop iteration):
>    - If any tool response contains an `"error"` key, surface that message to the user and STOP. Do NOT fall through to the markdown steps below — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule.
> 5. **Fallback (only when `workflows.acp.sync` is unmapped or `agent/driver.yaml` is absent):** Proceed to the markdown steps below as written — they describe ACP's default behavior for this command.
>
> ⚠️  **The rest of this file is the unbound-case fallback.** If the override block above dispatched a workflow (whether it completed successfully or errored), do NOT also execute the steps below. They are "execute only if step 5 above is the path you took."

> **🔌 Watcher Capability Check** (run once per command session, before query steps)
>
> Read `agent/driver.yaml`. If absent, no watcher concept applies — skip this check entirely.
> If `capabilities.watcher` is `true`: the driver auto-syncs its data layer with disk. Trust query results without prompting for refresh.
> Otherwise (`false` or absent — conservative default per DR15): the driver does NOT auto-sync. Note this internally. If query results in this command seem inconsistent with recent file changes, surface a brief note to the user when reporting results:
>   *"Note: this driver does not auto-sync. If results seem stale, ask the driver to refresh (e.g., via its scan/surface tool) and rerun."*
> Do NOT auto-invoke any refresh tool — the decision to refresh is the user's. (See design DR15.)

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

### 1.3. Scan Metadata Markers

Build the marker inventory once and hold it for the rest of the sync cycle. Every subsequent step that needs spec/task/code/design metadata consumes this inventory instead of re-reading files.

> **🔌 Driver Dispatch — `query.run`**
>
> 1. Read `agent/driver.yaml`. If the file does not exist, OR `bindings.query.run` is unset, jump to step 4 (fallback).
> 2. Invoke the MCP tool named by `bindings.query.run` with input: a query that returns the project's full marker inventory keyed by file path and grouped by kind (`spec`, `task`, `design`, `code`, `clarification`, `pattern`, `artifact`, `milestone`). Consult the bound tool's MCP description for its input DSL — SQL string, JSON-DSL, structured filter, or otherwise. Inspect the response:
>    - **One-shot result (typical for `query.run`)** — the response is the row set. Populate the in-memory inventory described below and continue.
>    - **Workflow start** — if the response is a workflow handle (e.g., `execution_id` + `instruction` + `input_shape`) rather than rows, this step is BLOCKED until the workflow terminates. Enter the workflow execution loop per the canonical Driver Dispatch directive (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): execute each `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion. The workflow's final output should be the inventory rows; populate the in-memory structure and continue. If the workflow reports termination without producing rows, that is a workflow-level failure — surface and STOP.
> 3. **Error handling:**
>    - If the tool call returns a JSON object with an `"error"` key, surface that message to the user and STOP this step. Do NOT fall through to step 4 — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule: no fallthrough.
> 4. **Fallback (only when `bindings.query.run` is unset or `agent/driver.yaml` is absent):** Run `./agent/scripts/acp.meta-scan.sh agent/` and parse its flat `file:` / `kind:` / `key:` stream into the same in-memory inventory structure.
> 5. **Missing-state guard:** if step 4 cannot proceed (`acp.meta-scan.sh` is missing or returns a non-zero exit code unrelated to "no markers found"), surface a clear, actionable error explaining BOTH paths are unavailable. Point the user at: "bind a `query.run` driver in `agent/driver.yaml`, or restore `agent/scripts/acp.meta-scan.sh`." Do NOT continue with an empty inventory.

The in-memory inventory structure (indexed by `kind`, populated by either path above):
```
specs:    { file_path → { topic, description, requirements, status, updated, ... } }
tasks:    { file_path → { topic, milestone, spec, covers, status, updated, ... } }
designs:  { file_path → { topic, informs, status, updated, ... } }
code:     { file_path → { topic, implements, spec, file_role, status, updated, ... } }
others:   { file_path → { kind, topic, ... } }  (clarifications, patterns, artifacts, milestones)
```

If the inventory is empty after a successful dispatch (driver returned zero rows) or a successful fallback (`acp.meta-scan.sh` exited 0 with no output), no markers exist yet. Continue without marker data; Step 1.4 will prompt the user to backfill.

**Expected Outcome**: Marker inventory available as structured data for Steps 1.4, 1.5, 1.6, 5, and 6.  

### 1.4. Backfill Markers and Remove Superseded Prose Frontmatter

Two passes over marker-eligible files: (A) add markers where missing, (B) strip prose frontmatter fields that the marker now supersedes. Never silently write in either pass — always prompt per file with a diff-like preview.

**Pass A — Add missing markers**:
- For each directory in `agent/{specs,design,tasks,milestones,patterns,clarifications,artifacts}/`, list the files.
- Subtract the files already in the marker inventory from Step 1.3.
- For each remaining file (has no marker):
  1. Derive a proposed marker from the filename, the first-level heading (`# ...`), and any obvious metadata bullets at the top (e.g., `**Type**: ...`, `**Status**: ...`, `**Last Verified**: ...`).
  2. Display the proposed marker block in a diff-like preview.
  3. Ask: "Add this marker to `<path>`? (y/n/edit/skip all)"
  4. On `y`: insert the marker block immediately after the top-level heading.
  5. On `edit`: open the proposed block for user modification, then insert.
  6. On `skip all`: abort this pass for the remainder of the sync cycle.
- Re-run Step 1.3 if any markers were added so downstream steps see the new entries.

**Pass B — Remove superseded prose frontmatter**:

Markers are the source of truth. When a file carries both a marker AND a prose field that the marker supersedes, the prose field is stale and must be removed. The following prose fields are superseded by marker fields and should be stripped:

| Prose field | Superseded by marker field | Applies to |
|---|---|---|
| `**Status**: ...` | `status:` | spec, task, design, milestone, pattern, clarification, research/glossary/reference |
| `**Last Updated**: ...` | `updated:` | spec |
| `**Last Verified**: ...` | `last_verified:` | research/glossary/reference |
| `**Confidence**: ...` | `confidence:` | research/glossary/reference |
| `**Milestone**: ...` (if marker `milestone:` present and matches) | `milestone:` | task |
| `**Dependencies**: ...` | `depends_on:` | task, milestone |
| `**Applicable To**: ...` | `applies_to:` | pattern |

- For every file in the marker inventory (Step 1.3), grep its prose for any of the superseded fields above.
- For each hit, display a diff showing the proposed deletion.
- Ask: "Remove superseded `**<Field>**: <value>` from `<path>`? The marker's `<field>: <value>` supersedes it. (y/n/skip all)"
- On `y`: delete the prose line.
- On `n`: leave it (user will address manually).
- On `skip all`: abort this pass.

Fields that remain in prose (not superseded, do NOT strip): `**Namespace**`, `**Version**`, `**Created**` (immutable), `**Design Reference**`, `**Estimated Time**`, `**Duration**`, `**Goal**`, `**Concept**`, `**Purpose**`, `**Category**`, `**Type**`, `**Sources**`, `**Total Terms**`.

**Pass C — Backfill DR-IDs in legacy designs**:

Designs created before v5.41.0 don't have DR-IDs. Tasks can't claim `incorporates:` against them, so the validate Probe 2 falls back to a holistic check. Backfilling DR-IDs restores exact traceability.

- For each design file in the marker inventory (kind: design) whose marker has no `design_requirements:` field OR whose body contains no DR-ID patterns (`**D\d+[:\s*]` or `### DR\d+:`):
  1. Read the design file.
  2. Identify candidate atomic units: headings under `## Key Decisions`, fenced code blocks (SQL, TS, Python, YAML), standalone tables, definition paragraphs introduced by `**Term**:`, or short `### SubHeading` sections that contain a single atomic idea.
  3. For each candidate, propose a DR-ID label and a short title derived from the content (e.g. `DR2: user_study_list table` for a SQL block following a "Data Model" heading).
  4. Display a list of proposed DR-ID additions:
     ```
     Design: agent/design/local.gamification.md
       DR1: Use SM-2 for vocab scheduling (from ### heading)
       DR2: user_study_list table (from SQL block)
       DR3: Attention score formula (from code paragraph)
       DR4: Letter frequency mapping (from table)
       ...
     Apply all / edit / skip all?
     ```
  5. On approval: insert DR-ID labels into the design body at the identified locations, and update the marker's `design_requirements:` field with the resulting range or list.
  6. On edit: let the user remove specific candidates from the proposal before applying.
  7. Never silently writes.

**Expected Outcome**: Every marker-eligible file has a marker (or was explicitly skipped) AND contains no superseded prose frontmatter fields AND (for designs) has DR-IDs on atomic units where applicable.

**If no files need any pass**: skip silently.

### 1.5. Build Spec Inventory from Markers

Source the spec requirement surface from the marker stream (Step 1.3) instead of re-reading every spec file.

**Actions**:
- From `specs:` in the Step 1.3 inventory, extract each spec's `requirements:` field (e.g., `FR1..FR30` or `FR1, FR3, FR7`).
- Expand range notation: `FR1..FR30` → `FR1, FR2, ..., FR30`.
- Build the requirement inventory: `{ spec_path → [FR1, FR2, ..., FR<N>] }`.
- For behavior scenarios and test names, fall back to reading the `## Behavior Table` and `## Tests` sections of each spec file — markers don't carry these (by design; they'd balloon). Only open each spec once, not per-task.

**Expected Outcome**: Complete spec requirement inventory keyed by spec path.

### 1.6. Cross-Reference Specs with Task Claims (Marker-Driven)

Determine which spec requirements are claimed by which tasks, and flag unclaimed ones.

**Actions**:
- From `tasks:` in the Step 1.3 inventory, extract each task's `spec:` and `covers:` fields.
- Skip tasks with no `covers:` (they claim no spec requirements).
- Build the claims inventory: `{ spec_path → { FR<N>: [task_paths] } }`.
- Compare against the requirement inventory from Step 1.5. Classify each FR<N> as:
  - **Claimed** — at least one task's `covers:` field contains it
  - **Unclaimed** — in the spec's `requirements:` but no task claims it
  - **Duplicated** — claimed by more than one task (possibly intentional; flag for review)
- Classify each claimed requirement further using the `code:` inventory from Step 1.3:
  - **Implemented** — at least one code marker's `implements:` field contains this FR<N> AND references the same spec
  - **Unimplemented** — claimed by a completed task (`status: complete`) but no code marker implements it
  - **Partial** — claimed by a task and some but not all sub-clauses are covered by code markers (judgment call; flag for review)

**Expected Outcome**: Traceability map of spec FR<N> → task claims → code implementation status, derived from marker data in one pass.  

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
  - **Unclaimed requirements**: FR<N> exists in `agent/specs/` but no task claims it in Spec Coverage. This is a *planning gap* — either a task should be created, or the requirement should be explicitly marked as deferred/out-of-scope in the spec itself.
  - **Unimplemented claims**: FR<N> claimed by a completed task but no implementation found in code. This is *completion drift* — the task was marked done without satisfying the claim.
  - **Partial claims**: FR<N> has some implementation but not all MUST clauses are satisfied.
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
  - local.gamification.md FR20 (Help System) — no task claims it
  - local.gamification.md FR24 (Loot Boxes) — deferred to M11 per notes
  - local.gamification.md FR30 (Notification Limits) — no task claims it
❌ 2 unimplemented claims (completion drift):
  - task-18 claims FR12 but letter frequency enforcement not found in code
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
