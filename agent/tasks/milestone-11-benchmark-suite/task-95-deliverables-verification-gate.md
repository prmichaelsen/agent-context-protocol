# Task 95: Add Deliverables Verification Gate to @acp.proceed

**Milestone**: [M11 - ACP Benchmark Suite](../milestones/milestone-11-benchmark-suite.md)
**Estimated Time**: 3-4 hours
**Dependencies**: None
**Status**: Not Started

---

## Objective

Enhance the `@acp.proceed` command with a mandatory deliverables verification gate that ensures all expected files and artifacts exist before a task can be marked complete. This addresses benchmark failures where the ACP agent produces correct, passing code but misses required documentation or artifact files (e.g., README.md in saas-platform benchmark scored 2/3 checks due to missing file).

---

## Context

In the saas-platform benchmark (2026-03-01), the ACP agent:
- Passed `file_executable` (correct directory structure) and `output_correct` (98 tests passing)
- Failed `file_exists` because README.md was not created during the docs step
- Scored 7.3/10 (EXCEEDS) on LLM eval but failed overall verification
- The baseline agent passed `file_exists` but failed the other two checks

The root cause: `@acp.proceed` tells agents to "verify functionality as you go" and "check all verification items" but has no explicit step requiring agents to confirm that all files listed in a task's Expected Output section actually exist on disk before marking complete. The methodology relies on agent diligence rather than enforcing a structured verification protocol.

Three changes are needed:
1. **Deliverables gate** in `@acp.proceed` — explicit step between implementation and progress update
2. **Completion sweep** for multi-task/milestone work — final audit after all tasks done
3. **Documentation parity** — methodology guidance that doc files are first-class deliverables

---

## Steps

### 1. Add Deliverables Verification Gate to Single-Task Mode

Edit `agent/commands/acp.proceed.md` to add a new **Step 3.5** (between current Step 3 "Complete the Task" and Step 4 "Update Progress Tracking"):

**New step: "Verify All Deliverables Exist"**

Content to add:

```markdown
### 3.5. Verify All Deliverables Exist

**Before marking a task complete, you MUST verify every expected deliverable:**

1. **Re-read the task document** — specifically the "Expected Output", "Acceptance Criteria", and "Verification" sections
2. **Check file existence** — for every file listed in "Files Created", verify it exists on disk (ls or stat)
3. **Check file content** — for files with specific content requirements (README, docs, configs), verify they contain the required sections
4. **Check modifications** — for every file listed in "Files Modified", verify the expected changes are present
5. **Walk the verification checklist** — go through each checkbox item and confirm it passes

**If ANY deliverable is missing:**
- DO NOT mark the task complete
- DO NOT move to progress update
- Create the missing deliverable first, then re-verify
- Only proceed to Step 4 when ALL deliverables confirmed

**This step is NON-NEGOTIABLE.** A task with passing tests but missing files is NOT complete.
```

### 2. Add Completion Sweep to Autonomous Mode

Edit `agent/commands/acp.proceed.md` to add a new step **A3.5** in the Autonomous Task Loop (between the loop and the Summary Report):

**New step: "Milestone Completion Sweep"**

Content to add:

```markdown
### A3.5. Milestone Completion Sweep

**After ALL tasks in the autonomous loop are done, perform a final deliverables audit:**

1. **Re-read each completed task's Expected Output section**
2. **Verify all files exist** — ls/stat every file listed across all tasks
3. **Run the full test suite** one final time
4. **Check for common omissions:**
   - README.md or project documentation
   - Configuration files (.env.example, etc.)
   - Architecture/design documentation if specified
   - Migration guides if specified

**If any deliverable from any task is missing:**
- Create it before generating the Summary Report
- Re-run verification for the affected task
- Only proceed to Summary Report when all tasks' deliverables are confirmed

This sweep catches files that may have been missed during individual task execution, especially documentation artifacts that are easy to overlook during coding-heavy milestones.
```

### 3. Add Documentation Parity Guidance to AGENT.md

Edit `AGENT.md` in the "Quality Best Practices" section to add:

```markdown
#### Documentation is a First-Class Deliverable
- README.md, architecture docs, and migration guides are deliverables equal to source code
- A project with passing tests but missing required documentation is INCOMPLETE
- Verify documentation files exist and contain required sections before marking tasks complete
- Documentation tasks deserve the same rigor as implementation tasks
```

### 4. Strengthen the Single-Task Verification Checklist

In `@acp.proceed`, update the Single-Task Mode verification section to explicitly include deliverables:

Add these items to the existing checklist:
```markdown
- [ ] All files in task's "Expected Output > Files Created" confirmed to exist
- [ ] All files in task's "Expected Output > Files Modified" confirmed to have changes
- [ ] Documentation deliverables (README, docs) contain required sections
```

### 5. Strengthen the Autonomous Mode Verification Checklist

In `@acp.proceed`, update the Autonomous Mode verification section:

Add this item:
```markdown
- [ ] Milestone completion sweep performed (all deliverables across all tasks verified)
```

---

## Verification

- [ ] `@acp.proceed` Step 3.5 added with deliverables verification gate
- [ ] `@acp.proceed` Step A3.5 added with milestone completion sweep
- [ ] `AGENT.md` updated with documentation parity guidance in Quality Best Practices
- [ ] Single-task verification checklist includes file existence checks
- [ ] Autonomous mode verification checklist includes completion sweep
- [ ] Changes are consistent with existing `@acp.proceed` structure and tone
- [ ] No existing steps broken or reordered incorrectly

---

## Expected Output

### Files Modified
- `agent/commands/acp.proceed.md` — Added Step 3.5 (deliverables gate), Step A3.5 (completion sweep), updated verification checklists
- `AGENT.md` — Added documentation parity guidance to Quality Best Practices section

---

## Common Issues and Solutions

### Issue 1: Step numbering conflicts
**Symptom**: Adding Step 3.5 disrupts existing step references
**Solution**: Use 3.5 notation (not renumbering) to avoid breaking cross-references. Alternatively, rename to "Step 3b" or integrate into Step 3 as a sub-step.

### Issue 2: Completion sweep adds too much overhead
**Symptom**: Autonomous mode takes significantly longer with the sweep
**Solution**: The sweep only re-reads task docs and checks file existence — it should take under 30 seconds per task. This is negligible compared to implementation time.

---

## Notes

- This task was motivated by the saas-platform benchmark failure where ACP passed 2/3 checks but missed README.md
- The enhancement is methodology-level (documentation changes), not code changes
- The deliverables gate should be phrased as non-negotiable to ensure agents follow it even under context pressure
- The completion sweep is specifically designed for multi-step work where individual task verification may miss files

---

**Next Task**: None (standalone enhancement)
**Related Design Docs**: None
**Estimated Completion Date**: TBD
