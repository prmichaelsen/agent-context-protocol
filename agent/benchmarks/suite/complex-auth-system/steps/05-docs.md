Create a README.md file with comprehensive API documentation.

Requirements:

The README.md should include:

**1. Project Title and Description**
- Brief description of the authentication system

**2. Setup Instructions**
- How to install dependencies (`npm install`)
- Environment variables: `PORT` (default 3000), `JWT_SECRET` (default "dev-secret-key")
- How to start the server (`npm start`)
- How to run tests (`npm test`)

**3. API Documentation**
Document all endpoints with:
- HTTP method and path
- Description
- Request body (if applicable)
- Response format and status codes
- Whether authentication is required

Endpoints to document:
- GET /health
- GET /public
- POST /auth/register
- POST /auth/login
- GET /auth/me (protected)

**4. Example curl Commands**
Provide working curl examples for the full flow:
1. Register a user
2. Login and get a token
3. Access the protected endpoint with the token
4. Show what happens with an invalid token

**5. Authentication**
- Explain the JWT-based auth flow
- Token format and expiration (1 hour)
- How to include the token in requests (`Authorization: Bearer <token>`)
