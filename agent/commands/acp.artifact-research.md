# Command: artifact-research

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.artifact-research` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.artifact-research NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-03-17  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Create long-lived research artifacts via systematic investigation with web/MCP integration and quality standards  
**Category**: Entity Creation  
**Frequency**: As Needed  

---

## Arguments

**CLI-Style Arguments**:
- `<topic>` (positional) - The research topic (e.g., "GraphQL federation patterns")
- `--from-clarification <file>` - Pull topic and context from clarification file
- `--output <path>` or `-o <path>` - Custom output path (default: auto-numbered in `agent/artifacts/`)
- `--shallow` - Skip web research and MCP tools, codebase only
- `--auto-commit` - Auto-commit the artifact after creation (default: true)
- `--no-commit` - Skip auto-commit, leave artifact staged

**Natural Language Arguments**:
- `@acp.artifact-research GraphQL federation patterns` - Research a specific topic
- `@acp.artifact-research authentication` - Research from conversation context
- `@acp.artifact-research --from-clarification clarification-12` - Pull topic from clarification
- `@acp.artifact-research` - Infer topic from current context

**Argument Mapping**:
The agent infers intent from context:
1. If explicit topic provided → research that
2. If `--from-clarification` → extract topic and context from clarification
3. If no arguments → infer from current task, milestone, or conversation context
4. If still ambiguous → prompt user for topic

---

## What This Command Does

This command creates high-quality, commit-ready research artifacts through a systematic, plan-first methodology. Unlike ephemeral reports or ad-hoc notes, research artifacts are permanent reference documents designed to survive across sessions and inform future decisions.

The command follows an academic research approach:
1. **Plan** - Generate research plan (gaps, considerations, outline)
2. **Execute** - Research systematically (WebSearch, MCP tools, codebase)
3. **Fill** - Populate sections progressively with citations
4. **Sanity Check** - Verify completeness, identify cascading impacts, discover new gaps
5. **Synthesize** - Generate analysis, conclusions, recommendations

All findings require exact citations with confidence scores (1-10) and reproducible verification processes. Conflicting sources trigger git conflict markers for user resolution.

---

## Prerequisites

- [ ] ACP installed in current directory (`agent/` directory exists)
- [ ] `agent/artifacts/` directory exists (will be created if not)
- [ ] `agent/artifacts/research.template.md` exists

---

## Steps

### 1. Determine Research Topic

Identify what to research.

**Actions**:
- If `--from-clarification <file>` provided:
  - Read the clarification file
  - Extract topic from clarification title, description, or questions
  - Extract any relevant context (decisions, constraints, questions)
- If positional `<topic>` argument provided:
  - Use that as the research topic directly
- If no arguments:
  - Infer from current conversation context (active task, recent discussion)
  - Check for clarifications with status "Captured" that mention research needs
- If still unclear:
  - Prompt user: "What topic would you like to research?"

**Expected Outcome**: Clear research topic identified (e.g., "GraphQL federation patterns in microservices")  

### 2. Generate Research Plan

Create a structured research plan before execution.

**Actions**:
- **Identify gaps**: What don't we know? What questions need answers?
- **Identify considerations**: What aspects matter? (performance, security, cost, DX, adoption)
- **List topics**: Break research into logical sub-topics
- **Create outline**: Map topics to artifact sections (6 core + optional)
- **Identify tools**: Check available MCP tools, determine if web research needed
- **Prompt user for refinement**: Show plan, ask "Is this the right scope? Should I go broad or granular?"

**Research plan format**:
```markdown
## Research Plan: {topic}

### Gaps to Fill
- [ ] What is {aspect}?
- [ ] How does {technology} compare to {alternatives}?
- [ ] What are known gotchas?

### Considerations
- Performance characteristics
- Security implications
- Integration complexity
- Community support

### Topics (Outline Mapping)
1. {Topic 1} → Detailed Analysis section
2. {Topic 2} → Detailed Analysis section
3. {Comparison matrix} → Comparison Matrix section (optional)
4. {Performance data} → Performance Benchmarks section (optional)

### Research Tools
- WebSearch/WebFetch: {yes/no - why?}
- MCP Tools: {list available tools if any}
- Codebase: {yes/no - what to search for?}

### Scope
- In scope: {what will be researched}
- Out of scope: {what is explicitly excluded}
```

**User refinement**:
- Display plan to user
- Ask: "Is this the right scope? Should I go broad or granular? Any specific areas to focus on?"
- Wait for user response
- Adjust plan based on feedback

**If multiple loosely-coupled topics detected**:
- Prompt: "I notice this research spans {topic A} and {topic B}. These seem loosely coupled. Should I split this into two research artifacts?"
- If user agrees → create separate artifacts (recursively invoke command twice)

**Expected Outcome**: Approved research plan with clear scope, topics, and tool strategy  

### 3. Execute Research

Systematically research each topic in the plan.

**Actions for each topic**:

**3a. Codebase Research** (if applicable):
- Use Glob to find relevant files
- Use Grep to search for patterns, keywords, imports
- Read relevant files to understand current implementation
- Note code pointers (`file:line`) for key locations
- Extract current patterns, conventions, or approaches

**3b. Web Research** (if `--shallow` not set):
- Use WebSearch to find:
  - Official documentation
  - Vendor comparisons
  - Community discussions (GitHub issues, Stack Overflow, Reddit)
  - Blog posts from reputable sources
  - Performance benchmarks from third parties
- Use WebFetch to read full content of promising sources
- For each finding, capture:
  - **Exact URL** (full URL, not shortened)
  - **Date accessed** (YYYY-MM-DD)
  - **Version number** if applicable (library v2.1.0, API v3)
  - **Confidence score** (1-10): How reliable is this source?
    - 9-10: Official docs, peer-reviewed papers, verified benchmarks
    - 5-8: Reputable blogs, community consensus, vendor claims
    - 1-4: Unverified claims, single-source anecdotes, outdated info
  - **Verification process**: How to independently verify this claim?

**3c. MCP Tool Invocation** (if available and `--shallow` not set):
- If user has MCP tools configured (GitHub, GitLab, vendor APIs):
  - Use tools to gather rich data (repo stats, issue response times, release history)
  - Cite tool invocation results with timestamps
  - Note any rate limits or auth failures (user handles resolution)

**3d. Conflict Detection**:
- If multiple sources disagree on a finding:
  - Use git conflict marker format:
    ```markdown
    <<<<<<< Source A: {source-name-date}
    {finding from source A}
    Source: {URL}
    Confidence: {score}
    =======
    {finding from source B}
    Source: {URL}
    Confidence: {score}
    >>>>>>> Source B: {source-name-date}

    [Agent note: Conflict detected. Sources disagree on {aspect}. Resolution needed before commit.]
    ```
  - Do NOT auto-resolve conflicts
  - Flag conflict in sanity check

**3e. Code Example Strategy**:
- **Local project files**: Use relative paths (`../../src/components/Button.tsx`)
- **External repos**: Convert to GitHub/GitLab URLs with line anchors
  - Format: `https://github.com/org/repo/blob/main/src/file.ts#L42`
- **Critical code**: Always inline (survives link rot)
- **Non-critical code**: Remote link acceptable
- **Unreachable remote**: Fallback to inline with "Source unavailable" note

**Expected Outcome**: All topics researched with citations, confidence scores, verification processes  

### 4. Fill Artifact Sections

Populate the research artifact progressively.

**Actions**:
- Start from template: `agent/artifacts/research.template.md`
- Fill metadata block:
  - **Type**: research
  - **Created**: Today's date (YYYY-MM-DD)
  - **Last Verified**: Same as Created
  - **Status**: Active
  - **Confidence**: Overall confidence (average of finding scores)
  - **Category**: Domain-specific category (infer from topic)
  - **Sources**: List of all primary sources
- Fill **Executive Summary** (100-300 words):
  - TL;DR of findings
  - Primary recommendation (if clear winner)
  - Critical gotchas readers must know immediately
- Fill **Research Context**:
  - Why this research was conducted (gap being filled)
  - Initial questions from research plan
  - Scope (in/out)
- Fill **Key Findings** (bullets/numbered):
  - Each finding with citation, confidence, verification process
  - Use verification format from Step 3
- Fill **Detailed Analysis**:
  - In-depth exploration by topic
  - Organize with sub-headings for each research topic
  - Include comparisons, tradeoff tables, code examples
- Fill **Sources & References**:
  - All URLs with exact attribution
  - Date accessed for each
  - Version numbers where applicable

**Optional sections** (include only when relevant):
- **Recommendations**: If clear action items emerge
- **Comparison Matrix**: If comparing vendors/libraries
- **Code Examples**: If demonstrating integration patterns
- **Integration Notes**: If explaining how tech fits project architecture
- **Limitations & Gaps**: If known unknowns remain
- **Migration Path**: If adoption steps are clear
- **Security & Compliance**: If security/license considerations exist
- **Performance Benchmarks**: If performance data was found
- **Community & Support**: If evaluating vendor/library maturity

**Quality enforcement**:
- Every claim must cite a source
- No "TODO" or placeholder text
- No unsupported opinions
- Confidence score for every finding
- Verification process documented

**Expected Outcome**: Research artifact file populated with all findings  

### 5. Sanity Check Loop

Verify completeness and identify gaps.

**Actions**:
- **Completeness check**:
  - Are all gaps from research plan addressed?
  - Are all questions from research context answered?
  - Are all sections complete (no placeholders)?
- **Cascading impacts check**:
  - Did research reveal new questions?
  - Do findings imply additional research areas?
  - Are there related topics that now need investigation?
- **New gaps check**:
  - Are there unanswered questions in the findings?
  - Are there conflicting sources still unresolved?
  - Are there missing verification processes?
- **Conflict resolution check**:
  - Are there unresolved git conflict markers?
  - If yes: Flag for user resolution, do NOT commit

**If new gaps discovered**:
- Option A: Extend current research (if closely related)
- Option B: Note in "Limitations & Gaps" section for follow-up research
- Prompt user: "I found additional gaps: {list}. Should I extend this research or note them for follow-up?"

**If conflicts detected**:
- Notify user: "Conflicting sources detected. Review conflict markers and resolve before commit."
- Do NOT proceed to Step 6 (auto-commit) if conflicts exist

**Expected Outcome**: Artifact verified complete, conflicts flagged, new gaps handled  

### 6. Synthesize (Analysis & Recommendations)

Generate synthesis sections if appropriate.

**Actions**:
- **Analysis**: Cross-finding synthesis
  - What patterns emerge across findings?
  - What are the key tradeoffs?
  - What are the implications for the project?
- **Conclusions**: Bottom-line takeaways
  - What did we learn?
  - What are the most important findings?
- **Recommendations** (if appropriate):
  - Specific actions ranked by priority/confidence
  - Rationale for each recommendation
  - Expected impact and effort
  - Only include if research provides enough data to recommend

**Synthesis guidelines**:
- Don't just summarize — synthesize (find connections, patterns, implications)
- Tie back to original research questions
- Be explicit about confidence level of conclusions
- Note where more research is needed

**Expected Outcome**: Synthesis sections added to artifact  

### 7. Auto-Commit (unless `--no-commit`)

Establish baseline commit for the artifact.

**Actions**:
- Determine next artifact number:
  - List files in `agent/artifacts/` matching `research-*`
  - Parse highest number, increment by 1
- Create file: `agent/artifacts/research-{N}-{topic-slug}.md`
  - Topic slug: kebab-case, derived from topic
  - Example: "GraphQL federation patterns" → "graphql-federation-patterns"
- If `--output <path>` provided, use that path instead
- If conflicts detected in Step 5:
  - Do NOT commit
  - Leave file unstaged
  - Notify user to resolve conflicts
- If no conflicts and `--auto-commit` (default):
  - `git add agent/artifacts/research-{N}-{topic-slug}.md`
  - Commit message: `docs(artifact): research {topic-slug} (research-{N})`
  - Notify user: "Baseline committed. Review and refine with visible git diff."
- If `--no-commit`:
  - Leave file staged but uncommitted
  - Notify user: "Artifact created, staged, awaiting commit."

**Expected Outcome**: Research artifact committed (or staged if conflicts/--no-commit)  

### 8. Report Success

Display what was produced.

**Output format**:
```
✅ Research Artifact Created!

File: agent/artifacts/research-{N}-{topic-slug}.md
Topic: {topic}
Confidence: {score}/10
Sections: {count} ({core-count} core + {optional-count} optional)
Findings: {count}
Sources: {count}
Status: {Active|WIP|Conflicted}

{If conflicts: "⚠️  Conflicts detected. Resolve git markers before commit."}
{If auto-committed: "✓ Baseline committed. Refine with `git diff` and amend."}
{If --no-commit: "ℹ️  Staged, not committed. Review and commit when ready."}

Next steps:
- Review the artifact for accuracy
- {If conflicts: Resolve conflict markers}
- {If committed: Refine findings and `git commit --amend`}
- {If gaps noted: Consider follow-up research for: {gap-list}}
```

**Expected Outcome**: User knows artifact is complete and where to find it  

---

## Verification

- [ ] Research topic identified (explicit or inferred)
- [ ] Research plan generated and user-approved
- [ ] Systematic research executed (codebase, web, MCP tools)
- [ ] All findings have citations + confidence scores + verification processes
- [ ] No "TODO" or placeholder text in artifact
- [ ] Executive Summary is 100-300 words
- [ ] Metadata block complete (all required fields)
- [ ] Sources & References section lists all URLs with access dates
- [ ] Conflicting sources use git conflict markers (not auto-resolved)
- [ ] Artifact file created in `agent/artifacts/research-{N}-{topic-slug}.md`
- [ ] Auto-commit executed (unless conflicts or `--no-commit`)
- [ ] Success message displayed

---

## Expected Output

### Files Created
- `agent/artifacts/research-{N}-{topic-slug}.md` - Research artifact

### Files Modified
- None (unless follow-up research extends existing artifact)

### Console Output
```
✅ Research Artifact Created!

File: agent/artifacts/research-1-graphql-federation-patterns.md
Topic: GraphQL federation patterns in microservices
Confidence: 8/10
Sections: 9 (6 core + 3 optional)
Findings: 12
Sources: 8
Status: Active

✓ Baseline committed. Refine with `git diff` and amend.

Next steps:
- Review the artifact for accuracy
- Refine findings and `git commit --amend`
```

---

## Examples

### Example 1: Research from Topic

**Context**: Need to understand GraphQL federation before architectural decision  

**Invocation**: `@acp.artifact-research GraphQL federation patterns`  

**Result**: Agent generates research plan, searches official docs + community discussions, compares federation vs schema stitching, captures performance benchmarks, creates `research-1-graphql-federation-patterns.md` with citations and confidence scores. Auto-commits baseline.  

### Example 2: Research from Clarification

**Context**: Clarification-12 captured decision to use JWT auth but noted "research JWT best practices"  

**Invocation**: `@acp.artifact-research --from-clarification clarification-12`  

**Result**: Agent extracts "JWT best practices" topic from clarification, researches token expiration strategies, refresh token patterns, storage security, creates artifact with recommendations, auto-commits.  

### Example 3: Quick Codebase-Only Research

**Context**: Need to understand current error handling patterns before refactor  

**Invocation**: `@acp.artifact-research error handling --shallow`  

**Result**: Agent scans codebase for error handling patterns, catalogs approaches across files, notes inconsistencies, creates lightweight artifact (no web research), auto-commits.  

### Example 4: Research with MCP Tools

**Context**: Evaluating vendor API, have GitHub MCP tool configured  

**Invocation**: `@acp.artifact-research Stripe API integration`  

**Result**: Agent uses WebSearch for Stripe docs, invokes GitHub MCP to check Stripe SDK repo stats (stars, issues, release cadence), captures community sentiment from Reddit/Twitter via web, creates comprehensive evaluation with vendor support metrics, auto-commits.  

### Example 5: Conflicting Sources

**Context**: Researching Redis persistence options, sources disagree on RDB vs AOF performance  

**Invocation**: `@acp.artifact-research Redis persistence strategies`  

**Result**: Agent finds vendor blog claiming "RDB is faster" and independent benchmark claiming "AOF is faster under load". Uses git conflict markers to preserve both findings. Does NOT auto-commit. Prompts user to resolve conflict.  

---

## Related Commands

- [`@acp.artifact-glossary`](acp.artifact-glossary.md) - Create terminology glossaries
- [`@acp.artifact-reference`](acp.artifact-reference.md) - Create reference guides (after command-first check)
- [`@acp.clarification-address`](acp.clarification-address.md) - Address clarifications (can trigger research)
- [`@acp.audit`](acp.audit.md) - Deep-dive investigation with ephemeral reports (not committed)
- [`@acp.sync`](acp.sync.md) - Detect artifact staleness after code changes

---

## Troubleshooting

### Issue 1: No web research results

**Symptom**: WebSearch returns no useful results for topic  

**Cause**: Topic too niche, or phrasing doesn't match common search terms  

**Solution**: Try alternative phrasings, break into sub-topics, or use `--shallow` for codebase-only research  

### Issue 2: Too many findings, artifact unwieldy

**Symptom**: Research uncovers 50+ findings, artifact is hundreds of lines  

**Cause**: Topic too broad or insufficiently scoped  

**Solution**: Split into multiple artifacts (one per sub-topic), or note additional topics in "Limitations & Gaps" for follow-up  

### Issue 3: Conflicting sources, can't decide

**Symptom**: Multiple sources disagree, unclear which is correct  

**Cause**: Technology landscape is legitimately contentious, or sources are outdated  

**Solution**: Use git conflict markers to preserve both views. User resolves based on project constraints. If time-sensitive, note in "Limitations & Gaps" and proceed with lower confidence score.  

### Issue 4: MCP tool not available

**Symptom**: User mentions MCP tool but agent can't access it  

**Cause**: MCP tool not configured in user's environment  

**Solution**: Skip MCP tool invocation, rely on web research. Note in artifact: "MCP tool {name} not available; data gathered via web research only."  

---

## Security Considerations

### File Access
- **Reads**: Any file in the project (for codebase research)
- **Writes**: `agent/artifacts/research-{N}-{topic-slug}.md` only
- **Executes**: `git add`, `git commit` (if auto-commit)

### Network Access
- **APIs**: WebSearch, WebFetch (if not `--shallow`)
- **MCP Tools**: User-configured tools only (agent does not install or configure)
- **Repositories**: Local git only (no remote push)

### Sensitive Data
- **Secrets**: Never include credentials, API keys, or secrets in artifacts
- **Private data**: If research uncovers private config, note existence but do not include contents
- **External sources**: Cite public URLs only; do not scrape private/authenticated content

---

## Key Design Decisions

### Research Methodology

| Decision | Choice | Rationale |
|---|---|---|
| Research approach | Plan-first (gaps → outline → execute → sanity check → synthesize) | Academic methodology prevents meandering research, catches cascading impacts early |
| Quality standard | Citation + confidence + verification process per finding | Makes research auditable and reproducible; explicit about reliability |
| Conflict handling | Git conflict markers, manual resolution required | Familiar workflow, forces user judgment, prevents silent loss of conflicting data |
| Scope refinement | User approval of research plan before execution | Prevents scope creep, aligns agent's work with user's expectations |
| Multi-topic detection | Prompt to split if loosely coupled | Keeps artifacts focused; avoids bloated documents covering disparate topics |

### Tool Integration

| Decision | Choice | Rationale |
|---|---|---|
| Web research | Yes (unless `--shallow`) | External knowledge is core value-add; codebase-only research has limited utility for most topics |
| MCP tool usage | Conditional (if user-configured) | MCP tools provide rich data but setup is user responsibility; agent uses if available |
| Code examples | Context-based (critical inline, non-critical remote) | Balances portability (remote readers) with permanence (critical survives link rot) |
| External repos | Convert to GitHub URLs with line anchors | Makes examples permanent and IDE-clickable |

### Artifact Lifecycle

| Decision | Choice | Rationale |
|---|---|---|
| Auto-commit | Yes (default), unless conflicts or `--no-commit` | Establishes baseline, enables visible git diff for refinements |
| Conflict resolution | User-driven, not auto-resolved | Agent cannot make judgment calls on conflicting claims; user context required |
| Living document | Edit in place (git history preserves versions) | Single canonical version per topic; git log shows evolution |
| Staleness detection | Via `@acp.sync` (separate command) | Artifact creation is independent of maintenance; sync command handles updates |

### Quality Enforcement

| Decision | Choice | Rationale |
|---|---|---|
| Mandatory citation | Yes (every finding must cite source) | Prevents unsourced claims, makes research transparent |
| Confidence scoring | Yes (1-10 per finding) | Explicit about reliability; helps readers assess trustworthiness |
| Verification process | Yes (how to independently verify) | Makes research reproducible; readers can re-validate claims |
| No placeholders | Yes (no "TODO", no "research this later") | Artifacts are commit-ready, not drafts; completeness enforced |

---

## Notes

- Research artifacts are permanent reference documents, not ephemeral reports
- The agent enforces quality through structure (mandatory fields) and prompt engineering ("critical foundational document, no stone unturned")
- Artifacts are tracked in `agent/artifacts/` but NOT in progress.yaml (they're reference material, not work items)
- Artifacts can be referenced in key file index (`agent/index/*.yaml`) for discoverability
- Clarification capture directive can be invoked to preserve ephemeral decisions before they're lost

---

**Namespace**: acp  
**Command**: artifact-research  
**Version**: 1.0.0  
**Created**: 2026-03-17  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Compatibility**: ACP 5.24.0+  
**Author**: ACP Project  
