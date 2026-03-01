# Task 87: Legacy Codebase Refactor Benchmark Task

**Milestone**: M11 - ACP Benchmark Suite
**Estimated Time**: 4-6 hours
**Dependencies**: Task 79 (runner must support multi-turn steps)
**Status**: Not Started

---

## Objective

Create the `legacy-refactor` benchmark task — a 6-step benchmark that starts with a pre-built messy Express app (single-file, no tests, globals, poor error handling) and requires the agent to refactor, test, extend, and document it. This tests planning under constraints — the agent must understand existing code before modifying it.

---

## Context

Current benchmark tasks are all greenfield — the agent builds from scratch. Real-world AI agent usage often involves working with existing (messy) codebases. This benchmark specifically tests whether ACP's planning approach helps agents avoid breaking existing functionality while refactoring, and whether the structured workflow leads to better architectural decisions when modifying legacy code.

The pre-built "legacy" app should be a ~200-line Express app with intentional code smells:
- Everything in one file (server.js)
- Global mutable state (in-memory array)
- No error handling (crashes on bad input)
- Inconsistent naming (camelCase mixed with snake_case)
- Hardcoded values (port, magic numbers)
- No tests
- Working but fragile CRUD for a "notes" resource

---

## Steps

### 1. Create Seed Application

Create `agent/benchmarks/suite/legacy-refactor/seed/` with:
- `server.js`: A working but messy Express CRUD app (~200 lines) with all the code smells above
- `package.json`: Minimal with express dependency only

The seed app should be functional — all routes work — but poorly structured. The runner will copy this into the workspace before starting.

### 2. Create Directory Structure
```
agent/benchmarks/suite/legacy-refactor/
├── config.yaml
├── seed/
│   ├── server.js
│   └── package.json
├── steps/
│   ├── 01-understand.md
│   ├── 02-refactor-structure.md
│   ├── 03-add-tests.md
│   ├── 04-fix-bugs.md
│   ├── 05-add-feature.md
│   └── 06-documentation.md
└── expected/
    └── structure.yaml
```

### 3. Define config.yaml
- name: legacy-refactor
- description: Refactor a legacy Express app, add tests, fix bugs, and extend with new features
- complexity: complex
- domain: web/refactoring
- timeout_minutes: 60
- max_turns: 40
- seed_dir: seed/ (runner copies this into workspace before step 1)
- 6 steps with phases

### 4. Write Step Prompts

- **01-understand.md**: "You have inherited a legacy Express application in server.js. Before making any changes, analyze the codebase. List all routes, identify code smells, and create a refactoring plan in REFACTOR_PLAN.md. Do NOT modify server.js yet."

- **02-refactor-structure.md**: "Refactor server.js into a proper Express project structure. Extract routes into separate files (routes/), create middleware (middleware/), extract the data store into its own module (models/ or store/), use environment variables for configuration, and add proper error handling middleware. All existing routes must still work identically after refactoring."

- **03-add-tests.md**: "Add a comprehensive test suite using Jest or Mocha + supertest. Write tests for every existing endpoint including: success cases, error cases (missing fields, invalid IDs, not found), and edge cases (empty title, very long content). All tests must pass."

- **04-fix-bugs.md**: "The application has several bugs that the tests should have revealed: 1) Creating a note with an empty title should return 400, not 201. 2) Updating a non-existent note returns 200 instead of 404. 3) The app crashes if you POST non-JSON content-type. Fix all three bugs and ensure tests cover them."

- **05-add-feature.md**: "Add search and filtering to the notes API: GET /notes?search=keyword (full-text search across title and content), GET /notes?sort=created_at&order=desc (sorting), GET /notes?limit=10&offset=0 (pagination). Add tests for all new functionality."

- **06-documentation.md**: "Add a comprehensive README.md with: project description, setup instructions, API documentation for all endpoints (including new search/filter params), example curl commands, architecture overview explaining the project structure, and a section on the refactoring decisions made."

### 5. Define Expected Structure
- Expected dirs: routes/, middleware/, models/ or store/, tests/
- Expected files: package.json, routes/notes.js, middleware/error-handler.js, tests/*.test.js, README.md, REFACTOR_PLAN.md
- Seed files should NOT still exist as monolith (server.js should be refactored)

### 6. Update Runner for Seed Support

If not already supported, add seed directory support to run-single.sh:
- Before step 1, if config.yaml has `seed_dir`, copy seed files into workspace
- Run `npm install` in workspace after copying seed

### 7. Add Verification to verify.sh
- Add `verify_legacy_refactor()` function
- Checks: structure_match, tests_pass, server_starts, all_original_routes_work, search_works, pagination_works, refactor_plan_exists, readme_exists

---

## Verification

- [ ] seed/server.js is a working but messy Express app with intentional code smells
- [ ] config.yaml valid with 6 steps and seed_dir
- [ ] Step prompts build progressively (understand → refactor → test → fix → extend → document)
- [ ] Step 1 explicitly forbids code changes (tests planning discipline)
- [ ] Step 4 introduces bugs that only surface through testing
- [ ] expected/structure.yaml covers refactored structure
- [ ] verify.sh has verify_legacy_refactor() function
- [ ] Runner supports seed directory copying

---

**Related Design Docs**: agent/design/local.benchmark-suite.md
