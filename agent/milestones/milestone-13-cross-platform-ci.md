# Milestone 13: Cross-Platform CI

**Goal**: Automated cross-platform E2E testing on Linux and macOS via GitHub Actions
**Status**: Not Started
**Estimated Duration**: 1 week
**Tasks**: 3 (task-96 through task-98)

---

## Overview

Add a GitHub Actions CI pipeline that runs all 17 E2E test suites on both Linux (`ubuntu-latest`) and macOS (`macos-latest`) using a matrix strategy. This prevents platform-specific regressions like the v5.10.2 BSD sed bug from reaching users.

## Deliverables

1. All E2E tests pass on macOS (fix platform-specific code in test files)
2. Unified test runner script (`run-e2e-tests.sh`)
3. GitHub Actions workflow (`.github/workflows/e2e-tests.yaml`)

## Success Criteria

- [ ] All 17 E2E test suites pass on `ubuntu-latest`
- [ ] All 17 E2E test suites pass on `macos-latest`
- [ ] CI triggers on push to mainline and pull requests
- [ ] Failed tests block PR merge
- [ ] Test runner provides clear pass/fail reporting

## Dependencies

- v5.10.2 macOS compatibility fix for scripts (completed)
- Design: `agent/design/local.cross-platform-ci.md`

## Tasks

| Task | Name | Status | Est. Hours |
|------|------|--------|------------|
| task-96 | Fix macOS Compatibility in E2E Tests | not_started | 2-3h |
| task-97 | Create Unified E2E Test Runner | not_started | 1-2h |
| task-98 | Create GitHub Actions CI Workflow | not_started | 1-2h |
