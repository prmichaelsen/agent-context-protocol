# Task 82: Complex Auth System Benchmark Task

**Milestone**: M11 - ACP Benchmark Suite
**Estimated Time**: 5-6 hours
**Dependencies**: Task 79 (runner must support multi-turn steps)
**Status**: Completed
**Actual Hours**: 0.5
**Completed**: 2026-02-28

---

## Objective

Create the `complex-auth-system` benchmark task with 5 multi-turn steps (scaffold, auth, test, correction, docs), config, and expected output structure.

---

## Context

The design spec defines a complex-complexity benchmark: adding authentication to an existing app scaffold. This tests the most challenging scenario — working with existing code, implementing security-sensitive features, comprehensive testing, debugging, and documentation. Expected ~10 minutes per run.

---

## Steps

### 1. Create Directory Structure
```
agent/benchmarks/suite/complex-auth-system/
├── config.yaml
├── steps/
│   ├── 01-scaffold.md
│   ├── 02-auth.md
│   ├── 03-test.md
│   ├── 04-correction.md
│   └── 05-docs.md
└── expected/
    └── structure.yaml
```

### 2. Define config.yaml
- name, description, complexity: complex, domain: web/security
- timeout_minutes: 45, runs: 5
- 5 steps with max_turns and phases

### 3. Write Step Prompts
- **01-scaffold.md**: "Create a Node.js/Express app with a users table, basic middleware, and 2 public endpoints: GET /health and GET /public."
- **02-auth.md**: "Add JWT authentication. Implement: POST /auth/register (email+password), POST /auth/login (returns JWT), GET /auth/me (protected, returns user), middleware that validates JWT on protected routes. Hash passwords with bcrypt."
- **03-test.md**: "Add comprehensive tests: registration, login, protected routes, invalid tokens, expired tokens, duplicate registration."
- **04-correction.md**: "The /auth/me endpoint returns the password hash in the response. The token doesn't expire. Fix both security issues — remove password from responses and set token expiry to 1 hour."
- **05-docs.md**: "Add a README.md with: API documentation for all endpoints, setup instructions, environment variables needed, and example curl commands."

### 4. Define Expected Structure
- Expected dirs: src/, src/middleware/, src/routes/, tests/
- Expected files: package.json, src/index.ts, src/routes/auth.ts, src/middleware/auth.ts, tests/*.test.ts, README.md

### 5. Add Verification to verify.sh
- Add `verify_complex_auth_system()` function
- Checks: structure_match, tests_pass, server_starts, auth_endpoints_work, password_not_in_response, readme_exists

---

## Verification

- [x] config.yaml valid with 5 steps (scaffold, auth, test, correction, docs)
- [x] Step prompts build progressively on previous work
- [x] Correction step targets real security issues (password leak, no token expiry)
- [x] expected/structure.yaml covers auth-specific files (routes/auth.js, middleware/auth.js, README)
- [x] verify.sh has verify_complex_auth_system() function

---

**Related Design Docs**: agent/design/local.benchmark-suite.md (Benchmark Task Definition)
