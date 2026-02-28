# Task 85: GitHub Actions Workflow

**Milestone**: M11 - ACP Benchmark Suite
**Estimated Time**: 2-3 hours
**Dependencies**: Tasks 79-84 (full pipeline must work locally first)
**Status**: Not Started

---

## Objective

Create an on-demand GitHub Actions workflow that runs the benchmark suite and uploads reports as artifacts.

---

## Context

The design spec calls for CI/CD integration via GitHub Actions with `workflow_dispatch` trigger. Benchmarks are too expensive and slow for per-commit runs, so on-demand triggering is required.

---

## Steps

### 1. Create .github/workflows/benchmark.yaml
- `workflow_dispatch` trigger with inputs: task (all/specific), mode (both/acp/baseline), runs (default: 5)
- Ubuntu latest runner
- Install Claude CLI, Node.js, jq
- Run benchmark suite
- Upload report directory as artifact

### 2. Handle Authentication
- Use repository secret for Claude access (API key or auth token)
- Document required secrets in README

### 3. Add Timeout and Cost Controls
- Per-job timeout (2 hours max)
- Per-task timeout from config.yaml
- Clear failure messages on timeout

### 4. Test Workflow
- Trigger manually with hello-world smoke test
- Verify reports are generated and uploaded as artifacts

---

## Verification

- [ ] Workflow file is valid GitHub Actions YAML
- [ ] workflow_dispatch trigger with configurable inputs
- [ ] Reports uploaded as artifacts
- [ ] Timeout controls prevent runaway jobs
- [ ] README documents required secrets

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (CI/CD Integration)
