# Task 59: Integration & Testing

**Milestone**: [M7 - Global ACP Project Registry](../../milestones/milestone-7-project-registry.md)  
**Estimated Time**: 3-4 hours  
**Dependencies**: Tasks 52-58 (All command implementations)  
**Status**: Not Started  

---

## Objective

Create comprehensive test suite for the project registry system including unit tests, integration tests, and E2E tests.

---

## Steps

### 1. Enhance Unit Tests

Expand `tests/acp.project-registry.test.sh` with:
- Registry initialization tests
- Project registration tests
- Current project tracking tests
- Project lookup tests
- Edge case handling

### 2. Create Integration Tests

Create `e2e/acp.project-list.test.sh`:
- Test listing empty registry
- Test listing with projects
- Test filtering by type, status
- Test current project marking

Create `e2e/acp.project-set.test.sh`:
- Test switching projects
- Test updating timestamps
- Test error cases (missing project, missing directory)

Create `e2e/acp.projects-sync.test.sh`:
- Test discovering unregistered projects
- Test skipping registered projects
- Test registration workflow

### 3. Create E2E Workflow Test

Create `e2e/acp.project-workflow.test.sh`:
- Full workflow: create → list → set → info → update → remove
- Verify registry state at each step
- Test context switching behavior

### 4. Run All Tests

```bash
./tests/acp.project-registry.test.sh
./e2e/acp.project-list.test.sh
./e2e/acp.project-set.test.sh
./e2e/acp.projects-sync.test.sh
./e2e/acp.project-workflow.test.sh
```

---

## Verification

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All E2E tests pass
- [ ] Edge cases covered
- [ ] Error handling tested
- [ ] 100% test coverage for registry functions

---

**Next Task**: [Task 60: Documentation Updates](task-60-documentation.md)  
