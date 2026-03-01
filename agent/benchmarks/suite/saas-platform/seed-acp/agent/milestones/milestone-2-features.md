# Milestone 2: Core Features

## Goal

Build the collaboration features that turn the basic task API into a
functional team productivity platform. This includes a task state
machine, comment threads, real-time event streaming, in-app
notifications, and full-text search with filtering.

## Tasks

| #  | Task                  | Description                                              |
|----|-----------------------|----------------------------------------------------------|
| 6  | Task State Machine    | Define valid status transitions, enforce in service layer |
| 7  | Comments & Activity   | Threaded comments on tasks, activity feed per task        |
| 8  | Real-Time Events      | EventBus + SSE endpoint for live workspace updates        |
| 9  | Notifications         | In-app notification records, mark-read, list per user     |
| 10 | Search & Filtering    | Search tasks by keyword, filter by status/priority/assignee |

## Deliverables

- Task status workflow: open -> in_progress -> review -> done / blocked
- Comment CRUD nested under tasks with activity log entries
- SSE endpoint streaming workspace events to connected clients
- EventBus wiring: task and comment mutations emit domain events
- Notification service creating records from event subscriptions
- Search endpoint with query, status, priority, and assignee filters
- All new features scoped to workspaces and respecting RBAC

## Success Criteria

- Invalid state transitions are rejected with a clear error message
- Comments appear in task activity feed in chronological order
- SSE clients receive events within one second of the triggering action
- All domain events flow through the EventBus with correct payloads
- Notifications are created automatically and can be marked as read
- Search returns relevant results filtered by workspace membership
- All features work correctly with workspace isolation in place
