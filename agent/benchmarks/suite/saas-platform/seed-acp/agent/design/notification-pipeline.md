# Notification Pipeline

## Overview

The notification system creates persistent, user-facing notifications when important events occur within a workspace. Unlike ephemeral SSE events, notifications are stored and retrievable later. Each notification targets a specific user and is scoped to a workspace. Users can mark notifications as read and configure preferences to suppress certain types.

## Data Model

### Notification

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| userId | string (UUID) | References User.id, the recipient |
| type | string | One of the notification types below |
| message | string | Human-readable notification text |
| read | boolean | Default: `false` |
| entityType | string | `task`, `project`, `workspace`, or `member` |
| entityId | string (UUID) | References the related entity |
| workspaceId | string (UUID) | References Workspace.id |
| createdAt | string (ISO8601) | Auto-set on creation |

### NotificationPreference

| Field | Type | Constraints |
|-------|------|-------------|
| userId | string (UUID) | Composite key with workspaceId and type |
| workspaceId | string (UUID) | Composite key |
| type | string | Notification type to configure |
| enabled | boolean | Default: `true` |

## Notification Types and Triggers

| Type | Trigger | Recipient |
|------|---------|-----------|
| `task_assigned` | Task assigneeId set or changed | The new assignee |
| `task_status_changed` | Task status transitions | The assignee (if not the changer) |
| `task_commented` | Comment created on a task | The assignee and creator (if not the commenter) |
| `member_added` | User added to workspace | The added user |
| `member_removed` | User removed from workspace | The removed user |

Self-triggered notifications are never created. A user does not receive notifications for their own actions.

## API Endpoints

### GET /notifications
- **Auth**: Required. Automatically scoped to `req.user.id`.
- **Query Parameters**: `workspaceId` (optional), `unreadOnly` (default: false), `type` (optional), `page` (default: 1), `limit` (default: 20, max: 100)
- **Response**: `200 OK`
```json
{
  "data": [
    { "id": "uuid", "userId": "uuid", "type": "task_assigned",
      "message": "You were assigned to task 'Implement auth'",
      "read": false, "entityType": "task", "entityId": "uuid",
      "workspaceId": "uuid", "createdAt": "ISO8601" }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 12, "totalPages": 1 }
}
```
- Sorted by `createdAt` descending (newest first).

### PUT /notifications/:id/read
- **Auth**: Required, notification must belong to the authenticated user.
- **Response**: `200 OK` — Updated notification with `read: true`.
- **Errors**: `404` if not found or does not belong to user.

### PUT /notifications/read-all
- **Auth**: Required. Optional `workspaceId` query parameter to scope.
- **Response**: `200 OK` — `{ "updated": 5 }`

### GET /notifications/preferences
- **Auth**: Required. `workspaceId` query parameter required.
- **Response**: `200 OK` — Array of `{ type, enabled }` objects for all notification types.

### PUT /notifications/preferences
- **Auth**: Required.
- **Request Body**: `{ "workspaceId": "uuid", "type": "task_commented", "enabled": false }`
- **Response**: `200 OK` — Updated preference.

## Relationships

```
User 1──* Notification (userId)
Workspace 1──* Notification (workspaceId)
User 1──* NotificationPreference (userId)
Workspace 1──* NotificationPreference (workspaceId)
```

## Dependencies

- Workspace scoping: Notifications are tied to a workspace (see workspace-architecture.md).
- RBAC: No special permissions needed; all users can access their own notifications.
- Realtime: Notification creation emits an SSE event for instant client updates (see realtime-events.md).

## Edge Cases

- Missing preference records default to `enabled: true`.
- A removed user's `member_removed` notification remains accessible even though the workspace reference is stale.
- If a task has no assignee, notifications go to the task creator instead.
- Notifications are never deleted; users can only mark them as read.
- Preference checks run before notification creation; disabled types are silently skipped.
