The application has stubbed task CRUD endpoints in src/routes/tasks.js (they return 501). Implement them fully:

1. Create a task model (src/models/task.js) with in-memory array storage:
   - Tasks have: id (UUID), title (string, required, max 200 chars), description (string, optional, max 2000 chars), status (todo/in_progress/done, default: todo), priority (low/medium/high/urgent, default: medium), projectId (UUID or null), assigneeId (UUID or null), createdBy (UUID, from authenticated user), createdAt (ISO8601), updatedAt (ISO8601), dueDate (ISO8601 or null)
   - CRUD functions: createTask, getTaskById, getAllTasks, updateTask, deleteTask

2. Implement all 5 REST endpoints in src/routes/tasks.js:
   - GET / — list tasks with pagination (page, limit query params), filtering (status, priority, projectId, assigneeId), and sorting (sort, order params). Return: { data: [...], pagination: { page, limit, total, totalPages } }
   - GET /:id — return single task or 404
   - POST / — create task with validation. Title required. Validate status/priority enums. If projectId provided, verify project exists. If assigneeId provided, verify user exists. Return 201.
   - PUT /:id — partial update with same validation. Set updatedAt. Return 200 or 404.
   - DELETE /:id — delete task. Return 204 or 404.

3. All errors must use format: { error: { code: "ERROR_CODE", message: "description" } }
   Error codes: VALIDATION_ERROR (400), NOT_FOUND (404), UNAUTHORIZED (401), INTERNAL_ERROR (500)
