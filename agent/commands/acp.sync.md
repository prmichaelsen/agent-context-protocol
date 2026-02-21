# Command: sync

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.sync` has been invoked. Follow the steps below to execute this command.

**Namespace**: acp
**Version**: 1.1.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-18
**Status**: Active

---

**Purpose**: Synchronize documentation with source code by identifying and updating stale documentation
**Category**: Documentation
**Frequency**: As Needed

---

## What This Command Does

This command synchronizes ACP documentation with the actual source code implementation. It reads source files, compares them with design documents and patterns, identifies documentation drift, and updates stale documentation to match reality.

Use this command after making significant code changes, when you suspect documentation is outdated, or periodically to ensure documentation stays current. It's particularly useful after implementing features, refactoring code, or completing milestones.

Unlike `@acp.update` which updates progress tracking, `@acp.sync` focuses on keeping design documents, patterns, and technical documentation aligned with the actual codebase.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] Source code exists to compare against
- [ ] Documentation exists in `agent/` directory (design, tasks, patterns)
- [ ] Scripts exist in `agent/scripts/` (if applicable)
- [ ] You have understanding of what changed in code

---

## Steps

### 1. Read Design Documents

Load all design documents to understand documented architecture.

**Actions**:
- Read all files in `agent/design/`
- Note documented features, patterns, and architecture
- Understand documented API contracts
- Identify documented dependencies
- List documented file structures

**Expected Outcome**: Documented architecture understood

### 2. Read Task Documents

Review task documents to understand documented implementation approach.

**Actions**:
- Read all files in `agent/tasks/`
- Note documented implementation steps
- Identify documented tools and dependencies
- Check for code examples in task steps
- List documented functions and approaches

**Expected Outcome**: Documented implementation approach understood

### 3. Read Source Code

Review actual implementation in source files.

**Actions**:
- Identify main source directories (src/, lib/, cmd/, etc.)
- Read key implementation files
- Note actual features implemented
- Understand actual architecture
- Identify actual dependencies and tools used
- Document actual file structures
- Check which functions/utilities are actually implemented
- **Compare implementation approach with task document examples**

**Expected Outcome**: Actual implementation understood

### 4. Compare Documentation vs Reality

Identify discrepancies between docs and code.

**Actions**:
- Compare documented features with implemented features
- **Compare documented tools (e.g., yq) with actual tools (e.g., acp.yaml-parser.sh)**
- **Compare documented functions with actual implementations**
- **Check if task code examples match actual code in scripts**
- Check if documented patterns match actual patterns
- Verify API contracts match implementation
- Compare file structures
- Note undocumented features in code
- Identify documented features not yet implemented
- **Flag task documents with outdated code examples**

**Expected Outcome**: Documentation drift identified (including implementation details)

### 5. Identify Stale Documentation

Determine which documents need updates.

**Actions**:
- List design docs that are outdated
- **List task docs with outdated code examples or tool references**
- Note patterns that don't match code
- Identify missing documentation for new features
- Flag incorrect technical specifications
- **Flag task documents referencing wrong tools (e.g., yq vs acp.yaml-parser.sh)**
- Prioritize updates by importance

**Expected Outcome**: Update priorities established

### 6. Update Design Documents

Refresh design documents to match reality.

**Actions**:
- Update feature descriptions
- Correct technical specifications
- Update code examples to match actual code
- Add notes about implementation differences
- Update status fields (Proposal → Implemented)
- Add "Last Updated" dates

**Expected Outcome**: Design docs reflect reality

### 7. Update Task Documents

Refresh task documents to match actual implementation.

**Actions**:
- **Update code examples in task steps to match actual code**
- **Replace references to external tools with actual tools used**
- **Update function names to match actual implementations**
- **Add notes about completed vs remaining work**
- **Update Common Issues sections**
- Mark completed steps as done

**Expected Outcome**: Task docs reflect actual implementation approach

### 8. Update Pattern Documents

Refresh patterns to match actual usage.

**Actions**:
- Update pattern examples with real code
- Correct pattern descriptions
- Add new patterns discovered in code
- Update anti-patterns based on lessons learned
- Ensure code examples compile/work

**Expected Outcome**: Patterns match actual usage

### 9. Document New Features

Add documentation for undocumented features.

**Actions**:
- Create design docs for undocumented features
- Document new patterns found in code
- Add technical specifications
- Include code examples
- Link related documents

**Expected Outcome**: All features documented

### 10. Update Progress Tracking

Update progress.yaml to reflect sync activity.

**Actions**:
- Add recent work entry for sync
- Note what was updated
- Update documentation counts if needed
- Add notes about documentation status

**Expected Outcome**: Sync activity tracked

---

## Verification

- [ ] All design documents reviewed
- [ ] **All task documents reviewed for code examples**
- [ ] Source code reviewed and compared
- [ ] **Scripts reviewed for actual tool usage (acp.yaml-parser.sh vs yq, etc.)**
- [ ] Documentation drift identified
- [ ] **Task document code examples checked against actual scripts**
- [ ] Stale documents updated
- [ ] **Task documents updated to match actual implementation**
- [ ] New features documented
- [ ] Pattern documents current
- [ ] Code examples work correctly
- [ ] progress.yaml updated with sync notes

---

## Expected Output

### Files Modified
- `agent/design/*.md` - Updated design documents
- `agent/patterns/*.md` - Updated pattern documents
- `agent/progress.yaml` - Sync activity logged
- Potentially new design/pattern documents created

### Console Output
```
🔄 Synchronizing Documentation with Code

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reading design documents...
✓ Read 5 design documents
✓ Read 3 pattern documents

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reviewing source code...
✓ Reviewed src/services/
✓ Reviewed src/models/
✓ Reviewed src/utils/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Comparing documentation vs reality...
⚠️  Found 3 discrepancies:
  1. auth-design.md: Documented OAuth, implemented API keys
  2. data-pattern.md: Example code outdated
  3. api-design.md: Missing /health endpoint documentation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Updating documentation...
✓ Updated auth-design.md (OAuth → API keys)
✓ Updated data-pattern.md (refreshed examples)
✓ Updated api-design.md (added /health endpoint)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Sync Complete!

Summary:
- Documents reviewed: 8
- Discrepancies found: 3
- Documents updated: 3
- New documents created: 0
- Documentation is now current
```

### Status Update
- Design documents synchronized
- Patterns updated
- New features documented
- Sync logged in progress.yaml

---

## Examples

### Example 1: After Major Refactoring

**Context**: Refactored authentication system, docs are outdated

**Invocation**: `@acp.sync`

**Result**: Identifies auth-design.md is stale, updates it to reflect new implementation, updates related patterns

### Example 2: After Adding Features

**Context**: Added 3 new API endpoints, not yet documented

**Invocation**: `@acp.sync`

**Result**: Identifies undocumented endpoints, updates api-design.md with new endpoints, adds code examples

### Example 3: Periodic Maintenance

**Context**: Monthly documentation review

**Invocation**: `@acp.sync`

**Result**: Reviews all docs, finds minor drift in 2 files, updates them, confirms rest is current

---

## Related Commands

- [`@acp.update`](acp.update.md) - Update progress tracking (not documentation)
- [`@acp.validate`](acp.validate.md) - Validate documentation structure and consistency
- [`@acp.init`](acp.init.md) - Includes sync as part of initialization
- [`@acp.report`](acp.report.md) - Generate report including documentation status

---

## Troubleshooting

### Issue 1: Can't determine what changed

**Symptom**: Unclear what documentation needs updating

**Cause**: Too many changes or unclear code

**Solution**: Review git commits since last sync, focus on major changes first, update incrementally

### Issue 2: Documentation and code both seem wrong

**Symptom**: Neither docs nor code match expected behavior

**Cause**: Requirements changed or misunderstood

**Solution**: Clarify requirements first, then update both code and docs to match correct requirements

### Issue 3: Too many discrepancies to fix

**Symptom**: Overwhelming number of outdated docs

**Cause**: Long time since last sync

**Solution**: Prioritize by importance, fix critical docs first, schedule time for rest, sync more frequently going forward

---

## Security Considerations

### File Access
- **Reads**: All files in `agent/design/`, `agent/patterns/`, source code directories
- **Writes**: `agent/design/*.md`, `agent/patterns/*.md`, `agent/progress.yaml`
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access secrets or credentials
- **Credentials**: Does not access credentials files

---

## Notes

- This command can be time-consuming for large projects
- Focus on high-priority documentation first
- Sync regularly to avoid large drift
- Use git diff to see what changed in code
- Document the "why" not just the "what"
- Keep code examples working and tested
- Update "Last Updated" dates in documents
- Consider running after each milestone completion

---

**Namespace**: acp
**Command**: sync
**Version**: 1.1.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-18
**Status**: Active
**Compatibility**: ACP 1.1.0+
**Author**: ACP Project
