# Task 15: Security Hardening

**Status:** not_started
**Milestone:** M3 — Production Hardening
**Estimated Hours:** 4
**Depends On:** task-5

## Objective

Apply production-grade security measures to the entire API. Add defense-in-depth
layers including rate limiting, input sanitization, security headers, CORS
configuration, token refresh, and password strength enforcement.

## Requirements

- Rate limiting middleware:
  - Apply global rate limit (e.g., 100 requests per 15 minutes per IP)
  - Stricter limit on auth endpoints (e.g., 10 requests per 15 minutes per IP)
  - Return 429 Too Many Requests with Retry-After header
  - Use express-rate-limit or similar library
- Input sanitization:
  - Sanitize all string inputs to prevent XSS
  - Strip HTML tags from user-provided content
  - Validate and sanitize query parameters
  - Use a sanitization library (e.g., xss, sanitize-html, or express-validator)
- Security headers via helmet:
  - `npm install helmet` if not present
  - Apply default helmet headers
  - Configure Content-Security-Policy
  - Set X-Content-Type-Options: nosniff
  - Set X-Frame-Options: DENY
  - Remove X-Powered-By header
- CORS configuration:
  - Configure allowed origins (from environment variable)
  - Restrict allowed methods and headers
  - Handle preflight requests properly
  - Credentials support for authenticated requests
- JWT refresh tokens:
  - Issue short-lived access tokens (15 minutes)
  - Issue long-lived refresh tokens (7 days)
  - POST /auth/refresh — Exchange refresh token for new access token
  - Invalidate refresh tokens on password change
  - Store refresh token hash (not plaintext)
- Password strength validation:
  - Minimum 8 characters
  - Require at least one uppercase, one lowercase, one digit
  - Return clear error messages listing unmet requirements
  - Validate on registration and password change

## Key Files

- `src/middleware/rate-limit.js` — New rate limiting middleware
- `src/middleware/sanitize.js` — New input sanitization middleware
- `src/server.js` — Helmet, CORS, middleware registration
- `src/routes/auth.js` — Refresh token endpoint, password validation
- `src/services/user-service.js` — Password strength validation, token management

## Acceptance Criteria

- [ ] Rate limiting active on all routes, stricter on auth endpoints
- [ ] 429 responses include Retry-After header
- [ ] All user input sanitized against XSS
- [ ] Helmet security headers present in all responses
- [ ] X-Powered-By header removed
- [ ] CORS configured with allowed origins from environment
- [ ] Refresh token endpoint functional
- [ ] Access tokens expire in 15 minutes, refresh tokens in 7 days
- [ ] Refresh tokens invalidated on password change
- [ ] Weak passwords rejected with specific feedback
- [ ] All existing tests still pass with security layers active
