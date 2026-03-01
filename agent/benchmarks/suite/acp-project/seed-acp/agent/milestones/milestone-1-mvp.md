# Milestone 1: MVP

## Goal

Complete the TaskFlow API with full CRUD for tasks and projects, a notification system, comprehensive tests, and API documentation.

## Success Criteria

- [ ] Task CRUD: all 5 operations work with validation, pagination, filtering, sorting
- [ ] Project CRUD: all 5 operations work with validation, pagination, cascade delete
- [ ] Notification system: auto-created on task/project events, list/mark-read endpoints work
- [ ] Test suite: 30+ tests covering all endpoints, all passing
- [ ] README: setup instructions, full API documentation with examples
- [ ] All error responses follow the standard format from `agent/patterns/error-handling.md`
- [ ] All list endpoints return paginated responses per `agent/patterns/api-conventions.md`

## Scope

- In-memory storage only (no database)
- No WebSocket/real-time — notifications are polled via GET
- No file uploads
- No rate limiting
- Single-user JWT auth (no roles beyond member/admin distinction)

## Tasks

1. **task-1**: Implement Task CRUD (3h)
2. **task-2**: Implement Project CRUD (2h)
3. **task-3**: Comprehensive Test Suite (4h)
4. **task-4**: Notification System (3h)
5. **task-5**: API Documentation (2h)
