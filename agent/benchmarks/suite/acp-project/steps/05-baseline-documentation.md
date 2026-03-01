Create a comprehensive README.md for the application:

1. Project description (1-2 sentences about what TaskFlow API does)

2. Setup instructions:
   - npm install
   - npm start (starts on port 3000)
   - npm test (runs Jest test suite)

3. Authentication guide:
   - How to register (POST /auth/register with name, email, password)
   - How to login (POST /auth/login with email, password)
   - How to use token (Authorization: Bearer <token> header)

4. API endpoint reference — for every endpoint:
   - Method and path
   - Auth requirement
   - Request body (with field types and constraints)
   - Response format (with example JSON)
   - Error codes and their meanings
   - Include at least one curl example per resource type

5. Pagination and filtering:
   - How pagination works (page, limit query params)
   - Available filters per endpoint
   - Sorting options

Run npm test one final time to verify all tests pass.
