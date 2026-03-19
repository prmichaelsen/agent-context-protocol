# Task 97: Create Unified E2E Test Runner

**Milestone**: M13 — Cross-Platform CI  
**Status**: Not Started  
**Estimated Hours**: 1-2  
**Dependencies**: task-96 (tests must have reliable exit codes)  

---

## Objective

Create a `run-e2e-tests.sh` script at the project root that discovers and runs all E2E test suites, reports results, and exits non-zero if any fail.

## Context

Currently there is no unified way to run all 17 E2E tests. Each must be invoked individually (`bash e2e/acp.sessions.test.sh`). The CI workflow needs a single entry point.

## Steps

### 1. Create `run-e2e-tests.sh`

Location: project root

Features:
- `#!/usr/bin/env bash` shebang for portability
- Discover all `e2e/*.test.sh` via glob
- Run each as subprocess: `bash "$test_file" 2>&1`
- Capture exit code per file — print PASS/FAIL per suite
- On failure, show last 20 lines of output for debugging
- Print summary table at end
- Exit 1 if any test failed, 0 if all passed
- Optional filter argument: `bash run-e2e-tests.sh sessions` (substring match)
- Use `set -uo pipefail` but NOT `set -e` (need to capture individual exit codes)

### 2. Make executable

`chmod +x run-e2e-tests.sh`

### 3. Test locally

- `bash run-e2e-tests.sh` — all 17 pass
- `bash run-e2e-tests.sh sessions` — filter works
- Verify a failing test produces non-zero exit and shows output

## Verification

- [ ] `run-e2e-tests.sh` exists at project root
- [ ] Discovers all 17 E2E test files
- [ ] Reports per-suite PASS/FAIL
- [ ] Shows output tail on failure
- [ ] Prints summary with counts
- [ ] Exits 0 when all pass, 1 when any fail
- [ ] Filter argument works
