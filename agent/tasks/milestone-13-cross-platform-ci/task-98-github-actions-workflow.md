# Task 98: Create GitHub Actions CI Workflow

**Milestone**: M13 — Cross-Platform CI
**Status**: Not Started
**Estimated Hours**: 1-2
**Dependencies**: task-97 (test runner must exist)

---

## Objective

Create a GitHub Actions workflow that runs the E2E test suite on both Linux and macOS on every push to mainline and every pull request.

## Context

The existing `.github/workflows/benchmark.yaml` is manual-dispatch only and runs benchmarks (not E2E tests). This new workflow provides automated regression detection across platforms.

## Steps

### 1. Create `.github/workflows/e2e-tests.yaml`

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
- `fail-fast: false` — both platforms run to completion
- Git config — tests use `git init`/`git commit` which need user config
- No additional dependencies — bash and git are pre-installed on both runners
- 30-minute timeout — generous for lightweight bash tests

### 2. Push and verify

- Push to a branch, open PR
- Confirm CI runs on both ubuntu-latest and macos-latest
- Confirm both runners pass all 17 tests
- Confirm failed tests would block merge (check required status)

## Verification

- [ ] `.github/workflows/e2e-tests.yaml` exists
- [ ] Triggers on push to mainline
- [ ] Triggers on pull requests to mainline
- [ ] Matrix includes ubuntu-latest and macos-latest
- [ ] Git configured for test commits
- [ ] Both runners pass all tests
- [ ] `fail-fast: false` set
