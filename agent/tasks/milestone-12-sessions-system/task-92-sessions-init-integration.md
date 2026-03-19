# Task 92: Init and Report Integration

**Milestone**: M12 — Sessions System  
**Status**: Not Started  
**Estimated Hours**: 1-2  
**Dependencies**: Task 91  
**Design**: [local.sessions-system.md](../../design/local.sessions-system.md)  

---

## Objective

Add directive-level (markdown) integration of sessions into `@acp.init`, `@acp.status`, and `@acp.report` commands. These are optional steps that gracefully skip if `acp.sessions.sh` is not present.

---

## Context

Integration is at the markdown directive level only — we add new steps to the command `.md` files. We do NOT modify any `.sh` scripts for existing commands. If `acp.sessions.sh` doesn't exist, agents simply skip the session step.

---

## Steps

### 1. Update @acp.init (acp.init.md)
- Add new step after "Check for ACP Updates" (early in init):
  - "Run `./agent/scripts/acp.sessions.sh register --project <current-project>` if script exists"
  - "Run `./agent/scripts/acp.sessions.sh list` and display active sibling sessions"
- Display format (compact, one line per sibling):
  ```
  Active Sessions: 2 others
    remember-core — task-12 (Implement Auth) — 20m ago
    agentbase.me — task-5 (Fix API Routes) — 8m ago
  ```
- Add to expected output template
- Note: "If acp.sessions.sh does not exist, skip this step silently"

### 2. Update @acp.status (acp.status.md)
- Add step to show session count:
  - "Run `./agent/scripts/acp.sessions.sh count` if script exists"
  - Display: `"Sessions: N active"` in status output
- Note: "If acp.sessions.sh does not exist, omit Sessions line"

### 3. Update @acp.report (acp.report.md)
- Add final step:
  - "Run `./agent/scripts/acp.sessions.sh deregister` if script exists"
  - Display: `"Session deregistered"` in report footer
- Note: "If acp.sessions.sh does not exist, skip this step silently"

---

## Verification

- [ ] `acp.init.md` has session registration and sibling display step
- [ ] `acp.status.md` has session count step
- [ ] `acp.report.md` has session deregistration step
- [ ] All steps include "if script exists" guard
- [ ] Display formats match design spec
- [ ] No changes to any `.sh` files for existing commands
- [ ] Existing command behavior unchanged when sessions.sh is absent

---

## Notes

- Keep changes minimal — add one step per command, clearly marked as optional
- Use consistent language: "If `./agent/scripts/acp.sessions.sh` exists, run..."
- Don't rewrite or restructure existing command steps
