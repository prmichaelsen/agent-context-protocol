# Task 2: Implement Project CRUD

**Status**: Not Started  
**Estimated Hours**: 2  
**Milestone**: M1 (MVP)  

## Objective

Replace the stubbed 501 responses in `src/routes/projects.js` with full CRUD implementation.

## Steps

1. Create `src/models/project.js` with in-memory storage and CRUD functions:
   - `createProject(data, ownerId)` — validates, generates UUID, returns project
   - `getProjectById(id)` — returns project or null
   - `getAllProjects(filters)` — returns filtered array (by status)
   - `updateProject(id, data)` — partial update, returns updated project or null
   - `deleteProject(id)` — removes project, returns boolean

2. Rewrite `src/routes/projects.js`:
   - GET / — list with pagination, status filter
   - GET /:id — single project lookup
   - POST / — create with validation (name required, status enum), set ownerId from req.user.id
   - PUT /:id — partial update
   - DELETE /:id — delete, cascade: set projectId to null on all tasks referencing this project

3. Use error format from `agent/patterns/error-handling.md`.

4. Use pagination from `agent/patterns/api-conventions.md`.

## Cascade Delete Behavior

When a project is deleted, all tasks with `projectId` matching the deleted project must have their `projectId` set to `null`. This prevents orphaned references. See `agent/design/data-model.md` for details.

## Acceptance Criteria

- All 5 endpoints return correct responses
- Validation rejects bad data with proper error format
- Pagination works
- Status filter works
- ownerId is automatically set from authenticated user
- Cascade on delete nullifies task projectId references
