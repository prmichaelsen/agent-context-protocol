# Task 81: Medium REST API Benchmark Task

**Milestone**: M11 - ACP Benchmark Suite
**Estimated Time**: 4-5 hours
**Dependencies**: Task 79 (runner must support multi-turn steps)
**Status**: Not Started

---

## Objective

Create the `medium-rest-api` benchmark task with 4 multi-turn steps (build, test, correction, refactor), config, and expected output structure.

---

## Context

The design spec defines a medium-complexity benchmark: building a REST API with CRUD operations. This tests more complex project scaffolding, multiple files, testing, debugging, and refactoring across steps. Expected ~5 minutes per run.

---

## Steps

### 1. Create Directory Structure
```
agent/benchmarks/suite/medium-rest-api/
├── config.yaml
├── steps/
│   ├── 01-build.md
│   ├── 02-test.md
│   ├── 03-correction.md
│   └── 04-refactor.md
└── expected/
    └── structure.yaml
```

### 2. Define config.yaml
- name, description, complexity: medium, domain: web
- timeout_minutes: 30, runs: 5
- 4 steps with max_turns and phases

### 3. Write Step Prompts
- **01-build.md**: "Build a REST API with CRUD operations for a todo app. Use Node.js/Express. Include endpoints: GET /todos, GET /todos/:id, POST /todos, PUT /todos/:id, DELETE /todos/:id. Use an in-memory array for storage."
- **02-test.md**: "Add comprehensive tests for all endpoints. Test happy paths, error cases (404, 400), and edge cases."
- **03-correction.md**: "The DELETE endpoint returns 200 instead of 204. The PUT endpoint doesn't validate required fields. Fix both issues."
- **04-refactor.md**: "Extract route handlers into a separate module (src/routes/todos.ts). Keep the server setup in src/index.ts."

### 4. Define Expected Structure
- Expected dirs: src/, src/routes/, tests/
- Expected files: package.json, src/index.ts, src/routes/*.ts, tests/*.test.ts

### 5. Add Verification to verify.sh
- Add `verify_medium_rest_api()` function
- Checks: structure_match, tests_pass, server_starts, endpoints_respond

---

## Verification

- [ ] config.yaml valid with 4 steps
- [ ] Step prompts are clear, each builds on previous context
- [ ] expected/structure.yaml defines directory and file expectations
- [ ] verify.sh has verification function for this task
- [ ] Correction step has a real, detectable bug to fix

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (Benchmark Task Definition)
