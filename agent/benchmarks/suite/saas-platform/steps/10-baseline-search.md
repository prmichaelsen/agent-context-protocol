Implement search and filtering:

1. Add GET /search endpoint with query parameters:
   - q (required) — search term, matched against titles, descriptions, comment bodies
   - type (optional) — comma-separated: tasks, projects, comments (default: all)
   - workspaceId (required) — scope search to workspace
   - status, priority, assigneeId — additional filters (for tasks)
   - sort — relevance (default), createdAt, updatedAt
   - order — desc (default), asc
   - page, limit — standard pagination
2. Search across tasks (title, description), projects (name, description), comments (body)
3. Case-insensitive substring matching
4. Return unified results: { data: [{ type: "task"|"project"|"comment", item: {...}, score }], pagination }
5. Results sorted by relevance (number of field matches) or specified sort field
6. All results must be within the specified workspace
