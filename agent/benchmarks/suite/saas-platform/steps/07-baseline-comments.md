Implement comments and activity feed:

1. Create a full Comment model: { id, taskId, userId, body (required, max 5000 chars), createdAt, updatedAt }
2. Implement CRUD on /tasks/:id/comments:
   - GET — list comments with pagination { data, pagination }
   - POST — create comment (require body), return 201
   - PUT /tasks/:id/comments/:commentId — update (only author can edit)
   - DELETE /tasks/:id/comments/:commentId — delete (author or admin)
3. Add GET /workspaces/:id/activity endpoint — returns recent activity across all tasks/projects in the workspace
4. Activity items: { type (task_created, task_updated, comment_added, member_joined), description, userId, entityType, entityId, timestamp }
5. Activity feed: paginated, sorted by timestamp desc, filterable by type
