Refactor the application architecture to address the structural issues identified in your analysis.

Requirements:

1. All routes must live in dedicated route files — nothing in server.js except app setup and middleware registration
2. Create a proper app.js / index.js separation (app setup vs server start) so the app can be imported for testing without starting the server
3. Fix any circular dependencies between modules
4. Apply authentication middleware consistently to all routes that need it
5. Standardize all error responses to use the same format: `{ "error": "message", "code": "ERROR_CODE" }`
6. Add input validation for all POST and PUT endpoints — reject requests with missing required fields
7. Move hardcoded configuration to environment variables with sensible defaults
8. Update package.json scripts as needed

All existing endpoints must continue to work. All existing tests must still pass. Run the test suite to verify.