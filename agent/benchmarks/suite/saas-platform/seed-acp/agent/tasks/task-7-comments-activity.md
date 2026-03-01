# Task 7: Comments & Activity Feed

**Status:** not_started
**Milestone:** M2 — Core Features
**Estimated Hours:** 3
**Depends On:** task-5

## Objective

Add a comment system for tasks and a workspace-level activity feed that
aggregates all notable events into a chronological timeline.

## Requirements

- Create Comment model:
  - Fields: id, taskId, authorId, body, createdAt, updatedAt
  - Support editing (track updatedAt)
  - Support soft deletion (deletedAt field, body replaced with "[deleted]")
- Implement Comment CRUD endpoints:
  - POST /tasks/:id/comments — Add comment to task
  - GET /tasks/:id/comments — List comments for a task (paginated)
  - PUT /tasks/:id/comments/:commentId — Edit own comment
  - DELETE /tasks/:id/comments/:commentId — Soft-delete own comment (admin+ can delete any)
- Create Activity model:
  - Fields: id, workspaceId, actorId, action, resourceType, resourceId, metadata, timestamp
  - Actions: created, updated, deleted, status_changed, commented, assigned, member_added, member_removed
- Implement Activity Feed endpoint:
  - GET /workspaces/:id/activity — Paginated activity feed
  - Support filtering by resourceType, action, actorId
  - Default sort: newest first
- Auto-record activity on all mutations:
  - Task CRUD, status changes, assignments
  - Project CRUD
  - Comment CRUD
  - Membership changes

## Key Files

- `src/models/comment.js` — New comment model
- `src/models/activity.js` — New activity model
- `src/services/comment-service.js` — Comment business logic
- `src/services/activity-service.js` — Activity recording and querying
- `src/routes/comments.js` — Comment endpoints
- `src/routes/activity.js` — Activity feed endpoint

## Acceptance Criteria

- [ ] Full comment CRUD on tasks
- [ ] Comments are paginated
- [ ] Only comment author (or admin+) can edit/delete
- [ ] Soft-deleted comments show "[deleted]" body
- [ ] Activity feed records all mutation events
- [ ] Activity feed is filterable and paginated
- [ ] Activity entries include actor, action, resource, and timestamp

## References

- `agent/patterns/api-conventions.md` — Pagination and response format
- `agent/patterns/event-patterns.md` — Event recording patterns
