# Task 2: Fix Critical Bugs

**Status:** not_started
**Milestone:** M1 — Foundation & Stabilization
**Estimated Hours:** 3
**Depends On:** task-1

## Objective

Fix all critical bugs identified in the architecture audit. Bring the existing
codebase to a stable, secure baseline before adding new features. Every fix
must preserve existing passing tests and not break any current functionality.

## Requirements

- Hash passwords with bcrypt on registration and login:
  - `npm install bcryptjs` if not already present
  - Hash on create, compare on login
  - Use cost factor of 10
- Add email uniqueness check on registration (return 409 Conflict if duplicate)
- Fix JWT configuration:
  - Ensure tokens have proper expiry (e.g., 24h)
  - Validate expiry on token verification
- Fix auth bypass on empty/malformed tokens:
  - Reject empty string, null, undefined, and malformed Bearer headers
  - Return 401 for all invalid token cases
- Fix 403 to 401 where user is not authenticated (not just unauthorized)
- Fix filter bug: change `||` to `&&` for multi-criteria task filtering
- Fix project routes returning 200 with null for non-existent resources:
  - Return 404 with proper error body
- Fix Express error handler signature (must be 4 params: err, req, res, next)
- Strip password fields from all user objects in API responses
- Add request body validation:
  - Registration: require email and password
  - Login: require email and password
  - Task creation: require title
  - Project creation: require name

## Key Files

- `src/routes/auth.js` — Password hashing, JWT, email uniqueness
- `src/routes/tasks.js` — Filter bug, validation
- `src/routes/projects.js` — 404 handling
- `src/middleware/auth.js` — Token validation, 401 vs 403
- `src/middleware/error.js` — Error handler signature

## Acceptance Criteria

- [ ] Passwords stored as bcrypt hashes, never plaintext
- [ ] Duplicate email registration returns 409
- [ ] JWT tokens expire and expiry is validated
- [ ] Empty/malformed tokens return 401
- [ ] Multi-criteria filters use AND logic
- [ ] Missing resources return 404 with error body
- [ ] Error handler has correct 4-parameter Express signature
- [ ] No password fields in any API response
- [ ] All required fields validated, missing fields return 400
- [ ] Existing tests still pass

## References

- `agent/patterns/error-handling.md` — Standard error response format
- ANALYSIS.md — Detailed bug descriptions from task-1
