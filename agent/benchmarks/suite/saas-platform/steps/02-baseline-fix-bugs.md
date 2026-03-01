Fix all critical bugs found in your analysis:

1. Hash passwords with bcrypt instead of storing plaintext
2. Add email uniqueness check on registration
3. Add JWT token expiry (e.g., 24h)
4. Fix auth middleware: return 401 (not 403) for invalid tokens, handle empty tokens
5. Fix task filter logic — the status filter condition is wrong, allowing unrelated tasks through
6. Fix project routes: return proper 404 status codes instead of 200 for missing resources
7. Fix Express error handler — it needs 4 parameters (err, req, res, next) to work
8. Strip password fields from all user responses
9. Add body validation on task creation (require title, validate status/priority enums)
10. Standardize all error responses to format: { error: { code: "ERROR_CODE", message: "description" } }
    Error codes: VALIDATION_ERROR (400), UNAUTHORIZED (401), FORBIDDEN (403), NOT_FOUND (404), CONFLICT (409), INTERNAL_ERROR (500)
