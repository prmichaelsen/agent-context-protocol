# Command: validate

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.validate` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.validate` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document.

> **🔌 Driver Override Check** (TOP-OF-FILE — runs BEFORE any other step in this file)
>
> 1. Read `agent/driver.yaml`. If the file does not exist OR there is no `workflows.acp.validate` mapping, jump to step 5 (fallback to the markdown steps below).
> 2. Look up `bindings.workflow.run` — the MCP tool name this driver uses for workflow dispatch. If the mapping exists but `workflow.run` is unbound, surface a clear configuration error (`"workflows.acp.validate is mapped but bindings.workflow.run is unset in agent/driver.yaml"`) and STOP.
> 3. Invoke that MCP tool with input `{action: "start", workflow: <mapped-value>, args: <user-arguments-from-this-invocation>}`. The command is now BLOCKED — execute the workflow loop per the canonical pattern (`agent/patterns/local.driver-dispatch-directive.md`, Core Principle 6): follow each returned `instruction`, return the requested output to the same MCP tool, repeat until the workflow signals completion or termination. The workflow's final output IS this command's output. **STOP. Do NOT execute any of the markdown steps below.**
> 4. **Error handling** (one-shot AND every loop iteration):
>    - If any tool response contains an `"error"` key, surface that message to the user and STOP. Do NOT fall through to the markdown steps below — a failed dispatch is NOT permission to use the fallback.
>    - If the tool call raises an MCP infrastructure exception (server unreachable, timeout), surface the exception and STOP. Same rule.
> 5. **Fallback (only when `workflows.acp.validate` is unmapped or `agent/driver.yaml` is absent):** Proceed to the markdown steps below as written — they describe ACP's default behavior for this command.
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
**Version**: 2.1.0  
**Created**: 2026-02-16  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Validate all ACP documents for structure, consistency, correctness, and namespace conventions  
**Category**: Documentation  
**Frequency**: As Needed  

---

## What This Command Does

This command validates all ACP documentation to ensure it follows proper structure, maintains consistency, contains no errors, and follows namespace conventions. It checks document formatting, verifies links and references, validates YAML syntax, ensures all required sections are present, validates namespace usage, and checks for reserved name violations.

Use this command before committing documentation changes, after creating new documents, or periodically to ensure documentation quality. It's particularly useful before releases or when onboarding new contributors.

Unlike `@acp.sync` which compares docs to code, `@acp.validate` checks the internal consistency and correctness of the documentation itself. Unlike `@acp.package-validate` which is for package authors, this command validates general ACP project documentation.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] Documentation exists in `agent/` directory
- [ ] You want to verify documentation quality

---

## Steps

### 0. Display Command Header

```
⚡ @acp.validate
  Validate all ACP documents for structure, consistency, correctness, and namespace conventions

  Related:
    @acp.package-validate  Package-specific validation
    @acp.sync              Sync documentation with code
    @acp.update            Update progress tracking
    @acp.report            Generate report with validation results
    @acp.init              Can include validation during init
```

This step is informational only — do not wait for user input.

### 1. Validate Directory Structure

Check that all required directories and files exist.

**Actions**:
- Verify `agent/` directory exists
- Check for `agent/design/`, `agent/milestones/`, `agent/patterns/`, `agent/tasks/`
- Verify `agent/progress.yaml` exists
- Check for `agent/commands/` directory
- Note any missing directories

**Expected Outcome**: Directory structure validated  

### 2. Validate progress.yaml

Check YAML syntax and required fields.

**Actions**:
- Parse `agent/progress.yaml` as YAML
- Verify required fields exist (project, milestones, tasks)
- Check field types (strings, numbers, dates)
- Validate date formats (YYYY-MM-DD)
- Verify progress percentages (0-100)
- Check milestone/task references are consistent
- Validate status values (not_started, in_progress, completed)

**Expected Outcome**: progress.yaml is valid  

### 3. Validate Design Documents

Check design document structure and content.

**Actions**:
- Read all files in `agent/design/`
- Verify required sections exist (Overview, Problem, Solution)
- Check for proper markdown formatting
- Validate code blocks have language tags
- Verify dates are in correct format
- Check status values are valid
- Ensure no broken internal links

**Expected Outcome**: Design docs are well-formed  

### 4. Validate Milestone Documents

Check milestone document structure.

**Actions**:
- Read all files in `agent/milestones/`
- Verify required sections (Overview, Deliverables, Success Criteria)
- Check naming convention (milestone-N-name.md)
- Validate task references exist
- Verify success criteria are checkboxes
- Check for proper formatting

**Expected Outcome**: Milestone docs are valid  

### 5. Validate Task Documents

Check task document structure and self-containment.

**Actions**:
- Read all files in `agent/tasks/`
- Verify required sections (Objective, Steps, Verification)
- Check naming convention (task-N-name.md)
- Validate milestone references
- Verify verification items are checkboxes
- Check for proper formatting
- Run **Self-Containment Probes** on every task with marker `status:` of `draft`, `in_progress`, or `not_started` (skip tasks marked `complete` — retroactive probing is noise)

**Expected Outcome**: Task docs are structurally valid AND incomplete tasks have verified self-containment  

#### 5.1. Self-Containment Probes

The Self-Contained Task Principle requires every relevant design excerpt, spec requirement, and clarification decision to be inlined verbatim in the task body so sub-agents have all the context they need without opening other files. These probes confirm the task actually did the inlining.

All three probes are **reading-comprehension checks**: you (as validate's executing agent) read the task file and the referenced files, then judge whether the claimed content is meaningfully reflected in the task body. No fingerprints, no thresholds — you compare.

All findings are **soft warnings**. They never hard-fail validate; they appear in the Self-Containment section of Step 12's report and the user decides whether each is deliberate scoping or missed inlining.

**Probe 1 — Spec inlining**

For each incomplete task with `@scry.entry` marker fields `spec:` + `covers:`:

1. Read the spec file from `spec:`.
2. Locate each `FR<N>` listed in `covers:`.
3. For each FR-ID: does the task body reflect FR<N>'s substance — its MUST/SHOULD language, its constraint, its short description — somewhere in Steps, Context, or a `## Spec Coverage` section? A `- [ ] FR<N>: <description>` line counts. So does a paraphrase that captures the constraint.
4. For each FR-ID that is NOT reflected in the body, emit a finding:
   ```
   ⚠️ <task_path>  (<status>)
      Probe 1 (spec): covers: <FR-ID> but <FR-ID>'s text not reflected in body
      → Inline from <spec_path> under Spec Coverage
   ```

Deferral phrasing (e.g., "FR11 deferred to task-19", "FR13 scoped out — handled by milestone M11") is NOT a finding — recognize it and skip.

**Probe 2 — Design inlining**

For each incomplete task with `**Design Reference**: [name](path) | None` resolving to a real file:

1. Read the design file. Locate every DR-ID in it (look for `\*\*DR\d+[:\s*]` bold-prefix form or `### DR\d+:` heading form).
2. Three sub-cases:
   - **Design has DR-IDs AND task marker has `incorporates:` listing some of them**: for each DR-ID in `incorporates:`, confirm that DR-ID's atomic unit (the decision text, code snippet, schema, algorithm, interface, rule, or diagram) is reflected verbatim or faithfully paraphrased in the task body. Flag specific missing DR-IDs with their short title:
     ```
     ⚠️ <task_path>  (<status>)
        Probe 2 (design): incorporates: <DR-ID> but <DR-ID> (<short title>) not found in body
        → Inline from <design_path>
     ```
   - **Design has DR-IDs but task marker has no `incorporates:` field**: soft-warn:
     ```
     ⚠️ <task_path>  (<status>)
        Probe 2 (design): design <design_path> has D<min>..D<max> but task
        marker has no `incorporates:` field.
        → Add `incorporates:` for relevant DR-IDs, or justify the omission in the task body
          (e.g., "scoped-out: DR2-DR4 handled by task-19")
     ```
   - **Design has no DR-IDs (legacy, pre-v5.41)**: fall back to a holistic judgment: "does the task body contain substantive content from the design?" Scan for atomic units in the design (fenced code blocks, definition lists, key invariants in the Implementation / Solution / Edge Cases / Interfaces sections) that appear uncovered. Flag with a snippet:
     ```
     ⚠️ <task_path>  (<status>)
        Probe 2 (design, legacy): design <design_path> has no DR-IDs and task
        body doesn't reflect substantive design content.
        Missing likely: <snippet from unreflected section>
        → Consider backfilling DR-IDs in the design (run @acp.sync), then claim
          specific DR-IDs in this task's `incorporates:` field
     ```

Deferral phrasing is NOT a finding, as in Probe 1.

**Probe 3 — Clarification inlining**

> **🔌 Driver Dispatch — `query.run`**
>
> 1. Read `agent/driver.yaml`. If the file does not exist, OR `bindings.query.run` is unset, jump to step 4 (fallback).
> 2. Invoke the MCP tool named by `bindings.query.run` with input: a query that returns all clarification markers (kind=clarification) with their `resolves`, `resolved`, file path, and body. Pass intent in natural language (e.g., `{intent: "all clarification markers with resolves/resolved fields and body"}`); the bound tool's MCP description specifies the exact input shape. Inspect the response:
>    - **One-shot result** — the response is the row set. Use it for the inlining checks below.
>    - **Workflow start** — if the response is a workflow handle, enter the workflow execution loop per `agent/patterns/local.driver-dispatch-directive.md` Core Principle 6.
> 3. **Error handling:**
>    - If the tool call returns a JSON object with an `"error"` key, surface and STOP. Do NOT fall through.
>    - If the tool call raises an MCP infrastructure exception, surface and STOP. Same rule.
> 4. **Fallback (only when `bindings.query.run` is unset or `agent/driver.yaml` is absent):** Run the marker scanner directly:
>    ```sh
>    ./agent/scripts/acp.meta-scan.sh --kind clarification agent/clarifications/
>    ```
>    Parse the resulting flat stream into the same row-set structure used by the bound path.
> 5. **Missing-state guard:** if step 4 cannot proceed (`acp.meta-scan.sh` missing or returns non-zero exit unrelated to "no markers found"), surface a clear actionable error explaining BOTH paths are unavailable.

For each clarification block with `resolves:` matching the task's path AND `resolved: true`:

1. Read the clarification file. Identify the resolved decisions (typically in the answers, resolutions, or a "Resolved Decisions" subsection).
2. For each resolved decision, check the task body reflects it — either in Steps, Context, or Key Design Requirements.
3. For each unreflected decision, emit a finding:
   ```
   ⚠️ <task_path>  (<status>)
      Probe 3 (clarification): <clarification_path> resolved
      '<short summary of decision>' but not inlined in task
      → Inline the decision under Steps or Key Design Requirements
   ```

#### Self-Containment vs structural validation

Structural findings (missing `## Verification`, malformed milestone link, etc.) remain **errors** that fail validate.

Self-containment findings are **warnings** that do NOT fail validate. If a task has only self-containment warnings and no structural errors, the overall status in Step 12 is "passed with warnings."

### 6. Validate Pattern Documents

Check pattern document structure.

**Actions**:
- Read all files in `agent/patterns/`
- Verify required sections (Overview, Implementation, Examples)
- Check code examples are properly formatted
- Validate examples have language tags
- Verify no broken links

**Expected Outcome**: Pattern docs are valid  

### 7. Validate Command Documents

Check command document structure.

**Actions**:
- Read all files in `agent/commands/`
- Verify required sections (Purpose, Steps, Verification)
- Check agent directive is present
- Validate namespace and version fields
- Verify examples are complete
- Check related commands links work

**Expected Outcome**: Command docs are valid  

### 8. Validate Artifact Documents

Check artifact document structure and staleness.

**Actions**:
- Read all files in `agent/artifacts/` matching `research-*.md`, `glossary-*.md`, `reference-*.md`
- **Validate metadata block**:
  - Verify required fields exist: Type, Created, Last Verified, Status, Confidence, Category, Sources
  - Check Type is one of: research, glossary, reference
  - Validate Created format (YYYY-MM-DD)
  - Validate Last Verified format (YYYY-MM-DD)
  - Check Status is one of: Active, Stale, Deprecated, WIP
  - Validate Confidence format (High/Medium/Low or score/10)
  - ERROR if any required field missing
- **Validate file naming**:
  - Check format: `{type}-{N}-{title}.md`
  - Verify N is a number
  - ERROR if naming doesn't match pattern
- **Check staleness**:
  - Calculate days since Last Verified
  - WARN if Last Verified > 180 days (6 months) and Status is Active
  - WARN if Status is Stale but Last Verified is recent (< 30 days)
- **Validate research artifacts**:
  - Verify Executive Summary exists
  - Check Key Findings section has citations
  - Verify Sources & References section exists
  - WARN if no sources cited
- **Validate glossary artifacts**:
  - Check for category tables structure
  - Verify Alphabetical Index exists
  - Check Total Terms metadata field matches actual term count
  - WARN if mismatch
- **Validate reference artifacts**:
  - Check for Command-First Principle Check section
  - Verify Purpose section exists
  - Check Content section has appropriate structure for reference type
  - WARN if missing command-first check explanation

**Output format**:
```
📚 Artifact Validation:
  ✓ agent/artifacts/research-1-graphql-federation.md (Active, Last Verified: 2026-03-17)
  ⚠️ agent/artifacts/research-2-redis-persistence.md (Active, Last Verified: 2025-09-20, STALE: 180+ days)
  ✓ agent/artifacts/glossary-1-core-terminology.md (Active, 15 terms)
  ✓ agent/artifacts/reference-1-environment-variables.md (Active, command-first check documented)
  ⚠️ agent/artifacts/reference-2-troubleshooting.md (Stale status but Last Verified: 2026-03-10, recent)

  Summary: 5 artifacts validated, 2 warnings
  - 2 potentially stale artifacts (Last Verified > 6 months)
  - 1 status mismatch (marked Stale but recently verified)
```

**Expected Outcome**: Artifact docs are valid, staleness warnings issued  

### 9. Validate Namespace Conventions

Check namespace usage across all files.

**Actions**:
- **Detect Context**: Check if package.yaml exists
  - If exists: This is a package (use package namespace)
  - If not exists: This is a project (use @local namespace)
- **Command Files**: Validate command filenames
  - In packages: Commands MUST use {namespace}.{command}.md format
  - In projects: Local commands MUST use local.{command}.md format
  - Core ACP commands always use acp.{command}.md format
  - ERROR if files missing proper namespace prefix
- **Pattern Files**: Validate pattern filenames
  - In packages: Patterns MUST use {namespace}.{pattern}.md format
  - In projects: Patterns MUST use local.{pattern}.md format
  - ERROR if patterns missing namespace prefix
  - Exception: Template files (*.template.md) don't need namespace
- **Design Files**: Validate design filenames
  - In packages: Designs MUST use {namespace}.{design}.md format
  - In projects: Designs MUST use local.{design}.md format
  - ERROR if designs missing namespace prefix
  - Exception: Template files (*.template.md) don't need namespace
- **Reserved Names**: Check for reserved namespace usage
  - Reject package names: acp, local, core, system, global
  - Reject command files starting with reserved namespaces (unless core ACP)
  - Reject pattern files starting with reserved namespaces (unless core ACP)
  - ERROR for any violations
- **Consistency**: Verify namespace consistency
  - All commands in package use same namespace
  - All patterns in package use same namespace
  - All designs in package use same namespace
  - Namespace matches package.yaml name field (if package)
  - ERROR for mixing of namespaces

**Expected Outcome**: Namespace conventions validated, errors reported for violations  

### 10. Validate Key File Index

Check index files in `agent/index/` for schema correctness and referential integrity.

**Actions**:
- Check that `agent/index/` directory exists (warn if missing)
- For each `*.yaml` file in `agent/index/` (skip `*.template.yaml`):
  - Verify filename follows `{namespace}.{qualifier}.yaml` naming
  - Parse the index entries under the top-level key
  - For each entry, verify required fields present: `path`, `weight`, `kind`, `description`, `rationale`, `applies`
  - Validate `weight` is a number in range 0.0-1.0
  - Validate `kind` is one of: `pattern`, `command`, `design`, `note`, `directive`
    - `requirements` is accepted as a deprecated alias for `design` (warn: "use `design` instead")
    - `artifact` is also accepted for backward compatibility
  - Validate path/kind consistency:
    - If `path` is `null`: `kind` must be `note` or `directive`
    - If `path` is a string: `kind` must be `pattern`, `command`, or `design`
    - For `path: null` entries, `description` must be non-empty (it IS the content)
  - Validate `applies` values use fully qualified command names (contain a dot, e.g. `acp.proceed`)
  - For entries where `path` is a string: check that the path actually exists in the project
  - Warn on missing paths (file may have been moved or deleted)
  - Skip path existence check for `path: null` entries
- Check total indexed entries across all files (warn if > 20)
- Check per-namespace entry count (warn if > 10)

**Output format**:
```
📑 Index Validation:
  ✓ agent/index/local.main.yaml (5 entries, all valid)
  ⚠️ agent/index/core-sdk.main.yaml: path not found: agent/patterns/core-sdk.deleted.md
  ✓ Total: 8 entries across 2 namespaces (within limits)
```

**Expected Outcome**: Index files validated for schema and referential integrity  

### 11. Check Cross-References

Validate links between documents.

**Actions**:
- Extract all internal links from documents
- Verify linked files exist
- Check milestone → task references
- Verify task → milestone back-references
- Validate command → command links
- Note any broken links

**Expected Outcome**: All links are valid  

### 11.5. Validate Driver Bindings (if `agent/driver.yaml` present)

Verify the project's driver-binding configuration. Skip silently when `agent/driver.yaml` is absent — backward-compat invariant: projects without a driver bound see zero behavior change in validate output.

**Actions**:

1. **Detect presence**:
   ```sh
   ./agent/scripts/acp.driver-yaml.sh present
   ```
   If output is `false`, skip this entire step and proceed to step 12.

2. **Read the binding manifest**:
   ```sh
   ./agent/scripts/acp.driver-yaml.sh list-bindings
   ./agent/scripts/acp.driver-yaml.sh list-workflows
   ./agent/scripts/acp.driver-yaml.sh get-driver-name
   ```
   Hold the parsed `(ext_point, tool_name)` pairs and `(command_name, workflow_name)` pairs in memory for the rules below.

3. **Apply Rule 1 — Tool resolution** (DR6.1): every `tool_name` from `list-bindings` must resolve in the agent runtime's MCP catalog. Mechanism is runtime-specific:
   - **Claude Code** (v1 target): the LLM consults its own tool catalog. MCP tools appear with the prefix convention `mcp__<server>__<tool>`. For each unprefixed `tool_name` from the binding, search the catalog for an entry matching `mcp__*__<tool_name>` (any server). If found, record `(tool_name → server_name)`. If not found, surface a Rule 1 error.
   - **Other runtimes** (Cursor, Claude Desktop, etc.): use the runtime's tool-listing mechanism if available. If the runtime offers no introspection, degrade gracefully: emit a Rule 1 *warning* (not error) — `"Could not verify <tool_name> resolves in MCP catalog (runtime introspection unavailable). Assuming binding is valid."`

   Rule 1 error format:
   ```
   ✗ <ext_point>: <tool_name> — NOT FOUND in MCP catalog
     Fix: ensure <tool_name> is exposed by a registered MCP server, or update agent/driver.yaml
   ```

4. **Apply Rule 2 — Single MCP server** (DR8): all bound tools must come from the same MCP server. Using the `(tool_name → server_name)` map from Rule 1, count distinct `server_name` values. If more than one, surface:
   ```
   ✗ Bindings span multiple MCP servers: <tool-A> from <server-1>, <tool-B> from <server-2>.
     One driver per project — pick one server.
   ```
   Skip Rule 2 entirely if Rule 1 emitted any warnings (resolution unverifiable; can't classify single-vs-multi).

5. **Apply Rule 3 — Mint/query pairing** (DR2 ↔ DR3): if `query.run` appears in `list-bindings` but `marker.mint` does not, surface:
   ```
   ✗ query.run is bound but marker.mint is not.
     A driver indexing markers must be able to produce them in canonical format.
     Either bind marker.mint or remove the query.run binding.
   ```
   The reverse (mint bound, query unbound) is allowed — drivers may stamp markers without exposing query.

6. **Apply Rule 4 — Server reachability**: the MCP server hosting the bound tools (resolved in Rule 1) must be currently registered and reachable. For Claude Code: presence in the tool catalog already implies registration; reachability is implicit because tools the LLM can see are tools the runtime can call. For runtimes where this distinction matters (e.g., a registered server that's offline), surface:
   ```
   ✗ MCP server '<server-name>' is unreachable.
     Ensure it's registered with your agent runtime and the process is running.
   ```
   If introspection cannot determine reachability, emit a *warning* not an error.

7. **Workflow names are NOT validated here**: per DR4 (lazy resolution), workflow names in `workflows:` are validated at invocation time by the driver itself. Validate only confirms `bindings.workflow.run` is bound IF `workflows:` is non-empty (a paired pre-condition):

   If `list-workflows` returns any rows but `get-binding workflow.run` returns empty, surface:
   ```
   ✗ workflows: section is non-empty but bindings.workflow.run is unset.
     Workflow overrides require workflow.run to be bound. Either bind workflow.run
     or remove the workflows: section.
   ```

   Otherwise, leave the workflow names alone — driver will surface unknown-workflow errors at invocation time.

8. **Compose findings**: collect all Rule 1–4 errors and warnings into a structured list. Errors block validate (`Failed` status); warnings do not (`Passed with warnings`).

**Expected Outcome**: When `agent/driver.yaml` is present, every binding is verified against the runtime's MCP catalog; pairing and single-server invariants enforced; workflow names left for lazy validation.

**Note on the report format**: Step 12 (below) renders the Driver Bindings findings as a dedicated section in the validation report. See the report-format example after step 12 for the rendering convention.

### 12. Generate Validation Report

Summarize validation results.

**Actions**:
- Count total documents validated
- List any errors found (structural issues — these fail validate)
- List any warnings, including a dedicated **Self-Containment** section populated by Step 5.1 probes
- Provide recommendations
- Suggest fixes for issues
- Compute overall status:
  - **Passed** — no errors, no warnings
  - **Passed with warnings** — no errors, but at least one warning (including self-containment)
  - **Failed** — at least one structural error

Self-containment warnings do NOT fail validate; they appear as warnings. The author decides whether each warning is deliberate scoping or missed inlining.

**Expected Outcome**: Validation report generated with structural results AND self-containment findings clearly separated.  

**Report format**:

```
Validation Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overall: <Passed | Passed with warnings | Failed>

Structural:
  ✓ 12 design documents valid
  ✓ 34 task documents valid (structural)
  ...
  <any ERROR findings>

Self-Containment (incomplete tasks only):
  ⚠️ agent/tasks/milestone-7/task-2-session-freshness-injector.md  (not_started)
     - Probe 1 (spec): covers: FR31 but FR31's text not reflected in body
       → Inline from agent/specs/local.freshness.md under Spec Coverage

  ⚠️ agent/tasks/milestone-10/task-4-character-grading.md  (in_progress)
     - Probe 2 (design): Design agent/design/local.gamification.md has DR1..DR8
       but task marker has no `incorporates:` field.
       → Add `incorporates:` for relevant DR-IDs or justify the omission
     - Probe 3 (clarification): clarification-12-grading.md resolved
       'Karl uses fluency-weighted formula' but not inlined in task body

Cross-References:
  <any broken links or cross-ref issues>

Driver Bindings (only when agent/driver.yaml is present):
  Driver: @example-org/example-driver
  ✓ marker.mint: example_mint (resolved in mcp.example-driver)
  ✓ query.run: example_sql (resolved in mcp.example-driver)
  ✓ workflow.run: example_workflow (resolved in mcp.example-driver)
  ✓ All bound tools from a single MCP server (mcp.example-driver)
  ✓ marker.mint paired with query.run
  ✓ MCP server reachable
  ✓ workflows: section non-empty AND workflow.run is bound
```

**Driver Bindings — failure example**:

```
Driver Bindings:
  Driver: @example-org/example-driver
  ✗ query.run: foo_tool — NOT FOUND in MCP catalog
    Fix: ensure foo_tool is exposed by a registered MCP server, or update agent/driver.yaml
  ✗ query.run is bound but marker.mint is not.
    A driver indexing markers must be able to produce them in canonical format.
    Either bind marker.mint or remove the query.run binding.
```

Driver-binding errors block validate (`Failed`). Driver-binding warnings (e.g., "could not verify resolution because runtime introspection unavailable") do not block — they appear in the report and contribute to `Passed with warnings`.

---

## Verification

- [ ] All required directories exist
- [ ] progress.yaml is valid YAML
- [ ] progress.yaml has all required fields
- [ ] All design documents are well-formed
- [ ] All milestone documents are valid
- [ ] All task documents are valid (structural)
- [ ] Self-Containment probes ran for every incomplete task (draft / in_progress / not_started)
- [ ] Probe findings appear in Step 12 report as warnings (not errors)
- [ ] All pattern documents are valid
- [ ] All command documents are valid
- [ ] All artifact documents are valid
- [ ] Artifact metadata blocks complete
- [ ] Artifact staleness checked (Last Verified dates)
- [ ] Artifact file naming validated
- [ ] Namespace conventions validated
- [ ] Reserved names checked
- [ ] Key file index validated (schema, paths, limits, artifact kind supported)
- [ ] No broken internal links
- [ ] Validation report generated

---

## Expected Output

### Files Modified
None - this is a read-only validation command

### Console Output
```
✓ Validating ACP Documentation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Directory Structure:
✓ agent/ directory exists
✓ agent/design/ exists (5 files)
✓ agent/milestones/ exists (2 files)
✓ agent/patterns/ exists (3 files)
✓ agent/tasks/ exists (7 files)
✓ agent/commands/ exists (11 files)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

progress.yaml:
✓ Valid YAML syntax
✓ All required fields present
✓ Date formats correct
✓ Progress percentages valid (0-100)
✓ Status values valid
✓ Task/milestone references consistent

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Design Documents (5):
✓ All have required sections
✓ Markdown formatting correct
✓ Code blocks properly tagged
⚠️  auth-design.md: Missing "Last Updated" date

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone Documents (2):
✓ All have required sections
✓ Naming convention followed
✓ Task references valid
✓ Success criteria are checkboxes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task Documents (7):
✓ All have required sections
✓ Naming convention followed
✓ Milestone references valid
✓ Verification items are checkboxes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pattern Documents (3):
✓ All have required sections
✓ Code examples properly formatted
✓ No broken links

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Command Documents (11):
✓ All have required sections
✓ Agent directives present
✓ Namespace and version fields valid
✓ Examples complete
✓ Related command links valid

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Namespace Conventions:
✓ Context detected: Project (no package.yaml)
✓ All core ACP commands use 'acp' namespace
✓ Local commands use 'local' namespace
✓ No reserved name violations
✓ Namespace consistency maintained

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Cross-References:
✓ All internal links valid
✓ Milestone → task references correct
✓ Task → milestone back-references correct
✓ Command → command links work

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Validation Complete!

Summary:
- Documents validated: 28
- Errors: 0
- Warnings: 1
- Overall: PASS

Warnings:
⚠️  auth-design.md: Missing "Last Updated" date

Recommendations:
- Add "Last Updated" date to auth-design.md
- Consider adding more code examples to patterns
```

### Status Update
- Validation completed
- Issues identified (if any)
- Documentation quality confirmed

---

## Examples

### Example 1: Before Committing Changes

**Context**: Made changes to several docs, want to verify before commit  

**Invocation**: `@acp.validate`  

**Result**: Validates all docs, finds 2 broken links, reports them, you fix them before committing  

### Example 2: After Creating New Documents

**Context**: Created 3 new design documents  

**Invocation**: `@acp.validate`  

**Result**: Validates new docs, confirms they follow proper structure, identifies missing section in one doc  

### Example 3: Periodic Quality Check

**Context**: Monthly documentation review  

**Invocation**: `@acp.validate`  

**Result**: Validates all 50+ documents, finds minor formatting issues in 3 files, overall quality is good  

---

## Related Commands

- [`@acp.package-validate`](acp.package-validate.md) - Package-specific validation (for package authors)
- [`@acp.sync`](acp.sync.md) - Sync documentation with code (different from validation)
- [`@acp.update`](acp.update.md) - Update progress tracking
- [`@acp.report`](acp.report.md) - Generate comprehensive report including validation results
- [`@acp.init`](acp.init.md) - Can include validation as part of initialization

---

## Troubleshooting

### Issue 1: YAML parsing errors

**Symptom**: progress.yaml fails to parse  

**Cause**: Invalid YAML syntax (indentation, special characters)  

**Solution**: Use YAML validator, check indentation (2 spaces), quote strings with special characters  

### Issue 2: Many broken links reported

**Symptom**: Validation finds numerous broken links  

**Cause**: Files were moved or renamed  

**Solution**: Update links to reflect new file locations, use relative paths, verify files exist  

### Issue 3: Validation takes too long

**Symptom**: Command runs for several minutes  

**Cause**: Very large project with many documents  

**Solution**: This is normal for large projects, consider validating specific directories only, run less frequently  

---

## Security Considerations

### File Access
- **Reads**: All files in `agent/` directory
- **Writes**: None (read-only validation)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access secrets or credentials
- **Credentials**: Does not access credentials files

---

## Notes

- This is a read-only command - it doesn't modify files
- Validation should be fast (< 30 seconds for most projects)
- Run before committing documentation changes
- Integrate into CI/CD pipeline if desired
- Warnings are informational, not failures
- Errors should be fixed before proceeding
- Consider running after major documentation updates
- Can be automated as a pre-commit hook

---

**Namespace**: acp  
**Command**: validate  
**Version**: 2.0.0  
**Created**: 2026-02-16  
**Last Updated**: 2026-02-21  
**Status**: Active  
**Compatibility**: ACP 2.0.0+  
**Author**: ACP Project  
