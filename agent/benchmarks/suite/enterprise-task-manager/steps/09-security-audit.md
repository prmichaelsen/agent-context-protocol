Perform a security audit and fix all issues found.

**Authorization boundary testing:**
- Verify that a user in Team A cannot access any of Team B's resources (projects, tasks, activity)
- Verify that role restrictions cannot be bypassed (e.g., by crafting requests directly)
- Verify that team scoping is enforced on all endpoints, including nested ones (e.g., /projects/:id/tasks)

**Rate limiting:**
- Add rate limiting middleware: 100 requests per minute per API key
- Return 429 Too Many Requests when limit is exceeded
- Include Retry-After header

**Data protection:**
- Ensure API keys are never returned in full in any response
- Ensure internal fields (_store, internal IDs) are never leaked
- Sanitize string inputs (strip HTML tags from name, title, description fields)

**Input validation hardening:**
- Validate all ID parameters are valid UUID format
- Reject requests with unexpected/extra fields in the body
- Validate numeric fields are actually numbers, string fields are actually strings

**Tests:**
- Write security-focused tests that attempt cross-team access
- Test rate limiting behavior
- Test that sanitization works (submit HTML in a field, verify it's stripped)
- Test that malformed IDs return 400 not 500
- All existing tests must still pass