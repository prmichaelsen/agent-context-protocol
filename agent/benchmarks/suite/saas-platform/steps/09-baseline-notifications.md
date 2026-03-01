Implement the notification system:

1. Create a full Notification model: { id, userId, type, message, read (default false), entityType, entityId, workspaceId, createdAt }
2. Notification types: task_assigned, task_status_changed, task_commented, member_added, member_removed
3. Auto-trigger notifications:
   - task_assigned: when a task's assigneeId is set or changed (notify the assignee)
   - task_status_changed: when task status changes (notify the assignee)
   - task_commented: when someone comments on a task (notify the assignee and task creator)
   - member_added/removed: when workspace membership changes (notify the affected user)
4. Never notify users about their own actions
5. API endpoints:
   - GET /notifications — list user's notifications with pagination, filter by ?unreadOnly=true
   - PUT /notifications/:id/read — mark single notification as read (only own notifications)
   - PUT /notifications/read-all — mark all user's notifications as read, return { updated: N }
6. Add NotificationPreference model per user per workspace to enable/disable notification types
