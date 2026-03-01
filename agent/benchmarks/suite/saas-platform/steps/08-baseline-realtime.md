Add real-time event streaming via Server-Sent Events (SSE):

1. Create an EventBus singleton with: emit(eventType, data), on(eventType, handler), off(eventType, handler)
2. Event naming: entity.action format (task.created, task.updated, task.deleted, task.status_changed, comment.created, member.joined, member.left)
3. Event payload: { type, data, workspaceId, userId, timestamp }
4. Add GET /workspaces/:id/events SSE endpoint:
   - Set headers: Content-Type text/event-stream, Cache-Control no-cache, Connection keep-alive
   - Only stream events for the authenticated user's workspace
   - Send keepalive comments every 30 seconds
   - Clean up on client disconnect
5. Wire all create/update/delete operations to emit events through the EventBus
6. SSE handler subscribes to EventBus and forwards matching workspace events to connected clients
