# Task 8: Real-time Events (SSE)

**Status:** not_started
**Milestone:** M2 — Core Features
**Estimated Hours:** 3
**Depends On:** task-6

## Objective

Implement Server-Sent Events (SSE) so clients can receive real-time updates
for their workspace without polling. All mutations should emit events that
are broadcast to connected workspace members.

## Requirements

- Create EventBus singleton:
  - In-memory pub/sub system
  - Subscribe by workspace ID
  - Unsubscribe on disconnect
  - Support multiple listeners per workspace
- Implement SSE endpoint:
  - GET /workspaces/:id/events — SSE stream for workspace
  - Requires authentication and workspace membership
  - Send keepalive comments every 30 seconds
  - Include `Last-Event-ID` support for reconnection
  - Set proper headers: Content-Type, Cache-Control, Connection
- Emit events on all mutations:
  - task.created, task.updated, task.deleted, task.status_changed
  - project.created, project.updated, project.deleted
  - comment.created, comment.updated, comment.deleted
  - member.added, member.removed, member.role_changed
  - notification.created
- Event message format:
  - id: incrementing event ID per workspace
  - event: event type string
  - data: JSON payload with resource data and actor info
- Handle connection lifecycle:
  - Track active connections per workspace
  - Clean up on client disconnect
  - Support auto-reconnect via Last-Event-ID
  - Graceful shutdown: close all connections on server stop

## Key Files

- `src/services/event-bus.js` — New EventBus singleton
- `src/routes/events.js` — SSE endpoint
- `src/services/task-service.js` — Emit events on mutations
- `src/services/project-service.js` — Emit events on mutations
- `src/services/comment-service.js` — Emit events on mutations
- `src/services/workspace-service.js` — Emit events on membership changes

## Acceptance Criteria

- [ ] SSE endpoint streams events to authenticated workspace members
- [ ] All CRUD operations emit appropriate events
- [ ] Events include event ID, type, and JSON data
- [ ] Keepalive sent every 30 seconds
- [ ] Last-Event-ID reconnection replays missed events
- [ ] Disconnected clients are cleaned up properly
- [ ] Multiple clients per workspace receive the same events

## References

- `agent/design/realtime-events.md` — SSE design and event catalog
- `agent/patterns/event-patterns.md` — Event naming and payload conventions
