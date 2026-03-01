Refactor the legacy server.js into a proper Express project structure. The goal is clean separation of concerns while keeping all existing routes working identically.

Requirements:

1. **Extract routes** into `routes/notes.js` — all CRUD endpoints for notes
2. **Create middleware** in `middleware/`:
   - `error-handler.js` — global error handling middleware (catches thrown errors, returns proper JSON error responses)
   - `request-logger.js` — logs HTTP method and path for each request
3. **Extract the data store** into its own module (`store/notes.js` or `models/notes.js`) — the in-memory array and all data access operations
4. **Create app entry point** — `app.js` for Express app setup (middleware, routes) and `index.js` for starting the server
5. **Use environment variables** — port should come from `process.env.PORT` with a default of 3000
6. **Fix naming consistency** — use camelCase throughout (fix any snake_case fields like `created_at` → `createdAt`)
7. **Update package.json** — update the `start` script to point to the new entry point

After refactoring:
- All existing routes must still work identically (same paths, same request/response formats)
- The monolithic server.js should no longer be the entry point
- Each module should have a single responsibility