# Task 117: Implement @acp.artifact-glossary Command

**Status**: completed  
**Priority**: high  
**Milestone**: M17 (Artifact Commands System)  
**Design Reference**: [Artifact Commands System](../../design/local.artifact-commands-system.md)  
**Estimated Time**: 3-4 hours  
**Started**: 2026-03-17  
**Completed**: 2026-03-17  

---

## Objective

Implement the `@acp.artifact-glossary` command that creates and maintains project glossaries through auto-extraction and interactive refinement, with category organization and alphabetical indexing.

---

## Requirements

1. Auto-extract terms from codebase (classes, interfaces, types, CamelCase patterns)
2. Generate definitions from context (docstrings, comments, surrounding code)
3. Interactive refinement for ambiguous terms (confidence scoring)
4. Category organization (infer categories, user can override)
5. Alphabetical index for fast term lookup
6. Living document pattern (single glossary until 50+ terms)
7. Create and update modes (merge new terms into existing glossary)
8. Scope filtering (`--scope <path>`) for targeted extraction
9. Auto-commit workflow with `--no-commit` override
10. Integration with glossary artifact template

---

## Implementation

### Command Structure

**File**: `agent/commands/acp.artifact-glossary.md`  

**Metadata**:
- Namespace: acp
- Version: 1.0.0
- Category: Entity Creation
- Scripts: None (LLM-based command)

### Arguments

**Flags**:
- `--create` / `-c` - Force create new glossary
- `--update` / `-u` - Update existing glossary
- `--scope <path>` / `-s <path>` - Limit extraction to directory
- `--category <name>` - Focus on specific category
- `--interactive` / `-i` - Prompt for every term
- `--auto` / `-a` - Accept all inferred definitions (no prompts)
- `--output <path>` / `-o <path>` - Custom output path
- `--no-commit` - Skip auto-commit

### Steps

**1. Determine Mode**
- Check for existing glossary files in `agent/artifacts/`
- If none exist → create mode
- If exists and no `--create` flag → update mode
- If `--create` flag → force create (increment glossary number)

**2. Scan Codebase for Terms**
- Extract term candidates:
  - Class names (`class UserService`)
  - Interface names (`interface IAuthProvider`)
  - Type aliases (`type UserId = string`)
  - Enum names (`enum PaymentStatus`)
  - CamelCase identifiers (> 3 chars)
  - Acronyms in all-caps (`API`, `JWT`, `SLA`)
  - Domain terms in comments/docs
- Deduplication: prefer most authoritative definition
- If update mode: filter out terms already in glossary
- Heuristics:
  - Classes/interfaces = high confidence
  - Generic names (`data`, `result`) = skip
  - Framework names (`React`, `Node`) = skip

**3. Generate Definitions from Context**
- Read context around term usage:
  - Docstrings, JSDoc comments
  - Surrounding code
  - Markdown docs
- Generate 1-2 sentence definition (purpose/role, not implementation)
- Classify confidence (1-10):
  - 9-10: Clear docstring
  - 5-8: Inferred from code
  - 1-4: Insufficient context
- Infer category (Architecture, Data, Infrastructure, Security, etc.)

**4. Interactive Refinement**
- Prompt conditions:
  - Confidence < 5/10
  - Multiple conflicting definitions
  - Ambiguous category
  - `--interactive` flag set
- Never prompt if `--auto` flag set
- Prompt format: Accept / Edit / Change category / Skip
- User actions applied to each term

**5. Organize into Categories**
- Group by category (alphabetical)
- Sort terms within category (alphabetical)
- Build category tables (`| Term | Definition |`)
- Build alphabetical index (A-Z with category references)

**6. Create or Update Glossary File**
- **Create mode**:
  - Determine next glossary number
  - Create `agent/artifacts/glossary-{N}-{title}.md`
  - Fill from template
  - Fill metadata block (Type, Created, Last Verified, Status, Total Terms)
- **Update mode**:
  - Read existing glossary
  - Merge new terms into existing categories
  - Update metadata (Last Verified, Total Terms)
  - Re-sort and re-index

**7. Auto-Commit**
- Create: `docs(artifact): create glossary {title} with {count} terms`
- Update: `docs(artifact): update glossary {title} (+{new-count} terms, {total} total)`
- If `--no-commit`: stage but don't commit

**8. Report Success**
- Display file, mode, total terms, new terms (if update), categories, status

### Heuristics for Term Detection

**Include**:
- Classes, interfaces, types, enums
- CamelCase identifiers > 3 characters
- Acronyms in documentation
- Domain-specific patterns (e.g., "event sourcing", "CQRS")

**Exclude**:
- Generic variable names (`data`, `result`, `temp`, `value`)
- Common framework terms (`React`, `Node`, `Express`, `Lodash`)
- Files matching `.env*`, `secrets/`, `credentials/` patterns

### Category Inference Strategy

**Based on**:
- File location (`src/auth/` → Security)
- Term type (interfaces → Architecture, types → Data)
- Usage context (comments mentioning "infrastructure", "business logic")

**Common categories**:
- Architecture
- Data
- Infrastructure
- Security
- Business Logic
- General

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
- [x] Metadata block complete
- [x] Prerequisites listed
- [x] Verification checklist present
- [x] Expected Output section shows files created/modified
- [x] Follows existing command pattern

### Integration Points

- [x] References glossary artifact template
- [x] Create and update modes
- [x] Scope filtering for targeted extraction
- [x] Interactive and auto modes
- [x] Auto-commit workflow

---

## Files Created

1. `agent/commands/acp.artifact-glossary.md` (643 lines)

---

## Files Modified

1. `package.yaml` - Added acp.artifact-glossary.md to commands list

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Auto-extraction | From classes/interfaces/types/comments | Reduces manual work, ensures completeness |
| Confidence scoring | 1-10 per term | Indicates definition quality, triggers prompts |
| Category inference | Based on file location and term type | Automates organization, user can override |
| Interactive refinement | Prompt for low-confidence or `--interactive` | Balances automation with quality control |
| Living document pattern | Single glossary until 50+ terms | Start simple, split when domain boundaries emerge |
| Update mode | Merge new terms into existing | Maintains single canonical glossary |
| Category organization | Group by category + alphabetical index | Conceptual understanding + fast lookup |

---

## Integration Points

- **@acp.artifact-research**: Research artifacts (external knowledge)
- **@acp.artifact-reference**: Reference artifacts (passive info)
- **@acp.sync**: Detect glossary staleness (new terms not in glossary)
- **@acp.validate**: Validate artifact metadata

---

## Notes

- Glossaries capture project-specific terminology
- Living documents — update frequently as codebase evolves
- Category boundaries are fluid — reorganize as understanding matures
- Consider splitting at 50+ terms or clear domain boundaries
- Reference glossaries in onboarding docs for maximum value
- Use `@acp.sync` to detect staleness
- Auto-extraction with interactive refinement balances speed and quality
- Confidence scoring makes definition quality explicit

Ready for testing with real codebases.
