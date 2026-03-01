# Audit Logging

## Overview

The audit log provides an immutable record of all significant actions performed within a workspace. Every create, update, delete, and access-control change is captured with the acting user, affected entity, and a JSON diff of changes. Audit records cannot be modified or deleted.

## Data Model

### AuditLog

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| workspaceId | string (UUID) | References Workspace.id, required |
| userId | string (UUID) | References User.id, the actor |
| action | string | `create`, `update`, `delete`, `login`, `logout`, `member_added`, `member_removed`, `role_changed` |
| entityType | string | `task`, `project`, `comment`, `workspace`, `member`, `webhook`, `user` |
| entityId | string (UUID) | The ID of the affected entity |
| changes | object or null | JSON diff of the changes (see below) |
| ipAddress | string or null | Request origin IP (use `X-Forwarded-For` behind proxies) |
| timestamp | string (ISO8601) | Auto-set on creation |

## Changes Format

The `changes` field uses a before/after format for each modified field:
```json
{ "status": { "from": "todo", "to": "in_progress" }, "assigneeId": { "from": null, "to": "uuid" } }
```
- **create**: All fields have `from: null`.
- **update**: Only changed fields are included.
- **delete**: All fields have `to: null`.
- **login/logout**: `changes` is `null`.
- Sensitive fields (`passwordHash`, webhook `secret`) and computed fields (`updatedAt`) are excluded.

## API Endpoint

### GET /workspaces/:id/audit-log

- **Auth**: Required, role `admin` or `owner`.
- **Query Parameters**:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| userId | string (UUID) | No | — | Filter by the acting user |
| action | string | No | — | Filter by action type |
| entityType | string | No | — | Filter by entity type |
| entityId | string (UUID) | No | — | Filter by specific entity |
| dateFrom | string (ISO8601) | No | — | Records on or after this date |
| dateTo | string (ISO8601) | No | — | Records on or before this date |
| page | number | No | 1 | Page number |
| limit | number | No | 50 | Items per page, max 100 |

- **Response**: `200 OK`
```json
{
  "data": [
    {
      "id": "uuid", "workspaceId": "uuid", "userId": "uuid",
      "action": "update", "entityType": "task", "entityId": "uuid",
      "changes": { "status": { "from": "todo", "to": "in_progress" } },
      "ipAddress": "192.168.1.1", "timestamp": "ISO8601"
    }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 234, "totalPages": 5 }
}
```
- Results are sorted by `timestamp` descending (newest first).
- **Errors**: `403` if the user's role is below `admin`.

## Recording Audit Events

Audit entries are created by service-layer functions after successful operations:
```
AuditLog.create({ workspaceId, userId, action: 'update', entityType: 'task',
  entityId: task.id, changes: computeDiff(oldTask, newTask), ipAddress: ctx.ip });
```

### What Gets Logged

| Operation | Action | Entity Type |
|-----------|--------|-------------|
| Create/update/delete task | `create`/`update`/`delete` | `task` |
| Create/update/delete project | `create`/`update`/`delete` | `project` |
| Create/delete comment | `create`/`delete` | `comment` |
| Add/remove workspace member | `member_added`/`member_removed` | `member` |
| Change member role | `role_changed` | `member` |
| Create/update/delete webhook | `create`/`update`/`delete` | `webhook` |
| User login/logout | `login`/`logout` | `user` |

## Immutability

- No `PUT`, `PATCH`, or `DELETE` endpoints exist for audit records.
- The data store does not expose update or delete methods. Attempts return `405 Method Not Allowed`.

## Relationships

```
Workspace 1──* AuditLog (workspaceId)
User 1──* AuditLog (userId)
```

## Dependencies

- Workspace scoping: All audit records are tied to a workspace (see workspace-architecture.md).
- RBAC: Only `admin` and `owner` roles can read audit logs (see rbac-system.md).
- Audit logging does not trigger notifications or SSE events.

## Edge Cases

- Login/logout actions may have `workspaceId: null` for global authentication events.
- If the acting user is deleted, their audit records remain with the original `userId`.
- Bulk operations produce individual audit records per entity.
- The `changes` field for `delete` captures entity state at deletion time.
- Failed operations (validation errors, permission denials) are not logged.
