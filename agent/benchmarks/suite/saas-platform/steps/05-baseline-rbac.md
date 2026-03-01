Implement role-based access control with 4 workspace roles:

1. owner — full access: all CRUD, manage members, transfer ownership, delete workspace
2. admin — manage members, full CRUD on tasks/projects/comments, cannot delete workspace or transfer ownership
3. member — create/read/update own tasks and comments, read all tasks/projects, cannot manage members
4. viewer — read-only access to all resources, cannot create/update/delete anything

Implementation:
- Create requirePermission(resource, action) middleware that checks the user's workspace role against a permission matrix
- Create requireOwnership(resourceGetter) middleware for member-level "own resource" checks
- Add shorthand: requireAdmin(), requireMember(), requireViewer()
- Apply to all endpoints — viewers cannot POST/PUT/DELETE, members can only modify their own items
- Owners can PUT /workspaces/:id/transfer-ownership to change workspace owner
