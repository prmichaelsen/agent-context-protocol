# Artifact Commands System

**Concept**: Long-lived reference material creation via systematic research with web/MCP integration  
**Created**: 2026-03-17  
**Status**: Design Specification  

---

## Overview

The Artifact Commands System introduces a new document type (`agent/artifacts/`) for permanent, high-quality reference material created through systematic research. Unlike ephemeral reports, volatile clarifications, or architectural designs, artifacts capture external knowledge that informs decisions without being decisions themselves.

Three artifact types are supported: **research** (investigative deep-dives), **glossary** (project terminology), and **reference** (quick-lookup guides). Each artifact undergoes rigorous quality standards with citation requirements, confidence scoring, and reproducible verification processes.

**Core principle**: Command-first — if information can be automated as an executable directive (`@local.*` or `@namespace.*`), create a command instead of a reference artifact.  

---

## Problem Statement

### Current Gap

Projects lack a structured way to capture long-lived external knowledge:
- **Research findings** are lost in chat history or scattered across issues/PRs
- **Terminology** remains tribal knowledge, causing onboarding friction
- **Reference guides** (schemas, formats, conventions) are either non-existent or buried in READMEs
- **Ad-hoc reports** capture point-in-time analysis but aren't maintained as technology evolves

### Consequences

- Repeated research (agents re-Google the same information every session)
- Inconsistent terminology across docs/code
- New team members struggle with project-specific concepts
- Stale documentation (no clear owner or update mechanism)
- Decision-making delayed by missing context

### Why This Matters

Artifacts fill the gap between "I keep looking this up" and "this belongs in formal documentation." They provide permanent, version-controlled reference material that remains accessible as the project evolves.

---

## Solution

### High-Level Approach

Introduce three artifact command types (`@acp.artifact-research`, `@acp.artifact-glossary`, `@acp.artifact-reference`) that create high-quality, commit-ready documents through systematic, agent-driven workflows.

**Research artifacts** follow a plan-first methodology:
1. Generate research plan (gaps, considerations, topics, outline)
2. Execute research systematically (WebSearch, MCP tools, codebase exploration)
3. Fill sections progressively
4. Sanity check loop (completeness, cascading impacts, new gaps)
5. Synthesize (analysis, conclusions, key findings, recommendations)

**Glossary artifacts** auto-extract terminology from code/docs with interactive refinement:
1. Scan codebase for terms (classes, interfaces, CamelCase patterns)
2. Generate definitions from context
3. Prompt user for ambiguity resolution and missing definitions
4. Organize into category-grouped tables with alphabetical index

**Reference artifacts** undergo command-first sanity check:
1. Before creating reference, evaluate: "Could this be a command instead?"
2. If executable → suggest `@local.*` command creation
3. If informational → proceed with reference artifact
4. Focuses on passive information (lookup tables, diagrams, standards)

### Key Components

- **`agent/artifacts/`** directory for all artifact types
- **File naming**: `{type}-{N}-{title}.md` (e.g., `research-5-graphql-federation.md`)
- **Separate templates** per artifact type (research/glossary/reference)
- **Quality enforcement** via prompt engineering and verification checklists
- **Auto-commit** workflow (establish baseline, user refines with visible diffs)
- **Integration** with `@acp.sync`, `@acp.validate`, key file index system

### Alternative Approaches Rejected

**Option A: Single artifact command with `--type` flag** — Rejected because each artifact type has fundamentally different workflows (research plan vs term extraction vs command-first check)

**Option B: Artifacts tracked in progress.yaml** — Rejected because artifacts aren't work items (tasks/milestones). They're reference material better suited for key file index.

**Option C: Inline `>` response replacement for research** — Rejected in favor of HTML comment blocks to never modify user content

**Option D: Multiple versioned glossaries** — Start with single living document until 50+ terms, then refactor to hybrid approach if needed

---

## Implementation

### Directory Structure

```
agent/
├── artifacts/
│   ├── research-1-api-vendor-comparison.md
│   ├── research-2-authentication-patterns.md
│   ├── glossary-1-core-terminology.md
│   └── reference-1-environment-variables.md
├── artifacts/
│   ├── research.template.md
│   ├── glossary.template.md
│   └── reference.template.md
```

### Artifact Metadata (All Types)

```markdown
# {Artifact Title}

**Type**: research | glossary | reference  
**Created**: YYYY-MM-DD  
**Last Verified**: YYYY-MM-DD  
**Status**: Active | Stale | Deprecated  
**Confidence**: High (9-10/10) | Medium (5-8/10) | Low (1-4/10)  
**Category**: {domain-specific, e.g., "API Integration", "Infrastructure", "Security"}  
**Sources**: [List of primary sources with access dates]  
```

### Research Artifact Structure

**Core Sections** (always include):
1. **Metadata Block** — Created, Last Verified, Status, Confidence, Version refs
2. **Executive Summary** (100-300 words) — TL;DR, primary recommendation, critical gotchas
3. **Research Context** — Why conducted, what gap it fills, initial questions, scope
4. **Key Findings** (bullets/numbered) — Critical discoveries with version numbers/dates
5. **Detailed Analysis** — In-depth exploration by topic, comparisons, tradeoff tables, code examples
6. **Sources & References** — All URLs, date accessed, attribution

**Optional Sections** (when relevant):
7. **Recommendations** — Specific actions, ranked by priority/confidence
8. **Code Examples** — Inline snippets with version annotations
9. **Comparison Matrix** — Side-by-side tables for vendor/library selection
10. **Integration Notes** — How tech integrates with project architecture
11. **Limitations & Gaps** — Known unknowns, areas requiring follow-up
12. **Migration Path** — Steps to adopt researched solution
13. **Security & Compliance** — Security considerations, license compatibility
14. **Performance Benchmarks** — External benchmark data
15. **Community & Support** — GitHub stars, issue response time, vendor support

### Research Verification Format

```markdown
**Finding**: [Statement with version/date]  
- **Source**: [Exact URL] (accessed 2026-03-17)
- **Confidence**: High (9/10)
- **Verification**:
  - Cross-referenced with [source B]
  - Tested claim against [official docs v2.1.0]
  - Confirmed by [community discussion]
- **How to verify**: [Step-by-step reproducible process]
```

### Glossary Artifact Structure

```markdown
# Project Glossary

## Architecture (Category)
| Term | Definition |
|------|------------|
| API Gateway | Central entry point that routes requests to microservices |
| Microservice | Self-contained service with single responsibility |

## Data (Category)
| Term | Definition |
|------|------------|
| Event Sourcing | Pattern where state changes are stored as events |
| CQRS | Command Query Responsibility Segregation pattern |

## Alphabetical Index
[A](#a) | [C](#c) | [E](#e) | [M](#m)

### A
- **API Gateway** → Architecture

### C
- **CQRS** → Data
```

### Reference Artifact Use Cases (After Command-First Filter)

**Appropriate for references** (passive information):
- Generic CLI syntax (Git, Docker, SQL — not project-specific)
- Configuration tables (environment variables, service URLs, feature flags)
- API/protocol contracts (API formats, message queue schemas)
- Architecture diagrams (service maps, data flows, deployment topology)
- Troubleshooting guides (diagnostic decision trees requiring human judgment)
- Standards/style guides (code style, commit format, documentation conventions)
- Data schemas (database ER diagrams, file format specifications)

**Should be commands instead** (executable procedures):
- Project-specific workflows (deploy, hotfix, release, feature start)
- Code scaffolding (API endpoint creation, test generation, migrations)
- Checklists with agent-followable steps (code review, onboarding)

### Conflict Handling (Git Markers)

```markdown
## Performance Benchmarks

<<<<<<< Source A: vendor-blog-2026-03-01
Average latency: 50ms (tested with 1000 req/s)
Source: https://vendor.com/blog/benchmarks
Confidence: Medium (vendor-reported, not independently verified)
=======
Average latency: 120ms (tested with 500 req/s)
Source: https://independent-benchmarks.org/vendor-analysis
Confidence: High (third-party verification)
>>>>>>> Source B: independent-benchmark-2026-02-15

[Agent note: Conflict detected. Sources disagree on performance. Resolution needed before commit.]
```

### Code Example Strategy

**Local project files**: Use relative paths  
```markdown
See: `../../src/components/Button.tsx`
```

**External project files**: Convert to GitHub/GitLab URLs  
```markdown
See: `https://github.com/org/repo/blob/main/src/file.ts#L42`
```

**Critical code**: Always inline (survives link rot)  
**Non-critical**: Remote link acceptable  
**Unreachable remote**: Fallback to inline  

### Integration with Existing Commands

**`@acp.validate`** — Check artifact Last Verified dates, warn about staleness
**`@acp.sync`** — Detect code changes affecting artifact content (new terms, changed commands)
**`@acp.update`** — Include artifact staleness in project health reports
**`@acp.artifact-refresh`** (new command) — Re-validate artifacts against current codebase

---

## Benefits

- **Permanent knowledge capture** — External knowledge survives beyond chat sessions and clarifications
- **Reproducible research** — Verification process documented, readers can re-validate findings
- **Command-first principle** — Reduces reference bloat by promoting executable directives
- **Living documents** — Artifacts evolve with technology (edit in place, git history preserves versions)
- **Quality enforcement** — Citation requirements, confidence scoring, sanity checks prevent low-quality artifacts
- **Git-native conflict resolution** — Familiar workflow for resolving conflicting sources
- **Discoverable** — Key file index integration makes artifacts visible during `@acp.init`
- **Context capture** — `@acp.clarification-capture` integration preserves decision rationale

---

## Trade-offs

- **Verbose artifacts** — Citation/verification requirements make artifacts longer (mitigated by Executive Summary for quick readers)
- **Upfront research cost** — Systematic research process is slower than ad-hoc notes (mitigated by long-term reusability)
- **Maintenance burden** — Living documents require periodic re-verification (mitigated by `@acp.sync` staleness detection)
- **Command boundary ambiguity** — Requires judgment to distinguish references from commands (mitigated by sanity check in Step 2.5)
- **Glossary categorization** — Auto-extracted terms need manual categorization (mitigated by agent-inferred suggestions)

---

## Dependencies

- **Web research tools** — WebSearch, WebFetch for external knowledge gathering
- **MCP tools** (optional) — GitHub, GitLab, vendor-specific MCP servers for rich integration
- **Codebase exploration** — Glob, Grep, Read for term extraction and code context
- **Key file index** — `agent/index/*.yaml` for artifact discoverability
- **Clarification capture** — `@acp.clarification-capture` directive for decision preservation
- **Git** — Conflict markers, auto-commit workflow, living document versioning

---

## Testing Strategy

### Unit Tests
- Artifact metadata parsing (Created, Last Verified, Status, Confidence)
- File naming validation (`{type}-{N}-{title}.md`)
- Template rendering for each artifact type

### Integration Tests
- E2E workflow: `@acp.artifact-research` → research plan → execution → commit
- Glossary extraction from sample codebase → category inference → user refinement
- Reference command-first sanity check → suggest command creation → fallback to reference
- Conflict detection → git markers → user resolution → commit

### Quality Tests
- Citation validation (all claims have sources + dates)
- Confidence score presence and range (1-10)
- Verification process documented for each finding
- No "TODO" or placeholder text in committed artifacts

### Staleness Tests
- `@acp.sync` detects outdated Last Verified dates
- `@acp.validate` warns about artifacts >6 months old
- Key file index integration loads artifacts correctly

---

## Migration Path

1. **Create artifact templates** — Add `research.template.md`, `glossary.template.md`, `reference.template.md` to `agent/artifacts/`
2. **Implement `@acp.artifact-research`** — Follow clarification-12 design for research workflow
3. **Implement `@acp.artifact-glossary`** — Auto-extraction + interactive refinement workflow
4. **Implement `@acp.artifact-reference`** — Command-first sanity check + reference creation
5. **Enhance `@acp.sync`** — Add artifact staleness detection logic
6. **Enhance `@acp.validate`** — Add artifact Last Verified date checks
7. **Update key file index schema** — Add `kind: artifact` support
8. **Documentation** — Add artifact examples to AGENT.md, update package system docs
9. **Test suite** — E2E tests for all three artifact types

---

## Key Design Decisions

### Artifact Document Type

| Decision | Choice | Rationale |
|---|---|---|
| Directory | `agent/artifacts/` | Separate from designs (architectural), patterns (code), reports (ephemeral) |
| File naming | `{type}-{N}-{title}.md` | Type prefix enables glob filtering, N ensures uniqueness, title is descriptive |
| Templates | Separate per subtype | Research, glossary, reference have distinct structure needs |
| Metadata | Created, Last Verified, Status, Confidence, Category, Sources | Tracks staleness, quality, and discoverability |
| Progress tracking | Not in progress.yaml, optionally in local.main.yaml | Artifacts aren't work items but are high-value reference material |
| Artifact subtypes | Research, glossary, reference only | Other candidates (audits, designs, patterns, reports) have existing homes |

### Research Command Design

| Decision | Choice | Rationale |
|---|---|---|
| Purpose | Capture long-lived artifacts not covered by existing tooling | Fills gap between "I keep looking this up" and "formal docs" |
| Topic input | Prompt if no context | Explicit scoping prevents scope creep |
| Research process | Plan-first: gaps → outline → execute → sanity check → synthesize | Academic methodology prevents meandering research, catches cascading impacts |
| Research tools | WebSearch + user MCP tools | MCP tools considered during plan generation for rich integration |
| Code exploration | Both local codebase + external repos | External repos provide context for library/API usage patterns |
| External service integration | MCP tool invocation if pre-configured | User responsibility to configure, agent uses if available |
| Artifact sections | 6 core + 9 optional (see Implementation) | Core ensures completeness, optional keeps minimal artifacts lightweight |
| Code examples | Context-based: critical inline, non-critical remote | Balances portability (remote readers) with permanence (critical survives link rot) |
| Quality standards | Citation + confidence + verification process per finding | Makes research auditable and reproducible |
| Auto-commit | Yes, establish baseline | Enables visible diff for user refinements |
| Multi-topic handling | Prompt for split if loosely coupled | Prevents bloated artifacts covering disparate topics |

### Quality Standards

| Decision | Choice | Rationale |
|---|---|---|
| High quality definition | Prompt engineering: "critical foundational document, bulletproof, no stone unturned" | Sets agent mindset for rigor |
| User review | Auto-commit (user reviews via git diff) | Baseline commit + visible refinements |
| Last Verified date | Yes | Tracks staleness for refresh decisions |
| Confidence score | Yes, per finding (1-10) | Indicates research completeness and reliability |
| Conflicting sources | Git conflict markers, do not commit | Familiar workflow, forces user resolution |
| Link rot mitigation | Context-based: inline critical, remote non-critical | Balances maintainability with permanence |
| Versioning | Edit in place (living documents) | Single canonical version, git history preserves all versions |

### Glossary Command Design

| Decision | Choice | Rationale |
|---|---|---|
| Living document count | Single until 50+ terms, then hybrid | Start simple, refactor when domain boundaries emerge |
| Entry structure | Category tables + alpha index | Category aids conceptual understanding, index aids fast lookup |
| Term extraction | Auto-extract, prompt for ambiguity/gaps | Balances automation with quality |

### Reference Command Design

| Decision | Choice | Rationale |
|---|---|---|
| Command-first principle | Sanity check before creating reference: "Could this be a command?" | References are passive info only; executable procedures become commands |
| Use cases | ~20 passive info types (see Implementation) | CLI syntax, config tables, diagrams, standards, schemas |
| Command suggestions | Step 2.5: suggest `@local.*` or `@namespace.*` | Reduces reference bloat, increases system power |

### Relationship to Existing Commands

| Decision | Choice | Rationale |
|---|---|---|
| Artifact vs Report | Reports are ephemeral (not committed) | Artifacts are committed, long-term, high-quality |
| Artifact vs Design | Unrelated; prompt users for clarification if gaps | Artifacts document external knowledge, designs document internal decisions |
| Progress tracking | Artifacts don't update progress.yaml | Artifacts are reference material, not work items |
| Clarification integration | Yes, via `@acp.clarification-capture` subroutine | Captures ephemeral decisions before loss |
| Capture into artifacts | Yes, clarifications can be captured into artifacts | Preserves decision rationale |

### User Workflow

| Decision | Choice | Rationale |
|---|---|---|
| Workflow | User prompts → agent researches → user reviews → commit | User controls scope and refinement |
| Scope refinement | Yes, prompt research plan: "broad or granular?" | Allows user to refine depth before execution |
| Incomplete research | Track incompleteness in artifact, prompt resolution strategy | Transparent about gaps, user decides next steps |
| WIP status | Yes, supported | Allows progressive refinement without committing incomplete work |
| Artifact discovery | List command + index file + search | Multiple access patterns for different use cases |
| Context capture flags | `--from-clarification`, `--from-design` | Pull in prior context for richer artifacts |

### External Service Integration

| Decision | Choice | Rationale |
|---|---|---|
| Service priority | Agent prompts: "I see I have access to {tools}, use in plan?" | User controls which services are invoked |
| MCP tool setup | Pre-configured by user | User responsibility, agent uses if available |
| Rate limits/auth failures | N/A (user handles) | Failures surface to user for manual resolution |
| Data caching | Cache to agent provider's standard (e.g., memory.md for Claude) | Leverage existing mechanisms |
| Security | Avoid secrets 100% | No credentials or secrets in committed artifacts |

### Artifact Lifecycle

| Decision | Choice | Rationale |
|---|---|---|
| Expiration date | No | Last Verified date sufficient for staleness tracking |
| Technology changes | `@acp.sync` command handles updates | Existing command extended, no new artifact-specific command |
| Refresh command | No, `@acp.sync` already does this | Avoids command proliferation |
| Archival/deprecation | Delete from repo, commit delete | Git history preserves, clean active set |
| Progress tracking | No | Artifacts aren't work items |

---

## Future Considerations

- **Artifact comparison** — Diff two research artifacts side-by-side for vendor selection
- **Multi-artifact research** — Research plan spans multiple artifacts automatically (e.g., vendor A, B, C each get separate artifact)
- **External artifact sources** — Import artifacts from other projects/packages
- **Artifact quality scoring** — Automated quality assessment based on citation density, verification completeness
- **Artifact templates from packages** — Packages can ship artifact templates for their domain
- **Cross-artifact references** — Glossary terms link to research artifacts, research artifacts reference glossary
- **Artifact changelog** — Track major updates in artifact metadata (Revision counter)

---

**Status**: Design Specification (Ready for Implementation)  
**Recommendation**: Create tasks for:  
1. Artifact templates creation
2. `@acp.artifact-research` command implementation
3. `@acp.artifact-glossary` command implementation
4. `@acp.artifact-reference` command implementation
5. Integration with `@acp.sync`, `@acp.validate`, key file index
**Related Documents**: clarification-12-artifact-commands.md (decisions captured here)  
