Add JWT-based authentication to the application.

Requirements:

**Dependencies**: Install `jsonwebtoken` and `bcryptjs` (or `bcrypt`).  

**User storage**: Use an in-memory array to store users. Each user has: `id` (auto-increment), `email` (string, unique), `password` (bcrypt hash), `createdAt` (ISO timestamp).  

**Auth routes** (create `src/routes/auth.js`):
1. `POST /auth/register`
   - Accept `{ "email": "...", "password": "..." }`
   - Validate: email required, password required and at least 8 characters
   - Hash the password with bcrypt (salt rounds: 10)
   - Return 201 with `{ "id": ..., "email": "...", "createdAt": "..." }`
   - Return 409 if email already exists
   - Return 400 for validation errors

2. `POST /auth/login`
   - Accept `{ "email": "...", "password": "..." }`
   - Verify credentials against stored users
   - Return 200 with `{ "token": "<jwt>" }` on success
   - JWT payload: `{ "userId": ..., "email": "..." }`
   - Use a secret key from `process.env.JWT_SECRET` or default to `"dev-secret-key"`
   - Return 401 for invalid credentials

3. `GET /auth/me` (protected)
   - Requires valid JWT in `Authorization: Bearer <token>` header
   - Returns the authenticated user's info: `{ "id": ..., "email": "...", "createdAt": "..." }`
   - Return 401 if no token or invalid token

**Auth middleware** (create `src/middleware/auth.js`):
- Extract JWT from `Authorization: Bearer <token>` header
- Verify the token using the JWT secret
- Attach decoded user info to `req.user`
- Return 401 with `{ "error": "Unauthorized" }` if token is missing or invalid

Mount auth routes at `/auth` in the main app. The `/health` and `/public` endpoints should remain unprotected.

Test the full flow: register a user, login, use the token to access /auth/me.
