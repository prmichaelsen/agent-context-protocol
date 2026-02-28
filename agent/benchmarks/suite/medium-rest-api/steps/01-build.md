Build a REST API for a todo application using Node.js and Express.

Requirements:
- Initialize a new Node.js project with `npm init -y`
- Install Express as a dependency
- Create `src/index.js` as the main entry point
- Use an in-memory array to store todos (no database needed)
- Each todo has: `id` (integer, auto-increment), `title` (string, required), `completed` (boolean, default false)

Endpoints:
1. `GET /todos` — Return all todos as a JSON array
2. `GET /todos/:id` — Return a single todo by ID. Return 404 if not found.
3. `POST /todos` — Create a new todo. Accept `{ "title": "..." }` in the request body. Return 201 with the created todo.
4. `PUT /todos/:id` — Update a todo by ID. Accept `{ "title": "...", "completed": true/false }`. Return 404 if not found.
5. `DELETE /todos/:id` — Delete a todo by ID. Return 200 with `{ "message": "deleted" }`. Return 404 if not found.

The server should listen on port 3000 (or `process.env.PORT`).

Add a `start` script to package.json: `"start": "node src/index.js"`

Make sure the API works by starting the server and testing at least one endpoint with curl.
