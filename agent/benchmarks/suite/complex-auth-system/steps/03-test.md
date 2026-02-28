Add comprehensive tests for the authentication system.

Requirements:
- Install a test framework (Jest or Mocha) and supertest
- Create test files in a `tests/` directory
- Add a `test` script to package.json

Test the following scenarios:

**Registration (POST /auth/register)**
- Successfully registers a new user (201)
- Returns user without password hash in response
- Returns 409 for duplicate email
- Returns 400 for missing email
- Returns 400 for missing password
- Returns 400 for password shorter than 8 characters

**Login (POST /auth/login)**
- Successfully logs in with correct credentials (200, returns token)
- Returns 401 for wrong password
- Returns 401 for non-existent email

**Protected route (GET /auth/me)**
- Returns user info with valid token (200)
- Returns 401 with no Authorization header
- Returns 401 with invalid/malformed token
- Returns 401 with expired token (if applicable)

**Public routes**
- GET /health returns 200 without authentication
- GET /public returns 200 without authentication

**Integration flow**
- Register → Login → Access /auth/me with token — full flow works end-to-end

Make sure the server is properly started and stopped for each test suite. Run all tests and confirm they pass.
