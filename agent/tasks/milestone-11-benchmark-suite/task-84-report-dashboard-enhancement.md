# Task 84: Report & Dashboard Enhancement

**Milestone**: M11 - ACP Benchmark Suite  
**Estimated Time**: 4-5 hours  
**Dependencies**: Task 79 (metrics), Task 83 (evaluator scores)  
**Status**: Not Started  

---

## Objective

Enhance report generation to support multi-task, multi-run data with ACP vs baseline comparison tables, statistical averaging, per-step breakdowns, and an improved HTML dashboard.

---

## Context

Current reports handle single-task, single-run data. The design spec calls for comparison summaries across tasks and modes with 5-run averaging. Reports need per-step breakdowns, phase-level analysis, and improvement percentages.

---

## Steps

### 1. Update report-markdown.sh
- Support multiple tasks in one report
- ACP vs baseline comparison table with improvement percentages
- 5-run statistical averaging (mean, stddev)
- Per-step breakdown per task
- LLM evaluator scores section

### 2. Update report-html.sh
- Styled comparison dashboard
- Color-coded improvement metrics
- Per-task expandable sections
- Evaluation radar chart (6 rubric dimensions)
- Run-by-run detail tables

### 3. Update summary.yaml Format
- Multi-task structure
- Per-run and averaged metrics
- Evaluator scores per task/mode

### 4. Update serve-reports.sh Index
- Show multi-task summaries in index
- Link to per-task detail pages
- Show improvement percentages in table

---

## Verification

- [ ] Markdown report has comparison table with improvement %
- [ ] HTML dashboard is visually clear with color-coded metrics
- [ ] 5-run averaging produces mean and stddev
- [ ] Per-step breakdowns show phase-level analysis
- [ ] Evaluator scores displayed in reports
- [ ] serve-reports.sh index shows multi-task summaries

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (Report Generation)  
