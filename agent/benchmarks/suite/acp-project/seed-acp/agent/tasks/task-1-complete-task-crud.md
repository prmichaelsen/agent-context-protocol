# Task 1: Implement Task CRUD

**Status**: Not Started  
**Estimated Hours**: 3  
**Milestone**: M1 (MVP)  

## Objective

Replace the stubbed 501 responses in `src/routes/tasks.js` with full CRUD implementation.

## Steps

1. Create `src/models/task.js` with in-memory storage and CRUD functions:
   - `createTask(data, createdBy)` — validates fields, sets defaults, generates UUID, returns task
   - `getTaskById(id)` — returns task or null
   - `getAllTasks(filters)` — returns filtered array (by status, priority, projectId, assigneeId)
   - `updateTask(id, data)` — partial update, sets updatedAt, returns updated task or null
   - `deleteTask(id)` — removes task, returns boolean

2. Rewrite `src/routes/tasks.js`:
   - GET / — list with pagination, filtering, sorting per `agent/design/api-design.md`
   - GET /:id — single task lookup
   - POST / — create with validation (title required, status/priority enums, projectId/assigneeId reference checks)
   - PUT /:id — partial update with same validation
   - DELETE /:id — delete, return 204

3. Use the error format from `agent/patterns/error-handling.md` for all error responses.

4. Use the pagination helper from `agent/patterns/api-conventions.md` for list responses.

## Validation Rules

See `agent/design/api-design.md` for exact field constraints, error codes, and response formats.

## Acceptance Criteria

- All 5 endpoints return correct responses
- Validation rejects bad data with proper error format
- Pagination works with page/limit params
- Filtering works for status, priority, projectId, assigneeId
- Sorting works for createdAt, updatedAt, dueDate, priority
- projectId/assigneeId are validated against existing records
