Implement workspace multi-tenancy:

1. Add a WorkspaceMember model: { workspaceId, userId, role (owner/admin/member/viewer), joinedAt }
2. Auto-create a WorkspaceMember with role "owner" when a workspace is created
3. Add an x-workspace-id header middleware that validates the header, checks membership, and attaches workspace context to the request
4. Scope ALL data queries by workspaceId — tasks, projects, comments should only return data within the current workspace
5. Complete workspace CRUD: add PUT /workspaces/:id and DELETE /workspaces/:id
6. Add membership endpoints: POST /workspaces/:id/members (add member), DELETE /workspaces/:id/members/:userId (remove member), GET /workspaces/:id/members (list members)
7. Users can only access workspaces they are members of
