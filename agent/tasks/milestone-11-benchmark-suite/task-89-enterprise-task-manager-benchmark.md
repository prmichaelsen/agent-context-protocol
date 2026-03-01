# Task 89: Enterprise Task Manager Benchmark Task

**Milestone**: M11 - ACP Benchmark Suite
**Estimated Time**: 8-12 hours
**Dependencies**: Task 79 (runner), Task 87 (seed support)
**Status**: Not Started

---

## Objective

Create the `enterprise-task-manager` benchmark task — a 10-step benchmark starting from a large seed project (~1200 lines, ~25 files). This is designed as a multi-hour benchmark that specifically tests whether ACP's planning approach helps agents navigate large, complex codebases with interacting requirements. The task is intentionally designed to punish "just diving in" — later steps interact with and invalidate earlier assumptions.

---

## Context

Current benchmarks are too simple — baseline consistently matches or beats ACP because the overhead of planning doesn't pay off on tasks small enough to hold in working memory. This benchmark creates conditions where ACP should excel:

- **Scale**: Seed project is too large to skim — agent must be strategic about what to read
- **Cascading changes**: Step 5 (add teams) changes the data model for everything downstream
- **Cross-cutting concerns**: Step 7 (RBAC) requires understanding ALL endpoints
- **Interacting requirements**: RBAC must work with teams, activity feed must respect RBAC, security audit must validate both
- **Planning payoff**: Without upfront architecture decisions, agents make contradictory choices that compound into rework

Expected runtime: 2-4 hours per mode (baseline + ACP).

---

## Steps

### 1. Create Seed Project

Create `agent/benchmarks/suite/enterprise-task-manager/seed/` with a substantial working Express application (~1200 lines, ~25 files):

**Directory structure:**
```
seed/
├── package.json
├── server.js              # Main entry — BUT some routes are leaked in here (messy)
├── config.js              # Hardcoded config values (port, limits, magic numbers)
├── routes/
│   ├── tasks.js           # Task CRUD (mostly correct)
│   ├── users.js           # User CRUD
│   └── projects.js        # Project CRUD
├── models/
│   ├── task.js            # Task model (in-memory store)
│   ├── user.js            # User model
│   ├── project.js         # Project model — has circular dependency with task.js
│   └── index.js           # Model barrel export
├── middleware/
│   ├── auth.js            # Basic API key auth — doesn't cover all routes
│   └── logger.js          # Request logger
└── utils/
    ├── errors.js          # Custom error classes (partially used)
    └── helpers.js         # Misc helpers
```

**The app should be functional but have these intentional issues:**

**5 Intentional Bugs:**
1. Creating a task with a non-existent projectId returns 201 (should validate project exists)
2. Deleting a project does NOT delete its tasks (orphaned tasks)
3. User email uniqueness is not enforced (can create duplicate emails)
4. GET /tasks?assignee=userId returns ALL tasks, not filtered (filter is ignored)
5. Updating a task's status to "done" doesn't set completedAt timestamp

**Architectural Issues:**
- Some routes are in server.js instead of route files (GET /status, POST /api-keys)
- Circular dependency between project.js and task.js (project imports task to count, task imports project to validate)
- auth middleware only applied to /tasks, not /users or /projects
- Inconsistent error responses (some return `{ error: "msg" }`, others return `{ message: "msg" }`)
- Hardcoded values in config.js (not using env vars)
- No input validation on most endpoints (accepts any fields)
- models/index.js has a weird re-export pattern

**Relationships:**
- Users have: id, name, email, role ("user"), createdAt
- Projects have: id, name, description, ownerId (references user), createdAt
- Tasks have: id, title, description, status (todo/in-progress/done), priority (low/medium/high), projectId (references project), assigneeId (references user), createdAt, updatedAt, completedAt

**Endpoints (15+):**
- GET /health, GET /status (in server.js — messy)
- POST /api-keys (in server.js — messy)
- CRUD for /users (5 endpoints)
- CRUD for /projects (5 endpoints) + GET /projects/:id/tasks
- CRUD for /tasks (5 endpoints) + PUT /tasks/:id/status + GET /tasks?assignee=X&status=X

### 2. Create Directory Structure
```
agent/benchmarks/suite/enterprise-task-manager/
├── config.yaml
├── seed/
│   └── (25 files as above)
├── steps/
│   ├── 01-deep-analysis.md
│   ├── 02-fix-critical-bugs.md
│   ├── 03-refactor-architecture.md
│   ├── 04-comprehensive-tests.md
│   ├── 05-add-teams.md
│   ├── 06-activity-feed.md
│   ├── 07-rbac.md
│   ├── 08-performance.md
│   ├── 09-security-audit.md
│   └── 10-migration-docs.md
└── expected/
    └── structure.yaml
```

### 3. Define config.yaml
- name: enterprise-task-manager
- description: Large-scale refactor, feature addition, and hardening of a task management platform
- complexity: expert
- domain: fullstack/architecture
- timeout_minutes: 240 (4 hours per mode)
- max_turns: 80
- seed_dir: seed/
- 10 steps with appropriate phases and high max_turns per step

### 4. Write Step Prompts

- **01-deep-analysis.md**: Analyze the entire codebase. Read EVERY file. Map all endpoints, models, relationships, middleware. Identify ALL bugs, architectural issues, inconsistencies, and security concerns. Create ANALYSIS.md with: endpoint inventory, data model diagram (text), bug list with severity, architectural issues, and a prioritized refactoring plan. Do NOT modify any code.

- **02-fix-critical-bugs.md**: Fix these 5 bugs: (1) task creation accepts non-existent projectId, (2) deleting project leaves orphaned tasks, (3) duplicate user emails allowed, (4) task assignee filter is broken, (5) completing task doesn't set completedAt. Write a regression test for each bug. All 5 tests must pass.

- **03-refactor-architecture.md**: (a) Move all routes from server.js to proper route files. (b) Fix circular dependency between project and task models. (c) Apply auth middleware to ALL routes. (d) Standardize error responses — always use `{ error: "message", code: "ERROR_CODE" }`. (e) Add input validation middleware (validate required fields, types). (f) Use environment variables for config. (g) Create proper app.js/index.js separation for testability. All existing endpoints must still work.

- **04-comprehensive-tests.md**: Create 50+ tests covering: all user CRUD + validation, all project CRUD + cascade delete, all task CRUD + status transitions + filters, auth middleware (with and without API key), error responses (404, 400, 401), edge cases (empty strings, invalid IDs, relationships). All tests must pass.

- **05-add-teams.md**: Add a teams system: (a) Team CRUD: POST /teams, GET /teams, GET /teams/:id, PUT /teams/:id, DELETE /teams/:id. (b) Users belong to teams (add teamId to user model). (c) Projects are scoped to teams (add teamId to project model). (d) Tasks inherit team from their project. (e) All list endpoints (/users, /projects, /tasks) must accept ?teamId= filter. (f) A user can only see/modify resources in their team. (g) Update ALL existing endpoints to respect team scoping. (h) Add tests for team scoping.

- **06-activity-feed.md**: Add an activity tracking system: (a) Every CRUD operation on any entity records an activity event with: type (created/updated/deleted), entity (user/project/task/team), entityId, userId (who did it), changes (what changed), timestamp. (b) GET /activity — paginated activity feed (limit/offset) with filters: ?entity=task&entityId=123&userId=456. (c) Activity is scoped to team (users only see their team's activity). (d) Add tests for activity recording and retrieval.

- **07-rbac.md**: Add role-based access control: (a) Roles: admin, manager, member, viewer. (b) Admin: full access to everything in their team. (c) Manager: create/update/delete projects, assign tasks, manage team members. (d) Member: create/update tasks assigned to them, view projects. (e) Viewer: read-only access to everything in their team. (f) Add RBAC middleware that checks role before each operation. (g) Retrofit onto ALL existing endpoints. (h) Add tests for each role's permissions (allowed and denied operations).

- **08-performance.md**: (a) Add pagination to ALL list endpoints: ?limit=20&offset=0 with response format `{ data: [...], total: N, limit: M, offset: O }`. (b) Add sorting: ?sort=createdAt&order=desc. (c) Add search: GET /tasks?search=keyword (searches title and description). GET /users?search=keyword (searches name and email). (d) Ensure backward compatibility (unpaginated requests still work or return first page). (e) Add tests for pagination, sorting, and search.

- **09-security-audit.md**: (a) Audit every endpoint for authorization bypass — can a user in team A access team B's data? Fix any leaks. (b) Add rate limiting middleware (100 req/min per API key). (c) Ensure passwords/API keys are never returned in responses. (d) Add input sanitization (strip HTML/script tags from string fields). (e) Validate all ID parameters are valid format. (f) Add security-focused tests that attempt unauthorized access patterns.

- **10-migration-docs.md**: (a) Create MIGRATION.md documenting all breaking changes from the original API (new required fields, changed response formats, new auth requirements, team scoping). (b) Create comprehensive README.md with: project description, setup instructions, environment variables, all API endpoints with request/response examples, authentication guide, RBAC roles table, team scoping explanation, pagination/sorting/search guide, architecture overview. (c) Create ARCHITECTURE.md explaining: data model with relationships, middleware chain, how RBAC works, how activity tracking works, design decisions and trade-offs.

### 5. Define Expected Structure
- Expected dirs: routes/, models/, middleware/, tests/
- Expected files: package.json, README.md, ANALYSIS.md, MIGRATION.md, ARCHITECTURE.md, tests/*.test.js
- Auth middleware must cover all routes
- Team model must exist

### 6. Add Verification to verify.sh
- Add `verify_enterprise_task_manager()` function
- Checks: structure_match, tests_pass, readme_exists, analysis_exists, migration_exists, architecture_exists

---

## Verification

- [ ] Seed project is ~1200 lines across ~25 files with 5 intentional bugs
- [ ] Seed project is functional (all routes work despite bugs)
- [ ] config.yaml valid with 10 steps, seed_dir, 240min timeout
- [ ] Step 1 forbids code changes (tests planning discipline)
- [ ] Step 5 (teams) forces cascading changes across all modules
- [ ] Step 7 (RBAC) requires understanding all endpoints
- [ ] Steps 5-9 interact with each other (teams + RBAC + activity + security)
- [ ] expected/structure.yaml covers final architecture
- [ ] verify.sh has verify_enterprise_task_manager() function
- [ ] Total expected runtime: 2-4 hours per mode

---

## Notes

- This benchmark is intentionally expensive to run. Use `--runs 1` for initial testing.
- The seed project must be large enough that the agent cannot read it all in one pass.
- Step ordering is critical — each step builds on the previous and interacts with later ones.
- The key metric is not just "did it complete" but "how much rework did it need?"
- ACP should excel here because planning prevents cascading errors.

---

**Related Design Docs**: agent/design/local.benchmark-suite.md
