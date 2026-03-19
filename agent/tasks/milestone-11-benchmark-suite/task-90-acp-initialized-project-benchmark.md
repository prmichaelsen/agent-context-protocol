# Task 90: ACP-Initialized Project Benchmark Task

**Milestone**: M11 - ACP Benchmark Suite  
**Estimated Time**: 8-12 hours  
**Dependencies**: Task 79 (runner), Task 87 (seed support)  
**Status**: Not Started  

---

## Objective

Create the `acp-project` benchmark task — a benchmark where the seed project comes pre-loaded with a full ACP agent/ directory: designs, patterns, milestones, tasks, progress.yaml, and commands. The baseline mode gets the same functional codebase but WITHOUT the agent/ directory. This directly measures whether having ACP context (architecture docs, task definitions, progress tracking) helps an agent build better software faster.

---

## Context

All existing benchmarks install ACP at runtime and have it bootstrap from scratch. This doesn't test the real-world ACP use case: a project where the human (or a previous agent session) has already defined the architecture, written design docs, broken work into milestones and tasks, and established patterns. In that scenario, ACP should massively outperform baseline because:

- **The agent doesn't have to figure out what to build** — tasks are defined
- **The agent doesn't have to guess the architecture** — designs exist
- **The agent knows what patterns to follow** — patterns are documented
- **The agent can track its own progress** — progress.yaml exists
- **The agent has context on WHY decisions were made** — design docs explain trade-offs

Baseline gets none of this. It just gets a prompt and has to figure everything out.

This benchmark isolates the value of **pre-existing project documentation** — the thing ACP is specifically designed to provide.

---

## Design

### Seed Structure

The seed has two layers:

**1. Functional codebase (both modes get this):**
A partially-built Express application with some features complete and others stubbed/incomplete:
- Working user auth (register, login, JWT)
- Working health endpoint
- Stubbed but non-functional: task CRUD, project CRUD, notifications
- package.json with dependencies
- Basic directory structure (src/, tests/)

**2. ACP agent/ directory (ACP mode only, baseline gets nothing):**
```
agent/
├── AGENT.md                    # Project overview, version, architecture summary
├── progress.yaml               # Current milestone, completed/pending tasks
├── design/
│   ├── api-design.md           # Full API design with endpoints, request/response formats
│   ├── data-model.md           # Entity definitions, relationships, constraints
│   └── notification-system.md  # Design for the notification feature
├── patterns/
│   ├── error-handling.md       # Standard error response format, error codes
│   ├── testing.md              # Testing conventions, file naming, setup patterns
│   └── api-conventions.md      # REST conventions, pagination, auth patterns
├── milestones/
│   └── milestone-1-mvp.md      # MVP milestone definition with success criteria
├── tasks/
│   ├── task-1-complete-task-crud.md      # Detailed task: implement task CRUD
│   ├── task-2-complete-project-crud.md   # Detailed task: implement project CRUD
│   ├── task-3-add-tests.md               # Detailed task: comprehensive test suite
│   ├── task-4-notifications.md           # Detailed task: notification system
│   └── task-5-documentation.md           # Detailed task: API docs and README
└── commands/                   # ACP commands (installed via acp.install.sh)
```

### How Modes Differ

**ACP mode:**
- Gets the full seed (codebase + agent/ directory)
- ACP is pre-installed (no need for acp.install.sh)
- First prompt tells agent to read @acp.status and @acp.proceed
- Agent has full context: what's done, what's next, how to build it

**Baseline mode:**
- Gets only the functional codebase (NO agent/ directory)
- Same prompts describe the same work, but without referencing ACP docs
- Agent must infer architecture, patterns, and priorities from the code alone

### Step Prompts

Both modes get prompts that describe the same work, but phrased differently:

**ACP mode prompts** reference the agent/ docs:
> "Read the project status and proceed with the next task. Follow the patterns and designs in agent/."

**Baseline mode prompts** describe the work directly:
> "The application has stubbed task CRUD endpoints. Implement them fully with proper validation, error handling, and all REST operations."

This means the ACP agent can leverage pre-written designs (which specify exact field names, validation rules, error codes, etc.) while the baseline agent has to make those decisions itself.

---

## Steps

### 1. Create Functional Seed Codebase

Create `agent/benchmarks/suite/acp-project/seed-base/` with a partially-built Express app:
- Working: auth (register/login/JWT), health endpoint, basic middleware
- Stubbed: task routes (return 501), project routes (return 501), notification placeholder
- ~400 lines across 10-15 files

### 2. Create ACP Agent Directory

Create `agent/benchmarks/suite/acp-project/seed-acp/agent/` with complete ACP documentation:

**AGENT.md**: Project overview, current version, architecture summary, what's built vs. what's remaining  

**progress.yaml**:
- Milestone 1: MVP (in_progress)
- Tasks 1-5 with status (task-1 through task-5 as not_started)
- Clear next_steps

**design/api-design.md**: Complete API specification with:  
- Every endpoint (method, path, request body, response format, error codes)
- Authentication requirements per endpoint
- Pagination format
- Exact field names, types, and validation rules

**design/data-model.md**: Entity definitions:  
- User: id, name, email, passwordHash, role, createdAt
- Project: id, name, description, ownerId, status, createdAt
- Task: id, title, description, status, priority, projectId, assigneeId, createdAt, updatedAt, dueDate
- Notification: id, userId, type, message, read, entityType, entityId, createdAt

**design/notification-system.md**: Notification triggers, types, delivery mechanism  

**patterns/error-handling.md**: Standard error format `{ error: { code, message, details } }`, error code catalog  

**patterns/testing.md**: Test file naming, setup/teardown patterns, what to test per endpoint  

**patterns/api-conventions.md**: REST conventions, pagination format, sorting, filtering  

**milestones/milestone-1-mvp.md**: Success criteria, scope definition  

**tasks/task-1 through task-5**: Detailed implementation instructions for each piece of remaining work  

### 3. Create Runner Support for Dual Seeds

The runner needs to handle this benchmark specially:
- ACP mode: copies seed-base/ + seed-acp/ (merged) into workspace
- Baseline mode: copies only seed-base/ into workspace
- Config.yaml specifies `seed_dir_base` and `seed_dir_acp` instead of single `seed_dir`

### 4. Create Step Prompts (Two Versions)

Create paired prompts — one for ACP, one for baseline:

```
steps/
├── 01-acp-implement-tasks.md       # "Read @acp.status and @acp.proceed to implement task CRUD"
├── 01-baseline-implement-tasks.md  # "Implement full CRUD for tasks with validation..."
├── 02-acp-implement-projects.md
├── 02-baseline-implement-projects.md
├── 03-acp-add-tests.md
├── 03-baseline-add-tests.md
├── 04-acp-notifications.md
├── 04-baseline-notifications.md
├── 05-acp-documentation.md
├── 05-baseline-documentation.md
```

ACP prompts should be SHORT — they point to the docs. The agent reads the designs for details.
Baseline prompts should be LONGER — they include the requirements inline since there are no docs.

### 5. Config.yaml

- name: acp-project
- complexity: complex
- seed_dir_base: seed-base/ (both modes)
- seed_dir_acp: seed-acp/ (ACP mode only, merged on top)
- 5 steps with mode-specific prompt files
- timeout_minutes: 120

### 6. Define Expected Structure and Verification

Both modes should produce the same final result. Verify:
- Task CRUD works (all 5 operations)
- Project CRUD works
- Tests exist and pass (30+ tests)
- Notifications work
- README exists

### 7. Metrics Focus

The key metrics to compare aren't just pass/fail but:
- **Consistency with design**: Does the implementation match the API spec? (ACP should win here)
- **Code quality**: Do patterns match? Error formats consistent? (ACP should win)
- **Completeness**: Did the agent implement everything? (ACP has a checklist, baseline doesn't)
- **Time/tokens**: Did ACP finish faster because it didn't need to make design decisions?

---

## Verification

- [ ] seed-base/ is a partially-built app with stubbed endpoints
- [ ] seed-acp/agent/ contains complete ACP documentation (designs, patterns, tasks, progress)
- [ ] ACP designs specify exact field names, validation rules, error codes
- [ ] ACP mode prompts are short (reference docs), baseline prompts are long (inline requirements)
- [ ] Runner supports dual seed directories (base + acp overlay)
- [ ] Both modes are asked to build the same thing
- [ ] LLM evaluator can assess consistency with the design spec
- [ ] config.yaml handles mode-specific prompt files

---

## Notes

- This is the benchmark most likely to show ACP's value — it tests the exact workflow ACP enables
- The ACP agent directory should feel like a real project that a human set up
- Design docs should be opinionated (specific field names, specific error codes) so we can measure adherence
- Baseline prompts should be fair — include the same information, just inline instead of in docs
- The question isn't "can ACP complete the task" but "does ACP produce MORE CONSISTENT, HIGHER QUALITY output"

---

**Related Design Docs**: agent/design/local.benchmark-suite.md  
