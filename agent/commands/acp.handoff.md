# Command: handoff

> **🤖 Agent Directive**: If you are reading this file, the command `@acp-handoff` has been invoked.
> Pretend this command was entered with this additional context: "Execute directive `@acp-handoff NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp  
**Version**: 1.0.0  
**Created**: 2026-03-13  
**Last Updated**: 2026-03-13  
**Status**: Active  
**Scripts**: None  

---

**Purpose**: Generate a context-aware handoff report for transferring work to an agent in a different context (different repository, provider, etc.)  
**Category**: Workflow  
**Frequency**: As Needed  

---

## Arguments

**CLI-Style Arguments**:
- `--to <path-or-project>` or `--target <path-or-project>` - Target project path or registered ACP project name

**Natural Language Arguments**:
- `@acp.handoff to weaviate-schema` - Handoff to a named project
- `@acp.handoff --to ~/projects/other-repo` - Handoff to a specific path
- `@acp.handoff` - Infer target from conversation context

**Argument Mapping**:
The agent infers intent from context:
- If `--to` or `--target` provided → use that as the target project
- If target mentioned in natural language → resolve against `~/.acp/projects.yaml` or treat as path
- If no target specified → infer from conversation context, ask if inference fails

---

## What This Command Does

This command generates a freeform handoff report that captures enough context from the current conversation to enable an agent in a different context (different repository, different provider, etc.) to understand and act on a request. The report explains the problem and the request — not specific implementation steps — so the receiving agent can apply its own judgment within its own codebase.

The handoff is designed for cross-context scenarios where work in one project reveals a need for changes in another. For example, while working in a REST server project, you discover a migration is needed in a Weaviate instance whose schema code lives in a separate repository. Rather than context-switching yourself, you generate a handoff report that another agent session can consume.

The report is written to be understandable by any agent, though ACP-aware agents will benefit from additional context. Chat conversation is the primary source for populating the report.

---

## Prerequisites

- [ ] Active conversation with context about the work to hand off
- [ ] Target project identifiable (via argument, conversation context, or `~/.acp/projects.yaml`)

---

## Steps

### 1. Identify Target Project

Determine where the handoff is going.

**Actions**:
- If `--to` or `--target` argument provided, use that value
- If no argument, analyze conversation context to infer the target project
- Check `~/.acp/projects.yaml` to resolve project names to paths
- If inference fails, ask the user: "Which project should this handoff target?"

**Expected Outcome**: Target project identified (name and/or path)  

### 2. Gather Context from Conversation

Extract relevant information from the current chat session.

**Actions**:
- Identify the problem or need that triggered the handoff
- Extract the request — what needs to happen in the target project
- Identify any relevant file paths (use absolute paths from `/`, not relative)
- Note error messages or blockers only if they add necessary context
- Note environment or dependency details only if they add necessary context
- Optionally check `agent/progress.yaml` if task context is relevant

**Expected Outcome**: Core handoff content gathered from conversation  

### 3. Identify Source Project

Determine the source project details for back-reference.

**Actions**:
- Get the current working directory (absolute path)
- Get the git remote URL if available
- Include source project path/repo URL in the report so the receiving agent can reference back

**Expected Outcome**: Source project location captured  

### 4. Generate Handoff Report

Write the handoff report in freeform markdown, shaped by the specific need.

**Actions**:
- Write a clear description of the problem
- Write the request — what the receiving agent should understand and address
- Include source project location for back-reference
- Include absolute file paths, code references, or schema details only if they add context
- Include error messages or blockers only if necessary
- Include environment/dependency context only if necessary
- If the target project is ACP-aware, suggest relevant files to read (e.g., `AGENT.md`), but keep the report generic enough for any agent
- Do NOT include specific implementation steps — describe the problem and request, let the receiving agent decide how to solve it

**Expected Outcome**: Handoff report generated  

### 5. Deliver Handoff

Ask the user how they want to receive the report.

**Actions**:
- Prompt: "Output to chat or save to disk?"
- If **chat**: Output the full report directly in the conversation
- If **disk**: Save to `agent/reports/handoff-{target-name}-{date}.md` (create `agent/reports/` if it doesn't exist)

**Expected Outcome**: Handoff report delivered to user in their preferred format  

---

## Verification

- [ ] Target project identified
- [ ] Problem and request clearly described
- [ ] Source project location included
- [ ] File paths use absolute paths (from `/`)
- [ ] Report is understandable without source project context
- [ ] No specific implementation steps prescribed
- [ ] Report delivered in user's preferred format

---

## Expected Output

### If Output to Chat
The handoff report is displayed directly in the conversation, ready to be pasted into the target agent session.

### If Saved to Disk
```
✅ Handoff Report Created

File: agent/reports/handoff-{target-name}-{date}.md
Target: {target project name/path}
Source: {current project path}

Paste the contents of this file into your agent session in the target project.
```

---

## Examples

### Example 1: Cross-Repo Migration Handoff

**Context**: Working in REST server project, discovered Weaviate schema needs a new field  

**Invocation**: `@acp.handoff --to weaviate-schema`  

**Result**: Generates a report explaining that the REST server needs a new `embedding_model` field on the `Document` class, references the source project path, and describes the data model expectations — without prescribing how to write the migration.  

### Example 2: Inferred Target

**Context**: Conversation mentions "the frontend repo needs to update its API client types"  

**Invocation**: `@acp.handoff`  

**Result**: Agent infers the target is the frontend project, checks `~/.acp/projects.yaml` for a match, generates the handoff report describing the API contract changes.  

### Example 3: Output to Chat

**Context**: Quick handoff, user doesn't need a file  

**Invocation**: `@acp.handoff --to ~/projects/infra`  

**Result**: Agent generates the report and outputs it directly in chat. User copies it into their next agent session.  

---

## Related Commands

- [`@acp-report`](acp.report.md) - Generate session reports (broader scope, same project)
- [`@acp-status`](acp.status.md) - Check current project status

---

## Troubleshooting

### Issue 1: Cannot infer target project

**Symptom**: Agent asks "Which project should this handoff target?"  

**Solution**: Provide the target explicitly with `--to` or `--target`, or register the project in `~/.acp/projects.yaml`.  

### Issue 2: Handoff report is too broad

**Symptom**: Report includes too much session context  

**Solution**: The handoff should be narrow — focused on the specific problem and request, not a full session summary. If the report is too broad, re-invoke with more specific conversation context.  

---

## Security Considerations

### File Access
- **Reads**: Current conversation context, `~/.acp/projects.yaml`, `agent/progress.yaml` (optional)
- **Writes**: `agent/reports/handoff-*.md` (if saved to disk)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Never include secrets, credentials, or tokens in handoff reports
- **Credentials**: Never include credentials

---

## Key Design Decisions

### Report Content

| Decision | Choice | Rationale |
|---|---|---|
| Session summary | Not included | Handoff is narrow in scope, focused on specific problem |
| Implementation steps | Not included | Receiving agent decides how to solve the problem |
| File paths | Absolute from `/` | Relative paths are meaningless across project contexts |
| Error/env context | Conditional | Only included when necessary to understand the problem |

### Report Format & Delivery

| Decision | Choice | Rationale |
|---|---|---|
| Template | Freeform | Each handoff has different needs; rigid templates add friction |
| Output destination | User prompted | Some handoffs are quick (chat), others need persistence (disk) |
| Disk location | `agent/reports/` | Consistent with project structure |
| Context source | Chat conversation | Primary source; progress.yaml used only if needed |

### Target & Lifecycle

| Decision | Choice | Rationale |
|---|---|---|
| Target identification | Infer first, ask if failed | Reduces friction for obvious cases |
| ACP projects.yaml support | Yes | Enables project name resolution |
| Receiving command | None | User pastes/references report manually |
| Status tracking | None | Lightweight; no lifecycle overhead |

---

## Notes

- The handoff report should be self-contained — the receiving agent should not need access to the source project to understand the request
- Chat context is the primary source; the agent synthesizes from conversation, not from exhaustive file scanning
- Keep reports focused and concise — describe the problem and what's needed, not everything that happened
- The `agent/reports/` directory is created on first use if it doesn't exist

---

**Namespace**: acp  
**Command**: handoff  
**Version**: 1.0.0  
**Created**: 2026-03-13  
**Last Updated**: 2026-03-13  
**Status**: Active  
**Compatibility**: ACP 5.15.0+  
**Author**: ACP Project  
