Add comprehensive documentation for the refactored Notes API.

Create a README.md with the following sections:

1. **Project Description** — What this API does, what it was refactored from
2. **Setup Instructions** — How to install dependencies and start the server
3. **Environment Variables** — PORT and any other configuration
4. **API Documentation** — For every endpoint:
   - HTTP method and path
   - Request body (if applicable)
   - Query parameters (search, sort, order, limit, offset)
   - Response format with examples
   - Error responses
5. **Example curl commands** — Working curl examples for each endpoint
6. **Architecture Overview** — Explain the project directory structure and the responsibility of each module (routes, middleware, store, etc.)
7. **Refactoring Decisions** — A section explaining what was changed from the original legacy code and why (reference REFACTOR_PLAN.md)