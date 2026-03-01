Write a comprehensive test suite using Jest and Supertest:

1. Create test helpers: createTestUser(), getAuthToken(user), createTestWorkspace(ownerId), setupTestContext() — returns { user, token, workspace }
2. Test files (one per feature area in tests/ directory):
   - auth.test.js — register, login, duplicate email, bad credentials, token validation
   - tasks.test.js — full CRUD, pagination, filtering, validation errors
   - projects.test.js — CRUD, cascading behavior on delete
   - workspaces.test.js — CRUD, membership management, workspace isolation
   - rbac.test.js — permission checks for all 4 roles (owner/admin/member/viewer) across resources
   - state-machine.test.js — valid transitions, invalid transitions (400 errors), status history
   - comments.test.js — CRUD, author-only edit, pagination
   - notifications.test.js — auto-trigger, mark read, preferences
   - search.test.js — cross-entity search, filters, workspace scoping
   - webhooks.test.js — registration, delivery, signatures, retry behavior
   - audit.test.js — log creation, immutability, query filters
3. Each test uses fresh workspace isolation — no test pollution
4. All tests must pass: npm test
