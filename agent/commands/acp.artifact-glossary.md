# Command: artifact-glossary

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.artifact-glossary` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp.artifact-glossary NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-03-17  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Create and maintain project glossaries through auto-extraction and interactive refinement  
**Category**: Entity Creation  
**Frequency**: As Needed  

---

## Arguments

**CLI-Style Arguments**:
- `--create` or `-c` - Create a new glossary (default if none exists)
- `--update` or `-u` - Update existing glossary with new terms
- `--scope <path>` or `-s <path>` - Limit term extraction to specific directory
- `--category <name>` - Focus on specific category (e.g., "Architecture", "Data")
- `--interactive` or `-i` - Prompt for every term (default: prompt only for ambiguous)
- `--auto` or `-a` - Accept all inferred definitions (no prompts)
- `--output <path>` or `-o <path>` - Custom output path (default: `agent/artifacts/glossary-1-core-terminology.md`)

**Natural Language Arguments**:
- `@acp.artifact-glossary` - Create or update glossary (auto-detect mode)
- `@acp.artifact-glossary --create` - Force create new glossary
- `@acp.artifact-glossary --update` - Update existing glossary
- `@acp.artifact-glossary --scope src/auth/` - Extract terms from auth module only
- `@acp.artifact-glossary --interactive` - Review every term

**Argument Mapping**:
The agent infers intent from context:
1. If no glossary exists → create mode
2. If glossary exists → update mode (extract new terms, prompt user)
3. If `--create` → force create new glossary (even if one exists)
4. If `--scope <path>` → limit extraction to that directory
5. If `--interactive` → prompt for all terms, not just ambiguous
6. If `--auto` → accept all inferred definitions without prompting

---

## What This Command Does

This command creates and maintains project glossaries through auto-extraction and interactive refinement. It scans the codebase for terminology (classes, interfaces, types, CamelCase patterns), generates definitions from context, and prompts the user to resolve ambiguities or fill gaps.

Glossaries use a living document pattern — a single glossary file per project until 50+ terms, at which point it can be split by domain. Terms are organized into category-grouped tables with an alphabetical index for fast lookup.

Unlike research artifacts (external knowledge) or reference artifacts (passive information), glossaries capture project-specific terminology that aids onboarding and ensures consistent understanding across the team.

---

## Prerequisites

- [ ] ACP installed in current directory (`agent/` directory exists)
- [ ] `agent/artifacts/` directory exists (will be created if not)
- [ ] `agent/artifacts/glossary.template.md` exists

---

## Steps

### 1. Determine Mode

Decide whether to create or update a glossary.

**Actions**:
- Check for existing glossary files in `agent/artifacts/` matching `glossary-*.md`
- If no glossary exists:
  - Mode: create
  - Notify user: "No glossary found. Creating new glossary."
- If glossary exists:
  - If `--create` flag → Mode: create (force new glossary, increment number)
  - If `--update` flag or no flag → Mode: update (add new terms to existing)
  - Notify user: "Glossary found: {path}. Mode: update."

**Expected Outcome**: Mode determined (create or update)  

### 2. Scan Codebase for Terms

Extract terminology from the codebase.

**Actions**:
- If `--scope <path>` provided:
  - Limit scan to that directory/file
- Otherwise:
  - Scan entire project (exclude `node_modules`, `.git`, `dist`, `build`, common ignore patterns)
- **Extract term candidates**:
  - Class names (e.g., `class UserService`)
  - Interface names (e.g., `interface IAuthProvider`)
  - Type aliases (e.g., `type UserId = string`)
  - Enum names (e.g., `enum PaymentStatus`)
  - CamelCase identifiers (e.g., `EventSourcing`, `CQRS` in comments/docs)
  - Acronyms in all-caps (e.g., `API`, `JWT`, `SLA`)
  - Domain-specific terms in comments/docs (e.g., `"microservice"`, `"saga pattern"`)
- **Deduplication**:
  - If term appears multiple times, note all occurrences
  - Prefer definition from most authoritative location (docs > comments > code)
- **If update mode**:
  - Read existing glossary
  - Filter out terms already defined
  - Only extract new terms not in existing glossary

**Heuristics for term detection**:
- Classes/interfaces are high-confidence terms
- CamelCase identifiers > 3 characters are likely terms
- Acronyms in documentation are likely terms
- Generic variable names (`data`, `result`, `temp`) are NOT terms
- Common framework terms (`React`, `Node`, `Express`) are NOT terms unless project-specific

**Expected Outcome**: List of term candidates with source locations  

### 3. Generate Definitions from Context

Infer definitions for each term candidate.

**Actions for each term**:
- **Read context** around term usage:
  - Class docstrings, JSDoc comments
  - Surrounding code that uses the term
  - Markdown docs that mention the term
- **Generate definition**:
  - 1-2 sentences, clear and concise
  - Focus on purpose/role, not implementation
  - Example: "API Gateway" → "Central entry point that routes requests to microservices"
  - Example: "Event Sourcing" → "Pattern where state changes are stored as events"
- **Classify confidence**:
  - **High** (9-10/10): Clear docstring or comment with definition
  - **Medium** (5-8/10): Inferred from code structure and usage
  - **Low** (1-4/10): Term found but insufficient context to define
- **Infer category**:
  - Based on file location, term type, and usage context
  - Common categories: Architecture, Data, Infrastructure, Security, Business Logic
  - If unclear, default to "General"

**Expected Outcome**: Each term has a generated definition, confidence score, and inferred category  

### 4. Interactive Refinement

Prompt user to resolve ambiguities and fill gaps.

**Prompt conditions**:
- **Always prompt if**:
  - Confidence is Low (< 5/10)
  - Term has multiple conflicting definitions in codebase
  - Inferred category is ambiguous (could fit multiple categories)
  - `--interactive` flag set (prompt for all terms)
- **Never prompt if**:
  - `--auto` flag set (accept all inferred definitions)
  - Confidence is High (9-10/10) and `--interactive` not set

**Prompt format** (for each ambiguous term):
```
Term: {TermName}
Generated definition: {definition}
Confidence: {score}/10
Inferred category: {category}

Options:
  1. Accept (keep definition as-is)
  2. Edit definition
  3. Change category
  4. Skip (exclude from glossary)

Your choice: _
```

**User actions**:
- If Accept → keep generated definition and category
- If Edit → prompt for new definition, keep category
- If Change category → prompt for new category, keep definition
- If Skip → exclude term from glossary

**Expected Outcome**: All terms have user-approved definitions and categories  

### 5. Organize into Categories

Group terms by category and build alphabetical index.

**Actions**:
- **Group by category**:
  - Sort categories alphabetically
  - Within each category, sort terms alphabetically
- **Build category tables**:
  - Format: `| Term | Definition |`
  - One table per category
- **Build alphabetical index**:
  - Group by first letter (A-Z)
  - Format: `- **{Term}** → {Category}`
  - Link terms to their category section (if using anchor links)

**Category table example**:
```markdown
## Architecture

| Term | Definition |
|------|------------|
| **API Gateway** | Central entry point that routes requests to microservices |
| **Microservice** | Self-contained service with single responsibility |
```

**Alphabetical index example**:
```markdown
### A
- **API Gateway** → Architecture

### M
- **Microservice** → Architecture
```

**Expected Outcome**: Terms organized into category tables with alphabetical index  

### 6. Create or Update Glossary File

Write the glossary artifact.

**Actions**:

**If create mode**:
- Determine next glossary number:
  - List files in `agent/artifacts/` matching `glossary-*`
  - Parse highest number, increment by 1
- Create file: `agent/artifacts/glossary-{N}-{title}.md`
  - Default title: "core-terminology"
  - If `--output <path>` provided, use that path instead
- Start from template: `agent/artifacts/glossary.template.md`
- Fill metadata block:
  - **Type**: glossary
  - **Created**: Today's date (YYYY-MM-DD)
  - **Last Verified**: Same as Created
  - **Status**: Active
  - **Confidence**: High (9-10/10) if all terms approved by user, Medium (5-8/10) otherwise
  - **Category**: Terminology
  - **Total Terms**: Count of terms in glossary
- Fill Purpose section (why this glossary exists)
- Fill category tables with terms
- Fill alphabetical index
- Fill Related Documents section (if applicable)

**If update mode**:
- Read existing glossary file
- Parse existing terms and categories
- Merge new terms into existing categories
  - If new category needed, add new section
  - If term already exists, skip (avoid duplicates)
- Update metadata:
  - **Last Verified**: Today's date
  - **Total Terms**: Updated count
- Re-sort category tables alphabetically
- Re-build alphabetical index with all terms (existing + new)

**Expected Outcome**: Glossary file created or updated with all terms  

### 7. Auto-Commit (unless `--no-commit`)

Commit the glossary artifact.

**Actions**:
- If create mode:
  - `git add agent/artifacts/glossary-{N}-{title}.md`
  - Commit message: `docs(artifact): create glossary {title} with {count} terms`
- If update mode:
  - `git add agent/artifacts/glossary-{N}-{title}.md`
  - Commit message: `docs(artifact): update glossary {title} (+{new-count} terms, {total} total)`
- If `--no-commit` flag:
  - Leave file staged but uncommitted
  - Notify user: "Glossary staged, awaiting commit."

**Expected Outcome**: Glossary committed (or staged if `--no-commit`)  

### 8. Report Success

Display what was produced.

**Output format**:
```
✅ Glossary {Created|Updated}!

File: agent/artifacts/glossary-{N}-{title}.md
Mode: {create|update}
Total terms: {count}
New terms: {new-count} (if update mode)
Categories: {category-list}
Status: Active

{If create: "✓ Baseline committed."}
{If update: "✓ Updated and committed."}
{If --no-commit: "ℹ️  Staged, not committed. Review and commit when ready."}

Next steps:
- Review the glossary for accuracy
- Add missing terms with `@acp.artifact-glossary --update`
- Reference glossary in onboarding docs
```

**Expected Outcome**: User knows glossary is complete and where to find it  

---

## Verification

- [ ] Mode determined (create or update)
- [ ] Codebase scanned for term candidates
- [ ] Definitions generated from context with confidence scores
- [ ] User prompted for ambiguous terms (unless `--auto`)
- [ ] Terms organized into category tables
- [ ] Alphabetical index built
- [ ] Glossary file created or updated
- [ ] Metadata block complete (Total Terms updated)
- [ ] Auto-commit executed (unless `--no-commit`)
- [ ] Success message displayed

---

## Expected Output

### Files Created (create mode)
- `agent/artifacts/glossary-{N}-{title}.md` - Glossary artifact

### Files Modified (update mode)
- `agent/artifacts/glossary-{N}-{title}.md` - Updated glossary

### Console Output (create mode)
```
✅ Glossary Created!

File: agent/artifacts/glossary-1-core-terminology.md
Mode: create
Total terms: 15
Categories: Architecture (5), Data (4), Infrastructure (3), Security (3)
Status: Active

✓ Baseline committed.

Next steps:
- Review the glossary for accuracy
- Add missing terms with `@acp.artifact-glossary --update`
- Reference glossary in onboarding docs
```

### Console Output (update mode)
```
✅ Glossary Updated!

File: agent/artifacts/glossary-1-core-terminology.md
Mode: update
Total terms: 20
New terms: 5
Categories: Architecture (7), Data (5), Infrastructure (4), Security (4)
Status: Active

✓ Updated and committed.

Next steps:
- Review the new terms for accuracy
- Add missing terms with `@acp.artifact-glossary --update`
```

---

## Examples

### Example 1: Create Glossary

**Context**: New project, no glossary exists, want to catalog terminology  

**Invocation**: `@acp.artifact-glossary`  

**Result**: Agent scans entire codebase, extracts 15 terms (classes, interfaces, domain patterns), generates definitions from docstrings/comments, prompts for 3 ambiguous terms, creates `glossary-1-core-terminology.md` with 3 categories (Architecture, Data, Infrastructure), auto-commits.  

### Example 2: Update Glossary with New Terms

**Context**: Glossary exists, new module added (src/auth/), want to add auth-related terms  

**Invocation**: `@acp.artifact-glossary --update --scope src/auth/`  

**Result**: Agent scans src/auth/, extracts 5 new terms (AuthProvider, TokenService, RefreshToken, etc.), generates definitions, prompts for 1 ambiguous term, adds to existing glossary under new "Security" category, auto-commits with "+5 terms" message.  

### Example 3: Interactive Review of All Terms

**Context**: Want to review every extracted term before accepting  

**Invocation**: `@acp.artifact-glossary --interactive`  

**Result**: Agent extracts 20 terms, prompts for EVERY term (not just ambiguous ones), user edits 3 definitions and changes 2 categories, creates glossary with all user-approved content.  

### Example 4: Auto-Accept All Terms

**Context**: High confidence in codebase documentation, want fast glossary creation  

**Invocation**: `@acp.artifact-glossary --auto`  

**Result**: Agent extracts terms, generates definitions, skips all prompts, creates glossary with inferred definitions and categories, auto-commits immediately.  

### Example 5: Force Create New Glossary

**Context**: Existing glossary is for backend, want separate frontend glossary  

**Invocation**: `@acp.artifact-glossary --create --scope src/frontend/ --output agent/artifacts/glossary-2-frontend-terminology.md`  

**Result**: Agent creates new `glossary-2-frontend-terminology.md` (does not update existing glossary-1), extracts frontend-specific terms, commits as separate glossary.  

---

## Related Commands

- [`@acp.artifact-research`](acp.artifact-research.md) - Create research artifacts (external knowledge)
- [`@acp.artifact-reference`](acp.artifact-reference.md) - Create reference guides (passive info)
- [`@acp.sync`](acp.sync.md) - Detect glossary staleness (new terms in code not in glossary)
- [`@acp.validate`](acp.validate.md) - Validate artifact metadata and structure

---

## Troubleshooting

### Issue 1: Too many generic terms extracted

**Symptom**: Glossary includes common framework terms (React, Node, Express)  

**Cause**: Heuristics too broad, extracting non-project-specific terms  

**Solution**: Skip generic terms during extraction. Manually remove from glossary in update mode.  

### Issue 2: Definitions too technical or implementation-focused

**Symptom**: Definitions describe how code works, not what concept means  

**Cause**: Insufficient context in code (no docstrings), agent infers from implementation  

**Solution**: Prompt user to edit definitions. Add docstrings to code for future updates.  

### Issue 3: Terms in wrong category

**Symptom**: "JWT" in Architecture category, should be in Security  

**Cause**: Category inference based on file location, not semantic meaning  

**Solution**: Use `--interactive` to review and correct categories. Or manually edit glossary file.  

### Issue 4: Glossary becoming unwieldy (50+ terms)

**Symptom**: Single glossary file is long and hard to navigate  

**Cause**: Project has grown, many domain areas  

**Solution**: Split into multiple glossaries by domain (backend, frontend, infrastructure). Use `--create --scope` to create domain-specific glossaries.  

---

## Security Considerations

### File Access
- **Reads**: All files in project (for term extraction)
- **Writes**: `agent/artifacts/glossary-{N}-{title}.md` only
- **Executes**: `git add`, `git commit` (if auto-commit)

### Network Access
- **APIs**: None (codebase-only command)
- **Repositories**: Local git only (no remote operations)

### Sensitive Data
- **Secrets**: Never extract terms from `.env` files or secret configs
- **Private data**: Skip extraction from `secrets/`, `credentials/`, `.env*` patterns

---

## Key Design Decisions

### Term Extraction

| Decision | Choice | Rationale |
|---|---|---|
| Auto-extraction | Yes, from classes/interfaces/types/comments | Reduces manual work, ensures glossary completeness |
| Confidence scoring | Yes, per term (1-10) | Indicates definition quality, triggers prompts for low-confidence |
| Category inference | Yes, based on file location and term type | Automates organization, user can override in interactive mode |
| Deduplication | Yes, prefer most authoritative definition | Prevents duplicate terms with conflicting definitions |

### Interactive Refinement

| Decision | Choice | Rationale |
|---|---|---|
| Prompt conditions | Low confidence, conflicts, ambiguous category, or `--interactive` | Balances automation with quality, user controls review level |
| Auto mode | Accept all inferred definitions (no prompts) | Fast path for well-documented codebases |
| Interactive mode | Prompt for every term | Full user control for critical glossaries |

### Living Document Pattern

| Decision | Choice | Rationale |
|---|---|---|
| Single glossary | Until 50+ terms | Start simple, split only when domain boundaries emerge |
| Update mode | Merge new terms into existing glossary | Maintains single canonical glossary, avoids proliferation |
| Category organization | Group by category + alphabetical index | Category aids conceptual understanding, index aids fast lookup |

### Integration

| Decision | Choice | Rationale |
|---|---|---|
| Template-based | Use `glossary.template.md` | Consistent structure across glossaries |
| Auto-commit | Yes (default), `--no-commit` to disable | Establishes baseline, enables visible diff |
| Scope filtering | `--scope <path>` for targeted extraction | Enables domain-specific glossaries |

---

## Notes

- Glossaries are living documents — update frequently as codebase evolves
- Category boundaries are fluid — reorganize categories as project understanding matures
- Consider splitting into multiple glossaries when 50+ terms or clear domain boundaries emerge
- Reference glossaries in onboarding docs and README for maximum value
- Glossaries complement research artifacts (external knowledge) and reference artifacts (passive info)
- Use `@acp.sync` to detect staleness (new terms in code not in glossary)

---

**Namespace**: acp  
**Command**: artifact-glossary  
**Version**: 1.0.0  
**Created**: 2026-03-17  
**Last Updated**: 2026-03-17  
**Status**: Active  
**Compatibility**: ACP 5.25.0+  
**Author**: ACP Project  
