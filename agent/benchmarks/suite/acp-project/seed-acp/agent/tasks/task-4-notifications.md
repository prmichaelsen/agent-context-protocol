# Task 4: Notification System

**Status**: Not Started  
**Estimated Hours**: 3  
**Milestone**: M1 (MVP)  
**Dependencies**: Task 1, Task 2  

## Objective

Implement the notification system as designed in `agent/design/notification-system.md`.

## Steps

1. Create `src/models/notification.js`:
   - `createNotification(userId, type, message, entityType, entityId)` — generates UUID, sets read=false, returns notification
   - `getNotificationsForUser(userId, { unreadOnly, page, limit })` — filtered, paginated
   - `markAsRead(id, userId)` — marks single notification as read, verifies ownership
   - `markAllAsRead(userId)` — marks all user's notifications as read, returns count

2. Rewrite `src/routes/notifications.js`:
   - GET / — list user's notifications with pagination and unreadOnly filter
   - PUT /:id/read — mark single notification as read
   - PUT /read-all — mark all as read

3. Add notification triggers to existing routes:
   - In `src/routes/tasks.js` POST handler: if assigneeId set and != req.user.id → create `task_created` notification
   - In `src/routes/tasks.js` PUT handler: if assigneeId changed → create `task_assigned` notification; if status changed to `done` and task has projectId → create `task_completed` notification for project owner
   - In `src/routes/projects.js` DELETE handler: create `project_archived` notification for users with tasks in that project

4. Use error format and pagination from patterns docs.

## Notification Types and Messages

See `agent/design/notification-system.md` for the complete trigger table with message templates.

## Acceptance Criteria

- Notifications are auto-created when tasks are assigned/completed and projects are deleted
- Users only see their own notifications
- Mark-read and mark-all-read work correctly
- Pagination and unreadOnly filter work
