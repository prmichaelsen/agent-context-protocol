Security hardening:

1. Rate limiting: add middleware to limit requests per IP (e.g., 100 req/min general, 10 req/min for auth endpoints). Return 429 Too Many Requests when exceeded.
2. Input sanitization: strip HTML tags from all string inputs to prevent XSS. Validate string lengths.
3. Security headers: add helmet or equivalent (X-Content-Type-Options, X-Frame-Options, Strict-Transport-Security, X-XSS-Protection)
4. CORS: configure allowed origins, methods, and headers. Reject unauthorized origins.
5. Auth hardening:
   - JWT refresh tokens (short-lived access token + long-lived refresh token)
   - Password strength validation (min 8 chars, require mixed case + number)
   - Account lockout after 5 failed login attempts (temporary, 15 minutes)
6. Ensure rate limiting and security headers apply to all routes including SSE endpoints
