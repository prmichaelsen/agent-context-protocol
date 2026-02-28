Add comprehensive tests for all API endpoints.

Requirements:
- Install a test framework (Jest, Mocha, or similar) and supertest for HTTP testing
- Create test files in a `tests/` directory
- Add a `test` script to package.json

Test the following scenarios:

**GET /todos**
- Returns 200 with an empty array initially
- Returns all todos after creating some

**GET /todos/:id**
- Returns 200 with the correct todo
- Returns 404 for a non-existent ID

**POST /todos**
- Returns 201 with the created todo (including generated id)
- The created todo has `completed: false` by default
- Returns 400 if `title` is missing or empty

**PUT /todos/:id**
- Returns 200 with the updated todo
- Can update both `title` and `completed`
- Returns 404 for a non-existent ID

**DELETE /todos/:id**
- Returns success for an existing todo
- The todo is actually removed (GET /todos no longer includes it)
- Returns 404 for a non-existent ID

Make sure the server is properly started and stopped for each test (or test suite). Run the tests and confirm they all pass.
