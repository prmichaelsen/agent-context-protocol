# Notification System Design

## Overview

Notifications are created automatically as side effects of task and project operations. They are stored in-memory and served via the `/notifications` endpoint.

## Notification Triggers

| Trigger | Type | Recipient | Message Template |
|---------|------|-----------|-----------------|
| Task created with assignee | `task_created` | Assignee (if different from creator) | `"You were assigned a new task: {title}"` |
| Task assignee changed | `task_assigned` | New assignee | `"You were assigned to task: {title}"` |
| Task status changed to `done` | `task_completed` | Project owner (if task has projectId) | `"Task completed: {title}"` |
| Project archived | `project_archived` | All users with tasks in that project | `"Project archived: {name}"` |

## Implementation

### Notification Model (`src/models/notification.js`)

```javascript
// In-memory storage
const notifications = [];

function createNotification(userId, type, message, entityType, entityId) { ... }
function getNotificationsForUser(userId, { unreadOnly, page, limit }) { ... }
function markAsRead(id, userId) { ... }
function markAllAsRead(userId) { ... }
```

### Integration Points

Notifications are created inline within route handlers — no event bus needed for MVP:

1. **POST /tasks** — After creating task, if `assigneeId` is set and differs from `req.user.id`, create `task_created` notification
2. **PUT /tasks/:id** — After updating:
   - If `assigneeId` changed → create `task_assigned` notification for new assignee
   - If `status` changed to `done` and task has `projectId` → create `task_completed` notification for project owner
3. **DELETE /projects/:id** — Before deleting, find all tasks with this projectId, collect unique assigneeIds, create `project_archived` notification for each

### Access Control

The GET /notifications endpoint filters by `req.user.id`. Users never see other users' notifications. PUT /notifications/:id/read verifies the notification belongs to the requesting user before updating.
