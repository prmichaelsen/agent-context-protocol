Refactor the codebase to a clean service architecture:

1. Create a services/ directory with: user-service.js, task-service.js, project-service.js, workspace-service.js
2. Move all business logic from route handlers into service functions. Routes should only parse requests, call services, and format responses.
3. Create a proper Express error handler middleware with 4 args (err, req, res, next) that catches all errors and returns the standard error format
4. Extract the inline health, status, comments, and notifications endpoints from server.js into their own route files
5. Ensure all list endpoints return { data: [...], pagination: { page, limit, total, totalPages } }
6. Ensure all single-item endpoints return the object directly (not wrapped)
7. Use 201 for creates, 204 for deletes, 200 for everything else
