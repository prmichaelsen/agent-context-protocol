# Command: index

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-index` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@acp-index` NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-03-02  
**Last Updated**: 2026-03-02  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Manage the key file index — list, add, remove, explore, and show indexed key files  
**Category**: Maintenance  
**Frequency**: As Needed  

---

## Arguments

This command supports both CLI-style subcommands and natural language arguments.

### Subcommands

| Subcommand | Description |
|------------|-------------|
| (none) / `list` | List all indexed key files (default) |
| `add <path>` | Add a file to `agent/index/local.main.yaml` |
| `remove <path>` | Remove a file from `agent/index/local.main.yaml` |
| `explore` | Scan codebase and suggest key files to add |
| `show` | Show full metadata for all entries |

### Natural Language (Fuzzy Matching)

| Example | Detected Subcommand |
|---------|---------------------|
| `@acp.index` | list |
| `@acp.index show all files` | show |
| `@acp.index add the testing pattern` | add (infer path from "testing pattern") |
| `@acp.index remove requirements.md` | remove |
| `@acp.index what should I add?` | explore |
| `@acp.index suggest key files` | explore |

**Matching rules**:
- Look for keywords: `add`, `remove`, `delete`, `explore`, `suggest`, `scan`, `show`, `detail`, `list`
- If a path is provided after `add`/`remove`, use it directly
- If a description is given instead of path (e.g., "the testing pattern"), search the codebase for matching files
- Default to `list` if no subcommand detected

---

## What This Command Does

This command manages the ACP Key File Index system. The key file index is a weighted list of critical project files stored in `agent/index/` that agents must read before taking action. This command provides a convenient interface for viewing, adding, removing, and discovering index entries without manually editing YAML.

Use this when you want to see what files are indexed, add newly created files, remove stale entries, or discover files that should be indexed based on codebase analysis.

See also: `agent/design/local.key-file-index-system.md`

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/index/` directory exists (created by `acp.install.sh` or Task 99)

---

## Steps

### 1. Check Index Directory

**Actions**:
- Check if `agent/index/` directory exists
- If not: warn user and suggest running `mkdir -p agent/index`
- List all `*.yaml` files (excluding `*.template.yaml`)

**Expected Outcome**: Index directory confirmed, files discovered  

### 2. Parse Arguments

**Actions**:
- Detect subcommand from flags or natural language (see Arguments section)
- If ambiguous, default to `list`
- If `add`/`remove` with natural language path description, search codebase to resolve to actual path

**Expected Outcome**: Subcommand and arguments determined  

### 3. Execute Subcommand

Branch to the appropriate subcommand handler below.

---

### Subcommand: `list` (Default)

List all indexed key files across all namespaces in a compact table.

**Actions**:
- Parse all index YAML files in `agent/index/`
- Group entries by namespace
- Sort within each namespace by weight descending

**Display format**:
```
📑 Key File Index (7 entries across 2 namespaces)

local (4 entries):
  1.0  requirements  agent/design/requirements.md
  0.8  pattern       agent/patterns/local.e2e-testing.md
  0.7  design        agent/design/local.architecture.md
  0.6  design        src/core/state-machine.ts

core-sdk (3 entries):
  0.5  pattern       agent/patterns/core-sdk.service-base.md
  0.4  pattern       agent/patterns/core-sdk.testing-unit.md
  0.3  design        agent/design/core-sdk.architecture.md
```

**If no index files found**:
```
📑 Key File Index: Empty

No index files found in agent/index/.
Run @acp.index explore to discover key files, or @acp.index add <path> to add one.
```

---

### Subcommand: `add <path>`

Add a file to `agent/index/local.main.yaml`.

**Actions**:
1. Validate the file exists at the given path
2. Check if it's already in any index file (warn if duplicate)
3. Prompt for required metadata:
   - **weight** (suggest based on kind: 0.9 for requirements, 0.8 for patterns, 0.7 for designs)
   - **kind** (pattern, command, design, requirements)
   - **description** (what the file contains)
   - **rationale** (why it should be in the index)
   - **applies** (comma-separated fully qualified command names)
4. Append entry to `agent/index/local.main.yaml`
   - If file doesn't exist, create it from `local.main.template.yaml`
5. Check recommended limits:
   - Warn if local namespace exceeds 10 entries
   - Warn if total across namespaces exceeds 20 entries

**Display on success**:
```
✅ Added to key file index:

  path: agent/patterns/local.my-pattern.md
  weight: 0.8
  kind: pattern
  applies: acp.proceed, acp.task-create

  Local namespace: 5 entries (within limits)
```

---

### Subcommand: `remove <path>`

Remove a file from `agent/index/local.main.yaml`.

**Actions**:
1. Find entry by path in `agent/index/local.main.yaml`
2. If not found: report error, suggest checking `@acp.index list`
3. If found: show the entry and confirm removal
4. Remove entry from YAML file

**Note**: Only entries in `local.*.yaml` can be removed via this command. Package index entries should be managed via package updates.  

**Display on success**:
```
✅ Removed from key file index:

  path: agent/patterns/local.old-pattern.md
  was: weight 0.8, pattern

  Local namespace: 3 entries remaining
```

---

### Subcommand: `explore`

Scan the codebase and suggest files that should be indexed.

**Actions**:
1. List all files in `agent/design/` (excluding templates)
2. List all files in `agent/patterns/` (excluding templates)
3. Check for `requirements.md`, `architecture` design docs
4. Cross-reference with all existing index entries
5. Present un-indexed files as suggestions with recommended metadata

**Display format**:
```
🔍 Exploring codebase for key files...

Found 4 un-indexed files:

  1. agent/design/requirements.md
     Suggested: weight 1.0, kind: requirements
     Applies: acp.init, acp.design-create, acp.task-create, acp.plan, acp.proceed

  2. agent/patterns/local.library-services.md
     Suggested: weight 0.7, kind: pattern
     Applies: acp.proceed, acp.task-create

  3. agent/design/yaml-parser-design.md
     Suggested: weight 0.6, kind: design
     Applies: acp.proceed

  4. agent/design/acp-package-development-system.md
     Suggested: weight 0.6, kind: design
     Applies: acp.design-create, acp.plan

Would you like to add any of these? (enter numbers, "all", or "none")
```

If user selects entries:
- Prompt for confirmation/adjustment of suggested metadata
- Add selected entries to `agent/index/local.main.yaml`

---

### Subcommand: `show`

Show full metadata for all index entries across all namespaces.

**Actions**:
- Parse all index YAML files
- Display every field for every entry
- Group by namespace and qualifier

**Display format**:
```
📑 Key File Index — Full Details

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  local.main.yaml (4 entries)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  path:        agent/design/acp-commands-design.md
  weight:      0.9
  kind:        design
  description: Core design document for the ACP command system.
  rationale:   Essential context for creating or modifying any ACP command.
  applies:     acp.command-create, acp.design-create, acp.plan

  ─────────────────────────────────────────

  path:        agent/patterns/local.e2e-testing.md
  weight:      0.8
  kind:        pattern
  description: E2E testing pattern used across all test suites.
  rationale:   Prevents agents from writing tests that don't follow conventions.
  applies:     acp.task-create, acp.proceed

  [... more entries ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  core-sdk.main.yaml (3 entries)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [... entries ...]
```

---

## Verification

- [ ] `agent/index/` directory checked
- [ ] Subcommand detected from arguments or NLP
- [ ] `list`: All entries displayed grouped by namespace
- [ ] `add`: File validated, metadata collected, entry appended, limits checked
- [ ] `remove`: Entry found, confirmed, removed from YAML
- [ ] `explore`: Un-indexed files discovered and presented with suggestions
- [ ] `show`: Full metadata displayed for all entries

---

## Expected Output

### Files Modified
- `agent/index/local.main.yaml` — Modified by `add` and `remove` subcommands

### Console Output
See display formats for each subcommand above.

---

## Examples

### Example 1: Listing Indexed Files

**Context**: Want to see what's currently indexed  

**Invocation**: `@acp.index`  

**Result**: Displays compact table of all indexed files grouped by namespace  

### Example 2: Adding a New Pattern

**Context**: Just created a new pattern and want to index it  

**Invocation**: `@acp.index add agent/patterns/local.api-conventions.md`  

**Result**: Prompts for weight/kind/description/rationale/applies, adds to local.main.yaml  

### Example 3: Exploring for Missing Files

**Context**: Want to discover what files should be indexed  

**Invocation**: `@acp.index explore`  

**Result**: Scans agent/design/ and agent/patterns/, shows un-indexed files with suggestions  

### Example 4: Natural Language Add

**Context**: Want to add a file using description instead of path  

**Invocation**: `@acp.index add the e2e testing pattern`  

**Result**: Agent searches for matching file, finds `agent/patterns/local.e2e-testing.md`, proceeds with add flow  

### Example 5: Removing a Stale Entry

**Context**: A file was deleted but still in the index  

**Invocation**: `@acp.index remove agent/design/old-feature.md`  

**Result**: Finds entry, confirms removal, updates local.main.yaml  

---

## Related Commands

- [`@acp.init`](acp.init.md) - Reads key files during initialization (step 2.8)
- [`@acp.proceed`](acp.proceed.md) - Reads contextual key files before task execution
- [`@acp.validate`](acp.validate.md) - Validates index file paths and schema
- [`@acp.design-create`](acp.design-create.md) - Prompts to add new designs to index
- [`@acp.pattern-create`](acp.pattern-create.md) - Prompts to add new patterns to index

---

## Troubleshooting

### Issue 1: No agent/index/ directory

**Symptom**: Warning "agent/index/ directory not found"  

**Cause**: ACP installed before key file index system was available  

**Solution**: Run `mkdir -p agent/index` to create the directory  

### Issue 2: File not found when adding

**Symptom**: Error "File does not exist: <path>"  

**Cause**: Path is incorrect or file was deleted  

**Solution**: Verify the file path. Use `@acp.index explore` to discover files automatically.  

### Issue 3: Cannot remove package index entry

**Symptom**: Error "Entry is in package index, not local"  

**Cause**: Trying to remove an entry from a package-shipped index file  

**Solution**: Package index entries are managed by the package. Use `@acp.package-update` or `@acp.package-remove` to modify package indices.  

### Issue 4: Exceeding recommended limits

**Symptom**: Warning about too many entries  

**Cause**: Index has more than 10 entries per namespace or 20 total  

**Solution**: Review entries and remove lower-priority ones. The index should focus on truly critical files.  

---

## Security Considerations

### File Access
- **Reads**: `agent/index/*.yaml`, `agent/design/*`, `agent/patterns/*`
- **Writes**: `agent/index/local.main.yaml` (add/remove operations)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never includes secrets in index entries
- **Credentials**: Does not access credentials

---

## Notes

- This is an LLM-based command — no shell scripts, the agent interprets and executes directly
- Only `local.*.yaml` files can be modified by this command; package indices are read-only
- The `explore` subcommand uses heuristics to suggest files, not exhaustive analysis
- Entries are YAML — the agent must maintain valid YAML when adding/removing
- Recommended limits are advisory, not enforced: 5-10 per namespace, 15-20 total
- The `applies` field should use fully qualified command names (e.g., `acp.init`, `core-sdk.bootstrap`)

---

**Namespace**: acp  
**Command**: index  
**Version**: 1.0.0  
**Created**: 2026-03-02  
**Last Updated**: 2026-03-02  
**Status**: Active  
**Compatibility**: ACP 5.10.0+  
**Author**: ACP Project  
