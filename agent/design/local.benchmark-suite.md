# ACP Benchmark Suite

**Concept**: E2E benchmark system comparing project outcomes with and without ACP to generate quantitative success metrics
**Created**: 2026-02-27
**Status**: Implemented

---

## Overview

This design describes an automated E2E benchmark suite that runs identical project-building tasks with and without ACP, measuring the impact of ACP on agent-driven development. The suite produces structured reports with quantitative metrics (time, tokens, code quality, conversation efficiency) that serve as data points for potential ACP consumers.

The benchmark uses Claude Code CLI in non-interactive mode (`claude -p`) to execute tasks in isolated environments, runs each scenario 5 times for statistical averaging, and generates reports in YAML, Markdown, and HTML formats.

---

## Problem Statement

- ACP claims to improve AI-driven development workflows, but there is no empirical data to back this up.
- Potential consumers have no quantitative basis for evaluating ACP's value proposition.
- Without reproducible benchmarks, improvements or regressions in ACP versions go undetected.
- The project needs concrete success metrics for documentation, marketing, and design decisions.

---

## Solution

A reproducible benchmark suite located in this project that:

1. Defines a suite of varied benchmark tasks (simple, medium, complex) across specific domains
2. Runs each task **with ACP** (full `@acp-init` + documentation + commands) and **without ACP** (vanilla environment, zero documentation)
3. Executes 5 runs per configuration to account for LLM non-determinism
4. Captures metrics: wall clock time, token usage, conversation loops, retries, code quality
5. Uses an LLM evaluator pass to assess outputs against rubrics and golden reference implementations
6. Generates structured reports with individual run data and comparison summaries

### Architecture

```
agent/benchmarks/
├── suite/                          # Benchmark task definitions
│   ├── simple-cli-tool/            # Simple: build a CLI tool
│   │   ├── steps/                  # Multi-turn conversation steps
│   │   │   ├── 01-build.md         # "Build a CLI tool that..."
│   │   │   ├── 02-test.md          # "Add tests for..."
│   │   │   └── 03-correction.md    # "The --verbose flag doesn't..."
│   │   ├── expected/               # Golden reference output
│   │   │   ├── structure.yaml      # Expected dirs/files spec
│   │   │   └── src/                # Reference implementation
│   │   └── config.yaml             # Steps, phases, max_turns, timeout
│   ├── medium-rest-api/            # Medium: build a REST API
│   │   ├── steps/
│   │   │   ├── 01-build.md
│   │   │   ├── 02-test.md
│   │   │   ├── 03-correction.md
│   │   │   └── 04-refactor.md
│   │   ├── expected/
│   │   └── config.yaml
│   └── complex-auth-system/        # Complex: add authentication
│       ├── steps/
│       │   ├── 01-scaffold.md
│       │   ├── 02-auth.md
│       │   ├── 03-test.md
│       │   ├── 04-correction.md
│       │   └── 05-docs.md
│       ├── expected/
│       └── config.yaml
├── runner/                         # Benchmark execution engine
│   ├── run-benchmark.sh            # Main runner (all tasks x modes x runs)
│   ├── run-single.sh               # Single run (multi-turn step loop)
│   ├── metrics-collector.sh        # Aggregate per-step metrics
│   ├── evaluator-prompt.md         # LLM evaluator rubric
│   └── evaluation-schema.json      # JSON schema for evaluator output
├── reports/                        # Generated reports
│   └── benchmark-{date}/
│       ├── summary.md              # Comparison summary table
│       ├── summary.yaml            # Machine-readable summary
│       ├── html/                   # HTML dashboard
│       │   └── index.html
│       ├── runs/                   # Individual run data (per-step breakdown)
│       │   ├── simple-cli-tool-acp-run1.yaml
│       │   ├── simple-cli-tool-baseline-run1.yaml
│       │   └── ...
│       └── evaluations/            # LLM evaluator outputs
│           ├── simple-cli-tool-acp-eval.yaml
│           └── simple-cli-tool-baseline-eval.yaml
└── .github/
    └── workflows/
        └── benchmark.yaml          # On-demand GitHub Actions workflow
```

### Alternative Approaches Considered

- **Custom agent loop**: Building our own LLM agent loop for benchmarks. Rejected because it wouldn't be a true test of real-world ACP usage — Claude Code CLI is what users actually use.
- **Single benchmark task**: Using one task for all benchmarks. Rejected because varied complexity levels give a more complete picture.
- **API-based execution**: Using Anthropic API directly. Rejected in favor of Claude Code CLI which is the actual tool users interact with, and the user has Claude Max.

---

## Implementation

### Benchmark Task Definition

Each benchmark task is defined by:

```yaml
# suite/medium-rest-api/config.yaml
name: medium-rest-api
description: Build a REST API with CRUD operations
complexity: medium
domain: web
timeout_minutes: 30
runs: 5

expected_structure: expected/structure.yaml

# Multi-turn conversation steps (executed sequentially in one session)
steps:
  - id: build
    prompt_file: steps/01-build.md        # "Build a REST API with CRUD for a todo app"
    phase: coding
    max_turns: 30
  - id: test
    prompt_file: steps/02-test.md         # "Add comprehensive tests for all endpoints"
    phase: testing
    max_turns: 20
  - id: correction
    prompt_file: steps/03-correction.md   # "The DELETE endpoint returns 200 instead of 204, fix it"
    phase: debugging
    max_turns: 10
  - id: refactor
    prompt_file: steps/04-refactor.md     # "Extract route handlers into a separate module"
    phase: coding
    max_turns: 15

# Environment setup (run before benchmark)
setup:
  - mkdir -p workspace
  - cd workspace && git init

# Cleanup (run after benchmark)
teardown:
  - rm -rf workspace
```

```yaml
# suite/medium-rest-api/expected/structure.yaml
directories:
  - src/
  - src/routes/
  - tests/
files:
  - package.json
  - src/index.ts
  - src/routes/*.ts
  - tests/*.test.ts
  - README.md
```

### Execution Flow

```
┌──────────────────────────────────────────────────────┐
│              run-benchmark.sh                         │
│                                                       │
│  For each task in suite/:                            │
│    For each mode in [acp, baseline]:                 │
│      For run in 1..5:                                │
│        1. Create isolated temp dir                   │
│        2. If mode=acp: install ACP, run @acp-init    │
│        3. For each step in config.steps:             │
│           a. Execute: claude -p <step.prompt>        │
│              --output-format json                    │
│              --allowedTools "Bash,Read,Edit,Write"   │
│              --max-turns <step.max_turns>            │
│              --resume <session_id>  (steps 2+)       │
│           b. Capture per-step metrics from JSON      │
│           c. Tag metrics with step.phase             │
│        4. Run evaluator pass on final workspace      │
│        5. Aggregate step metrics into run report     │
│        6. Save run report                            │
│        7. Cleanup temp dir                           │
│                                                       │
│  Generate summary report                             │
│  Generate HTML dashboard                             │
└──────────────────────────────────────────────────────┘
```

Each benchmark task is a **multi-turn conversation** — the same Claude Code session receives sequential prompts (build, test, correct, refactor) via `--resume`, simulating how a developer actually works with an agent. This captures realistic metrics like how well the agent maintains context across steps and how corrections affect subsequent work.

### Claude Code CLI Integration

Multi-turn execution with per-step metrics capture:

```bash
# run-single.sh — Execute one full benchmark run (all steps)
TOOLS="Bash,Read,Edit,Write,Glob,Grep"
session_id=""

for step_idx in $(seq 0 $((NUM_STEPS - 1))); do
  step_id=$(yaml_query ".steps[$step_idx].id" < config.yaml)
  step_prompt=$(cat "steps/$(yaml_query ".steps[$step_idx].prompt_file" < config.yaml)")
  step_phase=$(yaml_query ".steps[$step_idx].phase" < config.yaml)
  max_turns=$(yaml_query ".steps[$step_idx].max_turns" < config.yaml)

  step_start=$(date +%s)

  if [ -z "$session_id" ]; then
    # First step — start new session
    result=$(claude -p "$step_prompt" \
      --output-format json \
      --allowedTools "$TOOLS" \
      --max-turns "$max_turns" \
      2>"$LOG_DIR/step-${step_id}-stderr.log")
    session_id=$(echo "$result" | jq -r '.session_id')
  else
    # Subsequent steps — resume same session
    result=$(claude -p "$step_prompt" \
      --resume "$session_id" \
      --output-format json \
      --allowedTools "$TOOLS" \
      --max-turns "$max_turns" \
      2>"$LOG_DIR/step-${step_id}-stderr.log")
  fi

  step_end=$(date +%s)

  # Save per-step metrics
  echo "$result" | jq --arg phase "$step_phase" \
    --arg step "$step_id" \
    --argjson wall "$((step_end - step_start))" '{
    step: $step,
    phase: $phase,
    wall_clock_seconds: $wall,
    session_id: .session_id,
    input_tokens: .usage.input_tokens,
    output_tokens: .usage.output_tokens,
    cache_creation_tokens: .usage.cache_creation_input_tokens,
    cache_read_tokens: .usage.cache_read_input_tokens,
    total_turns: .num_turns
  }' > "$METRICS_DIR/step-${step_id}.json"
done

# Aggregate all steps into run report
```

### ACP vs Baseline Setup

**ACP mode**:
```bash
# Install ACP in workspace
./agent/scripts/acp.install.sh "$WORKSPACE"
cd "$WORKSPACE"
# ACP is available — agent will discover AGENT.md and agent/ directory
```

**Baseline mode**:
```bash
# Empty workspace — no documentation, no ACP
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
git init
# Agent gets only the task prompt, nothing else
```

### Metrics Collection

```yaml
# Per-run metrics (runs/medium-rest-api-acp-run1.yaml)
task: medium-rest-api
mode: acp          # or "baseline"
run: 1
session_id: "abc-123-def"
timestamp: 2026-02-27T10:30:00Z

# Per-step breakdown (from multi-turn conversation)
steps:
  - id: build
    phase: coding
    wall_clock_seconds: 120
    tokens: { input: 45000, output: 18000, cache_creation: 5000, cache_read: 30000 }
    turns: 12
  - id: test
    phase: testing
    wall_clock_seconds: 60
    tokens: { input: 35000, output: 12000, cache_creation: 2000, cache_read: 50000 }
    turns: 6
  - id: correction
    phase: debugging
    wall_clock_seconds: 25
    tokens: { input: 20000, output: 8000, cache_creation: 1000, cache_read: 55000 }
    turns: 3
  - id: refactor
    phase: coding
    wall_clock_seconds: 40
    tokens: { input: 25000, output: 7000, cache_creation: 2000, cache_read: 58000 }
    turns: 4

# Aggregated totals
time:
  wall_clock_seconds: 245
  by_phase:
    coding_seconds: 160    # build + refactor
    testing_seconds: 60
    debugging_seconds: 25

tokens:
  input: 125000
  output: 45000
  cache_creation: 10000
  cache_read: 193000
  total: 373000
  estimated_cost_usd: 2.50

conversation:
  total_turns: 25
  turns_per_step_avg: 6.25
  retries: 2              # times agent retried a failed approach
  stuck_count: 1          # times agent appeared stuck

code_quality:
  files_created: 8
  directories_created: 4
  structure_match_pct: 85  # vs expected/structure.yaml
  compiles: true
  tests_pass: true
  test_count: 5
  lint_errors: 2
```

### LLM Evaluator

The evaluator runs as a separate Claude Code invocation:

```bash
claude -p "$(cat runner/evaluator-prompt.md)" \
  --output-format json \
  --json-schema "$(cat runner/evaluation-schema.json)" \
  --allowedTools "Read,Glob,Grep,Bash" \
  --max-turns 10
```

Evaluator rubric categories:
- **Correctness** (1-10): Does the code work as specified?
- **Completeness** (1-10): Are all requirements addressed?
- **Code Style** (1-10): Is the code clean, idiomatic, well-structured?
- **Documentation** (1-10): README quality, comments, commit messages
- **Architecture** (1-10): Project structure, separation of concerns
- **Testing** (1-10): Test quality and coverage

Each category also gets a categorical rating:
- `MISS` — Does not meet expectations
- `MEETS` — Meets expectations
- `EXCEEDS` — Exceeds expectations

### Report Generation

**Summary comparison table** (summary.md):

```markdown
# Benchmark Results: 2026-02-27

## Summary

| Task | Mode | Avg Time | Avg Tokens | Avg Score | Structure Match |
|------|------|----------|------------|-----------|-----------------|
| simple-cli-tool | ACP | 120s | 85K | 8.2/10 | 95% |
| simple-cli-tool | Baseline | 180s | 120K | 6.5/10 | 70% |
| medium-rest-api | ACP | 245s | 180K | 7.8/10 | 88% |
| medium-rest-api | Baseline | 400s | 250K | 5.2/10 | 55% |
| complex-auth | ACP | 480s | 320K | 7.5/10 | 82% |
| complex-auth | Baseline | 720s | 450K | 4.8/10 | 40% |

## ACP Improvement Summary

| Metric | Improvement |
|--------|-------------|
| Time to implement | -38% avg |
| Token usage | -30% avg |
| Code quality score | +45% avg |
| Structure accuracy | +55% avg |
```

**HTML dashboard**: Static HTML with comparison charts (can be served via GitHub Pages).

---

## Benefits

- **Empirical validation**: Concrete data proving ACP's value, not just anecdotal claims
- **Regression detection**: Track if ACP changes improve or degrade benchmark performance
- **Consumer confidence**: Potential users can see quantitative improvement metrics
- **Design feedback**: Benchmark results inform which ACP features matter most
- **Reproducibility**: Anyone can run the suite and verify results independently

---

## Trade-offs

- **Cost**: Each full benchmark run uses significant LLM tokens across 5 runs x 2 modes x N tasks. Mitigated by on-demand execution only and Claude Max subscription.
- **Non-determinism**: LLM outputs vary between runs. Mitigated by 5-run averaging and statistical reporting.
- **Evaluation subjectivity**: LLM evaluator scores are inherently subjective. Mitigated by structured rubrics and automated checks (compile, tests pass, structure match).
- **Benchmark selection bias**: Chosen tasks may favor ACP. Mitigated by including tasks of varying complexity and domains.
- **Execution time**: Full suite may take hours. Mitigated by parallel execution where possible and on-demand triggering.

---

## Dependencies

- **Claude Code CLI** with `-p` (non-interactive) mode support
- **Claude Max subscription** (or API key) for LLM access
- **GitHub Actions** for CI/CD integration (on-demand workflow dispatch)
- **jq** for JSON parsing of Claude Code output
- **Ubuntu 24** (Linux) target platform
- **Internet access** in benchmark environment (for npm install, etc.)
- **ACP installation scripts** (this project's `acp.install.sh`)

---

## Testing Strategy

- **Runner tests**: Unit tests for metrics collection scripts (parsing JSON output, calculating averages)
- **Evaluator calibration**: Run evaluator on known-good and known-bad code samples to verify scoring consistency
- **Smoke test**: Single-run, single-task quick check that the full pipeline works (before running the expensive full suite)
- **Structure validation**: Verify expected structure YAML specs match reference implementations
- **Report generation**: Verify YAML/Markdown/HTML reports are valid and contain all required fields

---

## Migration Path

This is a new feature — no migration needed. Implementation phases:

1. **Phase 1**: Runner infrastructure (run-benchmark.sh, run-single.sh, temp dir isolation)
2. **Phase 2**: Define 3 benchmark tasks (simple, medium, complex) with prompts and expected outputs
3. **Phase 3**: Metrics collection (time, tokens from JSON output)
4. **Phase 4**: LLM evaluator (rubric, scoring, categorical ratings)
5. **Phase 5**: Report generation (YAML, Markdown, HTML)
6. **Phase 6**: GitHub Actions workflow (on-demand dispatch)
7. **Phase 7**: Historical tracking and GitHub Pages dashboard

---

## Future Considerations

- **Multi-agent comparison**: Benchmark ACP with different agent frameworks (Aider, Cursor, etc.)
- **Multi-model comparison**: Run same benchmarks with different LLM models
- **Regression CI**: Automatically run benchmarks on ACP version releases
- **Community benchmarks**: Allow users to submit benchmark tasks
- **Phase-level tracking**: More granular time tracking per ACP workflow phase (planning vs coding vs testing)
- **Cost optimization**: Cache benchmark prompts/outputs to reduce redundant token usage

---

**Status**: Implemented
**Recommendation**: Create milestone and task breakdown for implementation
**Related Documents**:
- [Clarification 1: Benchmark Suite Requirements](../clarifications/clarification-1-benchmark-suite-requirements.md)
- [Draft: Benchmark Concept](../drafts/benchmark.draft.md)
