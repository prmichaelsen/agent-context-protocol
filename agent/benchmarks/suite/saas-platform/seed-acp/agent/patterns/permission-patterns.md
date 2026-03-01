# Pattern: Permission Checks

Express middleware checks workspace role and optionally resource
ownership. Roles: owner (3), admin (2), member (1), viewer (0).

## Permission Matrix

| Resource  | Action | Min Role | Ownership Fallback |
|-----------|--------|----------|--------------------|
| workspace | update | admin    | No                 |
| workspace | delete | owner    | No                 |
| member    | add    | admin    | No                 |
| member    | remove | admin    | No                 |
| task      | create | member   | No                 |
| task      | read   | viewer   | No                 |
| task      | update | admin    | Yes (member)       |
| task      | delete | admin    | Yes (member)       |
| comment   | create | member   | No                 |
| comment   | delete | admin    | Yes (member)       |
| webhook   | manage | admin    | No                 |

"Ownership Fallback": members can act on resources they created.

## requirePermission Middleware

```js
function requirePermission(resource, action) {
  return (req, res, next) => {
    const membership = getMembership(req.userId, req.workspaceId);
    if (!membership) return next(createError('FORBIDDEN', 'Not a member'));
    const required = getRequiredLevel(resource, action);
    if (roleLevel(membership.role) >= required) return next();
    if (hasOwnershipFallback(resource, action) && membership.role === 'member') {
      req._checkOwnership = true;
      return next();
    }
    return next(createError('FORBIDDEN', 'Insufficient permissions'));
  };
}
```

## requireOwnership Middleware

Used after `requirePermission` when ownership fallback applies:

```js
function requireOwnership(resourceGetter) {
  return async (req, res, next) => {
    if (!req._checkOwnership) return next();
    const resource = await resourceGetter(req);
    if (!resource) return next(createError('NOT_FOUND'));
    if (resource.createdBy !== req.userId) return next(createError('FORBIDDEN'));
    return next();
  };
}
```

## Shorthand Helpers

`requireAdmin()`, `requireMember()`, `requireViewer()` — each calls
`requireRole(roleName)` for simple role-gating without ownership.

## Usage

```js
router.put('/api/tasks/:id', authenticate,
  requirePermission('task', 'update'),
  requireOwnership((req) => getTaskById(req.params.id)),
  taskController.update);
```
