# Testing Patterns

## Framework

Use Jest with Supertest for HTTP endpoint testing.

## File Structure

```
tests/
├── auth.test.js         — Registration and login tests
├── tasks.test.js        — Task CRUD tests
├── projects.test.js     — Project CRUD tests
├── notifications.test.js — Notification tests
```

## Test File Template

```javascript
const request = require('supertest');
const app = require('../src/index');

describe('Resource Name', () => {
  let authToken;

  beforeAll(async () => {
    // Register a test user and get token
    const res = await request(app)
      .post('/auth/register')
      .send({ name: 'Test User', email: 'test@example.com', password: 'password123' });
    authToken = res.body.token;
  });

  describe('POST /resource', () => {
    it('should create a resource with valid data', async () => { ... });
    it('should return 400 for missing required fields', async () => { ... });
    it('should return 401 without auth token', async () => { ... });
  });

  describe('GET /resource', () => {
    it('should return paginated results', async () => { ... });
    it('should filter by query params', async () => { ... });
  });

  // ... more describe blocks
});
```

## What to Test Per Endpoint

For each endpoint, test:
1. **Happy path** — valid request returns expected response
2. **Validation** — missing/invalid fields return 400 with correct error
3. **Auth** — unauthenticated request returns 401
4. **Not found** — invalid ID returns 404
5. **Edge cases** — empty strings, boundary values, duplicate data

## Test Coverage Targets

- Auth: 6+ tests (register success, register duplicate, register missing fields, login success, login wrong password, login missing fields)
- Tasks: 12+ tests (CRUD x happy + error paths, filtering, pagination)
- Projects: 8+ tests (CRUD x happy + error paths, cascade delete)
- Notifications: 6+ tests (list, filter unread, mark read, mark all read, access control)

**Minimum: 30 tests total.**

## Running Tests

```bash
npm test
```

Jest config is in package.json (default: `jest --verbose`).
