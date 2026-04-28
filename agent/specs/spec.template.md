# Spec: {Spec Name}

<!-- @acp.meta.spec
topic: {comma-separated keywords — e.g. auth, sessions, tokens}
description: {one-line summary, <=150 chars}
requirements: {R1..R<N> or R1, R3, R7}
status: draft
updated: {YYYY-MM-DD}
@acp.meta.end -->

**Namespace**: {namespace}  
**Version**: 1.0.0  
**Created**: YYYY-MM-DD  

---

## Purpose

[One-line statement of what this spec defines. Answer: "when this is implemented, what can someone do that they couldn't before?"]

**Example**: "Authenticate a user against the identity provider and return a session token that downstream services can verify without re-contacting the provider."

---

## Source

- **Mode**: `clarification` | `design` | `draft` | `requirements` | `interactive`
- **File**: `agent/clarifications/clarification-{N}-{slug}.md` (or the source path for other modes; omit for interactive)

---

## Scope

### In Scope
- [What this spec explicitly covers]
- [Another in-scope item]

### Out of Scope
- [What this spec explicitly does NOT cover, even though it might be related]
- [Another out-of-scope item]

---

## Requirements

Numbered, testable requirements. Each must be concrete enough that an implementer can know when they're done, and every requirement must be covered by at least one test in the Tests section.

1. **R1** — [Requirement statement. Must be observable and verifiable.]
2. **R2** — [Requirement statement.]
3. **R3** — [Requirement statement.]

**Example**:
1. **R1** — The system MUST reject login requests with missing `email` or `password` fields and return HTTP 400.
2. **R2** — On successful login, the system MUST issue a JWT signed with the configured secret, valid for 24 hours.
3. **R3** — On invalid credentials, the system MUST return HTTP 401 with a generic error message (no enumeration of which field was wrong).

---

## Behavior Table

The reviewer's scannable proofing surface. One row per scenario. The reviewer scrolls top-to-bottom and flags any row whose `Expected Behavior` doesn't match their expectation, or any scenario they care about that is missing.

**`undefined` rows are REQUIRED** for any scenario the source artifacts did not resolve. These are the highest-value rows for catching misunderstandings before code is written — do NOT silently guess.

| # | Scenario | Expected Behavior | Tests |
|---|----------|-------------------|-------|
| 1 | [short plain-English trigger / input class] | [short plain-English outcome] | `<test-name>` |
| 2 | [another scenario] | [outcome] | `<test-name>`, `<another-test>` |
| 3 | [scenario source did not resolve] | `undefined` | → [OQ-1](#open-questions) |

**Example** (remove before committing):

| # | Scenario | Expected Behavior | Tests |
|---|----------|-------------------|-------|
| 1 | Valid credentials | Returns 200 with a 24h JWT | `login-with-valid-credentials` |
| 2 | Missing email field | Returns 400 with `missing_field`; no DB query | `login-rejects-missing-email` |
| 3 | Wrong password for existing email | Returns 401 with `invalid_credentials` | `login-rejects-invalid-credentials-without-enumeration` |
| 4 | Login attempt for nonexistent email | Returns 401 with `invalid_credentials` (identical to wrong-password) | `login-rejects-invalid-credentials-without-enumeration` |
| 5 | Empty request body | Returns 400; error prioritizes `email` over `password` | `login-with-empty-body` |
| 6 | Email in alternate Unicode normalization | Lookup succeeds; returns 200 | `login-with-unicode-email` |
| 7 | Three rapid successive valid logins | All return 200 with distinct tokens; no extra user writes | `repeated-login-is-idempotent-on-state` |
| 8 | User account is disabled/suspended | `undefined` | → [OQ-1](#open-questions) |
| 9 | Password field exceeds max length (e.g., 10KB) | `undefined` | → [OQ-2](#open-questions) |
| 10 | Login during a password rotation window | `undefined` | → [OQ-3](#open-questions) |

**Rules for the Behavior Table**:
- Exactly four columns: `#`, `Scenario`, `Expected Behavior`, `Tests`
- Keep text short and plain-English; no code, no schemas (those live in the Tests section below)
- `Expected Behavior` must be either a concrete outcome OR the literal bolded word `undefined`
- `Tests` column: comma-separated kebab-case test names from the Tests section, OR `→ [OQ-N](#open-questions)` for undefined rows, OR `—` if truly N/A
- Every test defined below MUST appear in at least one row's `Tests` column
- Every `undefined` row MUST have a matching Open Question
- Row order: happy path, then bad path, then edge cases, then `undefined` rows last (or whatever ordering scans best)

---

## Interfaces / Data Shapes

Concrete schemas, signatures, and wire formats. Use whatever notation is clearest (TypeScript-like, JSON Schema, OpenAPI fragment, pseudo-code). Language-agnostic intent is fine — implementers adapt to their stack.

**Example**:
```
POST /login
Request:  { "email": string, "password": string }
Response 200: { "token": string, "expiresAt": string (ISO-8601) }
Response 400: { "error": "missing_field", "field": "email" | "password" }
Response 401: { "error": "invalid_credentials" }
```

Or for an internal function:
```
verifyToken(token: string) -> { userId: string, expiresAt: timestamp } | null
```

---

## Behavior

Step-by-step of what the implementation does. Describe the flow, not the code.

1. [First step]
2. [Second step]
3. [Third step]

**Example**:
1. Parse the request body and reject with 400 if `email` or `password` is missing.
2. Look up the user record by email (case-insensitive).
3. If no user found, return 401 with `invalid_credentials`.
4. Compare the password against the stored hash using a constant-time comparison.
5. On match, construct a JWT with `sub=userId`, `iat=now`, `exp=now+24h`, sign, and return it.
6. On mismatch, return 401 with `invalid_credentials`.

---

## Acceptance Criteria

Verifiable checklist. Each item must be checkable without reading the implementation.

- [ ] [Acceptance item 1]
- [ ] [Acceptance item 2]
- [ ] [Acceptance item 3]

**Example**:
- [ ] Valid credentials return 200 with a signed JWT whose `exp` is exactly 24h from `iat`.
- [ ] Missing `email` returns 400 with `{ "error": "missing_field", "field": "email" }`.
- [ ] Invalid credentials return 401 with `{ "error": "invalid_credentials" }` regardless of whether the email existed.
- [ ] The response time for invalid-credentials is statistically indistinguishable from valid-credentials (no timing leak).

---

## Tests

Language-agnostic test cases. Each test is `Given` / `When` / `Then`, where `Then` is one or more named assertions. Multiple assertions per test are expected — when a single action produces several observable outcomes, keep them together.

**Do not write code here.** Describe inputs, action, and observable outputs. Implementers translate these directly into their test framework (pytest, jest, go test, bats, etc.).

**This Tests section is the executable contract of the spec.** A reader proofing the spec must be able to find every scenario they care about represented as a test. If a plausible scenario is missing, the spec is incomplete — fix the spec before any code is written. Once the user has signed off, TDD is mechanical: translate each `#### Test:` into a test function, translate each assertion slug into an `assert`/`expect` call, watch it fail, implement, watch it pass.

The Tests section is split into **Base Cases** (the core behavior contract) and **Edge Cases** (boundaries, concurrency, unusual inputs), in that order. Both subsections are required.

**Coverage MUST span all four dimensions across Base + Edge combined**:
- **Happy path** — valid, typical inputs produce expected outputs
- **Bad path** — each distinct error condition and failure mode has its own test
- **Positive assertions** — "X happens" (returns value, emits event, writes record)
- **Negative assertions** — "Y does NOT happen" (no log of secret, no mutation, no timing leak, no extra write)

If you cannot decide the expected behavior for a plausible scenario, put it in **Open Questions** — never guess.

### Base Cases

The core behavior contract: happy path, common bad paths, primary positive and negative assertions. A reader should understand normal operation from this subsection alone.

#### Test: {kebab-case-test-name} (covers R1, R2)

`Given` and `When` may each be a single sentence OR a bulleted list — pick whichever is clearest. Mix forms freely across tests.

**Given**: [Single-sentence precondition]  
**When**: [Single-sentence action]  
**Then** (assertions):
- **{assertion-id}**: [Observable outcome 1 — concrete and checkable]
- **{assertion-id}**: [Observable outcome 2]
- **{assertion-id}**: [Observable outcome 3]

#### Test: {test-with-multi-line-given-and-when} (covers R3)

**Given**:
- [Precondition 1]
- [Precondition 2]

**When**:
- [Action or event 1]
- [Action or event 2]

**Then** (assertions):
- **{assertion-id}**: [...]
- **{assertion-id}**: [...]

### Edge Cases

Boundaries, unusual inputs, concurrency, idempotency, ordering, time-dependent behavior, resource exhaustion. Anything that is explicitly out of scope goes in **Non-Goals** instead; everything else goes here.

#### Test: {edge-case-test-name} (covers R4)

**Given**: [...]  
**When**: [...]  
**Then** (assertions):
- **{assertion-id}**: [...]
- **{assertion-id}**: [...]

---

**Example Tests** (remove this entire example block before committing):

### Base Cases

#### Test: login-with-valid-credentials (covers R2, happy path, positive)

**Given**: A user exists with email `alice@example.com` and password hash matching `correct-horse-battery-staple`.  
**When**: A client sends `POST /login` with `{ "email": "alice@example.com", "password": "correct-horse-battery-staple" }`.  
**Then** (assertions):
- **status-200**: The response status is `200`.
- **token-present**: The response body contains a non-empty `token` field (JWT format: three base64-url segments separated by dots).
- **token-subject**: Decoding the JWT payload yields `sub` equal to the user's ID.
- **token-expiry-24h**: The JWT `exp` claim is exactly `iat + 86400`.
- **expires-at-matches**: The `expiresAt` field in the response equals the JWT `exp` in ISO-8601 form.

#### Test: login-rejects-missing-email (covers R1, bad path, positive + negative)

**Given**: No user lookup has occurred.  
**When**: A client sends `POST /login` with `{ "password": "anything" }`.  
**Then** (assertions):
- **status-400**: The response status is `400`.
- **error-code**: The response body's `error` field equals `"missing_field"`.
- **error-field**: The response body's `field` field equals `"email"`.
- **no-db-query**: No user lookup query is issued to the database. *(negative: the system does NOT hit the DB for malformed input)*
- **no-password-log**: The password value does not appear in any log line emitted during this request. *(negative)*

#### Test: login-rejects-invalid-credentials-without-enumeration (covers R3, bad path, negative)

**Given**:
- A user exists with email `alice@example.com` and a known password hash.
- No user exists with email `nobody@example.com`.
- The timing-measurement harness is running with a 100-trial budget.

**When**:
- A client sends `POST /login` with `{ "email": "alice@example.com", "password": "wrong" }`.
- A client sends `POST /login` with `{ "email": "nobody@example.com", "password": "wrong" }`.

**Then** (assertions):
- **both-return-401**: Both requests return status `401`.
- **identical-error-body**: Both responses have identical body `{ "error": "invalid_credentials" }`.
- **no-enumeration-signal**: No difference in status, body, or header fields reveals which email exists. *(negative)*
- **no-timing-leak**: The two response times are statistically indistinguishable (difference < 5ms median over 100 trials). *(negative)*

### Edge Cases

#### Test: login-with-empty-body (covers R1, edge/bad path)

**Given**: Nothing specific.  
**When**: A client sends `POST /login` with an empty body.  
**Then** (assertions):
- **status-400**: The response status is `400`.
- **error-code**: The response body's `error` field equals `"missing_field"`.
- **error-field-is-email**: Missing-field error prioritizes `email` over `password` when both are missing.

#### Test: login-with-unicode-email (covers R2, edge/happy)

**Given**: A user exists with email `αlice@例え.jp` stored in NFC-normalized form.  
**When**: A client sends `POST /login` with the same email in NFD form and the correct password.  
**Then** (assertions):
- **status-200**: The response status is `200`.
- **normalization-applied**: The lookup succeeds despite the unicode normalization difference between request and stored form.

#### Test: repeated-login-is-idempotent-on-state (covers R2, edge/negative)

**Given**: A user exists with email `alice@example.com` and matching password.  
**When**: A client sends `POST /login` three times in rapid succession with the same valid credentials.  
**Then** (assertions):
- **all-three-return-200**: All three requests return `200`.
- **three-distinct-tokens**: The three returned tokens are all valid but distinct (no token reuse).
- **no-extra-user-writes**: The user record is not written to during any of the three requests. *(negative)*
- **session-count-unchanged**: If the system tracks active sessions, the count increments exactly 3 (not 0, not 1, not 6).

---

**Rules for the Tests section**:

*Structure*
- `### Base Cases` MUST come before `### Edge Cases`; both are required subsections
- Each test is a `####` heading with the form `Test: <kebab-case-name> (covers Rn, Rm)` where `Rn, Rm` are the requirements it covers
- Each test has a `Given` (setup), `When` (action), `Then` (assertions) block
- `Given` and `When` may each be a single sentence or a bulleted list — pick whichever is clearest; mixing forms across tests is fine

*Assertions*
- **At least one assertion per test; multiple assertions per test are the norm** — splitting outcomes of one action into separate tests duplicates setup and obscures that they come from the same operation
- Each assertion has a short identifier slug so it can be referenced in code review, tasks, and handoffs
- Assertions describe **observable outputs** (return values, status codes, emitted events, state changes, log lines, exit codes, side-effect presence/absence) — never internal implementation details
- No language-specific syntax, no mocking library references, no framework-specific types

*Comprehensive coverage (MANDATORY)*
- **Happy path, bad path, positive assertions, and negative assertions** must all appear across Base + Edge combined
- Negative assertions are especially easy to miss — explicitly scan for things that should NOT happen (no secret in logs, no input mutation, no retries on non-retriable errors, no enumeration of existence, no timing leak)
- Every requirement must be covered by ≥1 test; every test annotates `(covers Rn)`
- When in doubt about behavior, write an Open Question instead of guessing in a test

---

## Non-Goals

Explicit exclusions. Things that sound related but are NOT covered here.

- [Non-goal 1]
- [Non-goal 2]

**Example**:
- Password reset flow — covered by a separate spec.
- Multi-factor authentication — future work, not part of this spec.
- OAuth2 federation — out of scope.

---

## Open Questions

Unresolved items that must be answered before or during implementation. Link to clarifications where relevant.

- [ ] [Open question 1]
- [ ] [Open question 2]

**Example**:
- [ ] **OQ-1**: How should login behave for disabled/suspended user accounts? (401 like invalid credentials? 403 with an explicit code? 200 followed by a separate disabled-session signal?) — ties to Behavior Table row #8
- [ ] **OQ-2**: What is the maximum password length the endpoint accepts, and what is the rejection mode beyond it? (413? 400 with a specific error code? truncation?) — ties to Behavior Table row #9
- [ ] **OQ-3**: What behavior do concurrent logins see during a password rotation window? (accept old password until window closes? reject both? race-dependent?) — ties to Behavior Table row #10
- [ ] Should invalid-credentials responses include a `Retry-After` header on repeated failures? — [`clarification-18-auth-rate-limiting.md`](../clarifications/clarification-18-auth-rate-limiting.md)
- [ ] What is the configured JWT secret rotation cadence? Infrastructure decision, owned by @infra.

**Numbering convention**: Use `OQ-N` identifiers so Behavior Table rows can link directly via `→ [OQ-N](#open-questions)`. Keep numbers stable once assigned.

---

## Key Design Decisions (Optional)

<!-- This section is populated by @acp.clarification-capture when
     @acp.spec is invoked with --from-clar, --from-chat, or
     --from-context. It can also be manually authored.
     Omit this section entirely if no decisions to capture.

     Group decisions by agent-inferred category using tables:

### {Category}

| Decision | Choice | Rationale |
|---|---|---|
| {decision} | {choice} | {rationale} |
-->

---

## Related Artifacts

- **Source**: [Link to the source clarification / design / requirements / draft, if any]
- **Related Specs**: [Links to specs that depend on or complement this one]
- **Related Designs**: [Links to the design documents this spec derives from]
- **Tasks**: [Links to tasks created from this spec, once they exist]

---

**Namespace**: {namespace}  
**Spec**: {spec-name}  
**Version**: 1.0.0  
**Created**: YYYY-MM-DD  
**Last Updated**: YYYY-MM-DD  
**Status**: Draft | Active | Deprecated  
**Author**: [Your name or organization]  
