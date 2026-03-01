Add a teams system to the application. This is a major feature that touches every part of the codebase.

**Team entity:**
- Fields: id, name, description, createdAt
- CRUD endpoints: POST /teams, GET /teams, GET /teams/:id, PUT /teams/:id, DELETE /teams/:id

**User-Team relationship:**
- Add teamId field to users
- A user belongs to exactly one team
- POST /users now requires teamId
- GET /teams/:id/members returns users in that team

**Project-Team scoping:**
- Add teamId field to projects
- Projects belong to a team
- POST /projects now requires teamId (or inherits from the creating user's team)
- A user can only see and modify projects in their own team

**Task-Team scoping:**
- Tasks inherit teamId from their project
- A user can only see and modify tasks in their own team

**Team-scoped queries:**
- All list endpoints (/users, /projects, /tasks) must accept an optional ?teamId= filter
- When a user makes a request, they should only see resources belonging to their team

**Tests:**
- Add tests for team CRUD
- Add tests verifying team scoping (user in team A cannot see team B's projects/tasks)
- All existing tests must be updated to work with the new teamId requirement
- All tests must pass