Expand the test suite to comprehensively cover all functionality. Target: 50+ tests.

Cover the following areas:

**Users**: Create with valid data, create with missing fields (400), create with duplicate email, get by ID, get non-existent (404), update, delete, list all  

**Projects**: Create with valid data, create with missing name (400), get by ID, get non-existent (404), get project tasks, update, delete (verify cascade behavior), list all  

**Tasks**: Create with valid data, create with missing title (400), create with invalid projectId, get by ID, get non-existent (404), update fields, update status (all valid transitions), update with invalid status (400), delete, list all, filter by status, filter by assignee, filter by priority, filter by projectId  

**Auth**: Request without API key (401), request with invalid key (401), request with valid key (200), API key creation  

**Error handling**: Invalid JSON body, non-existent routes (404), server error handling  

**Edge cases**: Empty string fields, very long strings, special characters, concurrent-like operations (create then immediately read)  

All tests must pass. Run the full suite and report results.