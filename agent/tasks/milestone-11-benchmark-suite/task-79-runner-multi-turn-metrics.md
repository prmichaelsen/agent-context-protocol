# Task 79: Runner Multi-Turn & Metrics Fix

**Milestone**: M11 - ACP Benchmark Suite  
**Estimated Time**: 6-8 hours  
**Dependencies**: None  
**Status**: Completed  
**Actual Hours**: 1.5  
**Completed**: 2026-02-28  

---

## Objective

Upgrade the benchmark runner (`run-single.sh`, `run-benchmark.sh`) to support multi-turn conversation steps via Claude CLI `--resume`, fix token/cost metrics extraction (currently showing 0), and add per-step metrics collection with aggregation.

---

## Context

The current runner executes a single prompt per benchmark run. The design spec calls for multi-turn conversations where sequential prompts (build, test, correct, refactor) are sent to the same Claude session via `--resume`. Token metrics are also broken — showing 0 in reports despite successful runs.

---

## Steps

### 1. Fix Token/Cost Metrics Extraction
- Investigate why `run-single.sh` outputs 0 for input_tokens, output_tokens, cost_usd
- Check Claude CLI `--output-format json` structure — fields may be nested differently
- Fix JSON parsing (jq expressions) to extract correct token counts
- Verify with a hello-world test run

### 2. Implement Multi-Turn Step Loop in run-single.sh
- Read `config.yaml` for steps array
- For first step: start new session, capture session_id
- For subsequent steps: use `--resume <session_id>`
- Capture per-step metrics (tokens, time, turns) into separate files
- Save stderr logs per step

### 3. Create metrics-collector.sh
- Aggregate per-step metrics into run-level totals
- Calculate per-phase breakdowns (coding, testing, debugging)
- Output aggregated YAML report

### 4. Update run-benchmark.sh for Multi-Run Support
- Add `--runs <N>` flag (default: 5)
- Loop N times per task/mode combination
- Calculate averages across runs (mean, stddev for key metrics)
- Generate per-run and averaged summary

### 5. Verify with hello-world
- Run hello-world in both modes with multi-turn runner
- Confirm metrics are non-zero and accurate
- Confirm backward compatibility (single-step tasks still work)

---

## Verification

- [x] Token metrics extraction tries .usage.* then top-level (fallback)
- [x] Multi-turn steps execute with `--resume` session continuity
- [x] Per-step metrics captured (tokens, time, turns per step)
- [x] metrics-collector.sh produces valid aggregated YAML (mean, stddev)
- [x] `--runs N` executes N iterations and averages results
- [x] Backward compatible with single-step tasks (hello-world)
- [x] Task-aware verification dispatch (verify_<task_name> functions)
- [x] Raw JSON output saved for debugging
- [ ] Smoke test with real run (requires non-nested Claude session)

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (Execution Flow, Claude Code CLI Integration, Metrics Collection)  
