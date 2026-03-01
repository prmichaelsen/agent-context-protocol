Add an activity tracking system that records all changes made through the API.

**Activity events:**
Every create, update, and delete operation on any entity (user, project, task, team) should record an activity event with:
- id (unique)
- action: "created", "updated", or "deleted"
- entity: "user", "project", "task", or "team"
- entityId: the ID of the affected entity
- userId: who performed the action (from auth context)
- changes: object describing what changed (for updates, include old and new values)
- timestamp

**API:**
- GET /activity — paginated activity feed with limit/offset
- GET /activity?entity=task — filter by entity type
- GET /activity?entityId=123 — filter by specific entity
- GET /activity?userId=456 — filter by who performed the action

**Team scoping:**
- Activity feed must respect team boundaries — users only see activity for their team's resources

**Tests:**
- Verify activities are created for each CRUD operation
- Verify pagination works
- Verify filters work
- Verify team scoping (user cannot see other team's activity)
- All existing tests must still pass