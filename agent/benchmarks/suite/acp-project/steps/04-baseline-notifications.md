Implement a notification system. Notifications are created automatically as side effects of task and project operations.

1. Create src/models/notification.js with in-memory storage:
   - Notifications have: id (UUID), userId (UUID, the recipient), type (string), message (string), read (boolean, default false), entityType (task or project), entityId (UUID), createdAt (ISO8601)
   - Functions: createNotification, getNotificationsForUser (with unreadOnly filter, pagination), markAsRead (verify notification belongs to user), markAllAsRead (returns count)

2. Implement notification routes in src/routes/notifications.js:
   - GET / — list authenticated user's notifications, with unreadOnly query param and pagination. Users only see their own notifications.
   - PUT /:id/read — mark single notification as read (verify ownership)
   - PUT /read-all — mark all user's notifications as read, return { updated: N }

3. Add notification triggers to existing routes:
   - POST /tasks: if assigneeId is set and different from creator → create notification (type: task_created, message: "You were assigned a new task: {title}")
   - PUT /tasks/:id: if assigneeId changed → create notification (type: task_assigned, message: "You were assigned to task: {title}"); if status changed to done and task has projectId → create notification for project owner (type: task_completed, message: "Task completed: {title}")
   - DELETE /projects/:id: create notification for all users who have tasks in that project (type: project_archived, message: "Project archived: {name}")

4. All errors use format: { error: { code: "ERROR_CODE", message: "description" } }

5. Add notification tests to your test suite (6+ tests). All tests must still pass.
