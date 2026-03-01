Analyze the existing codebase thoroughly. Examine every file in models/, routes/, middleware/, and utils/. Look for:

1. Security vulnerabilities (authentication, authorization, data exposure)
2. Logic bugs (incorrect conditions, missing validations, wrong status codes)
3. Architecture problems (mixed concerns, missing layers, inconsistent patterns)
4. Missing features (incomplete CRUD, stub implementations)
5. Inconsistencies (error formats, response shapes, naming)

Document all findings in ANALYSIS.md with sections:
- Critical Bugs (security issues, logic errors)
- Architecture Issues (structural problems)
- Missing Features (stubs, incomplete endpoints)
- Recommended Fix Order (prioritized action plan)
