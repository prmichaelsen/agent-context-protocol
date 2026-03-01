Add a comprehensive test suite for the refactored Notes API.

Requirements:

1. Install a test framework (Jest or Mocha) and supertest
2. Add a `test` script to package.json
3. Create tests in `tests/` directory covering:

**GET /notes** (list all):
- Returns empty array when no notes exist
- Returns all notes after creating some

**POST /notes** (create):
- Creates a note with valid title and content, returns 201
- Creates a note with title only (no content), returns 201
- Returns the created note with id, title, content, and timestamps

**GET /notes/:id** (get one):
- Returns a note that exists
- Returns 404 for a note that doesn't exist
- Returns 404 for an invalid ID

**PUT /notes/:id** (update):
- Updates title of an existing note
- Updates content of an existing note
- Returns the updated note with new updatedAt timestamp

**DELETE /notes/:id** (delete):
- Deletes an existing note, returns 204
- Returns 404 for a note that doesn't exist

**GET /health** (health check):
- Returns status ok with noteCount

**Edge cases**:
- Creating a note with empty string title
- Very long title or content
- Updating with no fields provided

All tests must pass. Run the test suite to verify.