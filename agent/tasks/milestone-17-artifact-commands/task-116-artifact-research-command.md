# Task 116: Implement @acp.artifact-research Command

**Status**: completed  
**Priority**: high  
**Milestone**: M17 (Artifact Commands System)  
**Design Reference**: [Artifact Commands System](../../design/local.artifact-commands-system.md)  
**Estimated Time**: 4-6 hours  
**Started**: 2026-03-17  
**Completed**: 2026-03-17  

---

## Objective

Implement the `@acp.artifact-research` command that creates high-quality, commit-ready research artifacts through systematic investigation with web/MCP integration, citation requirements, and conflict handling.

---

## Requirements

1. Implement plan-first research methodology (gaps → outline → execute → sanity check → synthesize)
2. Support multiple research sources (codebase, web, MCP tools)
3. Enforce quality standards (citation + confidence scoring + verification processes)
4. Handle conflicting sources with git conflict markers
5. Support `--shallow` mode for codebase-only research
6. Auto-commit baseline by default (with `--no-commit` option)
7. Integrate with research artifact template
8. Support topic inference from context, clarifications, or explicit arguments

---

## Implementation

### Command Structure

**File**: `agent/commands/acp.artifact-research.md`  

**Metadata**:
- Namespace: acp
- Version: 1.0.0
- Category: Entity Creation
- Scripts: None (LLM-based command)

### Arguments

**Positional**:
- `<topic>` - Research topic

**Flags**:
- `--from-clarification <file>` - Pull topic from clarification
- `--output <path>` / `-o <path>` - Custom output path
- `--shallow` - Skip web research and MCP tools
- `--auto-commit` - Auto-commit after creation (default: true)
- `--no-commit` - Skip auto-commit

### Steps

**1. Determine Research Topic**
- From positional argument, `--from-clarification`, or inferred from context
- Prompt user if ambiguous

**2. Generate Research Plan**
- Identify gaps (what don't we know?)
- Identify considerations (performance, security, cost, DX)
- List topics and map to outline
- Identify available tools (MCP, web, codebase)
- Prompt user for scope refinement: "broad or granular?"
- Detect multi-topic scenarios, offer to split

**3. Execute Research**
- **Codebase**: Glob/Grep/Read for patterns, code pointers
- **Web**: WebSearch/WebFetch for docs, comparisons, benchmarks (if not `--shallow`)
- **MCP Tools**: Invoke if available (GitHub, GitLab, vendor APIs) (if not `--shallow`)
- **Capture per finding**:
  - Exact URL + date accessed
  - Version number (if applicable)
  - Confidence score (1-10): 9-10 official, 5-8 reputable, 1-4 unverified
  - Verification process (how to independently verify)
- **Conflict detection**: If sources disagree, use git conflict markers:
  ```markdown
  <<<<<<< Source A: {name-date}
  {finding A}
  =======
  {finding B}
  >>>>>>> Source B: {name-date}
  ```

**4. Fill Artifact Sections**
- Start from template: `agent/artifacts/research.template.md`
- Fill metadata block (Type, Created, Last Verified, Status, Confidence, Category, Sources)
- Fill Executive Summary (100-300 words: TL;DR, recommendation, gotchas)
- Fill Research Context (why, questions, scope)
- Fill Key Findings (bullets with citation + confidence + verification)
- Fill Detailed Analysis (in-depth by topic)
- Fill Sources & References (all URLs with attribution)
- Fill optional sections only when relevant (Recommendations, Comparison Matrix, etc.)

**5. Sanity Check Loop**
- Completeness: All gaps addressed?
- Cascading impacts: New questions revealed?
- New gaps: Unanswered questions remaining?
- Conflict resolution: Unresolved git markers?
- Prompt user if new gaps found: "Extend or note for follow-up?"

**6. Synthesize**
- Analysis: Cross-finding patterns, key tradeoffs, implications
- Conclusions: Bottom-line takeaways
- Recommendations: Specific actions (if data supports)

**7. Auto-Commit**
- Determine next artifact number
- Create file: `agent/artifacts/research-{N}-{topic-slug}.md`
- If conflicts: Do NOT commit, notify user
- If no conflicts and `--auto-commit`: Commit with message `docs(artifact): research {topic-slug}`
- If `--no-commit`: Stage but do not commit

**8. Report Success**
- Display file path, topic, confidence, sections, findings, sources, status
- Flag conflicts if detected
- Note next steps (review, resolve conflicts, refine)

### Quality Enforcement

- **Every claim must cite a source** (no unsourced opinions)
- **No "TODO" or placeholder text** (commit-ready only)
- **Confidence score for every finding** (explicit reliability)
- **Verification process documented** (reproducible research)
- **Git conflict markers for disagreements** (manual resolution required)

### Code Example Strategy

- **Local files**: Relative paths (`../../src/file.tsx`)
- **External repos**: GitHub URLs with line anchors (`https://github.com/org/repo/blob/main/src/file.ts#L42`)
- **Critical code**: Always inline (survives link rot)
- **Non-critical code**: Remote link acceptable
- **Unreachable remote**: Inline with "Source unavailable" note

---

## Testing

### Manual Testing

- [x] Command file created with full directive structure
- [x] 8 steps implemented with detailed actions
- [x] Arguments section covers CLI + natural language
- [x] Examples section shows 5 use cases
- [x] Related Commands section links to other artifact commands
- [x] Troubleshooting section covers common issues
- [x] Security Considerations section covers file/network access
- [x] Key Design Decisions section captures rationale

### Validation Checks

- [x] Agent directive header present
- [x] Metadata block complete (namespace, version, status, scripts)
- [x] Prerequisites listed
- [x] Verification checklist present
- [x] Expected Output section shows files created/modified
- [x] Follows existing command pattern (acp.audit.md, acp.clarification-address.md)

### Integration Points

- [x] References research artifact template
- [x] Uses git conflict markers for conflicts
- [x] Integrates with clarification system via `--from-clarification`
- [x] Auto-commit workflow for baseline establishment
- [x] Shallow mode for codebase-only research

---

## Files Created

1. `agent/commands/acp.artifact-research.md` (677 lines)

---

## Files Modified

1. `package.yaml` - Added acp.artifact-research.md to commands list

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Research methodology | Plan-first (gaps → outline → execute → sanity → synthesize) | Academic approach prevents meandering, catches cascading impacts |
| Quality standard | Citation + confidence + verification per finding | Makes research auditable and reproducible |
| Conflict handling | Git conflict markers, manual resolution | Familiar workflow, forces user judgment |
| Scope refinement | User approval of plan before execution | Prevents scope creep, aligns expectations |
| Web research | Default enabled, `--shallow` to disable | External knowledge is core value-add |
| MCP tools | Conditional (if user-configured) | Rich data but setup is user responsibility |
| Auto-commit | Default enabled, `--no-commit` to disable | Establishes baseline, enables visible diff |
| Code examples | Context-based (critical inline, non-critical remote) | Balances permanence with maintainability |

---

## Integration Points

- **@acp.artifact-glossary**: Related artifact command (glossaries)
- **@acp.artifact-reference**: Related artifact command (references)
- **@acp.clarification-address**: Can trigger research via `--from-clarification`
- **@acp.audit**: Similar investigation, but ephemeral reports (not committed)
- **@acp.sync**: Will detect artifact staleness (future integration)

---

## Notes

- Command implements full plan-first research methodology from design doc
- Quality enforcement through mandatory citation + confidence + verification
- Git conflict markers preserve conflicting sources without auto-resolution
- Auto-commit workflow enables baseline + visible diff refinement
- Shallow mode provides quick codebase-only research option
- MCP tool integration is conditional (user-configured tools only)
- Artifacts are permanent reference documents, not ephemeral reports
- Artifacts tracked in `agent/artifacts/` but NOT in progress.yaml

Ready for testing with real research scenarios.
