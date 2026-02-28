There are two security issues in the authentication system that need to be fixed:

**Security Issue 1: Password hash leaked in /auth/me response**
The `GET /auth/me` endpoint returns the full user object from the in-memory store, which includes the bcrypt password hash. This is a security vulnerability — password hashes should never be sent to clients.

Fix: Ensure `/auth/me` (and any other endpoint that returns user data) strips the `password` field from the response. The response should only contain `id`, `email`, and `createdAt`.

**Security Issue 2: JWT tokens never expire**
The JWT tokens are signed without an expiration time, meaning a leaked token would be valid forever.

Fix: Set JWT token expiry to 1 hour using the `expiresIn` option when signing tokens:
```javascript
jwt.sign(payload, secret, { expiresIn: '1h' })
```

After fixing both issues:
1. Verify that `/auth/me` no longer returns the password field
2. Verify that tokens include an `exp` claim
3. Update any tests that need adjustment for the new behavior
4. Add a test that confirms the password field is NOT present in `/auth/me` response
5. Run the full test suite and confirm all tests pass
