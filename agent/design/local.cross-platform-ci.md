# Cross-Platform E2E CI/CD Pipeline

**Concept**: GitHub Actions matrix strategy running E2E tests on Linux and macOS to catch platform-specific bugs automatically
**Created**: 2026-03-02
**Status**: Design Specification

---

## Overview

This design describes a cross-platform CI/CD pipeline that runs all 17 E2E test suites on both Linux and macOS using GitHub Actions matrix strategy. The pipeline catches platform-specific incompatibilities (e.g., BSD sed vs GNU sed, missing `sha256sum`) before they reach users.

---

## Problem Statement

- ACP scripts use GNU-specific utilities (`sed -i`, `sha256sum`) that silently fail or error on macOS.
- The v5.10.2 `sed -i` bug was caught manually by a user — there was no automated gate.
- macOS is a primary target platform (many developers use macOS).
- Several E2E test files also contain GNU-specific code that would fail on macOS.
- Without cross-platform CI, regressions can be introduced in any commit.

---

## Solution

A GitHub Actions workflow with a matrix strategy running on `ubuntu-latest` and `macos-latest` native runners, plus a unified test runner script.

**Why not Docker?**
- macOS cannot run in Docker (Apple licensing prohibits virtualization outside Apple hardware)
- Windows containers only run on Windows hosts, not Linux CI runners
- GitHub Actions native runners are the correct tool for cross-platform testing

**Why not Windows?**
- ACP is a pure bash project requiring bash 4+, git, and POSIX utilities
- Windows support would require Git Bash compatibility and significant test refactoring
- Minimal user benefit — Windows users typically use WSL for bash workflows

### Components

```
project-root/
├── run-e2e-tests.sh                    # Unified test runner (NEW)
├── .github/workflows/
│   ├── benchmark.yaml                  # Existing benchmark workflow
│   └── e2e-tests.yaml                  # Cross-platform E2E tests (NEW)
└── e2e/
    └── *.test.sh                       # 17 existing test suites (FIXES needed)
```

---

## Implementation

### 1. Unified Test Runner (`run-e2e-tests.sh`)

Discovers and runs all `e2e/*.test.sh` files, reports results, exits non-zero if any fail.

```bash
#!/usr/bin/env bash
# Usage:
#   bash run-e2e-tests.sh              # Run all E2E tests
#   bash run-e2e-tests.sh sessions     # Run only tests matching "sessions"
```

Behavior:
- Glob `e2e/*.test.sh` for test discovery
- Run each as subprocess: `bash "$test_file" 2>&1`
- Capture exit code per file — print PASS/FAIL
- On failure, show last 20 lines of output for debugging
- Print summary table, exit 1 if any failed

### 2. GitHub Actions Workflow (`.github/workflows/e2e-tests.yaml`)

```yaml
name: E2E Tests
on:
  push:
    branches: [mainline]
  pull_request:
    branches: [mainline]
jobs:
  e2e:
    runs-on: ${{ matrix.os }}
    timeout-minutes: 30
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4
      - name: Configure git for tests
        run: |
          git config --global user.email "ci@test.example.com"
          git config --global user.name "CI Test Runner"
          git config --global init.defaultBranch main
      - name: Run E2E tests
        run: bash run-e2e-tests.sh
```

Key decisions:
- **`fail-fast: false`** — both platforms run to completion so you see all failures
- **Git config step** — E2E tests use `git init`/`git commit` which need user config
- **No additional dependencies** — both runners have bash and git pre-installed
- **30-minute timeout** — generous for lightweight bash tests, protects against hangs

### 3. E2E Test Fixes (macOS Compatibility)

Three categories of fixes needed in existing test files before macOS CI passes:

**A. `sed -i` without backup suffix (3 files)**
- `e2e/acp.project-set.test.sh` — uses `sed -i` with GNU multiline insert
- `e2e/acp.experimental-features.test.sh` — 2 `sed -i` calls

Fix: Source `acp.common.sh` and use `_sed_i`, or inline the portable pattern.

**B. `date +%N` nanoseconds (3 files)**
- `e2e/acp.project-list.test.sh`
- `e2e/acp.project-update.test.sh`
- `e2e/acp.project-info.test.sh`

macOS `date` doesn't support `%N` — outputs literal "N". Fix: Use `$$-$RANDOM` instead.

**C. Exit code reliability (4 files)**
- `e2e/acp.project-list.test.sh`
- `e2e/acp.project-info.test.sh`
- `e2e/acp.project-update.test.sh`
- `e2e/acp.project-workflow.test.sh`

These call `print_test_summary` but don't propagate its non-zero return code (no `set -e`), so they exit 0 even on failure. Fix: Add explicit `exit $?` after the summary call.

---

## Benefits

- **Automated regression detection**: macOS-specific bugs caught before merge
- **Developer confidence**: PRs validated on both platforms before review
- **Low maintenance**: No Docker images to build/maintain — uses GitHub-managed runners
- **Minimal cost**: ~5 min runtime per platform; well within free tier for public repos

---

## Trade-offs

- **macOS runner cost**: 10x multiplier vs Linux on GitHub Actions (mitigated: short runtime, free for public repos)
- **No Windows coverage**: Acceptable given ACP's bash-only nature
- **Network-dependent test**: `acp.package-search.test.sh` hits GitHub API; may be rate-limited in CI (mitigated: test already handles failures gracefully)

---

## Dependencies

- GitHub Actions (already in use for benchmarks)
- `actions/checkout@v4`
- Native bash and git on both ubuntu-latest and macos-latest runners

---

## Testing Strategy

1. Run `bash run-e2e-tests.sh` locally on Linux — all 17 suites pass
2. Push branch, verify GitHub Actions runs on both ubuntu-latest and macos-latest
3. Intentionally introduce a `sed -i` call to confirm macOS runner catches it
4. Verify PR checks block merge when tests fail

---

## Future Considerations

- Add unit tests (`tests/*.test.sh`) to the runner with a `--unit` flag
- Cache bash/git setup if runner startup becomes a bottleneck
- Add Windows (Git Bash) if demand arises
- Add macOS-only trigger optimization if runner costs become a concern

---

**Status**: Design Specification
**Recommendation**: Implement — create test runner, workflow, and fix test macOS compatibility
**Related Documents**: [CHANGELOG 5.10.2 — macOS sed fix](../../CHANGELOG.md)
