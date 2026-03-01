The application has stubbed project CRUD endpoints in src/routes/projects.js (they return 501). Implement them fully:

1. Create a project model (src/models/project.js) with in-memory array storage:
   - Projects have: id (UUID), name (string, required, max 100 chars), description (string, optional, max 500 chars), ownerId (UUID, set from authenticated user), status (active/archived, default: active), createdAt (ISO8601)
   - CRUD functions: createProject, getProjectById, getAllProjects, updateProject, deleteProject

2. Implement all 5 REST endpoints in src/routes/projects.js:
   - GET / — list with pagination (page, limit) and status filter. Return: { data: [...], pagination: { page, limit, total, totalPages } }
   - GET /:id — return single project or 404
   - POST / — create with validation. Name required. Set ownerId from req.user.id. Return 201.
   - PUT /:id — partial update. Return 200 or 404.
   - DELETE /:id — delete project AND set projectId to null on all tasks that reference this project (cascade). Return 204 or 404.

3. All errors must use format: { error: { code: "ERROR_CODE", message: "description" } }
