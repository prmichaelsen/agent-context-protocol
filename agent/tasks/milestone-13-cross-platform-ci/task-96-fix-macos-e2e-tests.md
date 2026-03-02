# Task 96: Fix macOS Compatibility in E2E Tests

**Milestone**: M13 — Cross-Platform CI
**Status**: Not Started
**Estimated Hours**: 2-3
**Dependencies**: None (v5.10.2 script fixes already landed)

---

## Objective

Fix all macOS-incompatible code in the 17 E2E test files so they pass on both Linux and macOS.

## Context

The v5.10.2 release fixed `sed -i` and `sha256sum` in the ACP scripts themselves, but several E2E test files contain the same GNU-specific patterns that will fail on macOS.

## Steps

### 1. Fix `sed -i` in test files (3 files)

Replace raw `sed -i` with the portable `_sed_i` helper from `acp.common.sh`:

- `e2e/acp.project-set.test.sh:259` — GNU-specific multiline insert with `\n`; needs rewrite using printf or heredoc approach
- `e2e/acp.experimental-features.test.sh:273` — `sed -i 's/...'`
- `e2e/acp.experimental-features.test.sh:304` — `sed -i '/experimental: true/d'`

For tests that don't already source `acp.common.sh`, either source it or inline the portable pattern.

### 2. Fix `date +%N` in test files (3 files)

macOS `date` doesn't support `%N` (nanoseconds) — outputs literal "N".

- `e2e/acp.project-list.test.sh:12`
- `e2e/acp.project-update.test.sh:12`
- `e2e/acp.project-info.test.sh:12`

Replace with `$$-$RANDOM` or use `mktemp -d` directly for unique naming.

### 3. Fix exit code reliability (4 files)

These call `print_test_summary` but don't propagate its non-zero return code (no `set -e`), so they exit 0 even on failure:

- `e2e/acp.project-list.test.sh`
- `e2e/acp.project-info.test.sh`
- `e2e/acp.project-update.test.sh`
- `e2e/acp.project-workflow.test.sh`

Add explicit `exit $?` after the `print_test_summary` call.

### 4. Verify all tests pass on Linux

Run all 17 E2E tests locally to ensure no regressions.

## Verification

- [ ] No raw `sed -i` calls remain in any `e2e/*.test.sh` file
- [ ] No `date +%N` calls remain in any `e2e/*.test.sh` file
- [ ] All 17 E2E tests exit non-zero on failure
- [ ] All 17 E2E tests pass on Linux
