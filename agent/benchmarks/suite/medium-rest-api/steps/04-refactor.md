Refactor the API to separate concerns by extracting route handlers into their own module.

Requirements:
1. Create `src/routes/todos.js` containing all todo route handlers
2. The routes module should export an Express Router
3. `src/index.js` should only handle:
   - Express app setup and middleware (body-parser, etc.)
   - Mounting the routes (`app.use('/todos', todosRouter)`)
   - Starting the server
4. Move the in-memory todos array into the routes module (or a separate data module)
5. All existing functionality must be preserved — no behavior changes

After refactoring:
- Run the full test suite to confirm nothing is broken
- Verify the API still works correctly
