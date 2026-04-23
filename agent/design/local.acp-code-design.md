# acp-code: Python + SQLite Fork of ACP

**Concept**: A project fork of ACP reimplemented in Python, replacing the bash/yaml persistence model with a library-first architecture backed by SQLite + an authoritative event log, extensible through a VSCode-style plugin system.  
**Created**: 2026-04-23  
**Status**: Proposal  

---

## Overview

`acp-code` is a ground-up reimplementation of the Agent Context Protocol concept as a Python library with three peer-level adapters (MCP server, CLI, REST API) and a plugin system for extensibility. It is a **project fork**, not a code fork — no bash code is copied — and it coexists with the bash-based ACP rather than replacing it. Projects opt into acp-code by installing the fork and swapping their `.sh` scripts for `.py` equivalents.

The central architectural move is replacing `progress.yaml` as the authoritative state store with two artifacts: an append-only `events.jsonl` log (the true source of truth) and a derived SQLite database (`.acp/local.db`, gitignored, materialized view over events + markdown files). This enables per-event audit trails, time-travel views, undo, and plugin-contributed extensions to the core task/milestone model.

---

## Problem Statement

Bash-based ACP has served its purpose as the reference implementation of the methodology, but several limitations are structural rather than incidental:

- **`progress.yaml` is not diffable in useful ways.** A single task status change produces a large reformatting diff that obscures what actually changed. Audit history is reconstructible only from git log messages.
- **No extension mechanism.** New capabilities (task types, custom workflows, third-party integrations) require either bash script contributions to the core repo or unstructured conventions. There is no "plugin" story.
- **No undo or time-travel.** The current state is authoritative; prior states are recoverable only by `git checkout`.
- **Cross-platform constraints.** Bash scripts mean Unix-only (already true), but more pressingly, shell script maintenance has hit a complexity ceiling (`acp.common.sh` is 1700 lines, `acp.yaml-parser.sh` 971).
- **No introspection surface.** An LLM agent cannot ask "what milestone is task-37 on?" without parsing yaml; there is no queryable state.

These problems compound. The "methodology first" positioning of ACP is sound, but the bash substrate is no longer the best medium for the next order of features.

---

## Solution

Reimplement ACP in Python with four architectural pillars:

**1. Library-first with peer adapters.** The core is a Python library exposing the ACP data model and operations. Three thin adapters (~1 file of glue each) surface it via MCP tools, CLI subcommands, and REST endpoints. None is privileged; the library is the testable unit, the adapters are interchangeable transports. This lets `acp clar address` in a terminal, an MCP-driven LLM tool call, and an HTTP request all go through identical code paths.

**2. Events as authoritative state.** Every write operation emits a structured event appended to `agent/events.jsonl` (git-committed, human-readable, diffable). The SQLite DB is a materialized view rebuildable from events + markdown files via `@acp.reindex`. Binary DB file is gitignored; the commit surface stays diffable. Undo, time-travel, and audit are all views over the event log.

**3. VSCode-style plugin system.** Plugins are Python packages with a four-hook lifecycle (`install` / `activate` / `deactivate` / `uninstall`). A `PluginAPI` capability object is constructed per-plugin at activation time with the plugin's `(name, version)` identity bound in — plugins cannot forge records as other plugins. Plugin state is **isolated**: each plugin owns its own tables, accessible only through its own `api.db`. Cross-plugin interop goes through explicitly exposed **commands**, not ambient SQL joins. This borrows VSCode's extension-isolation discipline directly.

**4. Core vs plugin boundary.** The core (`tasks`, `milestones`/`progress`, events/audit framework, plugin loader, command registry, adapters) ships with every install. Plugins extend the core with third-party integrations, domain-specific contributions, and novel command surfaces — but cannot replace or reach into it.

---

## Implementation

### Project Structure

```
acp-code/                      # monorepo on github.com/prmichaelsen/acp-code
├── pyproject.toml             # uv-managed, Python >= 3.12
├── uv.lock
├── src/
│   ├── acp_code/
│   │   ├── core/              # non-pluggable foundation
│   │   │   ├── tasks.py
│   │   │   ├── milestones.py
│   │   │   ├── events.py      # events.jsonl writer + replayer
│   │   │   ├── plugin_loader.py
│   │   │   ├── plugin_api.py  # PluginAPI + PluginContext classes
│   │   │   └── commands.py    # command registry
│   │   ├── adapters/
│   │   │   ├── mcp_server.py
│   │   │   ├── cli.py
│   │   │   └── rest.py
│   │   └── db/
│   │       ├── schema.py
│   │       └── readonly.py
│   └── acp_plugins/           # (empty at v1; canonical plugins TBD)
└── tests/
```

Project marker (signals a project uses acp-code):
```
.acp/
├── acp-code.yaml              # committed; framework reads to determine mode
└── local.db                   # gitignored; derived
agent/
├── events.jsonl               # committed; authoritative
├── tasks/*.md                 # committed; authoritative
├── milestones/*.md            # committed; authoritative
└── plugins/<ns>/<name>/       # committed if --local install
```

### PluginAPI Surface

```python
class PluginAPI:
    """Constructed per-plugin at activation; identity bound immutably."""
    name: str           # plugin name (immutable after construction)
    version: str        # plugin version (immutable after construction)
    db: Connection      # read-write, scoped to this plugin's tables only
    logger: Logger      # namespaced logger

    def register_table(self, name: str, migrations: list[Migration]) -> None:
        """Create table '<self.name>__<name>'. Prefix auto-prepended; no raw CREATE TABLE escape hatch."""

    def register_command(self, name: str, handler: Callable, mcp_description: str) -> None:
        """Contribute a command callable from other plugins and surfaced as an MCP tool."""

    def register_event_handler(self, event_kind: str, handler: Callable) -> None: ...

    def query_readonly(self, sql: str) -> list[Row]:
        """Ad-hoc read queries, scoped to this plugin's tables only."""

    class events:
        def record(self, kind: EventKind, entities: list[EntityRef],
                   op: str, before: dict | None, after: dict | None,
                   meta: dict) -> str:
            """Emit an event. Framework auto-stamps id, ts, plugin_name, plugin_version."""

    class config:
        def get(self, key: str, default=None): ...

@dataclass
class PluginContext:
    """What the plugin owns and must clean up."""
    subscriptions: list[Disposable]
```

Plugin entry points:
```python
def install(api: PluginAPI, context: PluginContext) -> None: ...
def activate(api: PluginAPI, context: PluginContext) -> None: ...
def deactivate(context: PluginContext) -> None: ...
def uninstall(api: PluginAPI, context: PluginContext) -> None: ...
```

### Plugin Manifest (`plugin.yaml`)

```yaml
name: my-plugin
version: 1.2.0
namespace: prmichaelsen
api_version: "1.x"
dependencies:
  - name: other-plugin
    version: ">=1.0"
activation_events:
  - onCommand:my-plugin.*
contributes:
  tables: [things]
  commands:
    - name: my-plugin.do-something
      description: "..."
  event_handlers:
    - event: task.state_transition
      handler: handle_task_change
```

Plugins are Python. `pyproject.toml` handles deps/tooling; `plugin.yaml` handles the ACP contract. Neither file knows about the other's fields.

### Event Schema

```json
{
  "id": "01928f3e-....-....-....",
  "ts": "2026-04-23T15:04:05.123Z",
  "plugin_name": "progress",
  "plugin_version": "1.0.0",
  "kind": "state_transition",
  "entities": [
    {"type": "task", "id": "task-37"},
    {"type": "milestone", "id": "m6"}
  ],
  "op": "task.complete",
  "before": {"status": "in_progress"},
  "after": {"status": "completed"},
  "meta": {}
}
```

- `id`: UUIDv7 (time-ordered, no serialization bottleneck)
- `kind`: closed enum — `state_transition | edit | automation | custom`
- `entities`: multi-entity attribution (lets an event appear in both a task's and a milestone's visualizer panel)
- `before` / `after`: drives undo (`sqlite3changeset_invert` semantics apply for rich cases)

### Migrations

- Location: `<plugin>/migrations/NNNNN_slug.{sql,py}`
- Numbering: per-plugin, 5-digit zero-padded
- Format: `.sql` for schema-only, `.py` for logic (`def up(conn)` / `def down(conn)`)
- `up` and `down` both required. No opt-out. Migration discipline is a safety-critical invariant.
- Execution: each migration inside a `SAVEPOINT`. Failure rolls back that migration only; earlier succeeded migrations stay committed. Plugin marked `partially_migrated`, refuses to activate until resolved.
- Every migration emits an event (`kind: automation`, `op: migration.up|down`), so migration history joins the audit trail and time-travel.

### New Commands (v1)

| Command | Purpose |
|---|---|
| `@acp.reindex` | Rebuild `.acp/local.db` from files + events |
| `@acp.undo [N]` | Reverse last N events; writes inverse events |
| `@acp.time-travel <ISO-ts>` | Read-only snapshot of state at T |
| `@acp.plugin-install <name\|url>` | Install to `~/.acp/plugins/` (`--local` → `agent/plugins/`) |
| `@acp.plugin-search <query>` | Search canonical plugin registry |
| `@acp.plugin-list` | List installed plugins with versions |
| `@acp.plugin-uninstall <name>` | Run uninstall hook, remove dir |
| `@acp.plugin-validate` | Lint a plugin (schema, migrations, manifest) |

### Visualizer

Deferred to a separate repo (`acp-code-viz`, web-based). MVP is read-only: task/milestone detail views with attached audit log, time-travel slider, plugin-attribution badges. Consumes `events.jsonl` + DB via read-only MCP tools. Read-only because editing would either require exposing every plugin's write paths or bypassing isolation — neither is acceptable.

---

## Benefits

- **Diffable history.** Every state change is a line in `events.jsonl`; `git diff` becomes a meaningful audit trail without ceremony.
- **Reconstructible state.** `rm .acp/local.db && @acp.reindex` is always safe. DB corruption is never catastrophic.
- **Undo, time-travel, audit — by construction.** Event sourcing means these aren't separate systems; they're views over the same log.
- **Genuine plugin ecosystem.** Third parties can contribute functionality without forking the core. Install/uninstall hooks handle system-level setup (brew, data downloads).
- **Isolation prevents ecosystem rot.** Plugins cannot quietly couple to each other's schemas. Cross-plugin changes become visible via command-contract bumps.
- **Better LLM introspection.** The agent queries through `api.query_readonly(sql)` or calls plugin commands surfaced as MCP tools with descriptions — no yaml parsing, no schema guessing.
- **Backward compatibility.** Bash ACP is not deprecated. Migration is opt-in and mechanical (swap scripts).

---

## Trade-offs

- **Python runtime dependency.** Bash ACP needed only `bash` + coreutils. acp-code requires Python ≥ 3.12 + uv. This is a real install burden for some users; mitigated by documenting installation clearly and keeping bash ACP supported indefinitely.
- **Plugin isolation limits the "ad-hoc SQL across everything" use case.** An agent cannot join `pluginA__foo` with `pluginB__bar` at the SQL level. Must route through exposed commands. This is the correct trade for ecosystem health, but it is a trade.
- **Event log grows unboundedly.** At tens of thousands of events/year, disk cost is trivial (20–50 MB per 100k events) and replay remains fast. At orders of magnitude larger volume, reindex becomes slow; snapshots can be added later if profiling demands.
- **Two implementations to maintain.** Bash ACP and acp-code evolve independently. Keeping them conceptually aligned requires discipline; divergence in semantics will happen.
- **Plugin authors must think about stable contracts.** Isolation forces every cross-plugin touchpoint to be a deliberate API decision (a command with a description, a stable ordering, a versioning policy). This is more rigor than casual authorship; it's the cost of keeping the ecosystem non-rotting.

---

## Dependencies

- **Python** ≥ 3.12
- **uv** as package manager; `pyproject.toml` + `uv.lock` committed
- **SQLite** (stdlib via Python's `sqlite3`; `apsw` optional if we adopt the session extension for richer undo)
- **MCP SDK** (Anthropic-published) for the MCP server adapter
- **FastAPI** or similar for the REST adapter
- No external DB server; no network services; Unix-only (macOS, Linux)

---

## Testing Strategy

- **Unit tests** per core module (events, plugin loader, migration runner, command registry) with the library directly imported.
- **Adapter tests** verify MCP/CLI/REST produce identical results for the same library call.
- **Plugin framework tests**: isolation (plugin A cannot touch plugin B's tables), identity (plugin cannot forge events as another plugin), lifecycle (four hooks fire in order, disposables run on deactivate).
- **Event-replay determinism**: for each test scenario, write events, reindex from zero, assert DB state is identical to in-flight state.
- **Migration tests**: `up` then `down` must round-trip schema (not necessarily data). `SAVEPOINT` failure behavior verified by injecting errors.
- **Time-travel tests**: replay up to T, assert state matches expected snapshot.
- **Undo tests**: emit events, run undo, assert DB state matches pre-events state.

---

## Migration Path

Migration from bash ACP to acp-code is **mechanical, not data-driven**. There is no `@acp.migrate-to-code` and no synthetic event replay — fabricated history poisons the audit log.

1. In the target project, install acp-code (`pip install acp-code` or equivalent via uv).
2. Create `.acp/acp-code.yaml` marker file and commit it. This signals the project has switched modes.
3. Replace each `.sh` script with its `.py` equivalent (or delete scripts that had acp-code analogs built in).
4. Delete bash ACP from the project.
5. Fresh `events.jsonl` starts from that commit. `progress.yaml` remains in git history for reference; the new install does not reconstruct it as events.

A project is **either bash-ACP or acp-code**, never both simultaneously. The marker file (`.acp/acp-code.yaml`) is the invariant.

---

## Key Design Decisions

### Architecture

| Decision | Choice | Rationale |
|---|---|---|
| Project shape | Library-first with 3 peer adapters (MCP, CLI, REST) | Keeps the library design honest as a plain Python API; no adapter is privileged; all three surfaces are interchangeable transports |
| Core vs plugin boundary | `tasks`, `milestones`/`progress`, events framework are **core** (not plugins) | Foundational concepts shouldn't be optional; plugins extend the core, they don't replace it |
| Plugin interop model | VSCode-style isolation: private tables, cross-plugin access via exposed commands | Hidden schema coupling is how plugin ecosystems rot; commands are self-describing and stable, schemas drift silently |
| Plugin API delivery | Two-arg activate: `(api: PluginAPI, context: PluginContext)` | Mirrors VSCode's `activate(context)`; cleanly splits "what you can do" (capability) from "what you own" (lifecycle) |
| Plugin identity | `(name, version)` bound into `api` at construction; auto-stamped on events and rows | Plugins structurally cannot forge records as another plugin |
| Plugin lifecycle | Four hooks: `install` / `activate` / `deactivate` / `uninstall` | Matches real plugin needs; install handles system setup (brew, data downloads), activate handles per-session init |
| Activation model | Lazy (on first command invocation or event handler fire) | Fast startup, no cost for unused plugins, failed activations only hit users who try to use them |
| Guiding principle | Framework enforces safety-critical constraints (isolation, identity, namespacing); does not prevent architectural mistakes (cycles, bad command design) | "Let people write bad plugins" — paternalism without a safety benefit adds cost without return |

### Persistence

| Decision | Choice | Rationale |
|---|---|---|
| Database | SQLite, not PostgreSQL | File-based, committable-adjacent, zero install dependency, `sqldiff` ships with it |
| Source of truth | `events.jsonl` + markdown files; DB is derived | Reindex always safe; binary DB file doesn't pollute git diff |
| DB location | `.acp/local.db` (gitignored) | Not committed because binary files churn on every write |
| Event durability | `fsync` per event in v1 | Prefer durability over throughput until the access pattern is understood |
| Snapshots | Not in v1 | Premature optimization; replay from zero is milliseconds at expected volumes |
| Event log rotation | Never compact or rotate | Log is the only persistent artifact of history; rotation destroys the audit trail |
| Undo history | No cap | No engineering reason to refuse at any particular N; UX just means more inverse events |
| Project mode marker | `.acp/acp-code.yaml` (committed) | DB is gitignored and unreliable cross-machine; explicit marker works |

### Event System

| Decision | Choice | Rationale |
|---|---|---|
| Event ID | UUIDv7 | Time-ordered + sortable + no coordination; no single serialization point |
| Event kind | Closed enum: `state_transition | edit | automation | custom` | Keeps visualizer's severity tiers stable; `custom` + `meta.subkind` is the escape hatch |
| Write path | Only `api.events.record(...)` | Framework auto-stamps identity; plugins cannot bypass |
| Schema stamping | One column `_written_by_plugin_version` on every row | Name is redundant under isolation; version is the audit data that matters |

### Runtime & Tooling

| Decision | Choice | Rationale |
|---|---|---|
| Language | Python ≥ 3.12 | `tomllib` in stdlib, PEP 695 type aliases, broadest install base as of 2026 |
| Package manager | `uv`; `pyproject.toml` + `uv.lock` committed | Current idiomatic Python tooling; no requirements.txt, no poetry |
| Platforms | macOS + Linux only | Unix-derived; Windows deferred |
| Plugin language | Python only | Interoperability with PluginAPI requires it |
| Plugin manifest | `plugin.yaml` + `pyproject.toml` (two files, two contracts) | ACP contract separate from Python-package concerns; neither file knows the other's fields |

### Migrations

| Decision | Choice | Rationale |
|---|---|---|
| Format | `.sql` for schema, `.py` for logic (hybrid) | Neither pure-SQL nor Alembic-all-Python wins universally |
| Numbering | Per-plugin, 5-digit zero-padded | Plugins develop independently; no global sequence coordination |
| Reversibility | `up` and `down` both always required, no opt-out | Migration discipline is safety-critical; data-loss docs belong in `down()` comments |
| Failure mode | Per-migration `SAVEPOINT`; partial plugin activation blocked | Committed migrations stay committed; failed migration rolls back locally |
| Audit | Migrations emit `automation` events | Migration history is part of audit trail and time-travel; undo on migration event runs `down()` |

### Dependencies & Versioning

| Decision | Choice | Rationale |
|---|---|---|
| Plugin deps | Allowed, declared in `plugin.yaml` with version constraints | Normal package ecosystem behavior |
| Circular deps | Allowed (no cycle check) | Paternalism without safety benefit; cycle detection adds framework complexity; npm/pip allow them |
| API versioning | `api_version` in `plugin.yaml`; framework refuses incompatible loads | Establishes compat contract from day one instead of retrofitting |

### Scope

| Decision | Choice | Rationale |
|---|---|---|
| Relationship to bash ACP | Project fork (not code fork) | Different language, different persistence; shares only concepts |
| Migration from bash ACP | Mechanical script swap, no data migration | Synthetic events are theater; real audit only captures what actually happens |
| Bash ACP support | Continues indefinitely | acp-code is an optional upgrade path, not a replacement |
| First canonical plugins | TBD (deferred, not blocking v1) | Framework must ship before the plugin ecosystem can be evaluated |
| Visualizer | Deferred to separate repo (`acp-code-viz`), read-only MVP | Different product, different dev cycle; editing from visualizer would break isolation |

---

## Future Considerations

- **Canonical plugin candidates** (post-v1): `git` (auto-events from commits), `benchmark` (port of ACP's existing benchmark system), `linear` / `github` bridges, `audit-views` (rollup queries and reports).
- **SQLite session extension** for richer undo (via `apsw`). The `sqlite3_session_*` APIs record changesets as first-class objects and `sqlite3changeset_invert` gives native reverse application. Evaluate when undo UX feedback is available.
- **Snapshots** if profiling shows event replay is a bottleneck. The cost of adding later is low because `events.jsonl` was the source of truth all along.
- **Plugin registry** — v1 searches the monorepo's canonical plugins. Longer term: a lightweight registry (YAML file on GitHub, or a thin server) with install-by-name support.
- **Windows** — deferred explicitly. If user demand materializes, the Python core is portable; the install scripts and shell-adjacent parts need rework.
- **Visualizer write operations** — v1 is read-only. Future consideration: allow the visualizer to invoke plugin commands via MCP (same surface as the LLM), which preserves isolation.

---

**Status**: Proposal  
**Recommendation**: Treat this as the spec for bootstrapping `github.com/prmichaelsen/acp-code`. Next concrete steps: create the repo, set up the `uv` project skeleton, implement the core library (`tasks`, `events`, plugin loader) + MCP adapter, write one canonical plugin (`git` integration is a good candidate) to validate the PluginAPI surface.  
**Related Documents**: `agent/clarifications/clarification-14-acp-code-design.md` (source clarification; status: Captured).  
