# Task 3: Refactor to Service Architecture

**Status:** not_started
**Milestone:** M1 — Foundation & Stabilization
**Estimated Hours:** 4
**Depends On:** task-2

## Objective

Refactor the monolithic codebase into a clean service-layer architecture.
Extract business logic from route handlers into dedicated service modules.
Establish the structural foundation that all subsequent features will build on.

## Requirements

- Create service layer modules:
  - `src/services/user-service.js` — User CRUD, authentication logic, password hashing
  - `src/services/task-service.js` — Task CRUD, filtering, assignment
  - `src/services/project-service.js` — Project CRUD, membership
  - `src/services/workspace-service.js` — Workspace operations (stub for task-4)
- Move all business logic from route files to service modules:
  - Routes should only handle HTTP concerns (parse request, call service, send response)
  - Services handle data validation, business rules, database operations
  - Services throw typed errors that the error handler catches
- Implement proper Express error handler middleware:
  - 4-parameter signature: (err, req, res, next)
  - Map error types to HTTP status codes
  - Standardize all error responses per error-handling pattern
- Extract inline routes from server.js to dedicated route files:
  - `src/routes/health.js` — Health and status endpoints
  - `src/routes/comments.js` — Comment endpoints (stub for task-7)
  - `src/routes/notifications.js` — Notification endpoints (stub for task-9)
- Clean up server.js to only handle app setup, middleware registration, route mounting

## Key Files

- `src/server.js` — Refactor to thin app setup
- `src/routes/*.js` — Thin HTTP layer
- `src/services/*.js` — New service layer (create these)
- `src/middleware/error.js` — Proper error handler

## Acceptance Criteria

- [ ] All four service files exist with extracted business logic
- [ ] Route handlers contain no direct database calls
- [ ] Route handlers contain no business logic beyond request parsing
- [ ] Express error handler uses correct 4-param signature
- [ ] All error responses follow standard format from error-handling pattern
- [ ] server.js is under 60 lines (setup + middleware + route mounting only)
- [ ] All existing functionality still works after refactor
- [ ] No inline route definitions remain in server.js

## References

- `agent/patterns/error-handling.md` — Error response format and error types
- `agent/design/workspace-architecture.md` — Service layer design
