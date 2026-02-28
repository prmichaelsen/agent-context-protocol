# Milestone 11: ACP Benchmark Suite

**Goal**: Complete E2E benchmark suite comparing project outcomes with and without ACP, with multi-turn tasks, LLM evaluation, statistical reporting, and CI/CD integration
**Duration**: 3-5 weeks
**Dependencies**: None (benchmark infrastructure partially exists)
**Status**: Not Started

---

## Overview

This milestone implements the full ACP Benchmark Suite as specified in the design document (`agent/design/local.benchmark-suite.md`). The suite runs identical project-building tasks with and without ACP, using Claude Code CLI in non-interactive mode, measuring impact on agent-driven development through quantitative metrics.

Each benchmark task is a multi-turn conversation (build, test, correct, refactor) executed 5 times per mode (ACP vs baseline) for statistical averaging. An LLM evaluator scores output quality. Reports are generated in YAML, Markdown, and HTML.

**Existing infrastructure** (from prior work):
- Runner scripts: run-benchmark.sh, run-single.sh, verify.sh, report-markdown.sh, report-html.sh, serve-reports.sh
- One trivial benchmark task (hello-world) — kept as smoke test
- Report pipeline (YAML → MD → HTML) — working
- 3 baseline test runs completed

**What this milestone adds**:
- Multi-turn step execution with `--resume` session continuity
- 3 proper benchmark tasks (simple, medium, complex) with multi-turn steps
- Fixed metrics collection (token/cost parsing)
- LLM evaluator with rubric and structured scoring
- Multi-run statistical averaging (5 runs per config)
- Enhanced reports with comparison tables and dashboards
- GitHub Actions on-demand workflow
- Historical tracking via GitHub Pages

---

## Deliverables

### 1. Runner Infrastructure Enhancement
- Multi-turn step execution (sequential prompts via `--resume`)
- Per-step metrics capture (tokens, time, turns per step)
- Fixed token/cost metric extraction from Claude CLI JSON output
- Metrics aggregation across steps and runs
- 5-run statistical averaging

### 2. Benchmark Task Definitions (3 tasks)
- **simple-cli-tool**: Build a CLI tool (3 steps: build, test, correction)
- **medium-rest-api**: Build a REST API (4 steps: build, test, correction, refactor)
- **complex-auth-system**: Add authentication (5 steps: scaffold, auth, test, correction, docs)
- Each with: config.yaml, steps/*.md, expected/structure.yaml

### 3. LLM Evaluator
- Evaluator prompt with rubric (correctness, completeness, code style, documentation, architecture, testing)
- Evaluation schema (JSON) for structured output
- Numeric scores (1-10) + categorical ratings (MISS/MEETS/EXCEEDS)
- Integration into runner pipeline

### 4. Report Enhancement
- Multi-task, multi-run comparison tables
- ACP vs baseline side-by-side metrics
- Per-step and per-phase breakdowns
- Statistical averaging with variance
- Enhanced HTML dashboard

### 5. GitHub Actions & Tracking
- On-demand workflow dispatch
- Report artifact upload
- Historical tracking across versions
- GitHub Pages dashboard

---

## Success Criteria

- [ ] `run-benchmark.sh` executes multi-turn tasks with `--resume` session continuity
- [ ] 3 benchmark tasks defined with multi-turn steps and expected outputs
- [ ] Metrics correctly capture tokens, cost, turns, and wall clock time per step
- [ ] 5 runs per configuration with statistical averaging
- [ ] LLM evaluator scores outputs on 6 rubric categories
- [ ] Reports show ACP vs baseline comparison with improvement percentages
- [ ] GitHub Actions workflow runs on-demand
- [ ] hello-world smoke test still passes
- [ ] Full suite produces valid YAML, Markdown, and HTML reports

---

## Key Files to Create/Modify

```
agent/benchmarks/
├── suite/
│   ├── hello-world/              (existing — keep as smoke test)
│   ├── simple-cli-tool/          (NEW)
│   │   ├── config.yaml
│   │   ├── steps/
│   │   │   ├── 01-build.md
│   │   │   ├── 02-test.md
│   │   │   └── 03-correction.md
│   │   └── expected/
│   │       └── structure.yaml
│   ├── medium-rest-api/          (NEW)
│   │   ├── config.yaml
│   │   ├── steps/
│   │   │   ├── 01-build.md
│   │   │   ├── 02-test.md
│   │   │   ├── 03-correction.md
│   │   │   └── 04-refactor.md
│   │   └── expected/
│   │       └── structure.yaml
│   └── complex-auth-system/      (NEW)
│       ├── config.yaml
│       ├── steps/
│       │   ├── 01-scaffold.md
│       │   ├── 02-auth.md
│       │   ├── 03-test.md
│       │   ├── 04-correction.md
│       │   └── 05-docs.md
│       └── expected/
│           └── structure.yaml
├── runner/
│   ├── run-benchmark.sh          (MODIFY — multi-turn, multi-run)
│   ├── run-single.sh             (MODIFY — multi-turn steps, metrics fix)
│   ├── verify.sh                 (MODIFY — add verification for new tasks)
│   ├── metrics-collector.sh      (NEW — aggregate per-step metrics)
│   ├── evaluator-prompt.md       (NEW — LLM evaluator rubric)
│   ├── evaluation-schema.json    (NEW — structured evaluation output)
│   ├── report-markdown.sh        (MODIFY — multi-run comparison)
│   ├── report-html.sh            (MODIFY — dashboard enhancement)
│   └── serve-reports.sh          (existing — already fixed)
└── reports/                      (generated — not committed)

.github/workflows/
└── benchmark.yaml                (NEW — on-demand dispatch)
```

---

## Tasks

1. [Task 79: Runner Multi-Turn & Metrics Fix](../tasks/milestone-11-benchmark-suite/task-79-runner-multi-turn-metrics.md) — Upgrade runner for multi-turn steps, fix token metrics (6-8h)
2. [Task 80: Simple CLI Tool Benchmark](../tasks/milestone-11-benchmark-suite/task-80-simple-cli-tool-benchmark.md) — Define simple-cli-tool with 3 steps (3-4h)
3. [Task 81: Medium REST API Benchmark](../tasks/milestone-11-benchmark-suite/task-81-medium-rest-api-benchmark.md) — Define medium-rest-api with 4 steps (4-5h)
4. [Task 82: Complex Auth System Benchmark](../tasks/milestone-11-benchmark-suite/task-82-complex-auth-system-benchmark.md) — Define complex-auth-system with 5 steps (5-6h)
5. [Task 83: LLM Evaluator](../tasks/milestone-11-benchmark-suite/task-83-llm-evaluator.md) — Evaluator prompt, schema, integration (4-6h)
6. [Task 84: Report & Dashboard Enhancement](../tasks/milestone-11-benchmark-suite/task-84-report-dashboard-enhancement.md) — Multi-run reports, comparison tables (4-5h)
7. [Task 85: GitHub Actions Workflow](../tasks/milestone-11-benchmark-suite/task-85-github-actions-workflow.md) — On-demand CI/CD benchmark workflow (2-3h)
8. [Task 86: Documentation & Historical Tracking](../tasks/milestone-11-benchmark-suite/task-86-documentation-historical-tracking.md) — GitHub Pages, docs, README (3-4h)

**Total Estimated**: 31-41 hours

---

## Environment Variables

```env
# Claude CLI (for benchmark execution)
# Uses Claude Max subscription — no API key needed for claude CLI
# API key alternative: ANTHROPIC_API_KEY=sk-...

# GitHub Actions (for CI/CD)
# Uses repository secrets for Claude access
```

---

## Testing Requirements

- [ ] hello-world smoke test passes (existing)
- [ ] Multi-turn step execution works with --resume
- [ ] Token metrics correctly parsed from Claude CLI JSON output
- [ ] 5-run averaging produces valid statistics
- [ ] LLM evaluator returns valid structured scores
- [ ] Reports contain all required fields and comparison data
- [ ] GitHub Actions workflow triggers on dispatch

---

## Documentation Requirements

- [ ] Design document updated with implementation status
- [ ] README updated with benchmark section
- [ ] AGENT.md updated with benchmark suite reference
- [ ] CHANGELOG.md entries for each task

---

## Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| High LLM token cost | Medium | Medium | On-demand only, Claude Max subscription, start with single runs |
| Claude CLI JSON output format changes | High | Low | Pin CLI version, add format validation |
| Non-deterministic benchmark results | Medium | High | 5-run averaging, report variance/stddev |
| Multi-turn --resume session issues | High | Medium | Fallback to single-turn, test with hello-world first |
| LLM evaluator scoring inconsistency | Medium | Medium | Structured rubric, calibrate on known samples |
| Long execution times | Medium | High | Parallel execution where possible, start with simple task |

---

**Next Milestone**: TBD
**Blockers**: None
**Notes**:
- hello-world kept as smoke test (not part of the 3 benchmark tasks)
- Design doc is comprehensive — this milestone implements it fully
- Phases 1-3 (runner, tasks, metrics) should be done first before evaluator and reports
- Full suite run may take hours — design for incremental testing
