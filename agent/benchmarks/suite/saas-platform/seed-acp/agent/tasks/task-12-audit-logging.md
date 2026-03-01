# Task 12: Audit Logging

**Status:** not_started
**Milestone:** M3 — Production Hardening
**Estimated Hours:** 3
**Depends On:** task-7

## Objective

Implement an immutable audit log that records all significant actions within
each workspace. Provides a tamper-evident trail for compliance, debugging,
and security review.

## Requirements

- Create AuditLog model:
  - Fields: id, workspaceId, actorId, action, resourceType, resourceId, changes (before/after diff), ipAddress, userAgent, timestamp
  - Immutable: no update or delete operations allowed
  - Append-only storage
- Log all CRUD events:
  - Task: created, updated, deleted, status_changed, assigned
  - Project: created, updated, deleted
  - Comment: created, updated, deleted
  - Workspace: updated, member_added, member_removed, member_role_changed
  - Webhook: created, updated, deleted
- Log authentication events:
  - login_success, login_failure, token_refresh
  - Include IP address and user agent
- Record change diffs:
  - For update operations, store before/after values of changed fields
  - Only log fields that actually changed
  - Never log sensitive data (passwords, tokens) in audit entries
- Implement query API:
  - GET /workspaces/:id/audit-log — Paginated audit log (admin+ only)
  - Filter by: actorId, action, resourceType, resourceId, dateRange
  - Sort by timestamp (newest first by default)
  - Include actor details (name, email) in response

## Key Files

- `src/models/audit-log.js` — New audit log model
- `src/services/audit-service.js` — Audit recording and querying
- `src/routes/audit.js` — Audit log query endpoint
- `src/middleware/audit.js` — Optional middleware for automatic logging

## Acceptance Criteria

- [ ] All CRUD operations generate audit log entries
- [ ] Authentication events (login success/failure) are logged
- [ ] Audit entries include actor, action, resource, and timestamp
- [ ] Update operations include before/after change diffs
- [ ] No sensitive data (passwords, tokens) appears in audit log
- [ ] Audit entries are immutable (no update/delete API)
- [ ] Query API supports filtering by actor, action, resource type, date range
- [ ] Audit log is workspace-scoped and requires admin+ role

## References

- `agent/design/audit-logging.md` — Audit logging design and field specifications
