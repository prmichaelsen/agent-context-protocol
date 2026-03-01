Write a comprehensive test suite using Jest and Supertest. Create test files in a tests/ directory.

Test file structure:
- tests/auth.test.js — auth endpoint tests
- tests/tasks.test.js — task CRUD tests
- tests/projects.test.js — project CRUD tests

For each test file, register a test user in beforeAll and use the token for authenticated requests.

Tests to write:

Auth tests (6+):
- Register with valid data → 201 with user and token
- Register with duplicate email → 409
- Register with missing fields → 400
- Login with valid credentials → 200 with token
- Login with wrong password → 401
- Login with missing fields → 400

Task tests (12+):
- Create task with valid data → 201
- Create task missing title → 400
- Create task with invalid status → 400
- Create task with invalid priority → 400
- Create task with non-existent projectId → 404
- Get task by ID → 200
- Get non-existent task → 404
- List tasks → 200 with pagination structure
- List tasks with status filter
- Update task → 200
- Delete task → 204
- Request without auth → 401

Project tests (8+):
- Create project → 201
- Create project missing name → 400
- Get project → 200
- Get non-existent project → 404
- List projects → 200 with pagination
- Update project → 200
- Delete project → 204 (verify cascade nullifies task projectId)
- Request without auth → 401

All tests must pass when running npm test. Target: 30+ tests total.
