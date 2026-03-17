# Task 118: Implement @acp.artifact-reference Command

**Status**: completed
**Priority**: high
**Milestone**: M17 (Artifact Commands System)
**Design Reference**: [Artifact Commands System](../../design/local.artifact-commands-system.md)
**Estimated Time**: 2-3 hours
**Started**: 2026-03-17
**Completed**: 2026-03-17

---

## Objective

Implement the `@acp.artifact-reference` command that creates reference guides for passive information after performing a mandatory command-first principle check to prevent reference bloat.

---

## Requirements

1. Command-first principle check (mandatory, explicit evaluation)
2. Reference type system (7 types with distinct structures)
3. Content gathering (codebase + user input + external docs)
4. Template-based artifact creation
5. Type inference from keywords
6. Command suggestions when executable content detected
7. Auto-commit workflow with `--no-commit` override
8. Integration with reference artifact template
9. Support for configuration tables, CLI syntax, standards, diagrams, schemas, troubleshooting, API contracts

---

## Implementation

### Command Structure

**File**: `agent/commands/acp.artifact-reference.md`

**Metadata**:
- Namespace: acp
- Version: 1.0.0
- Category: Entity Creation
- Scripts: None (LLM-based command)

### Arguments

**Positional**:
- `<topic>` - Reference topic

**Flags**:
- `--type <type>` - Reference type (config-table, cli-syntax, standards, diagrams, schemas, troubleshooting, api-contract)
- `--from-clarification <file>` - Pull topic from clarification
- `--output <path>` / `-o <path>` - Custom output path
- `--skip-check` - Skip command-first principle check (use with caution)
- `--auto-commit` - Auto-commit after creation (default: true)
- `--no-commit` - Skip auto-commit

### Steps

**1. Determine Reference Topic**
- From positional argument, `--from-clarification`, or inferred from context
- Prompt user if ambiguous

**2. Command-First Principle Check** (mandatory unless `--skip-check`)
- **Critical question**: "Could this information be automated as an executable directive?"
- **Should be COMMAND if**:
  - Step-by-step procedures agents can follow
  - Project-specific workflows (deploy, hotfix, release)
  - Code scaffolding (API creation, test generation)
  - Checklists with clear success criteria
- **Should be REFERENCE if**:
  - Lookup tables, configuration data
  - Generic CLI syntax (not project-specific)
  - Architecture diagrams (human interpretation required)
  - External API contracts
  - Troubleshooting decision trees (human judgment required)
  - Standards/conventions (guide but don't automate)
- **If executable detected**:
  - Prompt: "This looks like an executable workflow. Consider: @local.{name} or @namespace.{name}. Would you like me to create a command instead?"
  - Wait for user response
  - If yes → Exit, suggest `@acp.command-create`
  - If no → Proceed to Step 3

**3. Determine Reference Type**
- From `--type` flag or infer from keywords:
  - "environment", "config", "variables" → config-table
  - "CLI", "syntax", "commands" → cli-syntax
  - "style", "conventions", "standards" → standards
  - "architecture", "diagram", "topology" → diagrams
  - "schema", "database", "model" → schemas
  - "troubleshooting", "debug", "diagnose" → troubleshooting
  - "API", "endpoint", "contract" → api-contract
- Prompt if ambiguous

**4. Gather Content**
- **Codebase**: Search for existing configs, diagrams, documentation
- **User input**: Prompt for domain-specific content (env vars, standards, troubleshooting steps)
- **External docs**: For CLI syntax, cite official documentation URLs

**5. Create Reference Artifact**
- Start from template: `agent/artifacts.template.md/reference.template.md`
- Fill metadata block (Type, Created, Last Verified, Status, Confidence, Category, Sources)
- Fill Purpose section (what this covers, when to use)
- Fill Command-First Principle Check section (explicit reasoning)
- Fill Content section based on reference type:
  - **Config table**: `| Variable | Type | Default | Description | Required |`
  - **CLI syntax**: Command examples with options
  - **Standards**: Rules with examples + rationale
  - **Diagrams**: ASCII/mermaid with component descriptions
  - **Schemas**: JSON/YAML with field descriptions
  - **Troubleshooting**: Decision tree (Symptom → Check → Resolution)
  - **API contract**: Endpoint, request/response formats, error codes
- Fill Sources & References (citations with dates)
- Fill Related Documents (links to commands, designs)

**6. Validate Content**
- Check for executability (no steps that could be automated)
- Check for completeness (no "TODO" or placeholders)
- Check for clarity (unambiguous descriptions)
- Check for accuracy (correct and up-to-date info)
- Check for sources (external info has citations)

**7. Auto-Commit**
- Determine next artifact number
- Create file: `agent/artifacts/reference-{N}-{topic-slug}.md`
- If `--auto-commit`: Commit with message `docs(artifact): reference {topic-slug}`
- If `--no-commit`: Stage but don't commit

**8. Report Success**
- Display file, topic, type, category, confidence, status
- Note next steps (review, refine, reference in docs)

### Reference Type Structures

| Type | Structure | Use Case |
|------|-----------|----------|
| config-table | Table with Variable/Type/Default/Description/Required columns | Environment variables, feature flags |
| cli-syntax | Command examples with options + descriptions | Git, Docker, SQL (generic tools) |
| standards | Rules with examples + rationale | Code style, commit format, doc style |
| diagrams | ASCII/mermaid diagram + component descriptions | Architecture, service maps, data flows |
| schemas | JSON/YAML with field descriptions | DB schemas, file formats |
| troubleshooting | Decision tree (Symptom → Check → Resolution) | Diagnostic guides |
| api-contract | Endpoint, request/response, error codes | API formats, message schemas |

---

## Testing

### Manual Testing

- [x] Command file created with full directive structure
- [x] 8 steps implemented with detailed actions
- [x] Arguments section covers CLI + natural language
- [x] Examples section shows 5 use cases (including command suggestion)
- [x] Related Commands section links to other artifact commands
- [x] Troubleshooting section covers common issues
- [x] Security Considerations section covers file/network access
- [x] Key Design Decisions section captures rationale

### Validation Checks

- [x] Agent directive header present
- [x] Metadata block complete
- [x] Prerequisites listed
- [x] Verification checklist present
- [x] Expected Output section shows files created
- [x] Follows existing command pattern
- [x] Command-first principle check is explicit and detailed

### Integration Points

- [x] References reference artifact template
- [x] Command-first principle check with user prompts
- [x] 7 reference types with distinct structures
- [x] Type inference from keywords
- [x] Auto-commit workflow
- [x] Command suggestions when executable content detected

---

## Files Created

1. `agent/commands/acp.artifact-reference.md` (629 lines)

---

## Files Modified

1. `package.yaml` - Added acp.artifact-reference.md to commands list

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Command-first check | Mandatory (unless `--skip-check`) | Prevents reference bloat, encourages automation |
| Check timing | Step 2 (before content gathering) | Saves work if content should be a command |
| Decision criteria | Executable vs passive information | Clear boundary: commands do, references inform |
| Reference types | 7 types with distinct structures | Covers common use cases, optimizes layout per type |
| Type inference | Keyword-based heuristics | Reduces user burden, explicit `--type` for precision |
| Command suggestions | Explicit prompts when executable detected | Educates users on command-first principle |
| Content gathering | User input + codebase + external docs | References often document existing patterns |

---

## Integration Points

- **@acp.artifact-research**: Research artifacts (external knowledge)
- **@acp.artifact-glossary**: Glossary artifacts (terminology)
- **@acp.command-create**: Suggested when executable content detected
- **@acp.sync**: Detect reference staleness (future)
- **@acp.validate**: Validate artifact metadata (future)

---

## Notes

- Command-first principle check is the core differentiator from other artifact types
- References are for passive information only — executable procedures should be commands
- 7 reference types cover common use cases but aren't rigid (adapt as needed)
- Reference type determines optimal structure (table vs syntax vs decision tree)
- Command suggestions educate users on when to use commands vs references
- References complement commands (informational support) but don't replace them
- Use `--skip-check` sparingly — only when certain content is passive
- References are living documents — update as project standards evolve

Ready for testing with real reference scenarios.
