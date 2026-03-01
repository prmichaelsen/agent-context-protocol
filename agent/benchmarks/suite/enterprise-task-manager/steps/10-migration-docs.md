Create comprehensive documentation for the application.

**MIGRATION.md:**
Document all breaking changes from the original API:
- New required fields (teamId on users and projects)
- Changed response formats (paginated responses, standardized errors)
- New authentication requirements (auth on all routes)
- RBAC restrictions (what each role can and cannot do)
- Rate limiting
- Include a section with before/after examples for each breaking change

**README.md:**
- Project description
- Setup instructions (install, environment variables, start, test)
- Authentication guide (how to create and use API keys)
- RBAC roles table with permissions matrix
- Complete API documentation for every endpoint with request/response examples
- Team scoping explanation
- Pagination, sorting, and search guide with examples
- Activity feed usage

**ARCHITECTURE.md:**
- System overview and data model with relationships
- Middleware chain description (auth → RBAC → validation → route handler → error handler)
- How team scoping works
- How activity tracking works
- How RBAC is enforced
- Design decisions and trade-offs made during development

All tests must pass. Run the full suite one final time.