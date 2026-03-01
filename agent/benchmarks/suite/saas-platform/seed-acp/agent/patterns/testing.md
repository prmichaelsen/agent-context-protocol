# Pattern: Testing

## Framework

All tests use **Jest** as the runner and **Supertest** for HTTP testing.

## Directory Structure

```
tests/
  auth.test.js          # Registration, login, token refresh
  workspaces.test.js    # Workspace CRUD, membership
  tasks.test.js         # Task CRUD, state transitions
  comments.test.js      # Comment threads, activity feed
  notifications.test.js # Notification creation and retrieval
  search.test.js        # Search and filtering
  webhooks.test.js      # Webhook registration and delivery
  audit.test.js         # Audit log entries
  helpers.js            # Shared test utilities
```

## Test Helpers

```js
function createTestUser(overrides = {})    // returns { id, email, name }
function getAuthToken(user)                // returns JWT token string
function createTestWorkspace(ownerId)      // returns workspace object
function setupTestContext()                // returns { user, token, workspace }
```

## Test Structure

```js
const { setupTestContext } = require('./helpers');

describe('POST /api/tasks', () => {
  let ctx;
  beforeAll(async () => { ctx = await setupTestContext(); });

  test('creates a task with valid input', async () => { /* ... */ });
  test('returns 400 for missing title', async () => { /* ... */ });
  test('returns 403 for viewer role', async () => { /* ... */ });
});
```

Each file: one `describe` per endpoint, test happy path + error cases.

## Workspace Isolation

Each test suite creates its own workspace via `setupTestContext()`.
Tests must never depend on data from another suite.

## Cleanup

In-memory stores are reset between suites. Use `beforeAll` for setup
and `beforeEach` only when individual test isolation is needed.

## Assertions

- `expect(res.status).toBe(...)` for status codes
- `expect(res.body).toMatchObject(...)` for partial body matching
- `expect(res.body.error.code).toBe('...')` for error assertions
- Validate pagination shape on all list endpoints
- Always test both success and at least one failure case per endpoint
