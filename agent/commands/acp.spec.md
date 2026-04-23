# Command: spec

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-spec` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-spec NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-04-22  
**Last Updated**: 2026-04-22  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Generate a specification document from a clarification, design, draft, requirements doc, or interactive input  
**Category**: Creation  
**Frequency**: As Needed  

---

## Arguments

**CLI-Style Arguments** (source — pick exactly one; default is `--interactive`):
- `--from-clarification <file>` or `--from-clar <file>` - Generate spec from a clarification file (`agent/clarifications/*.md`)
- `--from-design <file>` - Generate spec from a design document (`agent/design/*.md`)
- `--from-draft <file>` - Generate spec from a free-form draft file
- `--from-requirements <file>` or `--from-req <file>` - Generate spec from a requirements document
- `--interactive` or `-i` - Interactive mode; collect spec contents via chat (default)

**CLI-Style Arguments** (context capture, optional — passed through to `@acp.clarification-capture`):
- `--from-chat-context` or `--from-chat` - Also capture decisions from chat conversation
- `--from-context` - Shorthand for all sources (clarifications + chat)
- `--include-clarifications` - Alias for `--from-clars`
- `--no-commit` - Skip the automatic commit step after creation

**Natural Language Arguments**:
- `@acp.spec @my-draft.md` - Treated as `--from-draft @my-draft.md`
- `@acp.spec for <topic>` - Starts interactive mode seeded with `<topic>` as the spec subject
- `@acp.spec from the last clarification` - Resolves the most recent clarification file and uses `--from-clar`

**Argument Mapping**:
Arguments are inferred from chat context. The agent will:
1. Parse explicit CLI-style flags if present
2. Treat any positional `@<path>.md` as `--from-draft <path>`
3. If multiple source flags are specified, stop and ask which to use
4. If no source is specified, default to `--interactive`
5. Ask for clarification only if the source file cannot be resolved

---

## What This Command Does

Generates a specification document by reading an input source (clarification, design, draft, requirements, or interactive chat) and producing a structured spec in `agent/specs/{namespace}.{spec-name}.md`. The command handles namespace inference, optional package/README updates, and key file index registration.

A design captures the *what* and *why* (architecture, rationale, tradeoffs). A spec captures the *how* — concrete, implementation-ready acceptance criteria, interfaces, data shapes, and step-by-step behavior a developer or agent can build against. Use `@acp.design-create` when direction is still open; use `@acp.spec` when direction is settled and you need an executable blueprint.

### Core Principle: The Spec Defines the End-System Behavior Exactly

A complete spec MUST describe the exact observable behavior of the finished system — not a sketch, not a happy-path summary. The **Behavior Table** is the reviewer's scannable proofing surface (one row per scenario, including `undefined` rows for scenarios the source did not resolve), and the **Tests** section is the executable proof of the contract. A reader who knows nothing about the implementation should be able to predict, from the spec alone, what the system does for any reasonable input — or, where behavior is genuinely undecided, find it flagged as `undefined` rather than silently guessed.

This is valuable for two reasons:

1. **Proofing catches misunderstandings before code is written.** When the user reads the finished spec, every scenario they care about is represented as a test. Disagreements surface immediately — at the cheapest point to fix them — instead of after implementation.
2. **TDD becomes trivial.** Each assertion is already named, observable, and language-agnostic. Implementers translate assertions directly into their test framework, confirm the suite fails, then write code until it passes.

### Agent Instruction: Be Comprehensive

When generating a spec, the agent MUST be exhaustive about behavior. A spec that only covers the happy path is a draft, not a spec. The agent MUST explicitly think through:

- **Happy path** — valid, typical inputs produce expected outputs
- **Bad path** — invalid inputs, error conditions, failure modes, partial failures
- **Positive tests** — assertions that something expected happens (e.g., "returns 200", "emits event X")
- **Negative tests** — assertions that something unexpected does NOT happen (e.g., "does not enumerate valid emails", "does not log the password", "does not mutate the input object")
- **Edge cases** — boundary values, empty/null/max inputs, concurrency, idempotency, ordering, time-dependent behavior, resource exhaustion

If the agent cannot decide how the system should behave in a given scenario, it goes into **Open Questions** — never guessed into a test.

Use this command when you have a clarification, design, draft, or requirements document that needs to be turned into a concrete, implementation-ready specification.

---

## Prerequisites

- [ ] ACP installed in current directory
- [ ] (For `--from-*` modes) Source file exists and is readable
- [ ] (Optional) `agent/specs/spec.template.md` exists — if missing, a default structure is used

---

## Steps

### 0. Display Command Header (Default)

When the command is invoked, immediately display a brief informational header before proceeding. This step does NOT block execution — the agent prints it and continues into Step 1 without pausing.

**Actions**:
- Print the command's **Purpose** (from the metadata above)
- Print a one-line summary of what this invocation will do
- Print a **Usage** block listing available arguments
- Print a **Related Commands** block

**Display format**:
```
⚡ @acp.spec
  Generate a specification document from a clarification, design, draft, requirements doc, or interactive input

  Usage:
    @acp.spec                                      Interactive mode (default)
    @acp.spec -i                                   Interactive mode (explicit)
    @acp.spec --from-clar <file>                   Generate from clarification
    @acp.spec --from-design <file>                 Generate from design doc
    @acp.spec --from-draft <file>                  Generate from draft
    @acp.spec @my-draft.md                         Generate from draft (shorthand)
    @acp.spec --from-req <file>                    Generate from requirements
    @acp.spec --no-commit                          Skip automatic commit

  Related:
    @acp.design-create         Create design documents (what/why)
    @acp.clarification-create  Create a clarification to feed into --from-clar
    @acp.task-create           Break a finished spec into tasks
    @acp.package-validate      Validate package after creation
```

**Expected Outcome**: User sees at a glance what the command does and how to customize it.

### 1. Detect Context

Determine if the command is running in a package or a project directory.

**Actions**:
- Check if `package.yaml` exists
- If package: Infer namespace from `package.yaml`, directory, or git remote
- If project: Use `local` namespace

**Expected Outcome**: Context detected, namespace determined.

### 2. Resolve Source Mode

Parse arguments to pick exactly one source mode.

**Actions**:
- If any `--from-*` source flag is present: use that mode, read the referenced file, verify it exists
- If a positional `@<path>` argument is present: treat as `--from-draft`
- If no source is specified: default to `--interactive`
- If more than one source flag is present: stop and ask the user which source to use
- Resolve relative paths against the project root

**Expected Outcome**: Exactly one source mode selected; source file (if any) loaded into context.

### 3. Read Contextual Key Files

Before generating the spec, load relevant key files from the index.

**Actions**:
- Check if `agent/index/` directory exists
- If exists, scan for all `*.yaml` files (excluding `*.template.yaml`)
- Filter entries where `applies` includes `acp.spec`
- Sort by weight descending, read matching files
- Also read any design or requirements documents referenced by the source file
- Produce visible output listing what was read

**Expected Outcome**: High-weight contextual files loaded.

**Note**: If `agent/index/` does not exist, skip silently.

### 4. Capture Clarification Context

Invoke the `@acp.clarification-capture` shared directive if additional context flags were passed.

**Actions**:
- Read and follow the directive in [`agent/commands/acp.clarification-capture.md`](acp.clarification-capture.md)
- Pass through `--from-chat-context`, `--from-context`, or `--include-clarifications` if present
- If `--from-clar` was the primary source, the clarification is already loaded — do not re-capture it
- Hold any generated "Key Design Decisions" section for insertion during Step 6

**Expected Outcome**: Key Design Decisions section generated (if extra context is available), or skipped cleanly.

### 5. Collect Spec Information

Gather any missing metadata from the user. Only ask about genuinely ambiguous fields.

**Actions**:
- Determine **spec name** (lowercase, alphanumeric, hyphens); if source is a clarification/design/requirements file, suggest a name derived from the source filename
- Determine **one-line description**; in `--from-*` modes, infer from the source's title or first paragraph
- Set **version** to `1.0.0` by default
- Interactive mode only: additionally collect goal, scope boundaries (in/out), known constraints, and an acceptance-criteria draft
- Interactive mode MUST also probe for comprehensive coverage. Ask the user (or deduce and propose):
  - What does the happy path look like for each primary action?
  - What errors, invalid inputs, or failure modes exist? (bad path)
  - What should explicitly NOT happen? (negative assertions: no timing leaks, no data mutation, no extra writes, no logged secrets)
  - What are the boundary values? (empty, null, max size, unicode, negative numbers, zero, repeated calls)
  - Are there time-dependent, ordering-dependent, or idempotency concerns?
  - **Concurrency / coordination** — if not clear from the source material, explicitly ask: are there mutex locks, semaphores, or other synchronization primitives? async operations or promises/futures? event queues, message buses, or pub/sub? background workers, cron jobs, or scheduled tasks? database transactions or distributed locks? Each of these categories carries its own hazard classes and requires special edge-case tests:
    - **Mutex / locks**: tests for contention, lock ordering / deadlock, lock-held-while-failing (exception safety), reentrancy, timeout-on-acquire behavior, fairness if relevant
    - **Async operations**: tests for cancellation / abort, timeout, error propagation through the await chain, unhandled-rejection behavior, ordering of overlapping awaits, backpressure
    - **Event queues / message buses**: tests for duplicate delivery (at-least-once semantics), out-of-order delivery, replay / poison-message handling, dead-letter routing, consumer lag, ack/nack semantics, idempotency of handlers
    - **Background workers / schedulers**: tests for missed-tick recovery, overlapping runs, clock-skew, DST transitions if time-of-day matters, shutdown-in-flight behavior
    - **Transactions / distributed coordination**: tests for rollback on failure, partial-commit visibility, read-your-writes, isolation-level-dependent anomalies, split-brain if applicable
  - Do not assume "single-threaded / synchronous" by default — confirm it, and if confirmed, add one negative-assertion test stating that explicitly so future implementers don't accidentally add concurrency without updating the spec
- Record anything the user is unsure about into Open Questions — do NOT invent behavior

**Expected Outcome**: All metadata collected; source-derived content prepared.

### 6. Generate Spec File

Create the spec file.

**Actions**:
- Determine full filename: `agent/specs/{namespace}.{spec-name}.md`
- Ensure `agent/specs/` exists; create it if not
- If `agent/specs/spec.template.md` exists, use it as the base
- Otherwise, use this default structure:
  - Title and directive header (template-style)
  - Metadata block (Namespace, Version, Created, Last Updated, Status)
  - **Purpose** (one line)
  - **Source** (mode and source file path)
  - **Scope** (in-scope and out-of-scope bullets)
  - **Requirements** (numbered, testable)
  - **Interfaces / Data Shapes** (schemas, signatures, API shapes, where applicable)
  - **Behavior Table** (REQUIRED — scannable catalog of every scenario, including `undefined` rows; see format below)
  - **Behavior** (step-by-step)
  - **Acceptance Criteria** (verifiable checklist)
  - **Tests** (language-agnostic test cases — REQUIRED section; see format below)
    - **Base Cases** subsection (required) — the core behavior contract
    - **Edge Cases** subsection (required) — boundaries, concurrency, unusual inputs
  - **Non-Goals** (explicit exclusions)
  - **Open Questions** (unresolved items — link back to clarifications where relevant)
  - **Related Artifacts** (source design/clarification/requirements, related specs, tasks)
- Populate content from the selected source:
  - `--from-clarification`: carry decided answers into Requirements and Acceptance Criteria; carry unresolved questions into Open Questions
  - `--from-design`: extract concrete requirements and acceptance criteria from the design's implementation-focused sections
  - `--from-draft`: interpret free-form draft into the structured sections; flag ambiguities in Open Questions rather than guessing
  - `--from-requirements`: carry requirements forward verbatim where possible; expand each into acceptance criteria
  - `--interactive`: build from user-collected answers in Step 5
- If a "Key Design Decisions" section was generated in Step 4, insert it above "Related Artifacts"
- Save the file

**Behavior Table format** (REQUIRED — the reviewer's proofing surface):

The Behavior Table is a scannable catalog of every scenario the spec covers. The reviewer reads it top-to-bottom and flags any row whose `Expected Behavior` doesn't match their expectation, or any scenario they care about that isn't present. It is designed for **low cognitive load**: short rows, plain English, no jargon, no code.

Every scenario the agent considered MUST appear as a row — including scenarios the agent could not resolve from the input artifacts. Unresolved scenarios are marked `undefined` in the `Expected Behavior` column and linked to an Open Question. This is the whole point: surfacing "we don't know" explicitly is more valuable than quietly guessing.

```markdown
## Behavior Table

| # | Scenario | Expected Behavior | Tests |
|---|----------|-------------------|-------|
| 1 | <short plain-English trigger/input> | <short plain-English outcome> | `<test-name-1>`, `<test-name-2>` |
| 2 | <another scenario> | <outcome> | `<test-name-3>` |
| 3 | <scenario source did not resolve> | `undefined` | → [OQ-1](#open-questions) |
| 4 | <edge-case scenario> | <outcome> | `<edge-test-name>` |
```

**Rules for the Behavior Table**:
- Exactly four columns: `#`, `Scenario`, `Expected Behavior`, `Tests`
- One row per distinct scenario the spec covers
- `Scenario` is a short plain-English description of the trigger or input class (≤ ~12 words; no code, no schemas — those live in the Tests section)
- `Expected Behavior` is a short plain-English description of what the system does (≤ ~15 words) OR the literal bolded word `undefined` if the behavior has not been decided
- `Tests` lists the kebab-case test names from the Tests section (comma-separated), OR `→ [OQ-N](#open-questions)` for undefined rows (linking to the corresponding Open Question), OR `—` if truly N/A
- Every test in the Tests section MUST appear in at least one row's `Tests` column (no orphan tests)
- Every row with `undefined` MUST have a matching Open Question (no orphan undefineds)
- Add `undefined` rows aggressively for anything the source artifacts did not resolve — these are the highest-value rows for catching misunderstandings before code is written
- The table is not a replacement for the Tests section — it is a scannable index. Tests hold the rigorous Given/When/Then; the table points at them.
- Row order: typically happy-path rows first, then bad-path rows, then edge-case rows, then `undefined` rows last — but any ordering that aids scanning is fine

**Tests section format** (REQUIRED — language-agnostic; implementations translate these into their test framework):

The Tests section is split into **Base Cases** (the core behavior contract) and **Edge Cases** (boundaries, concurrency, unusual inputs), in that order. Both subsections are required; if one is genuinely empty, state that explicitly and explain why in a short note — do not silently omit.

Each test is a named case with one or more assertions. Do NOT write code — describe inputs, the action taken, and the observable outputs the implementation must produce. Multiple assertions per test are expected when one action produces several checkable facts.

```markdown
## Tests

### Base Cases

The core behavior contract: happy path, common bad paths, primary positive and negative assertions. A reader should be able to understand the normal operation of the system from this subsection alone.

#### Test: <kebab-case-test-name> (covers R1, R2)

**Given**: <single-sentence precondition>  
-- or --  
**Given**:
- <precondition 1>
- <precondition 2>

**When**: <single-sentence action>  
-- or --  
**When**:
- <action / event 1>
- <action / event 2>

**Then** (assertions):
- **<assertion-id>**: <observable outcome 1>
- **<assertion-id>**: <observable outcome 2>
- **<assertion-id>**: <observable outcome 3>

#### Test: <another-base-test> (covers R3)

...

### Edge Cases

Boundaries, unusual inputs, concurrency, idempotency, ordering, time-dependent behavior, resource exhaustion. Every edge case the agent or user can think of that is NOT in scope goes in **Non-Goals** instead; everything else is tested here.

#### Test: <edge-case-name> (covers R4)

**Given**: ...
**When**: ...
**Then** (assertions):
- **<assertion-id>**: ...
```

**Rules for the Tests section**:

*Structure*
- The Tests section MUST contain `### Base Cases` followed by `### Edge Cases` (in that order, both required)
- Each test is a `####` heading and has a `Given` (setup), `When` (action), `Then` (assertions) block
- `Given` and `When` may each be a single sentence or a bulleted list — pick whichever is clearest; mixing forms across tests is fine
- Test names are kebab-case and describe the scenario, not the implementation (e.g., `rejects-empty-payload`, not `test_validate_empty`)
- Each test SHOULD annotate which requirements it covers: `#### Test: <name> (covers R1, R3)`

*Assertions*
- **At least one assertion per test is required; multiple assertions per test are the norm** — when a single action produces several observable outcomes, keep them together in one test
- Each assertion has a short slug identifier (e.g., `status-400`, `no-db-query`, `token-expiry-24h`) so specific assertions can be referenced in code review, tasks, and handoffs
- Assertions describe **observable outputs** (return values, emitted events, state changes, logged messages, exit codes, side-effect presence/absence) — never internal implementation details
- Assertions MUST be language- and framework-agnostic — no pytest/jest/go-test syntax, no mocking library references, no language-specific types

*Comprehensive coverage (MANDATORY)*

The spec is the exact definition of end-system behavior. A reader proofing the spec must be able to find every scenario they care about. Before finishing the Tests section, the agent MUST verify all four coverage dimensions are present across Base + Edge combined:

- **Happy path** — valid, typical inputs produce expected outputs (at least one test per primary action)
- **Bad path** — each distinct error condition, invalid input class, and failure mode has its own test (malformed input, missing fields, auth failure, downstream failure, resource missing, permission denied, etc.)
- **Positive assertions** — "X happens": returns a value, emits an event, writes a record, updates state
- **Negative assertions** — "Y does NOT happen": no enumeration of valid emails, no password in logs, no mutation of input, no extra writes, no timing leak, no retry on non-retriable errors, idempotent on repeated calls

If the agent cannot decide the expected behavior for a plausible scenario, it goes into **Open Questions** — NEVER guessed into a test. Guessing in a test silently locks in an implementation decision the user never made.

*Coverage bookkeeping*
- Every requirement in **Requirements** MUST be covered by at least one test (Base or Edge)
- Every test SHOULD trace back to a requirement via the `(covers Rn)` annotation
- If a test covers behavior not in Requirements, add the corresponding requirement — the requirements and tests drift together or not at all
- If behavior varies by input class, prefer table-driven style: one test per class, with the class description in `Given` and one assertion per checkable output

**Expected Outcome**: Spec file created at `agent/specs/{namespace}.{spec-name}.md` with a populated Tests section.

### 7. Update package.yaml (If in Package)

Add the spec to `package.yaml` contents if this command is running inside a package.

**Actions**:
- Read `package.yaml`
- If `contents.specs` does not exist, create it
- Add entry:
  ```yaml
  - name: {namespace}.{spec-name}.md
    description: {description}
  ```
- Save `package.yaml`

**Expected Outcome**: `package.yaml` updated.

**Note**: If the package manifest schema does not yet support a `specs` section, report that to the user and continue without failing.

### 8. Update README.md (If in Package)

Regenerate the README "What's Included" section.

**Actions**:
- If `update_readme_contents()` is available in `agent/scripts/acp.common.sh`, invoke it
- Otherwise, skip silently

**Expected Outcome**: `README.md` updated.

### 9. Prompt to Delete Draft (If `--from-draft` Was Used)

If a draft file was the source, ask whether to delete it.

**Actions**:
- Ask the user: "Delete draft `{path}`?"
- Delete only on explicit confirmation

**Expected Outcome**: User decides whether to keep the draft.

### 10. Prompt to Add to Key File Index

After successful creation, offer to add the new spec to the index (if `agent/index/` exists).

**Actions**:
- Ask the user whether to add the spec to `agent/index/local.main.yaml`
- If yes, prompt for weight (suggest `0.7`–`0.8`), description, rationale, and `applies` values (suggested: `acp.proceed, acp.task-create`)

**Expected Outcome**: Spec optionally registered in the index.

**Note**: Skip silently if `agent/index/` does not exist.

### 11. Commit Created Artifacts (MANDATORY unless `--no-commit`)

> **⚠️ CRITICAL**: This step is NOT optional unless `--no-commit` was specified. You MUST commit created artifacts before finishing. Do NOT skip this step. Do NOT ask the user whether to commit. Do NOT defer the commit. If `--no-commit` was passed, skip this step silently.

**Actions**:
- Stage files created or modified during spec creation:
  - Spec file (`agent/specs/{namespace}.{spec-name}.md`)
  - `package.yaml` (if updated)
  - `README.md` (if updated)
  - `agent/index/*.yaml` (if user opted in via Step 10)
- Do NOT stage draft files — the draft was handled in Step 9
- Do NOT stage clarification files
- Invoke `@git.commit` with a message like `feat(spec): create {namespace}.{spec-name} from {source-mode}`
- Verify the commit succeeded

**Expected Outcome**: All spec artifacts committed.

---

## Verification

- [ ] Context detected correctly (package vs project)
- [ ] Exactly one source mode resolved
- [ ] Source file read successfully (if applicable)
- [ ] Namespace determined
- [ ] Spec metadata collected (name, description, version)
- [ ] Spec file created at `agent/specs/{namespace}.{spec-name}.md`
- [ ] Directive header present and correctly filled in
- [ ] Source and unresolved items captured in Open Questions
- [ ] **Behavior Table present with four columns (`#`, `Scenario`, `Expected Behavior`, `Tests`) and one row per scenario**
- [ ] Every test in the Tests section appears in at least one Behavior Table row (no orphan tests)
- [ ] Every `undefined` row has a matching Open Question (no orphan undefineds)
- [ ] Unresolved scenarios are marked `undefined` in the table — never guessed
- [ ] **Tests section present, language-agnostic, with both `### Base Cases` and `### Edge Cases` subsections**
- [ ] Each test has `Given` / `When` / `Then` and ≥1 assertion; multi-assertion tests used where appropriate
- [ ] **Coverage spans all four dimensions: happy path, bad path, positive assertions, negative assertions**
- [ ] Every Requirement is covered by ≥1 test via `(covers Rn)` annotation; every test traces back to a requirement
- [ ] Behaviors the agent could not confidently derive are in Open Questions AND flagged as `undefined` rows in the Behavior Table, NOT guessed into tests
- [ ] `package.yaml` updated (if package)
- [ ] `README.md` updated (if applicable)
- [ ] Spec artifacts committed via `@git.commit` (MANDATORY — skip only if `--no-commit`)

---

## Expected Output

### Files Modified
- `agent/specs/{namespace}.{spec-name}.md` — Created
- `agent/specs/` — Directory created if it did not exist
- `package.yaml` — Spec added to contents (if package + specs supported)
- `README.md` — Contents section regenerated (if regeneration helper available)
- `agent/index/local.main.yaml` — Index entry added (if user opted in)

### Console Output
```
✅ Spec Created Successfully!

File: agent/specs/local.auth-flow.md
Source: --from-clarification agent/clarifications/clarification-12-auth-flow.md
Namespace: local
Version: 1.0.0

✓ Spec file created
✓ package.yaml updated (if package)
✓ README.md updated (if package)
✓ Spec committed via @git.commit

Next steps:
- Review the spec and fill in any Open Questions
- Run @acp.task-create to break the spec into tasks
- Run @acp.package-validate to verify (if package)
```

### Status Update
- New file tracked in git: `agent/specs/{namespace}.{spec-name}.md`
- `package.yaml` version is unchanged (spec additions are content, not schema changes)
- Commit added to the current branch

---

## Examples

### Example 1: Spec From a Clarification

**Context**: Just finished `@acp.clarification-address` on `clarification-12-auth-flow.md`.  

**Invocation**: `@acp-spec --from-clar agent/clarifications/clarification-12-auth-flow.md`  

**Result**: Creates `agent/specs/local.auth-flow.md`, carrying decided answers into Requirements and Acceptance Criteria and any unresolved items into Open Questions.

### Example 2: Spec From a Design

**Context**: `agent/design/local.payment-processor.md` is settled; time to build.  

**Invocation**: `@acp-spec --from-design agent/design/local.payment-processor.md`  

**Result**: Creates `agent/specs/local.payment-processor.md` with concrete interfaces, data shapes, and acceptance criteria extracted from the design's implementation sections.

### Example 3: Spec From a Draft

**Context**: User wrote a rough draft of what they want.  

**Invocation**: `@acp-spec @agent/drafts/webhook-router.md`  

**Result**: Parses the draft into the structured spec format. Ambiguities land in Open Questions rather than being guessed.

### Example 4: Interactive

**Context**: User wants to build a spec from scratch via chat.  

**Invocation**: `@acp-spec -i`  

**Result**: Agent collects scope, requirements, interfaces, and acceptance criteria interactively, then produces the spec file.

### Example 5: Spec From Requirements Doc

**Context**: An external requirements doc was dropped into the project.  

**Invocation**: `@acp-spec --from-req agent/design/external-requirements.md`  

**Result**: Creates a spec that carries the requirements forward verbatim and expands each into acceptance criteria.

---

## Related Commands

- [`@acp-design-create`](acp.design-create.md) — Create design documents (the what/why; typically precedes `@acp.spec`)
- [`@acp-clarification-create`](acp.clarification-create.md) — Create a clarification to feed into `--from-clar`
- [`@acp-clarification-address`](acp.clarification-address.md) — Resolve a clarification before converting to spec
- [`@acp-task-create`](acp.task-create.md) — Break a finished spec into implementation tasks
- [`@acp-package-validate`](acp.package-validate.md) — Validate package after creation

---

## Troubleshooting

### Issue 1: Multiple source flags specified

**Symptom**: Command stops and asks which source to use.  

**Cause**: More than one `--from-*` flag was passed.  

**Solution**: Re-run with exactly one source flag.

### Issue 2: Source file not found

**Symptom**: Error reading source file.  

**Cause**: Path is wrong or file does not exist.  

**Solution**: Verify the path. Paths are resolved relative to the project root.

### Issue 3: `agent/specs/` does not exist

**Symptom**: Write fails.  

**Cause**: Directory missing.  

**Solution**: The command creates the directory automatically. If the write still fails, check filesystem permissions.

### Issue 4: `package.yaml` has no `specs` section

**Symptom**: Skipped `package.yaml` update with a note.  

**Cause**: The package manifest schema does not yet include specs.  

**Solution**: Non-fatal. The spec file is still created; only the `package.yaml` update is skipped.

---

## Security Considerations

### File Access
- **Reads**: Source file (clarification/design/draft/requirements), `package.yaml`, templates, `agent/index/*.yaml`
- **Writes**: `agent/specs/{namespace}.{name}.md`, `package.yaml`, `README.md`, `agent/index/local.main.yaml` (opt-in)
- **Executes**: `@git.commit` at the end (unless `--no-commit`)

### Network Access
- **APIs**: None
- **Repositories**: Only via `@git.commit` at the end

### Sensitive Data
- **Secrets**: Never include secrets in specs
- **Credentials**: Never include credentials

---

## Key Design Decisions (Optional)

<!-- This section is populated by @acp.clarification-capture when
     create commands are invoked with --from-clar, --from-chat, or
     --from-context. It can also be manually authored.
     Omit this section entirely if no decisions to capture. -->

---

## Notes

- Specs are the bridge between a settled design and implementation tasks — if scope is still unsettled, use `@acp.design-create` first
- `--from-clar` is the most common path: clarify → spec → tasks → build
- In non-package projects, the `local` namespace is used automatically
- The spec template (`agent/specs/spec.template.md`) is optional; the command falls back to a default inline structure when it is missing
- Unresolved items from the source are carried into **Open Questions** rather than guessed — preserving the distinction between "decided" and "undecided" is the whole point of a spec
- The **Tests** section is the executable contract of the spec: language-agnostic, Given/When/Then, one or more named assertions per test. Implementations in any language (Python, TypeScript, Go, Rust, shell, etc.) must be able to translate each test and each assertion directly into their own test framework without re-interpreting intent.
- Prefer **multiple assertions per test** when a single action produces multiple observable outcomes — splitting them into separate tests duplicates setup and obscures that the outcomes come from the same operation
- The spec is meant to be **proofed** by the user before any code is written. The **Behavior Table** is the primary proofing surface — the user scrolls through the rows, confirms each `Expected Behavior` matches what they want, and flags any row that doesn't. `undefined` rows are the most valuable: they surface gaps the agent could not resolve, exactly where the user's judgment is needed. Only after the Behavior Table is approved does the reviewer dive into the Tests section for rigor.
- If a scenario the user cares about isn't in the Behavior Table, the spec is incomplete. Fix the spec before starting implementation; that is the entire point.
- Once the user has signed off, **TDD from the spec is mechanical**: translate each `#### Test:` into a test function in the target framework, translate each assertion slug into an `assert`/`expect` call with the same name, run the suite, watch it fail, implement, watch it pass. No design decisions happen during coding — they have all been made in the spec.
- A spec that only covers the happy path is a draft. The Base/Edge split and the happy/bad/positive/negative coverage requirements exist specifically to prevent happy-path-only specs from shipping.

---

**Namespace**: acp  
**Command**: spec  
**Version**: 1.0.0  
**Created**: 2026-04-22  
**Last Updated**: 2026-04-22  
**Status**: Active  
**Compatibility**: ACP 3.13.0+  
**Author**: ACP Project  
