Implement audit logging:

1. AuditLog model: { id, workspaceId, userId, action, entityType, entityId, changes (before/after JSON diff), ipAddress, timestamp }
2. Actions to log: create, update, delete, login, logout, member_added, member_removed, role_changed
3. Entity types: task, project, comment, workspace, member, webhook
4. The audit log is immutable — no update or delete operations on audit records
5. Add middleware or service hooks to automatically log all CRUD operations with the before/after state
6. Add GET /workspaces/:id/audit-log endpoint with filters:
   - userId — filter by who performed the action
   - action — filter by action type
   - entityType — filter by entity type
   - startDate, endDate — date range filter
   - page, limit — standard pagination
7. Sort by timestamp descending (most recent first)
