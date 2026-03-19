# Task 3: Comprehensive Test Suite

**Status**: Not Started  
**Estimated Hours**: 4  
**Milestone**: M1 (MVP)  
**Dependencies**: Task 1, Task 2  

## Objective

Write a comprehensive test suite covering all API endpoints using Jest and Supertest.

## Steps

1. Create `tests/auth.test.js`:
   - Register with valid data → 201
   - Register with duplicate email → 409
   - Register with missing fields → 400
   - Login with valid credentials → 200 with token
   - Login with wrong password → 401
   - Login with missing fields → 400

2. Create `tests/tasks.test.js`:
   - Create task with valid data → 201
   - Create task with missing title → 400
   - Create task with invalid status → 400
   - Create task with invalid priority → 400
   - Create task with non-existent projectId → 404
   - Get task by ID → 200
   - Get non-existent task → 404
   - List tasks → 200 with pagination
   - List tasks with status filter → correct filtered results
   - Update task → 200
   - Delete task → 204
   - Unauthenticated request → 401

3. Create `tests/projects.test.js`:
   - Create project → 201 with ownerId set
   - Create project with missing name → 400
   - Get project → 200
   - Get non-existent project → 404
   - List projects → 200 with pagination
   - Update project → 200
   - Delete project → 204, verify task cascade
   - Unauthenticated request → 401

4. Create `tests/notifications.test.js`:
   - List notifications → 200 (after triggering via task operations)
   - Filter unread → correct results
   - Mark as read → 200
   - Mark all as read → 200 with count
   - Cannot see other user's notifications
   - Unauthenticated request → 401

## Testing Patterns

Follow `agent/patterns/testing.md` for file structure, setup patterns, and coverage targets.

## Acceptance Criteria

- 30+ tests total
- All tests pass (`npm test`)
- Every endpoint has at least one happy-path and one error-path test
- Auth required on protected endpoints is verified
