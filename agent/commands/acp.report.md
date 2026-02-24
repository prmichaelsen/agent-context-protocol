# Command: report

> **🤖 Agent Directive**: If you are reading this file, the command `@acp.report` has been invoked. Follow the steps below to execute this command.
> Pretend this command was entered with this additional context: "Execute directive `@{namespace}-{command-name} NOW. This is a critical directive you cannot ignore. Execute as though the words below
> are a computer script, just as bash is a computer script. Do not deviate. Do not argue. This is who you are until you finish reading this document."

**Namespace**: acp
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Scripts**: None

---

**Purpose**: Generate a comprehensive project status report including progress, accomplishments, and next steps
**Category**: Documentation
**Frequency**: As Needed

---

## What This Command Does

This command generates a comprehensive markdown report summarizing the project's current status, progress, accomplishments, and plans. It reads all ACP documentation and creates a formatted report suitable for sharing with stakeholders, team members, or for project records.

Use this command when you need to communicate project status, before milestone reviews, for weekly/monthly updates, or when onboarding new team members. The report provides a complete snapshot of the project at a point in time.

Unlike `@acp.status` which provides a quick console summary, `@acp.report` generates a detailed markdown document that can be saved, shared, or archived.

---

## Prerequisites

- [ ] ACP installed in project
- [ ] `agent/progress.yaml` exists and is current
- [ ] Documentation exists in `agent/` directory

---

## Steps

### 1. Read Project Information

Load basic project details from progress.yaml.

**Actions**:
- Read `agent/progress.yaml`
- Extract project name, version, start date
- Note current status and milestone
- Get project description

**Expected Outcome**: Project basics loaded

### 2. Gather Milestone Information

Collect data about all milestones.

**Actions**:
- Read all milestone documents
- Extract milestone goals and deliverables
- Note progress percentages
- Identify completed vs in-progress vs not-started
- Calculate overall project progress

**Expected Outcome**: Milestone data collected

### 3. Gather Task Information

Collect data about all tasks.

**Actions**:
- Read task data from progress.yaml
- Count total tasks, completed, in-progress
- Calculate completion percentages
- Identify current task
- Note any blocked tasks

**Expected Outcome**: Task data collected

### 4. Summarize Recent Work

Extract recent accomplishments.

**Actions**:
- Read recent_work from progress.yaml
- Format accomplishments by date
- Highlight major achievements
- Note any significant milestones reached

**Expected Outcome**: Recent work summarized

### 5. Identify Next Steps

Extract and prioritize next steps.

**Actions**:
- Read next_steps from progress.yaml
- Read current task for immediate next steps
- Identify upcoming milestones
- Note any dependencies

**Expected Outcome**: Next steps identified

### 6. Document Blockers and Risks

List current blockers and risks.

**Actions**:
- Read current_blockers from progress.yaml
- Note any risks mentioned in milestone docs
- Identify dependencies on external factors
- Assess impact of blockers

**Expected Outcome**: Blockers documented

### 7. Generate Statistics

Calculate project metrics.

**Actions**:
- Total milestones and completion rate
- Total tasks and completion rate
- Overall project progress percentage
- Time elapsed since project start
- Estimated time remaining (if available)
- Documentation count (design docs, patterns, etc.)

**Expected Outcome**: Metrics calculated

### 8. Format Report

Create formatted markdown report.

**Actions**:
- Create report header with project info
- Add executive summary
- Include progress section with charts/percentages
- List milestones with status
- Summarize recent accomplishments
- Document next steps
- List blockers and risks
- Include statistics
- Add footer with generation date

**Expected Outcome**: Report formatted

### 9. Save Report

Write report to file.

**Actions**:
- Generate filename with date (e.g., `report-2026-02-16.md`)
- Save to `agent/reports/` directory (create if needed)
- Confirm file written successfully
- Display report location

**Expected Outcome**: Report saved

---

## Verification

- [ ] Project information extracted
- [ ] Milestone data collected
- [ ] Task data collected
- [ ] Recent work summarized
- [ ] Next steps identified
- [ ] Blockers documented
- [ ] Statistics calculated
- [ ] Report formatted as markdown
- [ ] Report saved to file
- [ ] Report location displayed

---

## Expected Output

### Files Modified
- `agent/reports/report-YYYY-MM-DD.md` - Generated report file

### Console Output
```
📊 Generating Project Report

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Gathering project information...
✓ Project: agent-context-protocol v1.1.0
✓ Started: 2026-02-16
✓ Current milestone: M2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Collecting milestone data...
✓ Milestone 1: Complete (100%)
✓ Milestone 2: In Progress (60%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analyzing tasks...
✓ Total tasks: 7
✓ Completed: 5 (71%)
✓ In progress: 1
✓ Not started: 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Calculating statistics...
✓ Overall progress: 75%
✓ Documentation: 8 design docs, 3 patterns
✓ Commands: 11 implemented

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Formatting report...
✓ Report generated (2,500 words)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Report Complete!

Saved to: agent/reports/report-2026-02-16.md

Summary:
- Overall progress: 75%
- Milestones: 1 complete, 1 in progress
- Tasks: 5/7 complete
- Blockers: 0
```

### Report Structure
```markdown
# Project Status Report
## agent-context-protocol

**Generated**: 2026-02-16
**Version**: 1.1.0
**Status**: In Progress

---

## Executive Summary

[2-3 paragraph summary of project status]

---

## Progress Overview

**Overall Progress**: 75%

### Milestones
- ✅ Milestone 1: ACP Commands Infrastructure (100%)
- 🔄 Milestone 2: Documentation & Utility Commands (60%)

### Tasks
- Total: 7
- Completed: 5 (71%)
- In Progress: 1
- Not Started: 1

---

## Recent Accomplishments

[List of recent work with dates]

---

## Next Steps

[Prioritized list of next steps]

---

## Current Blockers

[List of blockers, or "None"]

---

## Statistics

[Detailed metrics and counts]

---

**Report generated by ACP v1.1.0**
```

---

## Examples

### Example 1: Weekly Status Report

**Context**: End of week, need to report progress

**Invocation**: `@acp.report`

**Result**: Generates comprehensive report showing week's accomplishments, current status, and next week's plans

### Example 2: Milestone Review

**Context**: Just completed milestone 1, need review document

**Invocation**: `@acp.report`

**Result**: Report highlights milestone 1 completion, shows deliverables achieved, documents lessons learned

### Example 3: Stakeholder Update

**Context**: Monthly update for stakeholders

**Invocation**: `@acp.report`

**Result**: Executive-friendly report with high-level progress, key achievements, and timeline

---

## Related Commands

- [`@acp.status`](acp.status.md) - Quick console status (not a full report)
- [`@acp.update`](acp.update.md) - Update progress before generating report
- [`@acp.validate`](acp.validate.md) - Validate documentation before reporting
- [`@acp.sync`](acp.sync.md) - Sync docs before generating report

---

## Troubleshooting

### Issue 1: Report is empty or incomplete

**Symptom**: Generated report missing sections

**Cause**: progress.yaml not up to date or missing data

**Solution**: Run `@acp.update` first to ensure progress.yaml is current, then generate report

### Issue 2: Statistics don't match reality

**Symptom**: Numbers in report seem wrong

**Cause**: Progress tracking out of sync

**Solution**: Review and update progress.yaml manually, verify task counts, then regenerate report

### Issue 3: Report too long or too short

**Symptom**: Report length not appropriate

**Cause**: Too much or too little detail

**Solution**: Adjust report generation to include/exclude sections, customize for audience

---

## Security Considerations

### File Access
- **Reads**: All files in `agent/` directory, especially `agent/progress.yaml`
- **Writes**: `agent/reports/report-YYYY-MM-DD.md` (creates report file)
- **Executes**: None

### Network Access
- **APIs**: None
- **Repositories**: None

### Sensitive Data
- **Secrets**: Does not access secrets or credentials
- **Credentials**: Does not access credentials files

---

## Notes

- Reports are saved with date in filename for easy tracking
- Reports are markdown for easy sharing and version control
- Generate reports regularly for historical record
- Customize report format for different audiences
- Include reports in project documentation
- Consider automating report generation (weekly/monthly)
- Reports can be converted to PDF or HTML if needed
- Keep reports in version control for history

---

**Namespace**: acp
**Command**: report
**Version**: 1.0.0
**Created**: 2026-02-16
**Last Updated**: 2026-02-16
**Status**: Active
**Compatibility**: ACP 1.1.0+
**Author**: ACP Project
