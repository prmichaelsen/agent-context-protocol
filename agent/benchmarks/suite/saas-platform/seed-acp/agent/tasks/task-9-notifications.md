# Task 9: Notification System

**Status:** not_started
**Milestone:** M2 — Core Features
**Estimated Hours:** 3
**Depends On:** task-7

## Objective

Build an in-app notification system that automatically generates notifications
for relevant events and provides a user-facing API for managing them.

## Requirements

- Create Notification model:
  - Fields: id, userId, workspaceId, type, title, body, resourceType, resourceId, read, createdAt, readAt
  - Types: task_assigned, task_status_changed, comment_added, member_added, member_removed, mentioned
- Implement auto-trigger notifications:
  - Task assigned to user -> notify assignee
  - Task status changed -> notify task assignee and creator
  - Comment added to task -> notify task assignee and creator (not comment author)
  - Member added to workspace -> notify new member
  - Member removed from workspace -> notify removed member
  - Deduplicate: do not notify user about their own actions
- Implement Notification API:
  - GET /notifications — List current user's notifications (paginated)
  - GET /notifications/unread-count — Return count of unread notifications
  - PUT /notifications/:id/read — Mark single notification as read
  - PUT /notifications/read-all — Mark all notifications as read
  - DELETE /notifications/:id — Delete a notification
- User notification preferences (optional enhancement):
  - Per-type enable/disable
  - Store in user profile or separate preferences model
- Integrate with EventBus:
  - Emit notification.created event for real-time delivery
  - Clients can update notification badge via SSE

## Key Files

- `src/models/notification.js` — New notification model
- `src/services/notification-service.js` — Notification creation, triggers, queries
- `src/routes/notifications.js` — Notification API endpoints
- `src/services/event-bus.js` — Emit notification events

## Acceptance Criteria

- [ ] Notifications auto-generated on task assignment
- [ ] Notifications auto-generated on status change
- [ ] Notifications auto-generated on new comments
- [ ] Notifications auto-generated on membership changes
- [ ] Users are not notified about their own actions
- [ ] GET /notifications returns paginated list for current user
- [ ] Unread count endpoint works correctly
- [ ] Mark-read and mark-all-read endpoints functional
- [ ] notification.created events emitted to SSE

## References

- `agent/design/notification-pipeline.md` — Notification trigger rules and pipeline
