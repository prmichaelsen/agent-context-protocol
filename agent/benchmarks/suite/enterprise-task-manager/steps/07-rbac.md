Add role-based access control to the application.

**Roles** (from most to least privileged):

- **admin**: Full access to everything in their team. Can manage team settings and members. Can assign any role.
- **manager**: Can create/update/delete projects. Can create/assign tasks to any team member. Can view all team data. Cannot manage team settings or change roles.
- **member**: Can create tasks. Can update tasks assigned to them. Can view projects and tasks in their team. Cannot create/modify projects or manage users.
- **viewer**: Read-only access to all resources in their team. Cannot create, update, or delete anything.

**Implementation:**

1. Add a role field to users (default: "member")
2. Create RBAC middleware that checks the user's role before allowing operations
3. Apply RBAC to every endpoint:
   - POST /teams, PUT /teams/:id, DELETE /teams/:id — admin only
   - POST /projects, PUT /projects/:id, DELETE /projects/:id — admin, manager
   - POST /tasks — admin, manager, member
   - PUT /tasks/:id — admin, manager, or the assigned member
   - PUT /tasks/:id/status — admin, manager, or the assigned member
   - DELETE /tasks/:id — admin, manager
   - GET endpoints — all roles (viewer and above)
   - User management (PUT /users/:id role changes) — admin only

**Tests:**
- For each role, test that allowed operations succeed and denied operations return 403
- Test that a member can only update their own assigned tasks
- Test role assignment (only admin can change roles)
- All existing tests must still pass (update test setup to use appropriate roles)