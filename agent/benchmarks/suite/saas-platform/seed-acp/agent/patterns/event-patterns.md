# Pattern: Event System

## Overview

All events flow through a single in-process EventBus instance.
Downstream systems (SSE, notifications, webhooks, audit) subscribe.

## EventBus Singleton

```js
const EventBus = {
  emit(eventType, data) { /* ... */ },   // Emit to all handlers
  on(eventType, handler) { /* ... */ },  // Register a handler
  off(eventType, handler) { /* ... */ }, // Remove a handler
};
```

Import from `src/events/eventBus.js` in any module.

## Event Naming

Events use the `entity.action` format:

| Event              | Trigger                       |
|--------------------|-------------------------------|
| task.created       | New task added                |
| task.updated       | Task fields modified          |
| task.deleted       | Task removed                  |
| task.statusChanged | Task state transition         |
| comment.created    | New comment posted            |
| comment.deleted    | Comment removed               |
| member.added       | User added to workspace       |
| member.removed     | User removed from workspace   |
| webhook.delivered  | Webhook payload sent          |

## Event Payload Shape

Every event payload MUST include:

```json
{
  "type": "task.created",
  "data": { "id": "...", "title": "...", "status": "open" },
  "workspaceId": "ws_abc123",
  "userId": "usr_def456",
  "timestamp": "2026-01-15T10:30:00.000Z"
}
```

## Handler Registration

Register handlers at startup before accepting requests:

```js
function registerAllHandlers() {
  EventBus.on('task.created', notificationHandler);
  EventBus.on('task.created', webhookHandler);
  EventBus.on('task.created', auditHandler);
  EventBus.on('task.statusChanged', sseHandler);
}
```

## Downstream Consumers

| Consumer      | Purpose                                    |
|---------------|--------------------------------------------|
| SSE           | Push real-time updates to connected clients |
| Notifications | Create in-app notification records          |
| Webhooks      | Forward event payloads to external URLs     |
| Audit Logging | Record immutable log entry for the action   |
