# Task State Machine

## Overview

Tasks follow a strict state machine governing valid status transitions. Every status change is recorded in a StatusHistory log. Invalid transitions are rejected with a `400` error, ensuring data integrity and predictable workflow behavior.

## States

| Status | Description |
|--------|-------------|
| `todo` | Created but work has not started |
| `in_progress` | Actively being worked on |
| `review` | Work complete, awaiting review |
| `done` | Finished and accepted |
| `blocked` | Cannot proceed due to external dependency |

Default on creation: `todo`.

## Transition Rules

### Valid Transitions
```
todo ──────────> in_progress
in_progress ───> review
in_progress ───> blocked
review ────────> done
review ────────> in_progress    (revisions requested)
blocked ───────> in_progress    (blocker resolved)
done ──────────> todo           (reopen)
```

### Transition Table

| From \ To | todo | in_progress | review | done | blocked |
|-----------|------|-------------|--------|------|---------|
| todo | - | YES | NO | NO | NO |
| in_progress | NO | - | YES | NO | YES |
| review | NO | YES | - | YES | NO |
| done | YES | NO | NO | - | NO |
| blocked | NO | YES | NO | NO | - |

Invalid transitions return `400`:
```json
{ "error": { "code": "INVALID_TRANSITION", "message": "Cannot transition from 'todo' to 'done'" } }
```

## Data Model

### StatusHistory

| Field | Type | Constraints |
|-------|------|-------------|
| id | string (UUID v4) | Primary key, auto-generated |
| taskId | string (UUID) | References Task.id |
| fromStatus | string | Previous status |
| toStatus | string | New status |
| changedBy | string (UUID) | References User.id |
| changedAt | string (ISO8601) | Auto-set on creation |
| reason | string or null | Optional explanation |

## API Endpoints

### PUT /tasks/:id (status change behavior)

When `status` is included in the update body, the server validates the transition before any other updates. The optional `reason` field is stored in StatusHistory.
```json
{ "status": "in_progress", "reason": "Starting work on this feature" }
```

### GET /tasks/:id/history
- **Auth**: Required, must be a workspace member.
- **Query**: `page` (default: 1), `limit` (default: 50, max: 100)
- **Response**: `200 OK`
```json
{
  "data": [
    { "id": "uuid", "taskId": "uuid", "fromStatus": "todo", "toStatus": "in_progress",
      "changedBy": "uuid", "changedAt": "ISO8601", "reason": "Starting sprint work" }
  ],
  "pagination": { "page": 1, "limit": 50, "total": 4, "totalPages": 1 }
}
```
- Sorted by `changedAt` ascending (oldest first). **Errors**: `404` if task not found.

## Relationships

```
Task 1──* StatusHistory (taskId)
User 1──* StatusHistory (changedBy)
```

## Dependencies

- Workspace scoping: Status operations respect `x-workspace-id` (see workspace-architecture.md).
- RBAC: Status changes require at least `member` role (see rbac-system.md).
- Realtime: Emits `task.status_changed` events (see realtime-events.md).
- Notifications: Triggers `task_status_changed` for the assignee (see notification-pipeline.md).

## Edge Cases

- Same-status updates are no-ops: return `200` with unchanged task, no history record.
- Deleting a task cascades to its StatusHistory records.
- Creating a task with non-default status does not create a history record; history tracks changes only.
- The `reason` field is encouraged for `blocked` and reopen transitions but never required.
