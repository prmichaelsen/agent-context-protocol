# Realtime Events

## Overview

The platform provides real-time updates via Server-Sent Events (SSE). Each workspace has its own event stream. When actions occur (task created, status changed, member joined, etc.), events are broadcast to all connected workspace members, enabling live collaboration without polling.

## SSE Endpoint

### GET /workspaces/:id/events

- **Auth**: Required, must be a workspace member.
- **Headers**: `Accept: text/event-stream`, `Authorization: Bearer <token>`
- **Response**: `200 OK` with `Content-Type: text/event-stream`
- **Connection**: Long-lived; kept open until the client disconnects.
- **Errors**: `403` if not a member, `404` if workspace not found.

### Message Format
```
event: task.created
data: {"type":"task.created","data":{...},"timestamp":"ISO8601","workspaceId":"uuid","userId":"uuid"}

```

## Event Types

| Event | Trigger | Data Payload |
|-------|---------|-------------|
| `task.created` | New task created | Full task object |
| `task.updated` | Task fields modified | Full updated task object |
| `task.deleted` | Task removed | `{ id }` |
| `task.status_changed` | Status transitions | `{ id, fromStatus, toStatus, changedBy }` |
| `comment.created` | New comment posted | Full comment object |
| `member.joined` | User added to workspace | `{ userId, name, email, role }` |
| `member.left` | User removed | `{ userId }` |

## Event Payload Schema

```json
{ "type": "task.created", "data": { }, "timestamp": "ISO8601", "workspaceId": "uuid", "userId": "uuid" }
```

## EventBus Architecture

The EventBus is an in-memory publish/subscribe system:

```
EventBus.emit(workspaceId, event)     — Publish event to all workspace subscribers.
EventBus.subscribe(workspaceId, fn)   — Register handler; returns subscriptionId.
EventBus.unsubscribe(subscriptionId)  — Remove handler (call on disconnect to prevent leaks).
```

### Connection Lifecycle

1. Client opens `GET /workspaces/:id/events`.
2. Server validates auth and membership.
3. Server subscribes a handler that writes SSE-formatted data to the response stream.
4. Initial event sent: `event: connection\ndata: {"status":"connected"}\n\n`
5. On disconnect, server calls `EventBus.unsubscribe()`.

### Emitting Events

Service layer emits events after successful database operations:
```
EventBus.emit(workspaceId, {
  type: 'task.created', data: createdTask,
  timestamp: new Date().toISOString(), workspaceId, userId
});
```

## Client Reconnection

- Browsers auto-reconnect on dropped SSE connections.
- Server sends `retry: 3000` in initial response (3-second reconnect delay).
- No event replay or `Last-Event-ID` for MVP; clients resume with new events only.

## Relationships

- Events are workspace-scoped (see workspace-architecture.md).
- The notification pipeline (notification-pipeline.md) and webhooks (webhook-system.md) also consume EventBus events.

## Edge Cases

- If a user loses membership while connected, the server closes the SSE connection.
- Failed subscriber writes (broken pipe) trigger automatic unsubscription.
- Events are not persisted; if no clients are connected, events are discarded.
- Users receive events for their own actions; clients filter by `userId` if desired.
- Max 5 concurrent SSE connections per user per workspace.
- `task.updated` fires for any field change; `task.status_changed` fires additionally on status changes.
