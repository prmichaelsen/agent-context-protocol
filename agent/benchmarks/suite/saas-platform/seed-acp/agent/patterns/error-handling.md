# Pattern: Error Handling

## Standard Error Response Format

All API errors MUST return: `{ error: { code, message, details: [] } }`

## Error Codes

| Code              | HTTP Status | When to Use                              |
|-------------------|-------------|------------------------------------------|
| VALIDATION_ERROR  | 400         | Invalid input, missing required fields   |
| UNAUTHORIZED      | 401         | Missing or invalid authentication token  |
| FORBIDDEN         | 403         | Valid auth but insufficient permissions   |
| NOT_FOUND         | 404         | Resource does not exist or not visible    |
| CONFLICT          | 409         | Duplicate resource, state conflict        |
| INTERNAL_ERROR    | 500         | Unexpected server error                   |

## Field-Level Validation

When `code` is `VALIDATION_ERROR`, include one entry per invalid field:

```json
{ "details": [{ "field": "email", "message": "Invalid format" }] }
```

## Factory Function

```js
function createErrorResponse(code, message, details = []) {
  const statusMap = {
    VALIDATION_ERROR: 400, UNAUTHORIZED: 401, FORBIDDEN: 403,
    NOT_FOUND: 404, CONFLICT: 409, INTERNAL_ERROR: 500,
  };
  return {
    status: statusMap[code] || 500,
    body: { error: { code, message, details } },
  };
}
```

## Express Error Handler Middleware

Register as the LAST middleware. Must use the four-argument signature:

```js
function errorHandler(err, req, res, next) {
  console.error(`[ERROR] ${err.code || 'INTERNAL_ERROR'}: ${err.message}`);
  const { status, body } = createErrorResponse(
    err.code || 'INTERNAL_ERROR',
    err.message || 'An unexpected error occurred',
    err.details || []
  );
  res.status(status).json(body);
}
```

## Rules

- Never expose stack traces in production responses.
- Always set the HTTP status code matching the error code.
- Throw errors with a `code` property so the handler can map them.
- Log the full error server-side before sending the sanitized response.
