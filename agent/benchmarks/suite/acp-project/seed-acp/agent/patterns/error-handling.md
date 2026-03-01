# Error Handling Pattern

## Standard Error Response Format

All error responses use this format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description"
  }
}
```

**Never** return bare `{ message: "..." }` — always wrap in `{ error: { ... } }`.

## Error Codes

| Code | HTTP Status | When |
|------|-------------|------|
| `VALIDATION_ERROR` | 400 | Missing/invalid request body fields |
| `UNAUTHORIZED` | 401 | No token or invalid credentials |
| `FORBIDDEN` | 403 | Valid token but expired or revoked |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `CONFLICT` | 409 | Duplicate (e.g., email already registered) |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

## Validation Errors

For field-level validation, include a `details` array:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      { "field": "title", "message": "Title is required" },
      { "field": "priority", "message": "Priority must be one of: low, medium, high, urgent" }
    ]
  }
}
```

For single-field errors, `details` is optional — the `message` can describe the issue directly.

## Implementation Pattern

Use try/catch in every route handler. Catch known errors (validation, not-found) and return appropriate codes. Let unknown errors fall through to a 500 response.

```javascript
router.post('/', async (req, res) => {
  try {
    // validate, create, respond
  } catch (err) {
    res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Internal server error' } });
  }
});
```
